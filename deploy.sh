#!/bin/bash

doctl >/dev/null 2>/dev/null

if [ "$?" != 0 ]; 
then 
    echo "Error!" 1>&2
    echo "doctl is not installed."
    echo -n "Install doctl?[Y/N]" && read -r reply 
    if [[ $reply =~ ^(Y|y)$ ]];
    then
        echo "Installing doctl"
        # Get doctl latest version
        latestver=$(curl --silent "https://api.github.com/repos/digitalocean/doctl/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//g')
        
        #get system arch
        sysarch=$(dpkg --print-architecture)

        #latest version uri
        downURL="https://github.com/digitalocean/doctl/releases/download/v$latestver/doctl-$latestver-linux-$sysarch.tar.gz"

        # Download the lastet release
        wget $downURL 

        # Extract archive
        echo Extracting the archive
        tar -xvf doctl-$latestver-linux-$sysarch.tar.gz

        # Move
        echo Installing
        sudo mv doctl /usr/local/bin
        if test -f "/usr/local/bin/doctl"; then
            echo done
        fi

        #cleanup
        echo cleaning up
        rm -rf doctl-$latestver-*
        echo done

        echo "Setup doctl auth. Please keep the auth token ready"
        echo "Start Authentication?[Y/N]"
        doctl auth init --context default
        
    else
        echo "Error!" 1>&2
        echo please install doctl
        exit 127
    fi
fi 

ssh_key=$(ssh-keygen -E md5 -lf ~/.ssh/id_rsa.pub | cut -b 10-56)

# get keys from doctl
doctlkeys=$(doctl compute ssh-key list | awk '{print $3}' | sed '/FingerPrint/d')

#check key is present
if [[ "$doctlkeys" != *"$ssh_key"* ]]; then
    echo "SSH key not added"
    sleep 1
    echo "Adding pub key to DigitalOcean"
    sysHost=$(hostname | sed 's/\.//g')
    doctl compute ssh-key import $sysHost --public-key-file ~/.ssh/id_rsa.pub
fi

echo -n 'Enter username of droplet:' && read -r User_Name

# Copy init file
cp copy.init.yml init.yml

# replace username
sed -i -e "s/username/$User_Name/" init.yml

# add pub key
key_pub=$(cat ~/.ssh/id_rsa.pub)
sed -i -e "s|pubkey|$key_pub|" init.yml

echo -n 'Enter the Name of the server:' && read -r Server_Name
echo -n 'Enter the Tag for the server:' && read -r Server_Tag

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

echo Name of the Server is $Server_Name && sleep 1s
echo Server Tag is $Server_Tag && sleep 1s
echo selected distro $Server_distro && sleep 1s
echo Selected Region $Server_region && sleep 1s
echo size is $Server_size && sleep 1s
echo ssh key $ssh_key && sleep 1s

echo "Creating droplet on Digital Ocean" 
deploy 

# remove init file
echo removing init file
rm init.yml

sleep 1s
echo list of droplets
list
