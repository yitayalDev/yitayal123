const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const Message = require('../models/Message');
const Appointment = require('../models/Appointment');
const { sendPushNotification } = require('../utils/firebase');
const User = require('../models/User');

// @route   POST api/messages
// @desc    Send a message
// @access  Private
router.post('/', auth, async (req, res) => {
    try {
        const { appointmentId, text } = req.body;
        
        const appointment = await Appointment.findById(appointmentId);
        if (!appointment) return res.status(404).json({ msg: 'Appointment not found' });

        // Check if user is part of the appointment
        const isStudent = appointment.userId.toString() === req.user.id;
        const isProvider = appointment.providerId.toString() === req.user.id;

        if (!isStudent && !isProvider && req.user.role !== 'admin') {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        const newMessage = new Message({
            appointmentId,
            senderId: req.user.id,
            text
        });

        const message = await newMessage.save();

        // Notify the other party
        const recipientId = isStudent ? appointment.providerId : appointment.userId;
        const sender = await User.findById(req.user.id);
        
        await sendPushNotification(
            recipientId, 
            `New message from ${sender.name}`, 
            text.length > 50 ? text.substring(0, 47) + '...' : text
        );

        res.json(message);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/messages/:appointmentId
// @desc    Get messages for an appointment
// @access  Private
router.get('/:appointmentId', auth, async (req, res) => {
    try {
        const appointment = await Appointment.findById(req.params.appointmentId);
        if (!appointment) return res.status(404).json({ msg: 'Appointment not found' });

        // Authorization check
        const isStudent = appointment.userId.toString() === req.user.id;
        const isProvider = appointment.providerId.toString() === req.user.id;

        if (!isStudent && !isProvider && req.user.role !== 'admin') {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        const messages = await Message.find({ appointmentId: req.params.appointmentId })
            .sort({ createdAt: 1 })
            .populate('senderId', 'name');

        res.json(messages);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
