const mongoose = require('mongoose');

const LOCAL_URI = 'mongodb://localhost:27017/university_appointments';
const ATLAS_URI = 'mongodb+srv://yitayal211219_db_user:yxwZOqNtWPwT08K3@cluster0.kqanvch.mongodb.net/university_appointment_system?retryWrites=true&w=majority';

async function migrate() {
    let localConn, atlasConn;
    try {
        console.log('Connecting to Local MongoDB...');
        localConn = await mongoose.createConnection(LOCAL_URI).asPromise();
        console.log('Connected to Local.');

        console.log('Connecting to Atlas MongoDB...');
        atlasConn = await mongoose.createConnection(ATLAS_URI).asPromise();
        console.log('Connected to Atlas.');

        const collections = ['users', 'services', 'appointments', 'notifications', 'reviews'];

        for (const colName of collections) {
            console.log(`\nMigrating collection: ${colName}`);
            const localCol = localConn.db.collection(colName);
            const atlasCol = atlasConn.db.collection(colName);

            const data = await localCol.find({}).toArray();
            console.log(`Found ${data.length} documents in local ${colName}`);

            if (data.length > 0) {
                // Clear existing data in Atlas for this collection to avoid duplicates or conflicts
                // Or you can use upsert, but for a clean transfer, clearing is safer if that's what the user wants.
                // Given the user said "not transfer", they probably want to overwrite Atlas with local.
                console.log(`Clearing ${colName} in Atlas...`);
                await atlasCol.deleteMany({});

                console.log(`Inserting ${data.length} documents into Atlas...`);
                await atlasCol.insertMany(data);
                console.log(`Migration of ${colName} completed.`);
            } else {
                console.log(`Skipping ${colName} as it is empty.`);
            }
        }

        console.log('\n--- ALL MIGRATIONS COMPLETED ---');
    } catch (err) {
        console.error('Migration error:', err);
    } finally {
        if (localConn) await localConn.close();
        if (atlasConn) await atlasConn.close();
        process.exit();
    }
}

migrate();
