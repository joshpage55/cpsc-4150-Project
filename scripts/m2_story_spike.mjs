#!/usr/bin/env node
/**
 * M2 AI story de-risk spike — local run (no Flutter).
 * Usage: node scripts/m2_story_spike.mjs
 * Requires .env with OPENAI_API_KEY (see .env.example).
 */

import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {createRequire} from "node:module";

const require = createRequire(import.meta.url);
const {buildStoryPrompt, generateStoryWithOpenAI} = require("../functions/storyPrompt.js");

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

function loadEnvFile(envPath) {
  if (!fs.existsSync(envPath)) return;
  const lines = fs.readFileSync(envPath, "utf8").split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (!process.env[key]) process.env[key] = value;
  }
}

loadEnvFile(path.join(root, ".env"));

const defaultWords = ["a", "and", "big", "blue", "can", "come", "down", "find", "for", "funny"];
const dolchWords = (process.env.DOLCH_WORDS || defaultWords.join(","))
    .split(",")
    .map((w) => w.trim())
    .filter(Boolean);

const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.error("Missing OPENAI_API_KEY. Copy .env.example to .env and paste key from Canvas.");
  process.exit(1);
}

const {system, user} = buildStoryPrompt(dolchWords);

console.log("M2 Story Spike");
console.log("Dolch words:", dolchWords.join(", "));
console.log("Model:", process.env.OPENAI_MODEL || "gpt-4o-mini");
console.log("---");

try {
  const result = await generateStoryWithOpenAI({
    apiKey,
    model: process.env.OPENAI_MODEL,
    system,
    user,
  });

  const payload = {
    generatedAt: new Date().toISOString(),
    dolchWords,
    model: result.model,
    story: result.story,
    usage: result.usage,
    prompt: {system, user},
  };

  const outDir = path.join(root, "docs/milestone2/spike");
  fs.mkdirSync(outDir, {recursive: true});
  const outFile = path.join(outDir, "spike_result_latest.json");
  fs.writeFileSync(outFile, JSON.stringify(payload, null, 2));

  console.log("Story:\n");
  console.log(result.story);
  console.log("\n---");
  console.log("Saved:", outFile);
} catch (err) {
  console.error("Spike failed:", err.message);
  process.exit(1);
}
