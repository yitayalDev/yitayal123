const mongoose = require('mongoose');

const DB_NAME = 'university_appointments';
const LOCAL_URI = `mongodb://localhost:27017/${DB_NAME}`;

async function checkLocal() {
    try {
        await mongoose.connect(LOCAL_URI);
        console.log(`Connected to local ${DB_NAME}`);
        
        const collections = await mongoose.connection.db.listCollections().toArray();
        console.log('Collections:', collections.map(c => c.name));
        
        for (const col of collections) {
            const count = await mongoose.connection.db.collection(col.name).countDocuments();
            console.log(`Collection ${col.name}: ${count} documents`);
        }
        
        await mongoose.disconnect();
    } catch (err) {
        console.error('Local connection error:', err.message);
    }
}

checkLocal();
