### Lutris Runner Selection for Battle.net (Known-Working)

> ✅ Use this runner **before installing Battle.net**. Other runners caused crashes and missing UI.

**Working Wine Runner**
- **wine-10.16-staging-amd64-wow64 (x86_64)**

---

### Steps in Lutris

1. In Lutris, click **☰ → Preferences → Runners**
2. Scroll to **Wine**
3. Click the **download / package icon** next to **Wine** to open *Manage Wine versions*
4. Install:
   - **wine-10.16-staging-amd64-wow64**
5. Close the Wine versions window
6. Click the **gear icon** next to **Wine**
7. Set **Wine version** to:
   - **wine-10.16-staging-amd64-wow64**
8. Ensure **DXVK** is enabled
9. Click **Save**

---

### Install Battle.net

1. Go to:
   ```
   https://lutris.net/games/battlenet/
   ```
2. Click **Install** (opens Lutris)
3. When prompted for install location, choose:
   ```
   /mnt/games/BattleNet
   ```

---

### Verify After Install

- Right-click **Battle.net → Configure → Runner options**
- Confirm **Wine version** is still:
  ```
  wine-10.16-staging-amd64-wow64
  ```

> ⚠️ Do **not** switch runners after install.  
> This specific Wine 10.16 staging runner is confirmed stable for Battle.net.
