/**
 * Dolch-constrained story prompt for M2 spike / M3 Story Builder.
 */

const {
  checkStorySafety,
  readingLevelLabel,
  validateInterest,
} = require("./contentSafety");

/** Mini-tier models allowed for course guardrails. */
const ALLOWED_MODELS = new Set([
  "gpt-4o-mini",
  "gpt-4.1-mini",
]);

const DEFAULT_MODEL = "gpt-4o-mini";

/**
 * @param {string[]} dolchWords
 * @param {object} [opts]
 * @param {number} [opts.maxWords]
 * @param {string} [opts.interest]
 * @param {string} [opts.readingLevel]
 * @return {{system: string, user: string}}
 */
function buildStoryPrompt(dolchWords, opts = {}) {
  const maxWords = typeof opts === "number" ? opts : (opts.maxWords || 120);
  const interest = typeof opts === "object" ?
    (opts.interest || "animals and play") :
    "animals and play";
  const readingLevel = typeof opts === "object" ?
    (opts.readingLevel || "first grade") :
    "first grade";

  const wordList = dolchWords.map((w) => w.trim()).filter(Boolean);
  if (wordList.length === 0) {
    throw new Error("At least one Dolch word is required");
  }

  const interestCheck = validateInterest(interest);
  if (!interestCheck.ok) {
    throw new Error(interestCheck.reason);
  }

  const levelPhrase = readingLevelLabel(readingLevel);

  const system = [
    "You write very short stories for children learning to read (ages 5–8).",
    "Use ONLY simple words. Prefer words from the provided Dolch list;",
    "do not invent advanced vocabulary when a Dolch word would work.",
    "Content must be warm, encouraging, and age-appropriate.",
    "Never include violence, weapons, death, horror, romance, drugs, alcohol,",
    "profanity, bullying, or frightening themes.",
    "Do not use markdown, titles, bullet points, or quotation wrappers.",
    "Output plain story text only.",
  ].join(" ");

  const user = [
    `Write a story of about 80-${maxWords} words for a ${levelPhrase} reader.`,
    `Theme / interest (keep it light and kid-safe): ${interest.trim()}.`,
    "You MUST include several of these Dolch sight words naturally: " +
      wordList.join(", ") + ".",
    "Keep sentences short (about 5–10 words). Target Flesch-Kincaid grade 1–2.",
    "No scary content. No adult topics.",
  ].join(" ");

  return {system, user};
}

/**
 * @param {string} model
 * @return {string}
 */
function resolveModel(model) {
  const chosen = (model || process.env.OPENAI_MODEL || DEFAULT_MODEL).trim();
  if (!ALLOWED_MODELS.has(chosen)) {
    const allowed = [...ALLOWED_MODELS].join(", ");
    throw new Error(
        `Model "${chosen}" is not allowed. Use mini-tier only: ${allowed}`,
    );
  }
  return chosen;
}

/**
 * Call OpenAI chat completions API (mini-tier model).
 * @param {object} params
 * @param {string} params.apiKey
 * @param {string} params.model
 * @param {string} params.system
 * @param {string} params.user
 * @return {Promise<Object>}
 */
async function generateStoryWithOpenAI({apiKey, model, system, user}) {
  const resolvedModel = resolveModel(model);
  const url = "https://api.openai.com/v1/chat/completions";

  const body = {
    model: resolvedModel,
    messages: [
      {role: "system", content: system},
      {role: "user", content: user},
    ],
    temperature: 0.7,
    max_tokens: 512,
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  const data = await res.json();
  if (!res.ok) {
    const msg = data?.error?.message || res.statusText;
    throw new Error(`OpenAI API error: ${msg}`);
  }

  const story = data?.choices?.[0]?.message?.content?.trim() || "";
  if (!story) {
    throw new Error("OpenAI returned empty story");
  }

  const safety = checkStorySafety(story);
  if (!safety.safe) {
    const err = new Error(
        `Story failed content-safety filter: ${safety.matches.join(", ")}`,
    );
    err.code = "content-safety";
    err.matches = safety.matches;
    throw err;
  }

  return {
    story,
    model: resolvedModel,
    usage: data?.usage || null,
    safety: {passed: true, matches: []},
  };
}

module.exports = {
  ALLOWED_MODELS,
  DEFAULT_MODEL,
  buildStoryPrompt,
  resolveModel,
  generateStoryWithOpenAI,
  checkStorySafety,
};
