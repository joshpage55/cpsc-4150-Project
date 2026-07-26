/**
 * Unit tests for the Story Builder prompt builder (storyPrompt.js).
 * Lightweight Node assertions, no test framework required.
 * Run: node test/storyPrompt.test.js
 */
const assert = require("assert");
const {
  ALLOWED_MODELS,
  DEFAULT_MODEL,
  buildStoryPrompt,
  resolveModel,
} = require("../storyPrompt");

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

// ---------------------------------------------------------------------------
// buildStoryPrompt - input validation
// ---------------------------------------------------------------------------

test("throws when dolch word list is empty", () => {
  assert.throws(
      () => buildStoryPrompt([]),
      /At least one Dolch word is required/,
  );
});

test("throws when dolch word list only contains blank strings", () => {
  assert.throws(
      () => buildStoryPrompt(["  ", "", "\t"]),
      /At least one Dolch word is required/,
  );
});

test("trims and filters blank entries from the dolch word list", () => {
  const {user} = buildStoryPrompt([" the ", "", "big", "  "]);
  assert.ok(user.includes("the, big"));
});

test("propagates validateInterest rejection as a thrown error", () => {
  assert.throws(
      () => buildStoryPrompt(["the"], {interest: "scary horror stories"}),
      /disallowed topic/,
  );
});

test("rejects a whitespace-only interest string", () => {
  // A single space is truthy so it bypasses the "interest || default"
  // fallback and reaches validateInterest, which trims it to empty.
  assert.throws(
      () => buildStoryPrompt(["the"], {interest: " "}),
      /interest is required/,
  );
});

test("falls back to the default interest when interest is an empty string", () => {
  // An empty string is falsy, so buildStoryPrompt substitutes the default
  // before validateInterest ever runs.
  const {user} = buildStoryPrompt(["the"], {interest: ""});
  assert.ok(user.includes("animals and play"));
});

// ---------------------------------------------------------------------------
// buildStoryPrompt - default option handling
// ---------------------------------------------------------------------------

test("applies default interest, reading level, and max words", () => {
  const {user} = buildStoryPrompt(["the", "big"]);
  assert.ok(user.includes("animals and play"));
  assert.ok(user.includes("grade 1 reader"));
  assert.ok(user.includes("80-120 words"));
});

test("accepts a bare number as opts and treats it as maxWords", () => {
  const {user} = buildStoryPrompt(["the"], 60);
  assert.ok(user.includes("80-60 words"));
  // defaults still apply for interest/reading level in the numeric-opts path
  assert.ok(user.includes("animals and play"));
  assert.ok(user.includes("grade 1 reader"));
});

test("custom opts override maxWords, interest, and readingLevel", () => {
  const {user} = buildStoryPrompt(["the", "big"], {
    maxWords: 90,
    interest: "dinosaurs",
    readingLevel: "third grade",
  });
  assert.ok(user.includes("80-90 words"));
  assert.ok(user.includes("dinosaurs"));
  assert.ok(user.includes("grade 2–3"));
});

// ---------------------------------------------------------------------------
// buildStoryPrompt - content shape / safety framing
// ---------------------------------------------------------------------------

test("system prompt bans unsafe themes and markdown formatting", () => {
  const {system} = buildStoryPrompt(["the"]);
  assert.ok(system.includes("ages 5–8"));
  assert.ok(system.toLowerCase().includes("age-appropriate"));
  assert.ok(system.includes("violence, weapons, death"));
  assert.ok(system.toLowerCase().includes("do not use markdown"));
});

test("user prompt lists every provided dolch word", () => {
  const words = ["a", "and", "big", "blue", "can"];
  const {user} = buildStoryPrompt(words);
  for (const w of words) {
    assert.ok(user.includes(w), `expected user prompt to include "${w}"`);
  }
  assert.ok(user.includes(words.join(", ")));
});

test("user prompt trims interest text before embedding it", () => {
  const {user} = buildStoryPrompt(["the"], {interest: "  dogs and parks  "});
  assert.ok(user.includes("dogs and parks."));
  assert.ok(!user.includes("  dogs"));
});

test("returns exactly a system/user pair", () => {
  const result = buildStoryPrompt(["the", "big"]);
  assert.deepStrictEqual(Object.keys(result).sort(), ["system", "user"]);
  assert.strictEqual(typeof result.system, "string");
  assert.strictEqual(typeof result.user, "string");
});

