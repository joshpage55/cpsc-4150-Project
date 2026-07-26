/**
 * Content-safety helpers for Story Builder (age-appropriate filters).
 * Teacher-in-the-loop approval remains the primary guardrail; this is the
 * automated pre-check before a draft is returned to the teacher.
 */

/** Blocklist for child-facing story text (case-insensitive). */
const BLOCKED_TERMS = [
  "kill",
  "killed",
  "killing",
  "murder",
  "blood",
  "bloody",
  "gun",
  "guns",
  "knife",
  "weapon",
  "die",
  "died",
  "death",
  "dead",
  "suicide",
  "hate",
  "horror",
  "monster",
  "monsters",
  "demon",
  "ghost",
  "scary",
  "terror",
  "violence",
  "violent",
  "abuse",
  "drug",
  "drugs",
  "alcohol",
  "beer",
  "wine",
  "sex",
  "sexy",
  "nude",
  "kiss",
  "romance",
  "boyfriend",
  "girlfriend",
  "damn",
  "hell",
  "crap",
];

/**
 * Soft daily token budget (prompt + completion). Crossing this logs a soft
 * alert for the instructor — it does not hard-block generation.
 */
const SOFT_DAILY_TOKEN_BUDGET = 50000;

/**
 * @param {string} text
 * @return {{safe: boolean, matches: string[]}}
 */
function checkStorySafety(text) {
  const lower = (text || "").toLowerCase();
  const matches = [];
  for (const term of BLOCKED_TERMS) {
    const re = new RegExp(`\\b${escapeRegex(term)}\\b`, "i");
    if (re.test(lower)) {
      matches.push(term);
    }
  }
  return {safe: matches.length === 0, matches};
}

/**
 * Reject interest strings that look like jailbreaks or unsafe topics.
 * @param {string} interest Interest theme from the teacher.
 * @return {{ok: boolean, reason: (string|undefined)}}
 */
function validateInterest(interest) {
  const trimmed = (interest || "").trim();
  if (!trimmed) {
    return {ok: false, reason: "interest is required"};
  }
  if (trimmed.length > 80) {
    return {ok: false, reason: "interest must be 80 characters or fewer"};
  }
  const blockedInterest = [
    "violence",
    "weapon",
    "kill",
    "death",
    "horror",
    "scary",
    "sex",
    "drug",
    "alcohol",
  ];
  const lower = trimmed.toLowerCase();
  for (const term of blockedInterest) {
    if (lower.includes(term)) {
      return {
        ok: false,
        reason: `interest contains disallowed topic: ${term}`,
      };
    }
  }
  return {ok: true};
}

/**
 * @param {string} level
 * @return {string} human reading-level phrase for the prompt
 */
function readingLevelLabel(level) {
  const map = {
    "pre-primer": "pre-primer / kindergarten",
    "preprimer": "pre-primer / kindergarten",
    "primer": "primer / kindergarten–grade 1",
    "first grade": "grade 1",
    "firstgrade": "grade 1",
    "second grade": "grade 2",
    "secondgrade": "grade 2",
    "third grade": "grade 2–3 (keep vocabulary simple)",
    "thirdgrade": "grade 2–3 (keep vocabulary simple)",
    "fourth grade": "grade 2–3 (keep vocabulary simple)",
    "fourthgrade": "grade 2–3 (keep vocabulary simple)",
    "fifth grade": "grade 2–3 (keep vocabulary simple)",
    "fifthgrade": "grade 2–3 (keep vocabulary simple)",
  };
  const key = (level || "").trim().toLowerCase().replace(/\s+/g, " ");
  const compact = key.replace(/[\s-]/g, "");
  return map[key] || map[compact] || "grade 1–2";
}

/**
 * @param {string} s
 * @return {string}
 */
function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

module.exports = {
  BLOCKED_TERMS,
  SOFT_DAILY_TOKEN_BUDGET,
  checkStorySafety,
  validateInterest,
  readingLevelLabel,
};
