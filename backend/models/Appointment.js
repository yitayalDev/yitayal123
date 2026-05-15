const mongoose = require('mongoose');

const AppointmentSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    serviceId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Service',
        required: true
    },
    providerId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    date: {
        type: Date,
        required: true
    },
    timeSlot: {
        type: String,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'approved', 'rejected', 'completed', 'cancelled', 'attended'],
        default: 'pending'
    },
    reason: {
        type: String
    },
    // Conditional fields
    studentId: String, // For students
    major: String,     // For students
    organization: String, // For others
    guestId: String,      // For others (Passport/National ID)
    attachments: [String], // Array of file names or URLs
    appointmentType: {
        type: String,
        enum: ['physical', 'virtual'],
        default: 'physical'
    },
    meetingRoom: {
        type: String
    },
    reminderSent: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Appointment', AppointmentSchema);