// ---------------------------------------------------------------------------
// resolveModel
// ---------------------------------------------------------------------------

test("resolveModel returns an explicitly allowed model unchanged", () => {
  assert.strictEqual(resolveModel("gpt-4.1-mini"), "gpt-4.1-mini");
});

test("resolveModel trims whitespace before validating", () => {
  assert.strictEqual(resolveModel("  gpt-4o-mini  "), "gpt-4o-mini");
});

test("resolveModel falls back to DEFAULT_MODEL when nothing is passed", () => {
  const original = process.env.OPENAI_MODEL;
  delete process.env.OPENAI_MODEL;
  try {
    assert.strictEqual(resolveModel(undefined), DEFAULT_MODEL);
  } finally {
    if (original !== undefined) process.env.OPENAI_MODEL = original;
  }
});

test("resolveModel honors OPENAI_MODEL env var when no model is passed", () => {
  const original = process.env.OPENAI_MODEL;
  process.env.OPENAI_MODEL = "gpt-4.1-mini";
  try {
    assert.strictEqual(resolveModel(undefined), "gpt-4.1-mini");
  } finally {
    if (original !== undefined) {
      process.env.OPENAI_MODEL = original;
    } else {
      delete process.env.OPENAI_MODEL;
    }
  }
});

test("resolveModel rejects a non-mini model with a helpful message", () => {
  assert.throws(() => resolveModel("gpt-4o"), /mini-tier only/);
});

test("resolveModel rejects an unrecognized model string", () => {
  assert.throws(() => resolveModel("not-a-real-model"), /is not allowed/);
});

test("ALLOWED_MODELS contains only the expected mini-tier models", () => {
  assert.ok(ALLOWED_MODELS instanceof Set);
  assert.strictEqual(ALLOWED_MODELS.size, 2);
  assert.ok(ALLOWED_MODELS.has("gpt-4o-mini"));
  assert.ok(ALLOWED_MODELS.has("gpt-4.1-mini"));
});

test("DEFAULT_MODEL is itself an allowed model", () => {
  assert.ok(ALLOWED_MODELS.has(DEFAULT_MODEL));
});

// ---------------------------------------------------------------------------
// Fixtures from data/seed_words.csv (real Dolch word lists shipped with the
// app, e.g. "a, and, away, big, blue, ..." for Pre-Primer). Exercising the
// prompt builder against the actual production word lists, not just toy
// examples, catches issues that only show up with real list sizes/content.
// ---------------------------------------------------------------------------

const REAL_PRE_PRIMER_WORDS = [
  "a", "and", "away", "big", "blue", "can", "come", "down",
];
const REAL_FIRST_GRADE_WORDS = [
  "after", "again", "an", "any", "ask", "as", "by", "could",
];

test("builds a prompt from the real Pre-Primer word list", () => {
  const {system, user} = buildStoryPrompt(REAL_PRE_PRIMER_WORDS, {
    interest: "puppies",
    readingLevel: "Pre-Primer",
  });
  assert.ok(user.includes(REAL_PRE_PRIMER_WORDS.join(", ")));
  assert.ok(user.includes("pre-primer / kindergarten reader"));
  assert.ok(system.length > 0);
});

test("builds a prompt from the real First Grade word list", () => {
  const {user} = buildStoryPrompt(REAL_FIRST_GRADE_WORDS, {
    interest: "space and rockets",
    readingLevel: "First Grade",
  });
  assert.ok(user.includes(REAL_FIRST_GRADE_WORDS.join(", ")));
  assert.ok(user.includes("grade 1 reader"));
});

test("a full 40-word Pre-Primer list is embedded without truncation", () => {
  // The real Pre-Primer list in seed_words.csv has 40 words; make sure the
  // prompt builder doesn't silently cap or drop entries from a longer list.
  const fullList = [
    "a", "and", "away", "big", "blue", "can", "come", "down", "find", "for",
    "funny", "go", "help", "here", "I", "in", "is", "it", "jump", "little",
    "look", "make", "me", "my", "not", "one", "play", "red", "run", "said",
    "see", "the", "three", "to", "two", "up", "we", "where", "yellow", "you",
  ];
  assert.strictEqual(fullList.length, 40);
  const {user} = buildStoryPrompt(fullList, {readingLevel: "pre-primer"});
  for (const w of fullList) {
    assert.ok(user.includes(w), `missing word "${w}" from full list`);
  }
});

console.log("storyPrompt tests finished");
