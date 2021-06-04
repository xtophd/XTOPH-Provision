# XTOPH-Provision
Playbooks that incorporate the xtoph_deploy ansible roles to provision systems.

This serves as a simple example of how to utilize xtoph_deploy and as a functional set of tools to provision machines (baremetal, ovirt-vms and libvirt-vms).

By design, the shell wrapper script xtoph_deploy.sh restricts deployments to speicifed systems only.  To override this behaviour and rely on ansible's normal inventory model you pass 'all' as the limiting parameter.

Better documentation to follow soon.
