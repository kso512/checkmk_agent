#!/usr/bin/env bash

# List of supported distros
distros=( debian11 debian12 )
distros+=( fedora40 fedora41 fedora42 )
distros+=( ubuntu2004 ubuntu2204 ubuntu2404 )

# Fail upon any error
set -e

# Loop through the list of distros
for distro in ${distros[@]}; do

  # Run the docker container, which outputs the unique id of the container
  echo ""
  echo "=00= Running container for distro: ${distro}"
  container=$(docker run --detach --privileged \
    --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw --cgroupns=host \
    --volume=$(pwd):/etc/ansible/roles/role_under_test:ro \
    "geerlingguy/docker-${distro}-ansible:latest")

  # Run the ansible playbook and look for no failures
  echo "-01- Testing playbook for no failures in distro: ${distro}"
  ansible_output=$(docker exec --tty "${container}" env TERM=xterm \
    ansible-playbook /etc/ansible/roles/role_under_test/test/playbook.yml)
  echo "${ansible_output}" | \
    grep -o "failed=0"

  # Run the ansible playbook again and look for idempotence
  echo "-02- Testing playbook for no changes (idempotence) in distro: ${distro}"
  ansible_output=$(docker exec --tty "${container}" env TERM=xterm \
    ansible-playbook /etc/ansible/roles/role_under_test/test/playbook.yml)
  echo "${ansible_output}" | \
    grep -o "changed=0"

  # Make sure the agent runs with sudo as the right user
  # NOTE: this test assumes the default values are set for:
  #     checkmk_agent_home
  #     checkmk_agent_user
  echo "-03- Testing CheckMK agent in distro: $distro"
  agent_output=$(docker exec --tty $container env TERM=xterm \
    sudo -u cmkagent sudo /home/cmkagent/check_mk_agent)
  echo "${agent_output}" | \
    grep --max-count 1 "\<\<\<check_mk\>\>\>"

  # Remove the container once the test passes
  echo "-04- Removing container for distro: ${distro}"
  docker rm -f "${container}"

  # End 'for distro' loop
  done

# Finish clean
exit 0
