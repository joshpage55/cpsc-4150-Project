/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
// Use the official firebase-admin SDK to access admin.initializeApp().
// The previous code attempted to read `admin` from `firebase-functions/https`
// which does not export an `admin` object (causing initializeApp
// to be undefined).
const admin = require("firebase-admin");
const {GoogleAuth} = require("google-auth-library");
const {buildStoryPrompt, generateStoryWithOpenAI} = require("./storyPrompt");
// const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
// Apply global options using the functions namespace
functions.setGlobalOptions({maxInstances: 10});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

admin.initializeApp();

exports.getPasswordPolicyForApp = functions.https.onCall(
    async (_data, context) => {
      // NOTE: Previously we enforced that callers must be authenticated
      // (i.e. `context.auth` existed) and would throw `permission-denied` if
      // not. For client-side apps that need to read the password policy before
      // signing in (for example to render password requirements on a signup
      // form), the policy should be readable by unauthenticated callers.
      //
      // If this policy contains sensitive admin-only configuration, re-enable
      // the check and require callers to be authenticated and/or have an
      // `admin` custom claim.
      // Optional: require admin callers only
      // if (!context.auth /* || context.auth.token.admin !== true */) {
      //   throw new functions.https.HttpsError(
      //       "permission-denied", "Auth required",
      //   );
      // }

      const auth = new GoogleAuth({
        scopes: ["https://www.googleapis.com/auth/cloud-platform"],
      });
      const client = await auth.getClient();
      const tokenResponse = await client.getAccessToken();
      const token = tokenResponse?.token;
      console.log("PasswordPolicy: got access token?", !!token);

      // TODO: This requires OAuth access to the Identity Toolkit API.
      // Forgetting about this for now and we'll just return a safe default.

      // Unhandled error GaxiosError: Request is missing required authentication
      // credential. Expected OAuth 2 access token, login cookie or other valid
      // authentication credential.
      // See https://developers.google.com/identity/sign-in/web/devconsole-project.

      // Call the Identity Toolkit API to get the password policy
      // for the Firebase project associated with the service account.
      const url = "https://identitytoolkit.googleapis.com/v2/passwordPolicy";
      let res;
      try {
        if (!token) {
          console.warn("No ADC access token; returning default policy");

          // This safe default is ignored and handled in the
          // `utils/fetchPasswordPolicy.dart` instead.
          throw new Error("No access token available from ADC");
          // Return a safe default policy so clients can continue.
          //   return {
          //     min: 6,
          //     max: 4096,
          //     needLower: false,
          //     needUpper: false,
          //     needNum: false,
          //     needSym: false,
          //     enforce: null,
          //   };
        }

        res = await client.request({
          url,
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });
      } catch (err) {
        // Log detailed diagnostics to help debugging IAM/ADC issues.
        console.error("Error requesting Identity Toolkit passwordPolicy:", err);
        if (err && err.response && err.response.data) {
          console.error("Response data:", JSON.stringify(err.response.data));
        }

        // This safe default is ignored and handled in the
        // `utils/fetchPasswordPolicy.dart` instead.
        throw new Error("Identity Toolkit passwordPolicy request failed");
        // On error, return a safe default so UI remains usable.
        // return {
        //   min: 6,
        //   max: 4096,
        //   needLower: false,
        //   needUpper: false,
        //   needNum: false,
        //   needSym: false,
        //   enforce: null,
        // };
      }
      // Return only the parts your app needs
      const p = res.data || {};
      return {
        min: p.customStrengthOptions?.minPasswordLength ?? 6,
        max: p.customStrengthOptions?.maxPasswordLength ?? 4096,
        needLower: !!p.customStrengthOptions?.containsLowercaseCharacter,
        needUpper: !!p.customStrengthOptions?.containsUppercaseCharacter,
        needNum: !!p.customStrengthOptions?.containsNumericCharacter,
        needSym: !!p.customStrengthOptions?.containsNonAlphanumericCharacter,
        enforce: p.enforcementState,
      };
    },
);

