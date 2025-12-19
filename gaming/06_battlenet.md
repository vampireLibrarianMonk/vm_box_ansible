# Install Battle.net (Manual via Lutris — REQUIRED)

⚠️ **Do not download or run the Battle.net installer manually.**  
Battle.net must be installed **through Lutris itself** to avoid update loops and rendering issues.

---

### Step 1 — Launch Lutris (Flatpak only)

```bash
flatpak run net.lutris.Lutris
```

> ❗ Do **not** launch Lutris from an APT-based or system-installed desktop entry.

---

### Step 2 — Search for Battle.net inside Lutris

In the Lutris UI:

1. Click the **“+”** button (top-left)
2. Select **“Search the Lutris website”**
3. Search for **Battle.net**
4. Select **“Battle.net (Blizzard Battle.net App)”**
5. Click **Install**

---

### Step 3 — Set the install location (IMPORTANT)

When prompted for the installation directory, **use exactly**:

```
/home/user/Games/battlenet
```

⚠️ Do not use `/mnt/games` here  
⚠️ Do not accept the default path  
⚠️ Do not change this later

---

### Step 4 — Configure the Wine runner (BEFORE first launch)

After installation, but **before launching Battle.net**:

Lutris → Battle.net → **Configure** → **Runner options**

Set the following:

- **Wine version:** Wine-GE 10.x or newer
- I did not touch any other settings, your on your own here.

❌ Do not use Proton  
❌ Do not use system Wine  
❌ Do not use default Lutris Wine

---

### Step 5 — Verify installation path

Confirm the following directory exists:

```
/home/user/Games/battlenet/drive_c/Program Files (x86)/Battle.net
```

If it does not exist, **stop and fix the install path before proceeding**.

---

### Step 6 — Launch Battle.net

Launch Battle.net from Lutris and allow it to fully update before interacting.

---

### Step 7 — Install StarCraft II

When installing StarCraft II inside Battle.net, set the install path to:

```
/mnt/games/SC2
```

This ensures:
- Correct disk detection
- No Wine Z:\ drive issues
- Stable performance in a VM

---

✅ **Battle.net installation complete**

