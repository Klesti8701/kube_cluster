#/bin/bash 


for i in 1 2 3 ; do 
	ssh -v root@node-$i "printf '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 \n10.10.10.101   master \n10.10.10.110   node-1 \n10.10.10.111   node-2 \n10.10.10.112   node-3' > /etc/hosts"
	ssh -v root@node-$i "hostnamectl set-hostname node-$i"
	ssh -v root@node-$i "yum update -y && yum upgrade -y"
done
