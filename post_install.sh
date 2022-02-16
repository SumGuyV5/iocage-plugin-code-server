#!/bin/sh -x
IP_ADDRESS=$(ifconfig | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}')
USER=code
USER_PASS=$(openssl rand -base64 20 | md5 | head -c6)

fetch https://github.com/rob4226/code-server-freebsd-port/releases/download/v3.10.2/code-server-3.10.2_amd64.txz

pkg install -y code-server-3.10.2_amd64.txz
rm code-server-3.10.2_amd64.txz

mkdir -p /usr/home/${USER}/.config
ln -s /usr/home /home

pw user add ${USER} -c ${USER} -s /bin/sh
echo $USER_PASS | pw usermod -n ${USER} -h 0
chown -R ${USER}:${USER} /home/${USER}

CONFIG=/home/${USER}/.config
CONFIG_FILE=${CONFIG}/config.yaml

sysrc code_server_enable=YES
sysrc code_server_user=${USER}
sysrc code_server_group=${USER}
sysrc code_server_config_file=${CONFIG_FILE}
sysrc code_server_user_data_dir=${CONFIG}/user-data
sysrc code_server_extensions_dir=${CONFIG}/extensions

# start the server to build the config
service code-server start

# we need to wait for the config to be built befor we continuing on
while [ ! -f $CONFIG_FILE ]
do
	sleep 15
done

sed -i' ' -e s"/127.0.0.1/${IP_ADDRESS}/g" $CONFIG_FILE

PASSWORD=$(cat $CONFIG_FILE | grep '^password' | awk '{ print $2}')

# Replaces "cert: false" with "cert: true" in the code-server config.
sed -i' ' 's/cert: false/cert: true/' $CONFIG_FILE
# Replaces "bind-addr: 127.0.0.1:8080" with "bind-addr: 0.0.0.0:443" in the code-server config.
sed -i' ' 's/bind-addr: 127.0.0.1:8080/bind-addr: 0.0.0.0:443/' $CONFIG_FILE

# restart the server because we have chanage the ip address
service code-server restart

echo -e "code-server is now installed.\n" > /root/PLUGIN_INFO
echo -e "\nPlease open your web browser and go to https://${IP_ADDRESS}:8080 and enter the password ${PASSWORD} to access code-server.\n" >> /root/PLUGIN_INFO
