const mongoose = require('mongoose');

const ATLAS_URI = 'mongodb+srv://yitayal211219_db_user:yxwZOqNtWPwT08K3@cluster0.kqanvch.mongodb.net/university_appointment_system?retryWrites=true&w=majority';

async function listAdmins() {
    try {
        await mongoose.connect(ATLAS_URI);
        console.log('Connected to Atlas.');
        
        const User = mongoose.connection.db.collection('users');
        const admins = await User.find({ role: 'admin' }).toArray();
        
        if (admins.length > 0) {
            console.log('Found Admin Accounts:');
            admins.forEach(admin => {
                console.log(`- Name: ${admin.name}, Email: ${admin.email}, Role: ${admin.role}`);
            });
        } else {
            console.log('No admin accounts found.');
            const allUsers = await User.find({}).toArray();
            console.log('All Users in Database:');
            allUsers.forEach(u => {
                console.log(`- Name: ${u.name}, Email: ${u.email}, Role: ${u.role}`);
            });
        }
        
        await mongoose.disconnect();
    } catch (err) {
        console.error('Error:', err.message);
    }
}

listAdmins();
