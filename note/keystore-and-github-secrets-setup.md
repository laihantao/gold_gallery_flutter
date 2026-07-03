# Keystore & GitHub Secrets Setup

## 📍 Section 1: Things to do on PC1 (the computer that generates the keystore)

`cd` into the project root, then run the generate command:

```powershell
keytool -genkeypair -v -keystore android/release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pocket_gold
```

You'll be prompted interactively for:

- Keystore password (set one, remember it → this is `storePassword`)
- Re-enter to confirm
- Name / organization / city / state / country code (fill in anything, doesn't affect functionality)
- Confirm the info (type `yes`)
- Key password (press Enter = reuse the same password as the keystore; or type a different one = this becomes a separate `keyPassword`)

Manually create `android/key.properties` (this is **not** auto-generated — you need to create this file yourself):

```properties
storePassword=your storePassword
keyPassword=your keyPassword (if you just pressed Enter when generating, fill in the same value as storePassword)
keyAlias=pocket_gold
storeFile=../release-key.jks
```

Confirm `.gitignore` already includes (to avoid accidentally committing them):

```
android/release-key.jks
android/key.properties
```

**Immediately back up** the `.jks` file to cloud storage / a password manager's file attachment (e.g. 1Password/Bitwarden file attachment feature). If this file is lost, it can never be recovered.

Verify the signing works:

```powershell
flutter build apk --flavor prod --target lib/main_prod.dart --dart-define=CHANNEL=prod --release
```

If the build succeeds without errors and isn't falling back to debug signing, you're done.

## 📍 Section 2: Things to do on PC2 (if you also develop/build on another computer)

1. Download the `release-key.jks` backup from PC1 (cloud storage / password manager).
2. Place it at the same path on PC2: `android/release-key.jks`.
3. Manually recreate `android/key.properties` with the exact same content as PC1 (this file does not sync via git/cloud — you need to type it manually or paste it from your backup).
4. Run the same build command to verify the signing matches.

## 📍 Section 3: Secrets to configure in GitHub Actions

**Step A — Generate the base64 text locally (only needs to be run once, on PC1):**

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\release-key.jks")) | Out-File keystore_base64.txt
```

**Step B — In the GitHub web UI:** repo → Settings → Secrets and variables → Actions → New repository secret. Create these one by one:

| Secret name | Value to paste in |
|---|---|
| `KEYSTORE_BASE64` | The whole text content of `keystore_base64.txt` |
| `KEYSTORE_PASSWORD` | Your `storePassword` |
| `KEY_PASSWORD` | Your `keyPassword` (same value as above if they're the same) |
| `KEY_ALIAS` | `pocket_gold` |

**Step C — Clean up:** once you've pasted everything in, immediately delete the local `keystore_base64.txt` — don't leave it lying around, and don't commit it.

## ✅ Regarding your question

> If I typed the same password for both prompts during keystore generation, then in the properties file, `storePassword` and `keyPassword` should be the same, right?

Yes, that's correct — as long as you pressed Enter at the key password step during `keytool` generation (reusing the store password), then in both `key.properties` and the GitHub Secrets, the `storePassword`/`KEYSTORE_PASSWORD` and `keyPassword`/`KEY_PASSWORD` pairs should be filled in with the exact same password.
