#!/usr/bin/env bash

function install_snap() {

cat << EOF

"Right, so first I will need to isntall snap for you"

EOF
	sudo apt update
	sudo apt install snapd
}

function install_homebrew() {

cat << EOF

Right, so first I will need to isntall homebrew for you

EOF
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


	if [ $? -ne 0 ]; then
		echo "hmmmm...That did not work! I am unable to install homebrew!"
		exit 1
	fi
}



cat << EOF
Hey there!!

Imma just be over here setting up nucamp VMs on your machine :) I will be sure
to let your know all the things that I am doing

EOF

sleep 10

OS=$(uname -s)

## Check if snap or homebrew is installed
if [ "$OS" == "Linux" ]; then
    DISTRO=$(lsb_release -is)
    if [[ $DISTRO == "Ubuntu" || $DISTRO == "Debian" || $DISTRO == "Linux Mint" || $DISTRO == "Pop!_OS" ]]; then
        which snap > /dev/null
        if [ $? -ne 0 ]; then
            echo "Snap is not installed! But not to fear, I know a trick or two..."
            install_snap
        fi
    fi
elif [ "$OS" == "Darwin" ]; then
    which brew > /dev/null
    if [ $? -ne 0 ]; then
        echo "Homebrew is not installed! But not to fear, I know a trick or two..."
        install_homebrew
    fi
fi

## Check if multipass is installed
if [ "$OS" == "Linux" ]; then
    DISTRO=$(lsb_release -is)
    if [[ $DISTRO == "Ubuntu" || $DISTRO == "Debian" || $DISTRO == "Linux Mint" || $DISTRO == "Pop!_OS" ]]; then
        which multipass > /dev/null
        if [ $? -ne 0 ]; then
            echo "multipass is not installed! But not to fear, I know a trick or two..."
            sudo snap install multipass
        fi
    fi
elif [ "$OS" == "Darwin" ]; then
    which multipass > /dev/null
    if [ $? -ne 0 ]; then
        echo "multipass is not installed! But not to fear, I know a trick or two..."
        brew install multipass
    fi
fi

sleep 10

cat << EOF

Next, I will check you already have multipass machines running on your
computer. This will help avoid potential naming conflicts.

EOF

sleep 10

# Get running instances
current_count=$(multipass list --format json | jq -r '.list.[].name' | wc -l)
current_names=$(multipass list --format json | jq -r '.list.[].name')

if [ $current_count -gt 0 ]; then
	echo -e "Hey look, I found some!\n"
fi

declare -a new_machines=("nucamp-ubuntu-machine-1" "nucamp-ubuntu-machine-2")

cat << EOF

Ok, now that I know that you have machines already running, I will check for
naming conflicts. Our machines will be called:

- nucamp-ubuntu-machine-1
- nucamp-ubuntu-machine-2

Just FYI, if I find naming conflicts I will exit out...

EOF

sleep 10

#check for existing machine and exit on name conflicts
for name in "${new_machines[@]}";
do
	for x in $current_names;
	do
		if [ "$name" == "$x" ]; then
			echo -e "\n[!] Found name conflict. Machine already exists with name $name"
cat << EOF

You may be wondering what to do now that I have found conflicts. Well, if you
still need the machine with the conflicting name ($name), you can rename the
machine with the following command:


multipass clone $name --name <your new name here>


Then, you can delete and purge the old machine with:


multipass delete $name && multipass purge

EOF
			exit 1
		fi
	done
done

cat << EOF

Ok, so good news; I did not find any name conflicts we we are good
to go ahead and create the machines without an issue

EOF

#Create new instance with features
for name in "${new_machines[@]}";
do
	multipass launch --cpus 2 --memory 2G --name "$name" 24.04 --disk 20GB < /dev/null

	if [ $? -ne 0 ]; then
		echo "ruh roh! Something is all screwy and I could not create the machines!"
		exit 1
	fi
done

cat << EOF

Ok! That worked! Now I will do some basic health checks and configuration to be
sure everything will work as expected.

EOF

# Network health checks

cat << EOF

First up, I need to make sure that VM has access to the internet, this is
required in order to update the vm and install software packages. The command
I will run is:

multipass exec <vm name> ping -c 3 1.1.1.1

This command will will 'ping' cloudflares dns servers 3 times. This
way we know that we can reach the WAN (wide area network)

EOF

for name in "${new_machines[@]}";
do
	multipass exec "$name" -- ping -c 3 1.1.1.1 < /dev/null

	if [ $? -ne 0 ]; then
		echo "ruh roh! Something is all screwy and I could not create the machines!"
		exit 1
	fi
done

cat << EOF

Looks like the network is setup correctly!

Now I will setup the hacking machine with all the tools that you will need.

You are about to see a lot of stuff wiz by!!

EOF

sleep 10

curl -fsSL https://raw.githubusercontent.com/nucamp/defsec/refs/heads/main/kali/setup.sh > ubuntu_setup.sh

if [ $? -ne 0 ]; then
	echo "ruh roh! I could not download the setup script from GitHub!"
	exit 1
fi

multipass transfer ./ubuntu_setup.sh nucamp-ubuntu-machine-2:/home/ubuntu < /dev/null

multipass exec nucamp-ubuntu-machine-2 -- sudo bash /home/ubuntu/ubuntu_setup.sh < /dev/null

if [ $? -ne 0 ]; then
	echo "Hmmm.... Something went heywire with that setup."
	echo "The machine will still work but will need some help getting setup the rest of the way"
	exit 1
fi
cat << EOF

That's it! I am done

EOF
