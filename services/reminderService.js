const cron = require('node-cron');
const moment = require('moment');
const Appointment = require('../models/Appointment');
const { sendPushNotification } = require('../utils/firebase');
const Notification = require('../models/Notification');

const initReminderJob = () => {
    // Run every 10 minutes
    cron.schedule('*/10 * * * *', async () => {
        console.log('Running Appointment Reminder Job...');
        
        try {
            const now = moment();
            const todayStart = moment().startOf('day').toDate();
            const todayEnd = moment().endOf('day').toDate();

            // Find approved appointments for today that haven't had a reminder sent yet
            const upcomingAppointments = await Appointment.find({
                date: { $gte: todayStart, $lte: todayEnd },
                status: 'approved',
                reminderSent: { $ne: true }
            }).populate('userId providerId serviceId');

            for (const appt of upcomingAppointments) {
                // Extract start time from timeSlot (e.g., "09:00 AM - 10:00 AM")
                const startTimeStr = appt.timeSlot.split(' - ')[0];
                const apptStartTime = moment(`${moment(appt.date).format('YYYY-MM-DD')} ${startTimeStr}`, 'YYYY-MM-DD hh:mm A');

                // Check if appointment starts within the next 35 minutes
                const diffMinutes = apptStartTime.diff(now, 'minutes');

                if (diffMinutes > 0 && diffMinutes <= 35) {
                    console.log(`Sending reminder for appointment: ${appt._id}`);

                    const title = 'Upcoming Appointment Reminder';
                    const message = `Reminder: Your appointment for ${appt.serviceId.name} starts in about ${diffMinutes} minutes at ${startTimeStr}.`;

                    // Notify User
                    await sendPushNotification(appt.userId._id, title, message);
                    await new Notification({
                        userId: appt.userId._id,
                        title,
                        message,
                        type: 'info'
                    }).save();

                    // Notify Provider
                    await sendPushNotification(appt.providerId._id, title, message);
                    await new Notification({
                        userId: appt.providerId._id,
                        title,
                        message,
                        type: 'info'
                    }).save();

                    // Mark as sent
                    appt.reminderSent = true;
                    await appt.save();
                }
            }
        } catch (error) {
            console.error('Error in Reminder Job:', error);
        }
    });
};

module.exports = { initReminderJob };
