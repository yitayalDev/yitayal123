const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env variables
const path = require('path');
dotenv.config({ path: path.join(__dirname, '../.env') });

// Load models
const User = require('../models/User');
const Service = require('../models/Service');
const Appointment = require('../models/Appointment');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const Review = require('../models/Review');

const clearDatabase = async () => {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected.');

        console.log('Clearing Users...');
        await User.deleteMany({});
        console.log('Users cleared.');

        console.log('Clearing Services...');
        await Service.deleteMany({});
        console.log('Services cleared.');

        console.log('Clearing Appointments...');
        await Appointment.deleteMany({});
        console.log('Appointments cleared.');

        console.log('Clearing Messages...');
        await Message.deleteMany({});
        console.log('Messages cleared.');

        console.log('Clearing Notifications...');
        await Notification.deleteMany({});
        console.log('Notifications cleared.');

        console.log('Clearing Reviews...');
        await Review.deleteMany({});
        console.log('Reviews cleared.');

        console.log('\n✅ Database successfully wiped!');
    } catch (err) {
        console.error('Error clearing database:', err);
    } finally {
        mongoose.connection.close();
        console.log('Connection closed.');
    }
};

clearDatabase();
