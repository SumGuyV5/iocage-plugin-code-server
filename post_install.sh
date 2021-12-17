#!/bin/sh -x
IP_ADDRESS=$(ifconfig | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}')

fetch https://github.com/rob4226/code-server-freebsd-port/releases/download/v3.10.2/code-server-3.10.2_amd64.txz

pkg install -y code-server-3.10.2_amd64.txz

sysrc code_server_enable=YES

#start the server to build the config
service code-server start

CONFIG=/var/code-server/nobody/config.yaml

#we need to wait for the config to be built befor we continuing on
while [ ! -f $CONFIG ]
do
    sleep 15
done

sed -i' ' -e s"/127.0.0.1/${IP_ADDRESS}/g" $CONFIG

PASSWORD=$(cat $CONFIG| grep '^password' | awk '{ print $2}')

#restart the server because we have chanage the ip address
service code-server restart

echo -e "code-server is now installed.\n" > /root/PLUGIN_INFO
echo -e "\nPlease open your web browser and go to http://${IP_ADDRESS}:8080 and enter the password ${PASSWORD} to access code-server.\n" >> /root/PLUGIN_INFO