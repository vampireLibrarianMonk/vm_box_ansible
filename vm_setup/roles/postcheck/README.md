# postcheck role

Read-only post-install validation for base VM hosts.

## What it checks
- libvirt installed, enabled, running
- libvirt socket present
- virt-manager installed
- KVM acceleration available
- User permissions correct
- VM storage directory exists and empty
- No libvirt VMs defined

## Expected result
- Zero system changes
- Failure on any misconfiguration
- Safe for CI, templates, golden images

## Usage

```yaml
- hosts: localhost
  become: yes
  roles:
    - base_vm
    - postcheck
