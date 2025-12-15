# Set Ubuntu Timezone to US Eastern (EST/EDT)

This README documents a **verified, command-line method** to configure an Ubuntu system to use the **US Eastern timezone**, with NTP synchronization enabled.

This procedure has been validated on Ubuntu systems using `systemd` and `timedatectl`.

---

## ✅ Prerequisites

- Ubuntu 20.04 / 22.04 / 24.04
- `systemd` (default on Ubuntu)
- Sudo privileges

---

## 1. Check Current Time and Timezone

```bash
timedatectl
date
```

This shows:
- Local time
- UTC time
- Active timezone
- NTP synchronization status

---

## 2. List Available Eastern Timezones (Optional)

```bash
timedatectl list-timezones | grep -i eastern
```

Typical output:
```
Canada/Eastern
US/Eastern
```

---

## 3. Set Timezone to US Eastern

```bash
sudo timedatectl set-timezone US/Eastern
```

✔ This immediately updates the system timezone
✔ Daylight Saving Time (EST/EDT) is handled automatically

---

## 4. Verify Configuration

```bash
timedatectl
date
```

Expected example output:
```
Local time: Mon 2025-12-15 15:02:01 EST
Universal time: Mon 2025-12-15 20:02:01 UTC
Time zone: US/Eastern (EST, -0500)
System clock synchronized: yes
NTP service: active
RTC in local TZ: no
```

---

## ⚠️ Notes on Timezone Names

- `US/Eastern` is **valid and supported** on Ubuntu
- Canonical IANA name is: `America/New_York`
- Both behave identically for EST/EDT

If you prefer the canonical name:

```bash
sudo timedatectl set-timezone America/New_York
```

---

## 🖥️ Server, VM, and Container Notes

- Linux systems **keep hardware clocks in UTC** (recommended)
- Timezone affects display and logging only
- Safe for:
  - Bare metal servers
  - Proxmox / KVM / VMware guests
  - Cloud instances (AWS / Azure / GCP)

> Containers typically inherit the host timezone unless explicitly overridden.

---

## ✅ Summary

- `timedatectl` is the supported method on Ubuntu
- `US/Eastern` works correctly and is active
- NTP remains enabled and synchronized
- DST changes are automatic

---

**Status:** Verified and working

