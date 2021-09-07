# checkmk_agent

An [Ansible](https://www.ansible.com/) [Role](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) to install the agent/client for [CheckMK RAW edition](https://checkmk.com/product/raw-edition).

This role utilizes SSH on Unix-type systems instead of the default port 6556.  This encrypts communications and avoids opening a new port for monitoring and setting up a new service.

## Requirements

This role requires no other roles.  It is designed to be compatible with CheckMK server in general and [kso512.checkmk_server](https://github.com/kso512/checkmk_server) specifically.

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
| checkmk_agent_authkey_src | Filename of the "authorized_keys" template | `"authorized_keys.j2"` |
| checkmk_agent_authkey_user | Name of the user that should own the "authorized_keys" file | `"{{ checkmk_agent_ssh_user }}"` |
| checkmk_agent_cache_group | Name of the group that should own the "cache" folder and files | `"{{ checkmk_agent_cache_user }}"` |
| checkmk_agent_cache_mode | File mode settings of the "cache" folder and files | `"{{ checkmk_agent_mode }}"` |
| checkmk_agent_cache_path | Full pathname of "cache" folder | `"{{ checkmk_agent_home }}/cache"` |
| checkmk_agent_cache_user | Name of the user that should own the "cache" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_comment | Full name of the CheckMK Agent user | `"CheckMK Agent"` |
| checkmk_agent_count_users_warn | Logged in users, warning threshold | `"10"` |
| checkmk_agent_count_users_crit | Logged in users, critical threshold | `"15"` |
| checkmk_agent_count_zombie_procs_warn | Zombie processes, warning threshold | `"5"` |
| checkmk_agent_count_zombie_procs_crit | Zombie processes, critical threshold | `"10"` |
| checkmk_agent_dest | Full pathname of the CheckMK Agent executable file | `"{{ checkmk_agent_home }}/check_mk_agent"` |
| checkmk_agent_group | Name of the group that should own the CheckMK Agent executable file | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_home | Full pathname of the CheckMK Agent user home folder | `"/home/{{ checkmk_agent_user }}"` |
| checkmk_agent_local_checks | List of checks to copy to the "local" folder | `"count_users"` `"count_zombie_procs"` |
| checkmk_agent_local_group | Name of the group that should own the "local" folder and files | `"{{ checkmk_agent_local_user }}"` |
| checkmk_agent_local_mode | File mode settings of the "local" folder and files | `"{{ checkmk_agent_mode }}"` |
| checkmk_agent_local_path | Full pathname of "local" folder | `"{{ checkmk_agent_home }}/local"` |
| checkmk_agent_local_user | Name of the user that should own the "local" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_mode | File mode settings of the CheckMK Agent executable file | `"0755"` |
| checkmk_agent_plugin_checks | List of checks to copy to the "plugin" folder | `"lvm"` `"mk_inventory.linux"` `"mk_iptables"` `"mk_nfsiostat"` `"mk_sshd_config"` `"netstat.linux"` `"nfsexports"` `"smart"` |
| checkmk_agent_plugin_group | Name of the group that should own the "plugin" folder and files | `"{{ checkmk_agent_plugin_user }}"` |
| checkmk_agent_plugin_mode | File mode settings of the "plugin" folder and files | `"{{ checkmk_agent_mode }}"` |
| checkmk_agent_plugin_path | Full pathname of "plugin" folder | `"{{ checkmk_agent_home }}/plugins"` |
| checkmk_agent_plugin_user | Name of the user that should own the "plugin" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_prereqs | List of packages needed for a successful installation | `"sudo"` |
| checkmk_agent_src | Filename of the CheckMK Agent executable file template | `"check_mk_agent.linux.j2"` |
| checkmk_agent_ssh_group | Name of the group that should own the ".ssh" folder and files | `"{{ checkmk_agent_group }}"` |
| checkmk_agent_ssh_mode | File mode settings of the ".ssh" folder and files | `"0700"` |
| checkmk_agent_ssh_path | Full pathname of ".ssh" folder | `"{{ checkmk_agent_home }}/.ssh"` |
| checkmk_agent_ssh_user | Name of the user that should own the ".ssh" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_spool_group | Name of the group that should own the "spool" folder and files | `"{{ checkmk_agent_spool_user }}"` |
| checkmk_agent_spool_mode | File mode settings of the "spool" folder and files | `"{{ checkmk_agent_mode }}"` |
| checkmk_agent_spool_path | Full pathname of "spool" folder | `"{{ checkmk_agent_home }}/spool"` |
| checkmk_agent_spool_user | Name of the user that should own the "spool" folder and files | `"{{ checkmk_agent_user }}"` |
| checkmk_agent_sudo_dest | Full pathname of "sudoers.d" file, used to grant the CheckMK Agent user sudo access to the CheckMK Agent executable file | `"/etc/sudoers.d/99_cmkagent"` |
| checkmk_agent_sudo_group | Name of the group that should own the "sudoers.d" file | `"{{ checkmk_agent_sudo_owner }}"` |
| checkmk_agent_sudo_mode | File mode settings of the "sudoers.d" file | `"0440"` |
| checkmk_agent_sudo_owner | Name of the user that should own the "sudoers.d" file | `"root"` |
| checkmk_agent_sudo_src | Filename of the "sudoers.d" file template | `"99_cmkagent.j2"` |
| checkmk_agent_sudo_validate | Command used to validate the "sudoers.d" file; %s will be filled in with `checkmk_agent_sudo_dest` | `'visudo -cf %s'` |
| checkmk_agent_user | Login name of the CheckMK Agent user | `"cmkagent"` |

## Dependencies

None yet defined.

## Example Playbook

Example that uses a local `authorized_keys` file:

    - hosts: servers
      roles:
         - { role: kso512.checkmk_agent, checkmk_agent_authkey_src="local/authorized_keys.j2" }

## License

[GNU General Public License version 2](https://www.gnu.org/licenses/gpl-2.0.txt)

## Author Information

[@kso512](https://github.com/kso512)
