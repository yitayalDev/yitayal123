const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const Service = require('../models/Service');
const Appointment = require('../models/Appointment');

// @route   GET api/services
// @desc    Get all services
// @access  Public
router.get('/', async (req, res) => {
    try {
        const services = await Service.find().populate('providerId', 'name email isAvailable category');
        res.json(services);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/services
// @desc    Create a service
// @access  Private (Provider/Admin)
router.post('/', [auth, checkRole(['provider', 'admin'])], async (req, res) => {
    const { name, description, duration, category, availability } = req.body;

    try {
        const newService = new Service({
            name,
            description,
            duration,
            category,
            availability,
            providerId: req.user.id
        });

        const service = await newService.save();
        res.json(service);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PUT api/services/:id
// @desc    Update a service
// @access  Private (Provider/Admin)
router.put('/:id', [auth, checkRole(['provider', 'admin'])], async (req, res) => {
    const { name, description, duration, category, availability } = req.body;

    try {
        let service = await Service.findById(req.params.id);
        if (!service) return res.status(404).json({ msg: 'Service not found' });

        // Make sure user owns service or is admin
        if (service.providerId.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(401).json({ msg: 'User not authorized' });
        }

        service = await Service.findByIdAndUpdate(
            req.params.id,
            { $set: { name, description, duration, category, availability } },
            { new: true }
        );

        res.json(service);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/services/:id
// @desc    Delete a service (and its associated appointments)
// @access  Private (Provider/Admin)
router.delete('/:id', [auth, checkRole(['provider', 'admin'])], async (req, res) => {
    try {
        const service = await Service.findById(req.params.id);
        if (!service) return res.status(404).json({ msg: 'Service not found' });

        // Make sure user owns service or is admin
        if (service.providerId.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(401).json({ msg: 'User not authorized' });
        }

        // Delete all appointments booked for this service
        await Appointment.deleteMany({ serviceId: req.params.id });

        // Delete the service itself
        await Service.findByIdAndDelete(req.params.id);

        res.json({ msg: 'Service and associated appointments removed' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
