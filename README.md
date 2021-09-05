# checkmk_agent

An [Ansible](https://www.ansible.com/) [Role](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) to install the agent/client for [CheckMK RAW edition](https://checkmk.com/product/raw-edition).

This role utilizes SSH on Unix-type systems instead of the default port 6556.  This encrypts communications and avoids opening a new port for monitoring and setting up a new service.

## Requirements

None yet defined.

## Role Variables

None yet defined.

## Dependencies

None yet defined.

## Example Playbook

Simple example:

    - hosts: servers
      roles:
         - { role: kso512.checkmk_agent }

## License

[GNU General Public License version 2](https://www.gnu.org/licenses/gpl-2.0.txt)

## Author Information

[@kso512](https://github.com/kso512)
