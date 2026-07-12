/**
 * Dolch-constrained story prompt for M2 spike / M3 Story Builder.
 */

/** Mini-tier models allowed for course guardrails — update if Canvas specifies another name. */
const ALLOWED_MODELS = new Set([
  "gemini-2.0-flash-lite",
  "gemini-2.0-flash-lite-001",
  "gemini-1.5-flash-8b",
]);

const DEFAULT_MODEL = "gemini-2.0-flash-lite";

/**
 * @param {string[]} dolchWords
 * @param {number} maxWords
 * @return {{system: string, user: string}}
 */
function buildStoryPrompt(dolchWords, maxWords = 120) {
  const wordList = dolchWords.map((w) => w.trim()).filter(Boolean);
  if (wordList.length === 0) {
    throw new Error("At least one Dolch word is required");
  }

  const system = [
    "You write very short stories for children learning to read.",
    "Use ONLY simple words. Prefer words from the provided Dolch list.",
    "Do not use markdown, titles, or bullet points.",
    "Output plain story text only.",
  ].join(" ");

  const user = [
    `Write a story of about 80-${maxWords} words for a first-grade reader.`,
    `You MUST include several of these Dolch sight words naturally: ${wordList.join(", ")}.`,
    "Keep sentences short. No scary content.",
  ].join(" ");

  return {system, user};
}

/**
 * @param {string} model
 * @return {string}
 */
function resolveModel(model) {
  const chosen = (model || process.env.GEMINI_MODEL || DEFAULT_MODEL).trim();
  if (!ALLOWED_MODELS.has(chosen)) {
    throw new Error(
        `Model "${chosen}" is not allowed. Use mini-tier only: ${[...ALLOWED_MODELS].join(", ")}`,
    );
  }
  return chosen;
}

/**
 * Call Gemini generateContent REST API.
 * @param {object} params
 * @param {string} params.apiKey
 * @param {string} params.model
 * @param {string} params.system
 * @param {string} params.user
 * @return {Promise<{story: string, model: string, usage: object|null}>}
 */
async function generateStoryWithGemini({apiKey, model, system, user}) {
  const resolvedModel = resolveModel(model);
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${resolvedModel}:generateContent?key=${apiKey}`;

  const body = {
    systemInstruction: {parts: [{text: system}]},
    contents: [{role: "user", parts: [{text: user}]}],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 512,
    },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(body),
  });

  const data = await res.json();
  if (!res.ok) {
    const msg = data?.error?.message || res.statusText;
    throw new Error(`Gemini API error: ${msg}`);
  }

  const story = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "";
  if (!story) {
    throw new Error("Gemini returned empty story");
  }

  return {
    story,
    model: resolvedModel,
    usage: data?.usageMetadata || null,
  };
}

module.exports = {
  ALLOWED_MODELS,
  DEFAULT_MODEL,
  buildStoryPrompt,
  resolveModel,
  generateStoryWithGemini,
};
