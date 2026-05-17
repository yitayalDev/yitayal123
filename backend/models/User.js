const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true
    },
    role: {
        type: String,
        enum: ['user', 'provider', 'admin'],
        default: 'user'
    },
    userType: {
        type: String,
        enum: ['student', 'staff', 'other', 'researcher'],
        required: function() { return this.role === 'user'; }
    },
    workingHours: {
        days: [String], // ['Monday', 'Tuesday', ...]
        startTime: { type: String, default: "09:00" },
        endTime: { type: String, default: "17:00" }
    },
    category: {
        type: String,
        default: "General" // Academic, Administrative, Health, etc.
    },
    phone: {
        type: String,
        default: ""
    },
    bio: {
        type: String,
        default: ""
    },
    busySlots: [{
        date: String,      // YYYY-MM-DD
        startTime: String, // HH:mm
        endTime: String,   // HH:mm
        reason: String
    }],
    recurringBusySlots: [{
        startTime: String, // HH:mm
        endTime: String,   // HH:mm
        reason: String,
        active: { type: Boolean, default: true }
    }],
    isAvailable: {
        type: Boolean,
        default: true
    },
    unavailableDates: [String], // ["2024-05-11", "2024-05-12"]
    fcmToken: {
        type: String,
        default: ""
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('User', UserSchema);
