# Team Firebase Setup — CPSC 4150 ReadRight

**Project ID:** `cpsc4150-readright`  
**Console:** https://console.firebase.google.com/project/cpsc4150-readright/overview

Created for M2 so the team is not blocked on inherited `readright-2ad31`.

## Teammates: get access

1. Firebase Console → Project Settings → Users and permissions  
2. Invite each teammate’s Google account as **Editor**

## Flutter client (when ready)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=cpsc4150-readright
```

Replaces `firebase_options.dart`, `google-services.json`, and iOS plist.

## Deploy story proxy

```bash
cd functions && npm install
firebase use cpsc4150-readright
firebase functions:secrets:set GEMINI_API_KEY   # paste key from private Canvas post
firebase deploy --only functions:generateStorySpike
```

## Local spike (before deploy)

```bash
cp .env.example .env
# add GEMINI_API_KEY from Canvas
node scripts/m2_story_spike.mjs
```

## Blaze plan

Cloud Functions require the **Blaze (pay-as-you-go)** plan. Enable in Firebase Console → Upgrade. Set a budget alert.
