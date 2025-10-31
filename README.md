# Ansible Workstation Management

Enterprise-grade Ansible automation for workstation management, supporting macOS, Debian/Ubuntu, and RedHat/CentOS systems.

## Features

- **System Updates**: Automated package management with OS-specific handlers
- **Backup Management**: Intelligent backup with retention policies and manifest generation
- **Security Hardening**: CIS-inspired security controls and firewall management
- **Compliance Auditing**: Automated security compliance checks with detailed reporting
- **Weekly Maintenance**: Comprehensive maintenance workflow with pre/post validation

## Quick Start

```bash
# Clone and navigate to repository
cd ansible-workstation

# Install dependencies
make install

# Run weekly maintenance
make weekly-os

# Or run specific tasks
make update         # Update packages only
make backup         # Backup only
make security       # Security hardening only
make compliance     # Compliance check only
```

## Roles

### common

Base role providing system facts and common utilities. Always executed first.

### system_update

Updates system packages across multiple platforms:

- **macOS**: Homebrew formulae and casks
- **Debian/Ubuntu**: APT packages with security updates
- **RedHat/CentOS**: YUM/DNF packages

**Key variables** (`roles/system_update/defaults/main.yml`):

```yaml
update_homebrew_formulae: true
update_homebrew_casks: true
apt_upgrade_type: dist          # Options: dist, full, safe
```

### backup

Automated backup with retention management:

- Archives specified directories with compression
- Backs up individual files (dotfiles, configs)
- Exports package manifests (Brewfile, dpkg, rpm)
- Creates backup manifests with metadata
- Automatic cleanup based on retention policy

**Key variables** (`roles/backup/defaults/main.yml`):

```yaml
backup_destination: "{{ ansible_env.HOME }}/backups"
backup_retention_days: 30
backup_directories:
  - "{{ ansible_env.HOME }}/Documents"
  - "{{ ansible_env.HOME }}/.ssh"
backup_files:
  - "{{ ansible_env.HOME }}/.zshrc"
  - "{{ ansible_env.HOME }}/.aliases"
  - "{{ ansible_env.HOME }}/.gitconfig"
```

### security

Security hardening following industry best practices:

- **macOS**: Application firewall, stealth mode, FileVault checks
- **Linux**: UFW/firewalld configuration, SSH hardening
- File permission hardening (SSH keys, home directory)
- Security tool installation (lynis, clamav, fail2ban)

**Key variables** (`roles/security/defaults/main.yml`):

```yaml
enable_firewall: true
enable_stealth_mode: true
harden_ssh: true
install_security_tools: true
```

### compliance

Automated compliance auditing and reporting:

- Firewall and security configuration checks
- File system permission audits
- Package and update status
- User account audits
- Optional Lynis security scanning
- Generates detailed compliance reports

**Key variables** (`roles/compliance/defaults/main.yml`):

```yaml
compliance_report_path: "{{ ansible_env.HOME }}/compliance-reports"
run_lynis_audit: false
```

## Playbooks

### playbooks/weekly-os.yml

**Recommended for regular maintenance.** Executes comprehensive maintenance workflow:

1. Pre-compliance check (baseline)
2. System updates
3. Backup (post-update)
4. Security hardening
5. Post-compliance check (validation)
6. Cleanup operations

```bash
ansible-playbook playbooks/weekly-os.yml --ask-become-pass
# or
make weekly-os
```

### Individual Playbooks

Execute specific roles in isolation:

```bash
# Update packages only
ansible-playbook playbooks/update.yml

# Backup only
ansible-playbook playbooks/backup.yml

# Security hardening (requires sudo)
ansible-playbook playbooks/security.yml --ask-become-pass

# Compliance check
ansible-playbook playbooks/compliance.yml
```

## Configuration

### Inventory Management

Edit `inventories/production/hosts.ini`:

```ini
[workstation]
localhost ansible_connection=local

[darwin]
localhost ansible_connection=local

[debian]
ubuntu-machine ansible_host=192.168.1.100 ansible_user=admin

[redhat]
centos-machine ansible_host=192.168.1.101 ansible_user=admin
```

### Variable Precedence

Variables are loaded in order (lowest to highest priority):

1. `roles/*/defaults/main.yml` - Role defaults
2. `group_vars/all.yml` - Global variables
3. `group_vars/{workstation,darwin,linux}.yml` - Group-specific
4. `host_vars/localhost.yml` - Host-specific overrides

