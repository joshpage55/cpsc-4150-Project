/**
 * Wipe all Firebase Auth users + related Firestore account data.
 * Run from repo root:
 *   node scripts/wipe_accounts.cjs
 */
const path = require("path");
const admin = require(path.join(__dirname, "..", "functions", "node_modules", "firebase-admin"));

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "cpsc4150-readright";

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: PROJECT_ID,
  });
}

const auth = admin.auth();
const db = admin.firestore();

const COLLECTIONS = [
  "users",
  "classes",
  "student.progress",
  "stories",
  "story_regen_counters",
  "ai_usage_logs",
  "ai_usage_daily",
  "ai_spend_alerts",
  "attempts",
];

async function deleteAuthUsers() {
  let deleted = 0;
  let nextPageToken;
  do {
    const result = await auth.listUsers(1000, nextPageToken);
    const uids = result.users.map((u) => u.uid);
    if (uids.length === 0) break;

    const chunk = await auth.deleteUsers(uids);
    deleted += chunk.successCount;
    if (chunk.failureCount > 0) {
      console.error("Some Auth deletes failed:", chunk.errors);
    }
    console.log(`Deleted ${chunk.successCount} Auth user(s)...`);
    nextPageToken = result.pageToken;
  } while (nextPageToken);
  return deleted;
}

async function wipeCollection(name) {
  const col = db.collection(name);
  let total = 0;
  while (true) {
    const snap = await col.limit(400).get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    total += snap.size;
    console.log(`  ${name}: deleted ${total} doc(s)...`);
  }
  return total;
}

async function main() {
  console.log(`Wiping accounts in project: ${PROJECT_ID}`);
  console.log("--- Auth users ---");
  const authDeleted = await deleteAuthUsers();
  console.log(`Auth users deleted: ${authDeleted}`);

  console.log("--- Firestore collections ---");
  for (const name of COLLECTIONS) {
    const n = await wipeCollection(name);
    console.log(`${name}: ${n} doc(s) removed`);
  }

  console.log("Done. Re-register a teacher to continue demos.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
