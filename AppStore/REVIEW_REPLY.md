# Reply to App Review: Guideline 2.1 (Information Needed), Nov 2 2026

Apple asked for six things. Items 2–6 are the text below: paste it into
**App Store Connect › Distribution › App Review Information › Notes** (replace the old notes).
Item 1 (the screen recording) has to be filmed on a real iPhone; see the checklist at the bottom.

---

## Text to paste into Notes (under the 4,000-character limit)

```
SCREEN RECORDING (physical device, latest iOS): [PASTE LINK HERE]
The recording starts at app launch and shows the full user flow: Home, browsing a section/discipline, opening an entry, sharing it, Search with filters, and the Index tab (recently read, statistics, privacy policy). The app has no account registration, login, user-generated content, or paid content, so none of those flows exist.

1. PURPOSE AND AUDIENCE
This is the official app of the Comprehensive Arabic Encyclopedia (Al-Mawsoa Al-Arabiya Al-Shamila), a project of the Arabic Language Academy in Sharjah (UAE), a government cultural institution. It gives free, read-only access to peer-reviewed scholarly Arabic terms (linguistic, Islamic, human and applied sciences, and literary arts). Each entry has its linguistic definition, technical definition, explanation, examples, and sources.
Problem it solves: reliable, sourced Arabic terminology is scattered across printed references that are hard to search. The app puts the Academy's verified definitions in one searchable place, in a reading-friendly Arabic layout.
Audience: researchers, university and graduate students, teachers, translators, and general readers of Arabic.

2. HOW TO USE THE MAIN FEATURES
No login, credentials, or sample files are needed. All content is public and free. The interface is Arabic (right-to-left).
- Home tab (first tab, right side): tap a section, then a field, then a discipline to see its terms. Tap a term to read the full entry.
- Entry page: use the share button to open the native iOS share sheet.
- Search tab: type any Arabic word (for example: بلاغة or نحو). Suggestions appear while typing; results can be filtered by discipline.
- Index tab (الفهرس): a native index of all sections, fields and disciplines, the "recently read" list (stored on the device only), statistics, and the app's privacy policy.

3. EXTERNAL SERVICES
- Encyclopedia website and API (https://4nov.sharjah-encyclopedia.org), owned and operated by the Arabic Language Academy in Sharjah. All content comes from it.
- Google Analytics, used by the website for anonymous usage statistics (not linked to identity, not used for tracking).
The app uses no authentication service, payment processor, advertising network, or AI service.

4. REGIONAL DIFFERENCES
None. The app works the same way and shows the same content in all regions.

5. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
The app is not in a regulated industry. All content is original material written and published by the Arabic Language Academy in Sharjah, which owns it and publishes it on its own website. The Arabic font (Scheherazade New) is used under the SIL Open Font License.

Contact for review: info@alashj.ae
```

---

## Screen recording checklist (item 1)

1. On a **real iPhone** updated to the **latest iOS** (Settings › General › Software Update).
2. Install the submitted build through **TestFlight** (build 1.0 (1)).
3. Turn on Screen Recording (Control Centre). Start recording **from the home screen**, then tap the app icon so the launch is visible.
4. Show, in order (about 1–2 minutes):
   - Home: tap a section › a field › a discipline › a term, scroll the entry.
   - Tap share on the entry, show the share sheet, close it.
   - Search tab: type بلاغة, show suggestions, open a result, use a discipline filter.
   - الفهرس tab: recently read, statistics, privacy policy, open an item from the index.
5. Stop the recording. Upload the video to a link Apple can open **without signing in** (Google Drive set to "Anyone with the link", Dropbox, or YouTube unlisted).
6. Replace `[PASTE LINK HERE]` with the link, save the Notes, then **Resubmit to App Review**.

## Check before resubmitting

- If the Apple developer account is **not** in the Arabic Language Academy's name, attach a short authorization letter from the Academy (in Notes or as an attachment) saying the account holder may publish the app. Apple asks for this under item 6 when the publisher and content owner differ.
- Privacy Policy URL in App Store Connect › App Privacy must be `https://sharjah-encyclopedia.org/app-privacy.html` (live, checked Nov 2). The `4nov.` address returns 404, so don't use it.
- Support URL: `https://sharjah-encyclopedia.org/app-support.html` (live, checked Nov 2).