const openAiApiKey = defineSecret("OPENAI_API_KEY");
const deepgramApiKey = defineSecret("DEEPGRAM_API_KEY");
const {
  SOFT_DAILY_TOKEN_BUDGET,
  validateInterest,
} = require("./contentSafety");

const MAX_REGENS_PER_DAY = 3;

/**
 * @param {string} uid
 * @return {Promise<{role: string}>}
 */
async function requireTeacher(uid) {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }
  const snap = await admin.firestore().collection("users").doc(uid).get();
  if (!snap.exists) {
    throw new HttpsError("permission-denied", "User profile not found");
  }
  const role = (snap.data()?.role || "").toString().toLowerCase();
  if (role !== "teacher") {
    throw new HttpsError(
        "permission-denied",
        "Only teachers may generate stories",
    );
  }
  return {role};
}

/**
 * Log token usage and emit a soft spend alert when the daily budget
 * is crossed. Soft alert = Firestore doc + structured console warn
 * (instructor path), not a hard block.
 * @param {object} params
 * @return {Promise<{dailyTokens: number, softAlert: boolean}>}
 */
async function logAiUsage({
  teacherId,
  studentId,
  model,
  usage,
  feature,
}) {
  const db = admin.firestore();
  const dayKey = new Date().toISOString().slice(0, 10);
  const promptTokens = usage?.prompt_tokens || 0;
  const completionTokens = usage?.completion_tokens || 0;
  const totalTokens = usage?.total_tokens || (promptTokens + completionTokens);

  await db.collection("ai_usage_logs").add({
    teacherId: teacherId || null,
    studentId: studentId || null,
    model: model || null,
    feature: feature || "story",
    promptTokens,
    completionTokens,
    totalTokens,
    dayKey,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const counterRef = db.collection("ai_usage_daily").doc(dayKey);
  await db.runTransaction(async (tx) => {
    const doc = await tx.get(counterRef);
    const prev = doc.exists ? (doc.data()?.totalTokens || 0) : 0;
    const next = prev + totalTokens;
    tx.set(counterRef, {
      totalTokens: next,
      dayKey,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  const after = await counterRef.get();
  const dailyTokens = after.data()?.totalTokens || totalTokens;
  const softAlert = dailyTokens >= SOFT_DAILY_TOKEN_BUDGET;

  if (softAlert) {
    console.warn(
        JSON.stringify({
          type: "SOFT_SPEND_ALERT",
          dayKey,
          dailyTokens,
          budget: SOFT_DAILY_TOKEN_BUDGET,
          message:
            "Team daily token soft budget crossed — " +
            "notify instructor (not a hard cap).",
        }),
    );
    await db.collection("ai_spend_alerts").add({
      dayKey,
      dailyTokens,
      budget: SOFT_DAILY_TOKEN_BUDGET,
      soft: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return {dailyTokens, softAlert};
}

/**
 * Enforce PRD regenerate limit (3 / teacher / day).
 * @param {string} teacherId
 * @return {Promise<{remaining: number, count: number}>}
 */
async function consumeRegenSlot(teacherId) {
  const db = admin.firestore();
  const dayKey = new Date().toISOString().slice(0, 10);
  const ref = db.collection("story_regen_counters")
      .doc(`${teacherId}_${dayKey}`);

  const result = await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const count = doc.exists ? (doc.data()?.count || 0) : 0;
    if (count >= MAX_REGENS_PER_DAY) {
      return {blocked: true, count, remaining: 0};
    }
    const next = count + 1;
    tx.set(ref, {
      teacherId,
      dayKey,
      count: next,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return {
      blocked: false,
      count: next,
      remaining: MAX_REGENS_PER_DAY - next,
    };
  });

  if (result.blocked) {
    throw new HttpsError(
        "resource-exhausted",
        "Daily story generate/regenerate limit reached (" +
        `${MAX_REGENS_PER_DAY}).`,
    );
  }
  return {remaining: result.remaining, count: result.count};
}

/**
 * Shared story generation core used by spike + production callables.
 * @param {object} params Generation inputs and attribution ids.
 * @return {Promise<object>}
 */
async function runStoryGeneration({
  apiKey,
  dolchWords,
  maxWords,
  interest,
  readingLevel,
  teacherId,
  studentId,
  feature,
}) {
  const interestCheck = validateInterest(interest || "animals and play");
  if (!interestCheck.ok) {
    throw new HttpsError("invalid-argument", interestCheck.reason);
  }

  const {system, user} = buildStoryPrompt(dolchWords, {
    maxWords,
    interest: interest || "animals and play",
    readingLevel: readingLevel || "first grade",
  });

  try {
    const result = await generateStoryWithOpenAI({
      apiKey,
      model: process.env.OPENAI_MODEL,
      system,
      user,
    });

    const spend = await logAiUsage({
      teacherId,
      studentId,
      model: result.model,
      usage: result.usage,
      feature,
    });

    return {
      story: result.story,
      model: result.model,
      dolchWords,
      interest: interest || "animals and play",
      readingLevel: readingLevel || "first grade",
      usage: result.usage,
      safety: result.safety,
      softSpendAlert: spend.softAlert,
      dailyTokens: spend.dailyTokens,
      promptPreview: {system, user},
      via: "firebase-proxy",
    };
  } catch (err) {
    if (err.code === "content-safety") {
      throw new HttpsError(
          "failed-precondition",
          err.message || "Story failed content-safety filter",
      );
    }
    throw err;
  }
}

/**
 * M2 de-risk spike: Dolch words in → proxied mini-tier LLM → story out.
 * Kept for M2 evidence scripts. Prefer generateStory for the teacher app.
 */
exports.generateStorySpike = onCall(
    {secrets: [openAiApiKey], maxInstances: 5},
    async (request) => {
      const apiKey = openAiApiKey.value();
      if (!apiKey) {
        throw new HttpsError(
            "failed-precondition",
            "OPENAI_API_KEY is not configured on the server",
        );
      }

      const data = request.data;
      const dolchWords = data?.dolchWords;
      if (!Array.isArray(dolchWords) || dolchWords.length === 0) {
        throw new HttpsError(
            "invalid-argument",
            "dolchWords must be a non-empty array of strings",
        );
      }

      const maxWords = typeof data?.maxWords === "number" ? data.maxWords : 120;
      try {
        return await runStoryGeneration({
          apiKey,
          dolchWords,
          maxWords,
          interest: data?.interest,
          readingLevel: data?.readingLevel,
          teacherId: request.auth?.uid || null,
          studentId: data?.studentId || null,
          feature: "story_spike",
        });
      } catch (err) {
        console.error("generateStorySpike failed:", err);
        if (err instanceof HttpsError) throw err;
        throw new HttpsError(
            "internal",
            err.message || "Story generation failed",
        );
      }
    },
);

/**
 * M3 production Story Builder callable.
 * Teacher-only. Writes a draft story doc; teacher must approve before
 * students see it.
 */
exports.generateStory = onCall(
    {secrets: [openAiApiKey], maxInstances: 5},
    async (request) => {
      const apiKey = openAiApiKey.value();
      if (!apiKey) {
        throw new HttpsError(
            "failed-precondition",
            "OPENAI_API_KEY is not configured on the server",
        );
      }

      const uid = request.auth?.uid;
      await requireTeacher(uid);

      const data = request.data || {};
      const studentId = data.studentId;
      const classId = data.classId;
      const readingLevel = data.readingLevel || "first grade";
      const interest = data.interest || "animals and play";
      const dolchWords = data.dolchWords;
      const maxWords = typeof data.maxWords === "number" ? data.maxWords : 120;

      if (!studentId || typeof studentId !== "string") {
        throw new HttpsError("invalid-argument", "studentId is required");
      }
      if (!classId || typeof classId !== "string") {
        throw new HttpsError("invalid-argument", "classId is required");
      }
      if (!Array.isArray(dolchWords) || dolchWords.length === 0) {
        throw new HttpsError(
            "invalid-argument",
            "dolchWords must be a non-empty array of strings",
        );
      }

      const regen = await consumeRegenSlot(uid);

      try {
        const generated = await runStoryGeneration({
          apiKey,
          dolchWords,
          maxWords,
          interest,
          readingLevel,
          teacherId: uid,
          studentId,
          feature: "story_builder",
        });

        const db = admin.firestore();
        const docRef = db.collection("stories").doc();
        const storyDoc = {
          id: docRef.id,
          status: "draft",
          text: generated.story,
          studentId,
          classId,
          teacherId: uid,
          readingLevel,
          interest,
          dolchWords,
          model: generated.model,
          usage: generated.usage || null,
          regenerationsRemainingToday: regen.remaining,
          softSpendAlert: generated.softSpendAlert,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          approvedAt: null,
        };
        await docRef.set(storyDoc);

        return {
          ...generated,
          storyId: docRef.id,
          status: "draft",
          regenerationsRemainingToday: regen.remaining,
        };
      } catch (err) {
        console.error("generateStory failed:", err);
        if (err instanceof HttpsError) throw err;
        throw new HttpsError(
            "internal",
            err.message || "Story generation failed",
        );
      }
    },
);

/**
 * Teacher approves a draft story so the assigned student can see it.
 */
exports.approveStory = onCall(
    {maxInstances: 5},
    async (request) => {
      const uid = request.auth?.uid;
      await requireTeacher(uid);

      const storyId = request.data?.storyId;
      if (!storyId || typeof storyId !== "string") {
        throw new HttpsError("invalid-argument", "storyId is required");
      }

      const ref = admin.firestore().collection("stories").doc(storyId);
      const snap = await ref.get();
      if (!snap.exists) {
        throw new HttpsError("not-found", "Story not found");
      }
      const story = snap.data();
      if (story.teacherId !== uid) {
        throw new HttpsError(
            "permission-denied",
            "Only the owning teacher may approve this story",
        );
      }
      if (story.status === "approved") {
        return {storyId, status: "approved", alreadyApproved: true};
      }

      await ref.update({
        status: "approved",
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {storyId, status: "approved", alreadyApproved: false};
    },
);

/**
 * Cloud STT proxy — Deepgram key stays on the server.
 * Flutter sends base64 audio; never embeds DEEPGRAM_API_KEY.
 */
exports.transcribeAudio = onCall(
    {secrets: [deepgramApiKey], maxInstances: 5},
    async (request) => {
      if (!request.auth?.uid) {
        throw new HttpsError("unauthenticated", "Sign in required");
      }

      const apiKey = deepgramApiKey.value();
      if (!apiKey) {
        throw new HttpsError(
            "failed-precondition",
            "DEEPGRAM_API_KEY is not configured on the server",
        );
      }

      const data = request.data || {};
      const audioBase64 = data.audioBase64;
      const mimeType = (data.mimeType || "audio/wav").toString();
      if (!audioBase64 || typeof audioBase64 !== "string") {
        throw new HttpsError(
            "invalid-argument",
            "audioBase64 is required",
        );
      }

      let audioBuffer;
      try {
        audioBuffer = Buffer.from(audioBase64, "base64");
      } catch (e) {
        throw new HttpsError("invalid-argument", "Invalid base64 audio");
      }
      if (audioBuffer.length === 0 || audioBuffer.length > 5 * 1024 * 1024) {
        throw new HttpsError(
            "invalid-argument",
            "Audio must be between 1 byte and 5MB",
        );
      }

      const url =
        "https://api.deepgram.com/v1/listen?model=nova-3&smart_format=true";
      let res;
      try {
        res = await fetch(url, {
          method: "POST",
          headers: {
            "Authorization": `Token ${apiKey}`,
            "Content-Type": mimeType,
          },
          body: audioBuffer,
        });
      } catch (err) {
        console.error("transcribeAudio network error:", err);
        throw new HttpsError("internal", "Deepgram request failed");
      }

      const body = await res.json();
      if (!res.ok) {
        console.error("Deepgram error:", body);
        throw new HttpsError(
            "internal",
            body?.err_msg || body?.error || "Deepgram transcription failed",
        );
      }

      const alt = body?.results?.channels?.[0]?.alternatives?.[0] || {};
      return {
        transcript: alt.transcript || "",
        confidence: typeof alt.confidence === "number" ? alt.confidence : 0,
        provider: "Deepgram Nova-3",
        via: "firebase-proxy",
      };
    },
);
