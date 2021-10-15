#!/bin/bash

doctl >/dev/null 2>/dev/null

if [ "$?" != 0 ]; 
    then echo "Error!" 1>&2
    echo please install doctl with config.sh
    exit 127
fi 

# Copy init file
cp copy.init.yml init.yml

echo -n 'Enter username of droplet:' && read -r User_Name

# replace username
sed -i -e "s/username/$User_Name/" init.yml

# add pub key
key_pub=$(cat ~/.ssh/id_rsa.pub)
sed -i -e "s|pubkey|$key_pub|" init.yml

echo -n 'Enter the Name of the server:' && read -r Server_Name
echo -n 'Enter the Tag for the server:' && read -r Server_Tag

ssh_key=$(ssh-keygen -E md5 -lf ~/.ssh/id_rsa.pub | cut -b 10-56)

PS3='Select Distribution: '
distro=("ubuntu-21-04-x64" "ubuntu-20-04-x64" "centos-7-x64" "centos-8-x64")
select opt1 in "${distro[@]}"

do
    case $opt1 in
        "ubuntu-21-04-x64")
            Server_distro="ubuntu-21-04-x64"
            break
            ;;
        "ubuntu-20-04-x64")
            Server_distro="ubuntu-20-04-x64"
            break
            ;;
        "centos-7-x64")
            Server_distro="ubuntu-20-04-x64"
            break
            ;;
        "centos-8-x64")
            Server_distro="centos-8-x64"
            break
            ;;
        *) echo "invalid option $REPLY";; 
    esac
done


PS3='Select the region: '
region=("Bengalore 1" "Singapore 1" "San Francisco 3" "San Francisco 2" "San Francisco 1" "New York 1" "New York 2" )
select opt2 in "${region[@]}"

do
    case $opt2 in
        "Bengalore 1")
            Server_region="blr1"
            break
            ;;
        "Singapore 1")
            Server_region="sgp1"
            break
            ;;
        "San Francisco 3")
            Server_region="sfo3"
            break
            ;;
        "San Francisco 2")
            Server_region="sfo2"
            break
            ;;
        "New York 1")
            Server_region="nyc1"
            break
            ;;
        "New York 2")
            Server_region="nyc2"
            break
            ;;
        *) echo "invalid option $REPLY";; 
    esac
done

PS3='Select the Size of VPS: '
Size=("s-1vcpu-1gb" "s-1vcpu-2gb" "s-2vcpu-2gb" )
select opt3 in "${Size[@]}"

do
    case $opt3 in
        "s-1vcpu-1gb")
            Server_size="s-1vcpu-1gb"
            break
            ;;
        "s-1vcpu-2gb")
            Server_size="s-1vcpu-2gb"
            break
            ;;
        "s-2vcpu-2gb")
            Server_size="s-2vcpu-2gb"
            break
            ;;
        *) echo "invalid option $REPLY";; 
    esac
done

deploy() {
    doctl compute droplet create $Server_Name --image $Server_distro --region $Server_region --size $Server_size --ssh-keys $ssh_key --user-data-file ./init.yml  --tag-name $Server_Tag --wait -v >/dev/null 2>/dev/null
}

list() {
    doctl compute droplet list --format ID,Name,Tags,"Public IPv4",Region
}

echo Name of the Server is $Server_Name
sleep 1s

echo Server Tag is $Server_Tag
sleep 1s

echo selected distro $Server_distro
sleep 1s

echo Selected Region $Server_region
sleep 1s

echo size is $Server_size
sleep 1s

echo ssh key $ssh_key
sleep 1s

echo "Creating droplet on Digital Ocean" 
deploy 

# remove init file
echo removing init file
rm init.yml

sleep 1s
echo list of droplets
list
