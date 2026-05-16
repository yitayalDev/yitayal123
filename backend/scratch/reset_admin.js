const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const ATLAS_URI = 'mongodb+srv://yitayal211219_db_user:yxwZOqNtWPwT08K3@cluster0.kqanvch.mongodb.net/university_appointment_system?retryWrites=true&w=majority';

async function resetAdminPassword() {
    try {
        await mongoose.connect(ATLAS_URI);
        console.log('Connected to Atlas.');
        
        const User = mongoose.connection.db.collection('users');
        const email = 'admin@university.edu';
        const newPassword = 'adminpassword123'; // Using the same as the other project for consistency
        
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);
        
        const result = await User.updateOne(
            { email: email },
            { $set: { password: hashedPassword } }
        );
        
        if (result.modifiedCount > 0) {
            console.log(`Successfully reset password for ${email}`);
            console.log(`New Password: ${newPassword}`);
        } else {
            console.log(`User ${email} not found or password already set.`);
        }
        
        await mongoose.disconnect();
    } catch (err) {
        console.error('Error:', err.message);
    }
}

resetAdminPassword();
