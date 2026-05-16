const mongoose = require('mongoose');

async function listDbs() {
    try {
        await mongoose.connect('mongodb://localhost:27017');
        const admin = mongoose.connection.db.admin();
        const dbs = await admin.listDatabases();
        console.log('Databases:', dbs.databases.map(d => d.name));
        await mongoose.disconnect();
    } catch (err) {
        console.error('Error:', err.message);
    }
}

listDbs();
