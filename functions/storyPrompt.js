/**
 * Dolch-constrained story prompt for M2 spike / M3 Story Builder.
 */

/** Mini-tier models allowed for course guardrails. */
const ALLOWED_MODELS = new Set([
  "gpt-4o-mini",
  "gpt-4.1-mini",
]);

const DEFAULT_MODEL = "gpt-4o-mini";

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
    "You MUST include several of these Dolch sight words naturally: " +
      wordList.join(", ") + ".",
    "Keep sentences short. No scary content.",
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

  return {
    story,
    model: resolvedModel,
    usage: data?.usage || null,
  };
}

module.exports = {
  ALLOWED_MODELS,
  DEFAULT_MODEL,
  buildStoryPrompt,
  resolveModel,
  generateStoryWithOpenAI,
};
