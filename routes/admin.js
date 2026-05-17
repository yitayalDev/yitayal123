const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const User = require('../models/User');
const Service = require('../models/Service');
const Appointment = require('../models/Appointment');

const Message = require('../models/Message');
const Notification = require('../models/Notification');
const Review = require('../models/Review');

// TEMPORARY: Endpoint to clear database from production
router.get('/clear-database-now', async (req, res) => {
    try {
        await User.deleteMany({});
        await Service.deleteMany({});
        await Appointment.deleteMany({});
        await Message.deleteMany({});
        await Notification.deleteMany({});
        await Review.deleteMany({});
        res.send('<h1>✅ Database successfully wiped from production!</h1>');
    } catch (err) {
        console.error('Error clearing database:', err);
        res.status(500).send('Error clearing database: ' + err.message);
    }
});

// @route   GET api/admin/stats
// @desc    Get system-wide stats
// @access  Private (Admin)
router.get('/stats', [auth, checkRole(['admin'])], async (req, res) => {
    try {
        const totalUsers = await User.countDocuments({ role: 'user' });
        const totalProviders = await User.countDocuments({ role: 'provider' });
        const totalAppointments = await Appointment.countDocuments();
        
        const pending = await Appointment.countDocuments({ status: 'pending' });
        const approved = await Appointment.countDocuments({ status: 'approved' });
        const rejected = await Appointment.countDocuments({ status: 'rejected' });

        res.json({
            users: totalUsers,
            providers: totalProviders,
            appointments: totalAppointments,
            statusBreakdown: { pending, approved, rejected }
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/admin/users
// @desc    Get all users
// @access  Private (Admin)
router.get('/users', [auth, checkRole(['admin'])], async (req, res) => {
    try {
        const users = await User.find().select('-password').sort({ createdAt: -1 });
        res.json(users);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/admin/users/:id
// @desc    Delete a user
// @access  Private (Admin)
router.delete('/users/:id', [auth, checkRole(['admin'])], async (req, res) => {
    try {
        await User.findByIdAndDelete(req.params.id);
        res.json({ msg: 'User removed' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
