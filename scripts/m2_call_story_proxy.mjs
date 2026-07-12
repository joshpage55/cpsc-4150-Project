#!/usr/bin/env node
/**
 * Call deployed generateStorySpike Cloud Function (M2 proxy evidence).
 * Usage: node scripts/m2_call_story_proxy.mjs
 */

import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

const projectId = process.env.FIREBASE_PROJECT_ID || "cpsc4150-readright";
const region = process.env.FIREBASE_REGION || "us-central1";
const functionName = "generateStorySpike";

const defaultWords = ["a", "and", "big", "blue", "can", "come", "down", "find", "for", "funny"];
const dolchWords = (process.env.DOLCH_WORDS || defaultWords.join(","))
    .split(",")
    .map((w) => w.trim())
    .filter(Boolean);

const url = `https://${region}-${projectId}.cloudfunctions.net/${functionName}`;

console.log("M2 Proxy Spike Call");
console.log("Endpoint:", url);
console.log("Dolch words:", dolchWords.join(", "));
console.log("---");

const res = await fetch(url, {
  method: "POST",
  headers: {"Content-Type": "application/json"},
  body: JSON.stringify({data: {dolchWords}}),
});

const text = await res.text();
let body;
try {
  body = JSON.parse(text);
} catch {
  console.error("Non-JSON response:", text);
  process.exit(1);
}

if (!res.ok || body.error) {
  console.error("Proxy call failed:", JSON.stringify(body, null, 2));
  process.exit(1);
}

const result = body.result;
const payload = {
  generatedAt: new Date().toISOString(),
  via: "firebase-proxy",
  endpoint: url,
  dolchWords: result.dolchWords || dolchWords,
  model: result.model,
  story: result.story,
  usage: result.usage,
  prompt: result.promptPreview,
};

const outDir = path.join(root, "docs/milestone2/spike");
fs.mkdirSync(outDir, {recursive: true});
const outFile = path.join(outDir, "spike_result_via_proxy.json");
fs.writeFileSync(outFile, JSON.stringify(payload, null, 2));

console.log("Story:\n");
console.log(result.story);
console.log("\n---");
console.log("Saved:", outFile);