### Customization Examples

**Extend backup directories** (`host_vars/localhost.yml`):

```yaml
backup_directories:
  - "{{ ansible_env.HOME }}/Documents"
  - "{{ ansible_env.HOME }}/Projects"
  - "{{ ansible_env.HOME }}/Code"
  - "{{ ansible_env.HOME }}/.config"
```

**Enable Lynis auditing** (`group_vars/workstation.yml`):

```yaml
run_lynis_audit: true
```

**Adjust backup retention** (`host_vars/localhost.yml`):

```yaml
backup_retention_days: 60
```

**Add custom files to backup** (`host_vars/localhost.yml`):

```yaml
backup_files:
  - "{{ ansible_env.HOME }}/.aliases"
  - "{{ ansible_env.HOME }}/.zshrc"
  - "{{ ansible_env.HOME }}/.gitconfig"
  - "{{ ansible_env.HOME }}/.custom_script.sh"
```

## Tags

Use tags to execute specific subsets of tasks:

```bash
# List all available tags
make list-tags

# Update only
ansible-playbook playbooks/full.yml --tags update

# Security hardening only
ansible-playbook playbooks/full.yml --tags security,hardening

# Skip backup
ansible-playbook playbooks/full.yml --skip-tags backup
```

Common tags:

- `always` - Always executed (common role)
- `update` - System updates
- `backup` - Backup operations
- `security` - Security hardening
- `compliance` - Compliance checks
- `audit` - Audit operations
- `maintenance` - Maintenance tasks

## Testing and Validation

### Dry Run (Check Mode)

```bash
# Test without making changes
make dry-run
make dry-run-weekly

# Or directly
ansible-playbook playbooks/full.yml --check --diff
```

### Syntax Validation

```bash
# Check playbook syntax
make check

# Lint playbooks (requires ansible-lint)
make lint
```

### Connection Testing

```bash
# Test connectivity to all hosts
make test-connection
```

## Scheduling

### macOS (launchd)

Create `~/Library/LaunchAgents/com.user.ansible-weekly-maintenance.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.ansible-weekly-maintenance</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/make</string>
        <string>-C</string>
        <string>/Users/lucas/Workspace/personal/ansible-workstation</string>
        <string>weekly-os</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/lucas/logs/ansible-maintenance.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/lucas/logs/ansible-maintenance-error.log</string>
</dict>
</plist>
```

Load: `launchctl load ~/Library/LaunchAgents/com.user.ansible-weekly-maintenance.plist`

### Linux (cron)

```bash
crontab -e

# Add entry (Sundays at 2 AM)
0 2 * * 0 cd /path/to/ansible-workstation && /usr/bin/make weekly-os >> ~/logs/ansible-maintenance.log 2>&1
```

## Security Considerations

- Sensitive variables should use Ansible Vault
- SSH keys and credentials are excluded via `.gitignore`
- Security role requires sudo for system-level changes
- Always review compliance reports after hardening
- Test in development environment first

### Using Ansible Vault

```bash
# Encrypt sensitive variables
ansible-vault encrypt host_vars/secrets.yml

# Run playbook with vault
ansible-playbook playbooks/full.yml --ask-vault-pass

# Edit encrypted file
ansible-vault edit host_vars/secrets.yml
```

## Troubleshooting

### Permission Denied

```bash
# Use --ask-become-pass for sudo operations
ansible-playbook playbooks/security.yml --ask-become-pass
```

### Collection Not Found

```bash
# Install required collections
make install
# or
ansible-galaxy collection install -r requirements.yml
```

### Dry Run First

```bash
# Always test with check mode first
ansible-playbook playbooks/weekly-os.yml --check
```

### Verbose Output

```bash

# Add verbosity for debugging
ansible-playbook playbooks/full.yml -vvv
```

### Check Logs

```bash
# Review Ansible logs
tail -f ansible.log

# Review compliance reports
ls -la ~/compliance-reports/
cat ~/compliance-reports/compliance_*.txt
```

## Development

```bash
# Setup development environment
make dev-setup

# Run all checks
make dev-check

# Test individual roles
ansible-playbook playbooks/full.yml --tags update --check
```

## Requirements

- **Ansible**: >= 2.15
- **Python**: >= 3.8
- **Collections**: community.general >= 8.0.0
- **macOS**: Homebrew (if running on macOS)
- **Sudo**: Required for system-level security hardening
