# App Store Review Response — Guideline 2.1 / Information Needed
_Prepared: 2026-06-10_

---

Thank you for your review. Please find all requested information below.

**Regarding the login / demo account requirement:**
This app does not require an account to access any of its features. On the login screen, directly below the "Sign in with Apple" button, there is a **"CONTINUE AS GUEST"** button. Tapping it grants full, unrestricted access to every feature with no credentials required, so no demo account is necessary. "Sign in with Apple" is an optional convenience offered solely to enable CloudKit sync across the user's own devices; it is not a gate to any functionality.

---

## 1. Screen Recording

A screen recording captured on a physical iPhone running the latest available iOS is attached. The recording demonstrates:

- App launch
- Tapping "CONTINUE AS GUEST(ゲストとして続ける)" (no credentials entered)
- The core logging workflow: recording urination, bowel movement, breastfeeding, and formula-feeding events
- The RPG battle screen that updates in response to each log entry
- The calendar/timeline history view

---

## 2. Devices and OS Tested

| Device | OS |
|---|---|
| iPhone 14 Pro | iOS 26 Developer Beta (latest available at submission) |

---

## 3. Purpose and Target Audience

**Rメモ** is a daily activity logger for parents of newborns. It records four event types: urination, bowel movement, breastfeeding, and formula feeding.

Because caregivers must log these events repeatedly throughout the day—often while sleep-deprived and holding a baby—the app minimizes friction by reducing every action to a single tap. To make the repetitive logging feel less tedious, the experience is framed as a retro text-RPG: each logging button doubles as an "attack" action, and consistent daily logging gradually defeats on-screen enemies. A calendar/timeline view lets parents review their log history at a glance.

**Target audience:** New parents and other primary caregivers of infants.

**Problem solved:** Tracking feeding and diaper-change frequency is medically recommended in the newborn period, but existing apps are feature-heavy and slow to use one-handed. This app strips the feature set to the four essential events and adds a lightweight gamification layer to sustain daily engagement.

---

## 4. Setup and Access Instructions

No setup, account, or credentials are required.

1. Launch the app.
2. Tap **"CONTINUE AS GUEST"**.
3. All features are immediately accessible.

If the reviewer wishes to test CloudKit sync, tapping "Sign in with Apple" with a valid Apple ID will enable data sync across devices, but this step is entirely optional and does not affect access to any feature.

---

## 5. External Services and Tools

| Service | Purpose |
|---|---|
| Apple CloudKit | Stores and syncs the user's log data across their own devices |
| Sign in with Apple | Optional authentication used exclusively to enable CloudKit sync |

The app uses **no** third-party data providers, analytics SDKs, advertising networks, payment processors, or AI services.

---

## 6. Regional Differences

None. The app functions identically in all regions. There are no region-locked features, locale-specific content, or territory restrictions.

---

## 7. Regulated Industry / Protected Material

Although the app is listed under the **Medical** category (the most appropriate available category for infant-care utilities), it is strictly a personal activity tracker with a gamified interface. It does **not**:

- Provide medical diagnosis, advice, or treatment recommendations
- Perform any health assessment
- Connect to any medical device or external health service (beyond Apple CloudKit for personal data sync)

No protected third-party material, licensed health data, or regulated content is used. The app is not intended to replace professional medical guidance.
