# George's next steps, in order

Written 2026-09-08. Do them top to bottom. Each one is a few minutes except the phone
install. Everything else is already done and sitting on `main`.

## 1. Turn the bridge on (5 minutes)

Nothing can pair until this is done.

1. Open https://supabase.com and sign in.
2. Click your Prepkin project (its address starts with `aetv`).
3. In the left menu click **SQL Editor**, then **New query**.
4. On your Mac open `bridge/schema.sql` in any text editor. Select all, copy.
5. Paste it into the query box. Click **Run**. Wait for "Success".
6. If it complains about `pg_cron`: left menu, **Database**, **Extensions**, search
   `pg_cron`, turn it on, then run the query again.

## 2. Reload the extension and pair a phone (5 minutes)

This proves step 1 worked.

1. In Chrome type `chrome://extensions` in the address bar.
2. Top right, turn on **Developer mode**.
3. If "Prepkin for Canvas" is already there, click its **reload** arrow. If not, click
   **Load unpacked** and pick the `extension` folder inside the repo.
4. Open your Canvas site and log in. Click the Prepkin icon next to the address bar.
5. On your iPhone open Prepkin, tap **Today**, tap the sliders, and read the code.
6. Type that code into the Chrome popup. It should say "Paired. Getting your work…".
7. If it says the link ran out or needs an update, step 1 did not finish. Do it again.

## 3. Look at the art (10 minutes)

1. Open `ios/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`.
   That is the app icon. It is a placeholder I made from a Sprout still.
   Keep it, or replace it with your own 1024 by 1024 PNG with no transparency.
   Same file name, same folder.
2. Open `design/screenshots/appstore-6.9/`. Seven phone screenshots. These go to Apple.
3. Open `design/store/chrome-tile-440x280.png` and `chrome-marquee-1400x560.png`.
   Placeholders. Replace them if you want them to look good. Same size, same names.

## 4. Put the app on your phone (30 minutes the first time)

1. Open Xcode. Menu **Xcode**, **Settings**, **Accounts**. Click **+**, add your Apple ID.
2. Go to https://developer.apple.com/account. Under **Membership details** copy the
   **Team ID** (ten letters and numbers).
3. Open `ios/project.yml`. Under the first `settings: base:` block add one line:
   `DEVELOPMENT_TEAM: ABCDE12345` with your real Team ID.
4. In Terminal: `cd ~/Desktop/app/prepkin-canvas/ios && xcodegen generate`.
5. Open `ios/PrepkinCanvas.xcodeproj` in Xcode.
6. Plug in your iPhone with a cable. At the top of Xcode pick your iPhone as the device.
7. Press the **Play** button. Wait for the build.
8. On the phone: **Settings**, **General**, **VPN & Device Management**, tap your Apple ID,
   tap **Trust**. Open Prepkin.
9. Use it for one school day. Write down anything that looks wrong.
10. This expires in seven days. Repeat step 7 each week until you pay for the developer
    program.

## 5. Make the web addresses real (30 minutes)

Five addresses are already inside the app and extension. They have to exist.

1. Wherever `prepkin.com` is hosted, upload the four files in `bridge/site/`:
   `privacy.html`, `terms.html`, `support.html`, `site.css`.
   They must open at `prepkin.com/privacy`, `prepkin.com/terms`, `prepkin.com/support`.
2. Make two redirects: `prepkin.com/app` and `prepkin.com/chrome`. For now point both
   at `prepkin.com`. Later point them at the two store pages.
3. Make the email `support@prepkin.com` and make sure it lands in an inbox you read.
   A forward to your normal email is fine.
4. Open each of the five addresses in a browser and check they load.

## 6. Send to Apple (1 hour)

1. Go to https://appstoreconnect.apple.com. Click **My Apps**, **+**, **New App**.
2. Name **Prepkin for Canvas**, bundle ID `com.prepkin.canvas`, SKU `prepkin-canvas`.
3. Open `design/store/app-store-listing.md`. Copy each field into the matching box.
4. **App Privacy**: click **Get started**. Say yes, you collect data. Pick
   **Other User Content**. Say it is NOT linked to the user, NOT used for tracking,
   used for **App Functionality**. That matches what the app declares.
5. Upload the seven screenshots from `design/screenshots/appstore-6.9/` to the 6.9" slot.
6. In Xcode: top bar, pick **Any iOS Device**. Menu **Product**, **Archive**. When it
   finishes click **Distribute App**, **App Store Connect**, **Upload**. Click through.
7. Back in App Store Connect, under **Build**, pick the build that just arrived.
8. Paste `design/store/reviewer-notes.md`, App Store section, into **Notes for review**.
9. Click **Submit for Review**.

## 7. Send to Google (30 minutes)

1. In Terminal: `cd ~/Desktop/app/prepkin-canvas && npm run package`.
   It makes `dist/prepkin-canvas-0.6.0.zip`.
2. Go to https://chrome.google.com/webstore/devconsole. Pay the one-time $5 if asked.
3. Click **New item**. Upload that zip.
4. Open `design/store/chrome-listing.md`. Copy each field into the matching box.
5. **Privacy practices** tab: for the data question, tick **Personal communications /
   other user content**. Do NOT tick "does not collect data". Paste the permission
   reasons from the same file. Privacy policy URL is `https://prepkin.com/privacy`.
6. Screenshots: the four 1280x800 files in `design/signoff/extension-ui/`
   (`panel-open.png`, `banner-picker-0/1/2.png`). Tile and marquee from `design/store/`.
7. Paste `design/store/reviewer-notes.md`, Chrome section, into the reviewer notes box.
8. Click **Submit for review**. Expect one to three weeks.

## 8. Push the code (5 minutes)

1. In Terminal: `cd ~/Desktop/app/prepkin-canvas && git grep -il dartmouth -- design`.
   If that prints any file names, real school data is in the repo. Decide whether that
   is OK before pushing. If not, delete those files and commit.
2. `git status`. Anything listed is the games session's unfinished work. Finish or
   commit it in that session first.
3. `git push origin main`.

## 9. Stop the sandbox (2 minutes)

1. Go to https://console.cloud.google.com. Left menu, **Compute Engine**, **VM instances**.
2. Tick `canvas-sandbox`. Click **Stop** at the top. It costs money while it runs.

## Later, not this week

- Prepkin Plus has no screen yet. The purchase code is in `ios/Sources/Core/Plus.swift`.
  The screen comes after the design handoff.
- The Home tank still moves when Reduce Motion is on. Needs the Sprout source repo.
- Delete `PlayRecord.streak` and `playStreak()` in `GameState.swift` once the games land.
