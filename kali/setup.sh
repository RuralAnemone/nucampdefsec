#!/bin/bash

sudo apt update && sudo apt upgrade -y

sudo apt install nmap \
	gobuster \
	openvpn \
	nikto \
	john \
	git \
	cargo \
	golang-go -y

echo "export PATH=$PATH:$HOME/go/bin" >> $HOME/.bashrc

mkdir -p /usr/share/wordlists/

git clone --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/wordlists/
