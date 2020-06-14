#!/bin/bash

fail="\033[1;31m"
success="\033[1;32m"
reset="\033[0m"

gateway=`ip -o -4 route show to default | awk '{print $3}'`
interface=`ip -o -4 route show to default | awk '{print $5}'`
dns=`nmcli device show $interface | grep IP4.DNS | awk '{print $2}'`
successMessage() {
	printf "$success$1$reset\n"
}
errorMessage() {
	printf "$fail$1$reset\n"
}
checkStatus() {
	echo "Pinging gateway ($gateway) [ping -4 -c 1 $gateway > /dev/null]"
	ping -4 -c 1 $gateway > /dev/null
	if [ $? -eq 0 ]; then
		successMessage "Gateway ping successful"
	else
		errorMessage "Gateway ping not successful"
		return 1;
	fi
	echo "Pinging trusted IP (1.1.1.1) [ping -4 -c 1 1.1.1.1 > /dev/null]"
	ping -4 -c 1 1.1.1.1 > /dev/null
	if [ $? -eq 0 ]; then
		successMessage "Connection to external IP successful"
	else
		errorMessage "Could not connect to external IP"
		return 2;
	fi
	echo "Attempting to resolve trusted domain name (google.com) [nslookup google.com > /dev/null]";
	nslookup google.com > /dev/null
	if [ $? -eq 0 ]; then
		successMessage "Domain name server successful"
	else
		errorMessage "Could not connect to domain name server"
		return 3;
	fi
	return 0;
}
checkStatus
status=$?
if [ $status -eq 0 ]; then
	successMessage "No errors were detected."
else
	if [ $status -eq 1 ]; then
		echo "Attempting to fix internal network"
		echo "Restarting NetworkManager [systemctl restart NetworkManager]"
		systemctl restart NetworkManager
		echo "Unblocking all interfaces [rfkill unblock all]"
		rfkill unblock all
		echo "Using ifupdown [sudo ifconfig down $interface; sudo ifup $interface]"
		sudo ifconfig down $interface;
		sudo ifup $interface;
		echo "Connecting and managing interface $interface [nmcli device connect $interface; nmcli dev set $interface managed yes"
		nmcli device connect $interface
		nmcli device set $interface managed yes
		echo "Checking if the issue is resolved..."
		checkStatus > /dev/null
		status=$?
		if [ $status -eq 1 ]; then
			errorMessage "Issue unresolved, attempting more fixes (possibly dangerous!)"
			echo "Uninstalling network-manager-config-connectivity-ubuntu [sudo apt remove network-manager-config-connectivity-ubuntu]"
			sudo apt remove network-manager-config-connectivity-ubuntu;
			echo "Adding device configuration file (if it doesn't already exist) [sudo touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf]"
			sudo touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
			
			checkStatus > /dev/null
			status=$?
			if [ $? -eq 1 ]; then
				errorMessage "Still not fixed, listing debug information below and quitting [nmcli device show $interface]"
				nmcli device show $interface
				return 1;
			fi
		fi
		successMessage "Fixed internal network connection"
	fi
	if [ $status -eq 2 ]; then
		errorMessage "Could not connect outside of the local network. This is not a computer software/hardware issue. You may need to restart your router."
		exit
	fi
	if [ $status -eq 3 ]; then
		echo "Attempting to fix domain name server"
		echo "Pinging primary domain name server ($dns) [ping -4 -c 1 $dns]"
		ping -4 -c 1 $dns > /dev/null
		if [ $? -eq 0 ]; then
			errorMessage "Could not ping domain name server. This could be caused by the server blocking ping requests or an invalid domain name server."
		else
			errorMessage "Could ping domain name server, but it either does not have port 53 open or does not resolve domain names correctly."
		fi;
		echo "Attempting to use a trusted domain name server (1.1.1.1) by temporarily overriding /etc/resolv.conf [echo "nameserver 1.1.1.1" >| /tmp/nsfix; sudo mv /etc/resolv.conf /etc/resolv.conf.old; sudo mv tmp /etc/resolv.conf]"
		echo "nameserver 1.1.1.1" >| /tmp/nsfix;
		sudo mv /etc/resolv.conf /etc/resolv.conf.old
		sudo mv /tmp/nsfix /etc/resolv.conf
		echo "Checking if name server was fixed using trusted domain (google.com) [nslookup google.com]"
		nslookup google.com > /dev/null
		if [ $? -eq 0 ]; then
			successMessage "Successfully fixed nameserver for this current session. You may want to look into changing the nameserver permanently."
		else
			errorMessage "Could not use 1.1.1.1 as a nameserver. Check the firewall rules to see if port 53 is blocked or if your nameservers are blocked. Aborting."
			return 3;
		fi
	fi
	echo "All fixes should be applied. Verifying connectivity."
	checkStatus
	if [ $? -eq 0 ]; then
		successMessage "All connection isues were fixed! Exiting."
		return 0;
	else
		errorMessage "The connection has not been fixed. Try running this script again."
	fi
fi
