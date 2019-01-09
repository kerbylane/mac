System set up instructions

- Install XCode command line tools:
```
xcode-select --install
```
- Install MacPorts coreutils
```bash
sudo port install coreutils
```
- in your home directory create links to the files in the dotFiles directory except for .bash_profile
- In ~/.bash_profile add the following:
```bash
export MY_HOST_NAME=LAPTOP # see bash_prompt.sh for information
source ~/personal/mac/dotfiles/.bash_profile
```
- Update your shell to a more recent version:
```bash
# Install a recent version of bash
sudo port install bash

# Add it to the list of shells that are acceptable
sudo echo "/opt/local/bin/bash" >> /etc/shells

# change the default shell to the new one
sudo chsh -s /opt/local/bin/bash $(whoami)
```