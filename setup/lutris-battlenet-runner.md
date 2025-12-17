# Battle.net + StarCraft II on Lutris (Known‑Working, Persistent Storage)

This README reconciles **runner selection**, **installation**, and **Wine drive mapping**
into a single **known‑good**, reproducible process.

It fixes the common issue where Battle.net:
- Sees disk space but writes no files
- Installs to `Z:` silently
- Loses installs after reboot

---

## Prerequisites

- Linux host
- Lutris installed
- `/mnt/games` **already mounted** and writable by your user

Verify:
```bash
mount | grep /mnt/games
ls -ld /mnt/games
```

---

## Part 1 — Install the Known‑Working Wine Runner (DO THIS FIRST)

> ⚠️ Do **not** install Battle.net before completing this section.

### Working Wine Runner (Confirmed Stable)
- **wine-10.16-staging-amd64-wow64 (x86_64)**

### Steps in Lutris

1. Open **Lutris**
2. Click **☰ → Preferences → Runners**
3. Scroll to **Wine**
4. Click the **package/download icon** (Manage Wine versions)
5. Install:
   ```
   wine-10.16-staging-amd64-wow64
   ```
6. Close the Wine versions window
7. Click the **gear icon** next to Wine
8. Set **Wine version** to:
   ```
   wine-10.16-staging-amd64-wow64
   ```
9. Ensure **DXVK** is enabled
10. Click **Save**

---

## Part 2 — Add a Real Game Drive to the Battle.net Wine Prefix

This is the **critical fix** that makes installs persist.

### Step 1 — Open the Battle.net Wine Prefix

In Lutris:
- Right‑click **Battle.net**
- Click **Configure**
- Go to **Runner options**
- Note the **Wine prefix path**

We will use `/mnt/games`:

---

### Step 2 — Run winecfg for Battle.net

```bash
WINEPREFIX="/mnt/games" winecfg
```

---

### Step 3 — Add a New Drive Letter

In **winecfg → Drives**:

- Click **Add**
- Set:
  - **Drive letter:** `G:`
  - **Path:** `/mnt/games`
- Click **Apply → OK**

---

## Part 3 — Install Battle.net via Lutris

1. Open:
   ```
   https://lutris.net/games/battlenet/
   ```
2. Click **Install** (opens Lutris)
3. When prompted for install location, choose:
   ```
   /mnt/games/BattleNet
   ```
4. Complete the installer and let Battle.net launch once

---

## Part 4 — Install StarCraft II Correctly

Inside Battle.net:
- Set install path to:
  ```
  G:\StarCraft II
  ```

### What You Should See Immediately

In another terminal:
```bash
ls -lh /mnt/games
```

Expected:
```
StarCraft II/
```

---

## Verification Checklist

- ✅ Files appear instantly in `/mnt/games`
- ✅ Disk space is detected correctly
- ✅ Installs survive reboot
- ✅ No race conditions
- ✅ No reliance on `Z:` root mapping

---

## Important Warnings

- ⚠️ **Do not switch Wine runners after install**
- ⚠️ Always install games to `G:` (or your mapped drive)
- ⚠️ If `/mnt/games` is not mounted, installs will fail silently

---

## Why This Works

- Wine treats custom drive letters as real disks
- Battle.net disk checks succeed
- Avoids fragile `Z:` filesystem mapping
- This is the **standard, proven Linux Battle.net solution**

---

## Troubleshooting

### Files not appearing?
- Re‑open `winecfg`
- Confirm `G:` → `/mnt/games`
- Restart Battle.net

### Battle.net crashes?
- Confirm Wine version is still:
  ```
  wine-10.16-staging-amd64-wow64
  ```

---

## Status

✅ **Battle.net: Stable**  
✅ **StarCraft II: Working**  
✅ **Persistent Storage: Confirmed**
