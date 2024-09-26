# [checkmk_agent](https://galaxy.ansible.com/kso512/checkmk_agent)

[![Ansible role quality](https://img.shields.io/ansible/quality/56196)](https://galaxy.ansible.com/kso512/checkmk_agent) [![Ansible role downloads](https://img.shields.io/ansible/role/d/56196)](https://galaxy.ansible.com/kso512/checkmk_agent) [![GitHub repo size](https://img.shields.io/github/repo-size/kso512/checkmk_agent)](https://github.com/kso512/checkmk_agent)

[![Release](https://github.com/kso512/checkmk_agent/actions/workflows/release.yml/badge.svg)](https://github.com/kso512/checkmk_agent/actions/workflows/release.yml) [![GitHub issues](https://img.shields.io/github/issues-raw/kso512/checkmk_agent)](https://github.com/kso512/checkmk_agent)

[![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/) [![made-with-Markdown](https://img.shields.io/badge/Made%20with-Markdown-1f425f.svg)](http://commonmark.org) [![GitHub](https://img.shields.io/github/license/kso512/checkmk_agent)](https://www.gnu.org/licenses/gpl-2.0.txt)

An [Ansible](https://www.ansible.com/) [Role](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) to install the agent/client for [CheckMK RAW edition](https://checkmk.com/product/raw-edition).

This is a complete rebuild of the [install-check_mk-agent](https://github.com/kso512/install-check_mk-agent) role I created and maintained for years, undertaken due to changes in CI/CD and naming conventions in Ansible Galaxy & CheckMK.

All tasks are tagged with `checkmk-agent`.

The following distributions have been tested automatically:

- [Debian 10 "Buster"](https://www.debian.org/releases/buster/)
- [Debian 11 "Bullseye"](https://www.debian.org/releases/bullseye/)
- [Debian 12 "Bookworm"](https://www.debian.org/releases/bookworm/)
- [Fedora 38](https://docs.fedoraproject.org/en-US/fedora/f38/release-notes/)
- [Fedora 39](https://docs.fedoraproject.org/en-US/fedora/f39/release-notes/)
- [Fedora 40](https://docs.fedoraproject.org/en-US/fedora/f40/release-notes/)
- [Microsoft Windows Server 2019](https://docs.microsoft.com/en-us/windows-server/get-started/whats-new-in-windows-server-2019) / [Microsoft Windows 10](https://www.microsoft.com/en-us/windows/windows-10-specifications)
- [Microsoft Windows Server 2022](https://docs.microsoft.com/en-us/windows-server/get-started/whats-new-in-windows-server-2022) / [Microsoft Windows 11](https://www.microsoft.com/en-us/windows/windows-11-specifications)
- [Ubuntu 20.04 LTS "Focal Fossa"](http://releases.ubuntu.com/focal/)
- [Ubuntu 22.04 LTS "Jammy Jellyfish"](http://releases.ubuntu.com/jammy/)
- [Ubuntu 24.04 LTS "Noble Numbat"](http://releases.ubuntu.com/noble/)

For performance reasons, the following "sections" have been disabled by default in the Windows agent:

- services
- msexch
- dotnet_clrmemory
- wmi_webservices
- wmi_cpuload
- ps
- fileinfo
- logwatch
- openhardwaremonitor

In addition, the execution of plugins have been adjusted:

- Timeout raised from `30` to `120`
- Async enabled
- Cache_age set to `3600` (1 hour)

Create your own "check_mk.user.yml.j2" and override `checkmk_agent_win_config_src` to customize further, or set the `checkmk_agent_win_config_optimize` variable to `false` to disable this optimization.

Similar modifications have been made to the `docker.cfg` default file.  Here, all docker sections have been enabled and can be returned to the default by setting the `checkmk_agent_docker_complete` variable to `false`.

## Recent Version Matrix

| CheckMK Raw Edition Version | Role Version/Tag |
| --------------------------- | ---------------- |
| 2.3.0p17                    | 1.1.5            |
| 2.3.0p16                    | 1.1.4            |
| 2.3.0p15                    | 1.1.3            |
| 2.3.0p14                    | 1.1.2            |
| 2.3.0p13                    | 1.1.1            |

## Requirements

This role requires no other roles.  It is designed to be compatible with CheckMK server in general and [kso512.checkmk_server](https://github.com/kso512/checkmk_server) specifically.

If connecting to a Windows host with [Windows Remote Management (WinRM)](https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html#what-is-winrm), you may need to install the `pywinrm` package on your Ansible system:

    pip install "pywinrm>=0.3.0"

This role utilizes SSH on Unix-type systems instead of the default port 6556.  This encrypts communications and avoids opening a new port for monitoring and setting up a new service.

To create authentication keys for SSH, use the "ssh-keygen" program as shown [here](https://man.openbsd.org/ssh-keygen).

Example to create default keys with no passphrase in the local folder:

    ssh-keygen -C "cmkagent@$HOSTNAME" -f ./id_rsa -N "" -v

This will create two files:  `id_rsa` & `id_rsa.pub`

**`id_rsa`** = Private key which should be kept safe.  This file needs to be placed in the `~/.ssh` folder of the live CheckMK Agent user.  Example using the "kso512.checkmk_server" default user & site:

    cp ./id_rsa /opt/omd/sites/test/.ssh

**`id_rsa.pub`** = Public key which may be shared with other trusted hosts.  This file needs to be added to your own local "authorized_keys.j2" file.  Assuming a default role structure:

    echo '# {{ ansible_managed }}' > /etc/ansible/local/authorized_keys.j2
    cat ./id_rsa.pub >> /etc/ansible/local/authorized_keys.j2

Then declare `local/authorized_keys.j2` as `checkmk_agent_authkey_src` in your own variables; an example is shown below.

Finally, configure CheckMK itself to leverage these files instead of trying to connect to TCP port 6556:

- Log in to CheckMK
- Setup > Search > "individual" > Individual program call instead of agent access
- Create rule in folder: Main directory
  - Description: `Use SSH and cmkagent account with SSH keys`
  - Command line to execute: `ssh -i ~/.ssh/id_rsa -l cmkagent <IP> sudo /home/cmkagent/check_mk_agent`
  - Explicit hosts: (select a test host, then once it's working, set up [host tags or labels](https://docs.checkmk.com/latest/en/labels.html))
  - Save
- 1 change > Activate on selected sites

## Role Variables

Some of these may be seem redundant but are specified so future users can override them with local variables as needed.

### Table of Variables (with Defaults)

| Variable | Description | Default |
| -------- | ----------- | ------- |
| checkmk_agent_authkey_dest | Full pathname of "authorized_keys" file | `"{{ checkmk_agent_ssh_path }}/authorized_keys"` |
| checkmk_agent_authkey_group | Name of the group that should own the "authorized_keys" file | `"{{ checkmk_agent_ssh_group }}"` |
| checkmk_agent_authkey_mode | File mode settings of the "authorized_keys" file | `"0600"` |
| checkmk_agent_authkey_src | Filename of the "authorized_keys" template | `authorized_keys.j2` |
| checkmk_agent_authkey_user | Name of the user that should own the "authorized_keys" file | `"{{ checkmk_agent_ssh_user }}"` |
| checkmk_agent_cache_group | Name of the group that should own the "cache" folder and files | `"{{ checkmk_agent_cache_user }}"` |
| checkmk_agent_cache_mode | File mode settings of the "cache" folder and files | `"{{ checkmk_agent_mode }}"` |
| checkmk_agent_cache_path | Full pathname of "cache" folder | `"{{ checkmk_agent_home }}/cache"` |
| checkmk_agent_cache_user | Name of the user that should own the "cache" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_comment | Full name of the CheckMK Agent user | `CheckMK Agent` |
| checkmk_agent_count_users_crit | Logged in users, critical threshold | `15` |
| checkmk_agent_count_users_warn | Logged in users, warning threshold | `10` |
| checkmk_agent_count_zombie_procs_crit | Zombie processes, critical threshold | `10` |
| checkmk_agent_count_zombie_procs_warn | Zombie processes, warning threshold | `5` |
| checkmk_agent_dest | Full pathname of the CheckMK Agent executable file | `"{{ checkmk_agent_home }}/check_mk_agent"` |
| checkmk_agent_docker_complete | Include all docker modules | `true` |
| checkmk_agent_docker_dest | Full pathname of the Docker configuration file | `"{{ checkmk_agent_home }}/docker.cfg"` |
| checkmk_agent_docker_group | Name of the group that should own the Docker configuration file | `"{{ checkmk_agent_group }}"` |
| checkmk_agent_docker_mode | File mode settings of the Docker configuration file | `"0644"` |
| checkmk_agent_docker_src | Filename of the Docker configuration file template | `docker.cfg.j2` |
| checkmk_agent_docker_user | Filename of the Docker configuration file template | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_group | Name of the group that should own the CheckMK Agent executable file | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_home | Full pathname of the CheckMK Agent user home folder | `/home/{{ checkmk_agent_user }}` |
| checkmk_agent_local_checks | List of checks to copy to the "local" folder | `count_users` `count_zombie_procs` |
| checkmk_agent_local_checks_async | List of checks to copy to the "local" async folders | (See [NOTE A](https://github.com/kso512/checkmk_agent#note-a) below) |
| checkmk_agent_local_group | Name of the group that should own the "local" folder and files | `"{{ checkmk_agent_local_user }}"` |
| checkmk_agent_local_mode | File mode settings of the "local" folder and files | `"{{ checkmk_agent_mode }}"` |
| checkmk_agent_local_path | Full pathname of "local" folder | `"{{ checkmk_agent_home }}/local"` |
| checkmk_agent_local_purge | Delete "local" folder before sync | `false` |
| checkmk_agent_local_user | Name of the user that should own the "local" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_mode | File mode settings of the CheckMK Agent executable file | `"0755"` |
| checkmk_agent_plugin_checks | List of checks to copy to the "plugin" folder | `hpsa` `lvm` `mk_inventory.linux` `mk_iptables` `mk_nfsiostat` `mk_sshd_config` `netstat.linux` `nfsexports` `smart` |
| checkmk_agent_plugin_checks_async | List of checks to copy to the "plugin" async folders | (See [NOTE A](https://github.com/kso512/checkmk_agent#note-a) below) |
| checkmk_agent_plugin_group | Name of the group that should own the "plugin" folder and files | `"{{ checkmk_agent_plugin_user }}"` |
| checkmk_agent_plugin_mode | File mode settings of the "plugin" folder and files | `"{{ checkmk_agent_mode }}"` |
| checkmk_agent_plugin_path | Full pathname of "plugin" folder | `"{{ checkmk_agent_home }}/plugins"` |
| checkmk_agent_plugin_purge | Delete "plugin" folder before sync | `false` |
| checkmk_agent_plugin_user | Name of the user that should own the "plugin" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_prereqs | List of packages needed for a successful installation | `python3-docker` `sudo` |
| checkmk_agent_prereqs_yum | List of packages needed for a successful installation with systems using YUM as their package manager | `sudo` |
| checkmk_agent_src | Filename of the CheckMK Agent executable file template | `check_mk_agent.linux.j2` |
| checkmk_agent_ssh_group | Name of the group that should own the ".ssh" folder and files | `"{{ checkmk_agent_group }}"` |
| checkmk_agent_ssh_mode | File mode settings of the ".ssh" folder and files | `"0700"` |
| checkmk_agent_ssh_path | Full pathname of ".ssh" folder | `"{{ checkmk_agent_home }}/.ssh"` |
| checkmk_agent_ssh_user | Name of the user that should own the ".ssh" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_spool_group | Name of the group that should own the "spool" folder and files | `"{{ checkmk_agent_spool_user }}"` |
| checkmk_agent_spool_mode | File mode settings of the "spool" folder and files | `"{{ checkmk_agent_mode }}"` |
| checkmk_agent_spool_path | Full pathname of "spool" folder | `"{{ checkmk_agent_home }}/spool"` |
| checkmk_agent_spool_user | Name of the user that should own the "spool" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_sudo_dest | Full pathname of "sudoers.d" file, used to grant the CheckMK Agent user sudo access to the CheckMK Agent executable file | `/etc/sudoers.d/99_cmkagent` |
| checkmk_agent_sudo_group | Name of the group that should own the "sudoers.d" file | `"{{ checkmk_agent_sudo_owner }}"` |
| checkmk_agent_sudo_mode | File mode settings of the "sudoers.d" file | `"0440"` |
| checkmk_agent_sudo_owner | Name of the user that should own the "sudoers.d" file | `root` |
| checkmk_agent_sudo_src | Filename of the "sudoers.d" file template | `99_cmkagent.j2` |
| checkmk_agent_sudo_validate | Command used to validate the "sudoers.d" file; %s will be filled in with `checkmk_agent_sudo_dest` | `'visudo -cf %s'` |
| checkmk_agent_user | Login name of the CheckMK Agent user | `cmkagent` |
| checkmk_agent_version | Version of CheckMK Agent to install | `2.3.0p17` |
| checkmk_agent_win_config_dest | Full pathname of configuration file | `"{{ checkmk_agent_win_data_folder }}check_mk.user.yml"` |
| checkmk_agent_win_config_optimize | Optimize the Windows agent by dropping some of the slower checks | `true` |
| checkmk_agent_win_config_src | Filename of the configuration file template | `check_mk.user.yml.j2` |
| checkmk_agent_win_data_folder | Full pathname of the CheckMK Agent data folder | `C:\\ProgramData\\checkmk\\agent\\` |
| checkmk_agent_win_install_dest | Full pathname of the CheckMK Agent installation file | `c:\\Users\\{{ ansible_user }}\\Downloads\\{{ checkmk_agent_win_install_src }}` |
| checkmk_agent_win_install_src | Short file name of the CheckMK Agent installation file | `check_mk_agent.msi` |
| checkmk_agent_win_plugins | List of Windows plugins to copy to the "plugin" folder" | `mk_inventory.vbs` `windows_updates.vbs` |
| checkmk_agent_win_productid | Version-specific "Product ID" to install | `"{B6212139-D124-4782-8F81-05D08203092D}"` |

### NOTE A

`checkmk_agent_local_checks_async` and `checkmk_agent_plugin_checks_async` - List of checks to copy to the "plugin" async folders.  Per the [documentation](https://docs.checkmk.com/latest/en/localchecks.html#cache):

> The output of local checks, like that of agent plug-ins, can be cached. This can be necessary if a script has a longer processing time. Such a script is then executed asynchronously and only in a defined time interval and the last output is cached. If the agent is queried again before the time expires, it uses this cache for the local check and returns it in the agent output.

The format of these lists is as follows, with `checkmk_agent_plugin_checks_async` shown:

    300:
      - apache_status.py
    600:
      - ""
    900:
      - ""
    1800:
      - ""
    86400:
      - mk_apt
      - mk_docker.py

This runs the `apache_status.py` plugin only once per five minutes, and the `mk_apt` and `mk_docker.py` plugins only once per day, instead of every check. This shaves seconds off every remaining check of the day which uses the cached value.

## Dependencies

None yet defined.

## Example Playbook and Invocation

Example that uses a local `authorized_keys` file:

    - hosts: all
      roles:
         - { role: kso512.checkmk_agent, checkmk_agent_authkey_src="local/authorized_keys.j2" }

Example that purges the `plugin` folder before re-creating it:

    $ ansible-playbook site.yml -t checkmk-agent -e "checkmk_agent_plugin_purge=true"
    
    ...

    TASK [kso512.checkmk_agent : Delete directory - plugins | FILE] ***********
    changed: [instance]
    
    TASK [kso512.checkmk_agent : Create directory - plugins | FILE] ***********
    changed: [instance]

## License

[GNU General Public License version 2](https://www.gnu.org/licenses/gpl-2.0.txt)

## Contributing

If you have any suggestions or ideas, please feel free to open an issue, or fork the repository and submit an merge request.

## Author Information

- [@kso512](https://github.com/kso512)
- [@iamdevnull](https://github.com/iamdevnull)
