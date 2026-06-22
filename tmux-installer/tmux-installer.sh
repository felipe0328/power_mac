#!/bin/bash
# This bash install tmux and adds some toppings

printf "Welcome to TMUX Installer V1.0 \n \n"
echo "Please select the desired flavor to install:"
printf " 1 \t Tmux With Bottom aligment and ctrl+a as active command \n"
printf " 2 \t Tmux With Top Bar and Ctrl+b as active command \n"
read -p "Selected Option: " selected_option

## 1. Install Tmux based on the SO
printf "\n \n"
echo "Installing Tmux"
if [[ "$OSTYPE" == "darwin"* ]]; then
	brew install tmux;
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
	sudo apt-get install tmux
fi

## 2. Install Tmux plugins
printf "\n \n"
echo "Installing Tmux Plugins"
rm -rf ~/.tmux/plugins/tpm/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm


## 3. Adding Tmux based on the selected flavor
printf "\n \n"
echo "Adding the Tmux Selected plugins"
if [[ $selected_option == 1 ]]; then
	rm -rf ~/.tmux.conf
	cp tmux-bottom.conf ~
	mv ~/tmux-bottom.conf ~/.tmux.conf
elif [[ $selected_option == 2 ]]; then
	rm -rf ~/.tmux.conf
	cp tmux-top.conf ~
	mv ~/tmux-top.conf ~/.tmux.conf
fi