const admin = require("firebase-admin");
const serviceAccount = require("../serviceAccountKey.json");
const data = require("../products.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function importData() {
  const collections = Object.keys(data);

  for (const collectionName of collections) {
    const collectionData = data[collectionName];

    for (const docId of Object.keys(collectionData)) {
      const docData = collectionData[docId];

      // Add timestamp
      docData.createdAt = admin.firestore.FieldValue.serverTimestamp();

      await db.collection(collectionName).doc(docId).set(docData);
      console.log(`✅ Added ${docId} to ${collectionName}`);
    }
  }

  console.log("Import completed!");
  process.exit(0);
}

importData().catch(console.error);
