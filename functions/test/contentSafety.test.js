/**
 * Lightweight Node assertions for content-safety + prompt builder.
 * No Firebase required. Run: node test/contentSafety.test.js
 */
const assert = require("assert");
const {
  checkStorySafety,
  validateInterest,
  readingLevelLabel,
  SOFT_DAILY_TOKEN_BUDGET,
} = require("../contentSafety");
const {buildStoryPrompt, resolveModel} = require("../storyPrompt");

/**
 * @param {string} name
 * @param {Function} fn
 */
function test(name, fn) {
  try {
    fn();
    console.log("ok -", name);
  } catch (err) {
    console.error("FAIL -", name);
    console.error(err);
    process.exitCode = 1;
  }
}

test("blocks violent story text", () => {
  const r = checkStorySafety("The monster will kill the dragon with a gun.");
  assert.strictEqual(r.safe, false);
  assert.ok(r.matches.length >= 1);
});

test("allows warm kid story", () => {
  const r = checkStorySafety(
      "Sam and Max play with a big blue ball at the park.",
  );
  assert.strictEqual(r.safe, true);
});

test("rejects unsafe interest", () => {
  const r = validateInterest("horror movies");
  assert.strictEqual(r.ok, false);
});

test("accepts interest about dogs", () => {
  const r = validateInterest("dogs and parks");
  assert.strictEqual(r.ok, true);
});

test("prompt includes interest and dolch list", () => {
  const {system, user} = buildStoryPrompt(
      ["a", "and", "big", "blue", "can"],
      {interest: "dogs", readingLevel: "Pre-Primer", maxWords: 100},
  );
  assert.ok(system.toLowerCase().includes("age-appropriate"));
  assert.ok(user.includes("dogs"));
  assert.ok(user.includes("blue"));
});

test("mini-tier model allowlist", () => {
  assert.strictEqual(resolveModel("gpt-4o-mini"), "gpt-4o-mini");
  assert.throws(() => resolveModel("gpt-4o"), /mini-tier/);
});

test("soft budget constant is positive", () => {
  assert.ok(SOFT_DAILY_TOKEN_BUDGET > 0);
});

test("reading level labels", () => {
  assert.ok(readingLevelLabel("Pre-Primer").length > 0);
  assert.ok(readingLevelLabel("first grade").includes("grade"));
});

console.log("contentSafety tests finished");
