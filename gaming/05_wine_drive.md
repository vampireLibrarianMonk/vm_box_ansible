# Battle.net Wine Drive Mapping (Manual GUI Method)

This document describes the **manual, click-through equivalent** of the automated script for mapping `/mnt/games` as a dedicated drive (`G:`) inside **Battle.net running in Lutris via Wine**.

This method uses **Lutris → Wine Configuration (`winecfg`)** and is functionally identical to the scripted approach.

---

## Purpose

Mapping `/mnt/games` as a real Wine drive:

- Prevents Battle.net disk-space detection issues
- Ensures large games install to the correct disk
- Avoids Wine `Z:` root mapping problems
- Survives reboots and Wine upgrades
- Keeps game data off the OS disk

---

## Prerequisites

Before proceeding, confirm the following:

- ✅ **Battle.net is already added in Lutris**
- ✅ `/mnt/games` exists and is mounted
- ✅ Battle.net is configured to use a **Wine runner**
  - Wine-GE or Lutris Wine are recommended

---

## Step 1 — Open Battle.net Wine Configuration

1. Open **Lutris**
2. Right-click **Battle.net**
3. Click **Configure**
4. Go to **Runner options**
5. Click **Wine configuration**

This launches `winecfg` for the Battle.net Wine prefix.

> This is equivalent to running:
>
> ```
> WINEPREFIX=~/Games/battlenet winecfg
> ```
>
> (Exact prefix path may vary depending on your Lutris setup.)

---

## Step 2 — Add the G: Drive

Inside the **winecfg** window:

1. Open the **Drives** tab
2. Click **Add**
3. Configure the new drive:
   - **Drive letter:** `G:`
   - **Path:** `/mnt/games`
4. Click **Apply**
5. Click **OK**

### What This Does

This is the GUI equivalent of creating a Wine drive mapping:

```
ln -s /mnt/games ~/Games/battlenet/dosdevices/g:
```

Wine now treats `/mnt/games` as a real disk.

---

## Step 3 — Verify the Mapping

(Optional but recommended)

1. Reopen **Wine configuration** if needed
2. Go to the **Drives** tab
3. Confirm:
   - `G:` exists
   - Path is set to `/mnt/games`

---

## Step 4 — Use the Drive in Battle.net

1. Launch **Battle.net**
2. When installing a game (e.g., **StarCraft II**), set the install location to:

```
G:\StarCraft II
```

---

## Expected Results

After completing these steps:

- ✅ Battle.net correctly detects available disk space
- ✅ Game files are stored under `/mnt/games`
- ✅ Installs are stable and consistent
- ✅ No reliance on Wine’s `Z:` mapping
- ✅ Configuration persists across reboots

---

## Notes

- This process only needs to be done **once per Wine prefix**
- If you delete or recreate the Battle.net prefix, repeat these steps
- This approach works for **any large Battle.net game**

