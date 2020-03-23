# installed shells
cat /etc/shells

# current default shell
dscl . -read /Users/bengelens UserShell

# change shell to pwsh 6
chsh -s /usr/local/microsoft/powershell/6/pwsh

# start shell, show env:PATH, e.g. no docker

# change shell to pwsh 7, show env:PATH, docker on path
chsh -s /usr/local/bin/pwsh
