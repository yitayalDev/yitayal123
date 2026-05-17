const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { auth, checkRole } = require('../middleware/auth');
const Appointment = require('../models/Appointment');
const Service = require('../models/Service');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { sendPushNotification } = require('../utils/firebase');

// @route   GET api/appointments/stats
// @desc    Get provider appointment stats
// @access  Private (Provider)
router.get('/stats', auth, async (req, res) => {
    try {
        const pending = await Appointment.countDocuments({ providerId: req.user.id, status: 'pending' });
        const approved = await Appointment.countDocuments({ providerId: req.user.id, status: 'approved' });
        res.json({ pending, approved });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/appointments/analytics
// @desc    Get detailed provider analytics
// @access  Private (Provider)
router.get('/analytics', [auth, checkRole(['provider'])], async (req, res) => {
    try {
        const providerId = req.user.id;

        // 1. Popular Services (Top 5)
        const popularServices = await Appointment.aggregate([
            { $match: { providerId: new mongoose.Types.ObjectId(providerId) } },
            { $group: { _id: '$serviceId', count: { $sum: 1 } } },
            { $sort: { count: -1 } },
            { $limit: 5 },
            {
                $lookup: {
                    from: 'services',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'serviceDetails'
                }
            },
            { $unwind: '$serviceDetails' },
            {
                $project: {
                    name: '$serviceDetails.name',
                    count: 1
                }
            }
        ]);

        // 2. Booking Trends (Last 7 Days)
        const last7Days = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            d.setHours(0, 0, 0, 0);
            last7Days.push(d);
        }

        const bookingTrends = await Promise.all(last7Days.map(async (date) => {
            const nextDay = new Date(date);
            nextDay.setDate(nextDay.getDate() + 1);

            const count = await Appointment.countDocuments({
                providerId,
                date: { $gte: date, $lt: nextDay }
            });

            return {
                date: date.toLocaleDateString('en-US', { weekday: 'short' }),
                count
            };
        }));

        // 3. Customer Growth (Total Unique Users)
        const totalUsers = await Appointment.distinct('userId', { providerId });

        // 4. Status Breakdown
        const statusBreakdown = await Appointment.aggregate([
            { $match: { providerId: new mongoose.Types.ObjectId(providerId) } },
            { $group: { _id: '$status', count: { $sum: 1 } } }
        ]);

        res.json({
            popularServices,
            bookingTrends,
            totalCustomers: totalUsers.length,
            statusBreakdown
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/appointments/book
// @desc    Book an appointment
// @access  Private (User)
router.post('/book', [auth, checkRole(['user'])], async (req, res) => {
    const { serviceId, date, timeSlot, reason, studentId, major, organization, guestId, attachments, appointmentType } = req.body;

    try {
        const service = await Service.findById(serviceId).populate('providerId');
        if (!service) return res.status(404).json({ msg: 'Service not found' });

        if (!service.providerId.isAvailable) {
            const appointmentDate = new Date(date);
            const today = new Date();
            
            // Check if appointment is for today (same year, month, day)
            const isToday = appointmentDate.getFullYear() === today.getFullYear() &&
                          appointmentDate.getMonth() === today.getMonth() &&
                          appointmentDate.getDate() === today.getDate();

            if (isToday) {
                return res.status(400).json({ msg: 'This provider is currently in emergency mode for today. Please book for a future date.' });
            }
        }

        // 4. Check for Planned Absence (Multi-day)
        if (service.providerId.unavailableDates.includes(date)) {
            return res.status(400).json({ msg: 'Provider is unavailable on the selected date due to a planned absence.' });
        }

        // Helper to convert "09:00 AM" or "14:00" to 24h number (e.g., 1400)
        const to24h = (timeStr) => {
            if (!timeStr) return 0;
            // Handle "09:00 AM" format
            if (timeStr.includes('AM') || timeStr.includes('PM')) {
                const [time, modifier] = timeStr.split(' ');
                let [hours, minutes] = time.split(':');
                if (hours === '12') hours = '00';
                if (modifier === 'PM') hours = parseInt(hours, 10) + 12;
                return parseInt(`${hours.toString().padStart(2, '0')}${minutes}`, 10);
            }
            // Handle "14:00" format
            return parseInt(timeStr.replace(':', ''), 10);
        };

        const reqTime = to24h(timeSlot);

        // 5. Check for Busy Slots (Specific Date/Hours)
        const busySlot = service.providerId.busySlots.find(slot => {
            if (slot.date !== date) return false;
            const slotStart = to24h(slot.startTime);
            const slotEnd = to24h(slot.endTime);
            return reqTime >= slotStart && reqTime < slotEnd;
        });

        if (busySlot) {
            return res.status(400).json({ msg: `This time slot is blocked: ${busySlot.reason || 'Provider is busy'}` });
        }

        // 6. Check for Recurring Busy Slots (Daily)
        const recurringSlot = service.providerId.recurringBusySlots?.find(slot => {
            if (!slot.active) return false;
            const slotStart = to24h(slot.startTime);
            const slotEnd = to24h(slot.endTime);
            return reqTime >= slotStart && reqTime < slotEnd;
        });

        if (recurringSlot) {
            return res.status(400).json({ msg: `This time is reserved for: ${recurringSlot.reason || 'Lunch/Break'}` });
        }

        const newAppointment = new Appointment({
            userId: req.user.id,
            serviceId,
            providerId: service.providerId,
            date,
            timeSlot,
            reason,
            studentId,
            major,
            organization,
            guestId,
            attachments,
            appointmentType: appointmentType || 'physical'
        });

        if (appointmentType === 'virtual') {
            newAppointment.meetingRoom = `Room-${require('crypto').randomBytes(8).toString('hex')}`;
        }

        const appointment = await newAppointment.save();

        // Notify Provider
        const student = await User.findById(req.user.id);
        const notification = new Notification({
            userId: service.providerId,
            title: 'New Appointment Booking',
            message: `A new appointment has been booked by ${student.name} for ${service.name} on ${date} at ${timeSlot}.`,
            type: 'info'
        });
        await notification.save();
        await sendPushNotification(service.providerId, notification.title, notification.message);

        res.json(appointment);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/appointments/my
// @desc    Get user's appointments
// @access  Private
router.get('/my', auth, async (req, res) => {
    try {
        let appointments;
        if (req.user.role === 'user') {
            const rawAppointments = await Appointment.find({ userId: req.user.id })
                .populate('serviceId')
                .populate('providerId', 'name email');
            
            const to24h = (timeStr) => {
                if (!timeStr) return 0;
                if (timeStr.includes('AM') || timeStr.includes('PM')) {
                    const [time, modifier] = timeStr.split(' ');
                    let [hours, minutes] = time.split(':');
                    if (hours === '12') hours = '00';
                    if (modifier === 'PM') hours = parseInt(hours, 10) + 12;
                    return parseInt(`${hours.toString().padStart(2, '0')}${minutes}`, 10);
                }
                return parseInt(timeStr.replace(':', ''), 10);
            };

            const appointmentsWithQueue = await Promise.all(rawAppointments.map(async (appt) => {
                const apptObj = appt.toObject();
                
                // Only show queue for today's pending/approved appointments
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                const apptDate = new Date(appt.date);
                apptDate.setHours(0, 0, 0, 0);

                if (apptDate.getTime() === today.getTime() && (appt.status === 'pending' || appt.status === 'approved')) {
                    const others = await Appointment.find({
                        providerId: appt.providerId._id,
                        date: appt.date,
                        status: { $in: ['pending', 'approved'] }
                    });

                    // Sort others by time
                    const sorted = others.sort((a, b) => to24h(a.timeSlot) - to24h(b.timeSlot));
                    const pos = sorted.findIndex(o => o._id.toString() === appt._id.toString());
                    apptObj.queuePosition = pos + 1;
                }
                return apptObj;
            }));
            appointments = appointmentsWithQueue;
        } else if (req.user.role === 'provider') {
            appointments = await Appointment.find({ providerId: req.user.id })
                .populate('serviceId')
                .populate('userId', 'name email userType');
        } else if (req.user.role === 'admin') {
            appointments = await Appointment.find()
                .populate('serviceId')
                .populate('userId', 'name email')
                .populate('providerId', 'name email');
        }

        res.json(appointments);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PATCH api/appointments/:id/status
// @desc    Update appointment status
// @access  Private (Provider/Admin)
router.patch('/:id/status', [auth, checkRole(['provider', 'admin'])], async (req, res) => {
    const { status, reason } = req.body;

    try {
        let appointment = await Appointment.findById(req.params.id);
        if (!appointment) return res.status(404).json({ msg: 'Appointment not found' });

        if (appointment.providerId.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(401).json({ msg: 'User not authorized' });
        }

        appointment.status = status;
        if (reason) {
            appointment.reason = reason;
        }

        if (status === 'approved' && appointment.appointmentType === 'virtual' && !appointment.meetingRoom) {
            const crypto = require('crypto');
            appointment.meetingRoom = `Room-${crypto.randomBytes(8).toString('hex')}`;
        }

        await appointment.save();

        const provider = await User.findById(req.user.id);
        const service = await Service.findById(appointment.serviceId);
        
        let notificationMessage = `Your appointment for ${service.name} has been ${status} by ${provider.name}.`;
        if (reason) notificationMessage += ` Reason: ${reason}`;

        const notification = new Notification({
            userId: appointment.userId,
            title: `Appointment ${status.charAt(0).toUpperCase() + status.slice(1)}`,
            message: notificationMessage,
            type: status === 'approved' ? 'success' : (status === 'cancelled' ? 'error' : 'info')
        });
        await notification.save();
        await sendPushNotification(appointment.userId, notification.title, notification.message);

        res.json(appointment);

        // If cancelled, notify the NEXT person in line
        if (status === 'cancelled') {
            const to24h = (timeStr) => {
                if (!timeStr) return 0;
                if (timeStr.includes('AM') || timeStr.includes('PM')) {
                    const [time, modifier] = timeStr.split(' ');
                    let [hours, minutes] = time.split(':');
                    if (hours === '12') hours = '00';
                    if (modifier === 'PM') hours = parseInt(hours, 10) + 12;
                    return parseInt(`${hours.toString().padStart(2, '0')}${minutes}`, 10);
                }
                return parseInt(timeStr.replace(':', ''), 10);
            };

            const others = await Appointment.find({
                providerId: appointment.providerId,
                date: appointment.date,
                status: { $in: ['pending', 'approved'] }
            });

            const sorted = others.sort((a, b) => to24h(a.timeSlot) - to24h(b.timeSlot));
            const nextPerson = sorted.find(o => to24h(o.timeSlot) > to24h(appointment.timeSlot));

            if (nextPerson) {
                const nextNotification = new Notification({
                    userId: nextPerson.userId,
                    title: 'Queue Update!',
                    message: `Someone cancelled! You have moved up in the queue for ${service.name}.`,
                    type: 'info'
                });
                await nextNotification.save();
                await sendPushNotification(nextPerson.userId, nextNotification.title, nextNotification.message);
            }
        }
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   DELETE api/appointments/:id
// @desc    Permanently delete an appointment
// @access  Private (Provider/Admin)
router.delete('/:id', [auth, checkRole(['provider', 'admin'])], async (req, res) => {
    try {
        let appointment = await Appointment.findById(req.params.id);
        if (!appointment) return res.status(404).json({ msg: 'Appointment not found' });

        if (appointment.providerId.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(401).json({ msg: 'User not authorized' });
        }

        await Appointment.findByIdAndDelete(req.params.id);
        res.json({ msg: 'Appointment permanently deleted' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   POST api/appointments/emergency-cancel
// @desc    Toggle provider availability and cancel today's appointments
// @access  Private (Provider)
router.post('/emergency-cancel', auth, async (req, res) => {
    const { dates } = req.body; // Array of date strings like ["2024-05-11"]

    try {
        const user = await User.findById(req.user.id);
        if (user.role !== 'provider' && user.role !== 'admin') {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        let cancelledCount = 0;
        let message = "";

        if (dates && Array.isArray(dates) && dates.length > 0) {
            // Planned absence for specific dates
            user.unavailableDates = [...new Set([...user.unavailableDates, ...dates])];
            await user.save();

            for (const dateStr of dates) {
                const searchDate = new Date(dateStr);
                const startOfDay = new Date(searchDate.setHours(0, 0, 0, 0));
                const endOfDay = new Date(searchDate.setHours(23, 59, 59, 999));

                const appointments = await Appointment.find({
                    providerId: req.user.id,
                    date: { $gte: startOfDay, $lte: endOfDay },
                    status: { $in: ['pending', 'approved'] }
                });

                cancelledCount += appointments.length;

                for (const appt of appointments) {
                    appt.status = 'cancelled';
                    await appt.save();

                    const service = await Service.findById(appt.serviceId);
                    const notification = new Notification({
                        userId: appt.userId,
                        title: 'EMERGENCY: Appointment Cancelled',
                        message: `We regret to inform you that your appointment for ${service.name} on ${dateStr} has been cancelled due to a planned absence.`,
                        type: 'error'
                    });
                    await notification.save();
                    await sendPushNotification(appt.userId, notification.title, notification.message);
                }
            }
            message = `Absence scheduled for ${dates.join(', ')}. ${cancelledCount} appointments cancelled.`;
        } else {
            // Traditional toggle for "Today"
            user.isAvailable = !user.isAvailable;
            await user.save();

            if (!user.isAvailable) {
                const startOfDay = new Date();
                startOfDay.setHours(0, 0, 0, 0);
                const endOfDay = new Date();
                endOfDay.setHours(23, 59, 59, 999);

                const appointments = await Appointment.find({
                    providerId: req.user.id,
                    date: { $gte: startOfDay, $lte: endOfDay },
                    status: { $in: ['pending', 'approved'] }
                });

                cancelledCount = appointments.length;

                for (const appt of appointments) {
                    appt.status = 'cancelled';
                    await appt.save();

                    const service = await Service.findById(appt.serviceId);
                    const notification = new Notification({
                        userId: appt.userId,
                        title: 'EMERGENCY: Appointment Cancelled',
                        message: `We regret to inform you that your appointment for ${service.name} today has been cancelled due to an emergency absence.`,
                        type: 'error'
                    });
                    await notification.save();
                    await sendPushNotification(appt.userId, notification.title, notification.message);
                }
                message = `Emergency mode activated for today. ${cancelledCount} appointments cancelled.`;
            } else {
                message = "Back online!";
            }
        }

        res.json({ msg: message, isAvailable: user.isAvailable, unavailableDates: user.unavailableDates, cancelledCount });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});
// @route   POST appointments/block-time
// @desc    Block specific hours for a provider
// @access  Private (Provider only)
router.post('/block-time', auth, async (req, res) => {
    try {
        const { date, startTime, endTime, reason } = req.body;
        const provider = await User.findById(req.user.id);
        
        if (provider.role !== 'provider') {
            return res.status(403).json({ msg: 'Not authorized' });
        }

        provider.busySlots.push({ date, startTime, endTime, reason });
        await provider.save();

        res.json({ msg: 'Time slot blocked successfully', busySlots: provider.busySlots });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   PATCH api/appointments/:id/reschedule
// @desc    Request to reschedule an appointment
// @access  Private (User)
router.patch('/:id/reschedule', [auth, checkRole(['user'])], async (req, res) => {
    const { date, timeSlot } = req.body;

    try {
        let appointment = await Appointment.findById(req.params.id);
        if (!appointment) return res.status(404).json({ msg: 'Appointment not found' });

        // Check if user owns the appointment
        if (appointment.userId.toString() !== req.user.id) {
            return res.status(401).json({ msg: 'User not authorized' });
        }

        appointment.date = date;
        appointment.timeSlot = timeSlot;
        appointment.status = 'pending'; // Reset to pending for provider review
        
        await appointment.save();

        // Notify Provider
        const student = await User.findById(req.user.id);
        const service = await Service.findById(appointment.serviceId);
        const notification = new Notification({
            userId: appointment.providerId,
            title: 'Reschedule Request',
            message: `${student.name} requested to reschedule their appointment for ${service.name} to ${date} at ${timeSlot}.`,
            type: 'info'
        });
        await notification.save();
        await sendPushNotification(appointment.providerId, notification.title, notification.message);

        res.json(appointment);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// Multer Storage Configuration
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const dir = 'uploads/appointments';
        if (!fs.existsSync(dir)){
            fs.mkdirSync(dir, { recursive: true });
        }
        cb(null, dir);
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + '-' + file.originalname);
    }
});

const upload = multer({ storage: storage });

// @route   POST api/appointments/:id/upload
// @desc    Upload an attachment for an appointment
// @access  Private
router.post('/:id/upload', auth, upload.single('file'), async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ msg: 'No file uploaded' });

        let appointment = await Appointment.findById(req.params.id);
        if (!appointment) return res.status(404).json({ msg: 'Appointment not found' });

        // Check if user is either the student OR the provider
        const isStudent = appointment.userId.toString() === req.user.id;
        const isProvider = appointment.providerId.toString() === req.user.id;

        if (!isStudent && !isProvider && req.user.role !== 'admin') {
            return res.status(401).json({ msg: 'Not authorized' });
        }

        appointment.attachments.push(req.file.filename);
        await appointment.save();

        // Notify the other party
        const sender = await User.findById(req.user.id);
        const recipientId = isStudent ? appointment.providerId : appointment.userId;
        const notification = new Notification({
            userId: recipientId,
            title: 'New Document Uploaded',
            message: `${sender.name} uploaded a new document for your appointment.`,
            type: 'info'
        });
        await notification.save();
        await sendPushNotification(recipientId, notification.title, notification.message);

        res.json(appointment);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
