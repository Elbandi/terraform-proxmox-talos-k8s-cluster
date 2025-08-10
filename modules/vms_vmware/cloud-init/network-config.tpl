instance-id: ${hostname}
local-hostname: ${hostname}
wait-on-network:
  ipv4: true
  ipv6: false
network:
  version: 2
  ethernets:
    eth0:
%{if ipaddress == "dhpc" }
        dhcp4: true
%{ else }
        dhcp4: false
        addresses: [${ipaddress}]
        gateway4: '${gateway}'
%{if dns != null }
        nameservers:
          search: [foo.local, bar.local]
          addresses:
%{ for d in dns }
            - ${d}
%{ endfor }
%{ endif }
%{ endif }
