# Constants
USER="archie"
ADMIN_GROUP="wheel"
EMPTYDIR="/tmp/bootstrap/emptydir"
ENABLE_SSH_SERVER="true"

# Create temporary empty directory for use in script
mkdir -p ${EMPTYDIR}

# Initialize wired network device as managed
ethernet_device=$(ip -oneline addr show scope global | cut -f 2,4 -d ' ' | head -n 1)
echo "
[Match]
Name=${ethernet_device}

[Network]
DHCP=yes
" > /etc/systemd/network/bootstrap-wired.network

# Configure dns resolution
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Enable and start network services
systemctl enable --now systemd-networkd.service
systemctl enable --now systemd-resolved.service

# Download and install packages
pacman --sync --refresh --quiet --noconfirm --needed sudo zsh neovim git openssh chezmoi bat

# Configure sshd
printf '%s' '
Port 22
PermitRootLogin no
PasswordAuthentication no
PrintLastLog no
AcceptEnv LANG LC_*
' > /etc/ssh/sshd_config.d/bootstrap-ssh.conf

# Enable sshd if requested
if [ "$ENABLE_SSH_SERVER" = true ]; then
	systemctl enable --now sshd.service
fi

# Initialize custom sudoers file
printf '%s' "
# Use root user's password whenever using sudo
Defaults rootpw
# Add the admin group to the sudoers list
%${ADMIN_GROUP} ALL=(ALL:ALL) ALL
" > /etc/sudoers.d/bootstrap-sudoers

# Initialize primary user
useradd --create-home --skel ${EMPTYDIR} ${USER} 2> /dev/null
usermod --shell /usr/bin/zsh ${USER} 1> /dev/null
usermod -a -G ${ADMIN_GROUP} ${USER} 2> /dev/null
passwd --quiet -d ${USER}

# Enable autologin for primary user
mkdir --parents /etc/systemd/system/getty@tty1.service.d
printf '%s' '
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin archie --noclear %I $TERM
' > /etc/systemd/system/getty@tty1.service.d/bootstrap-autologin.conf

# Cleanup
rm -rd ${EMPTYDIR}

# Optional tailscale package
pacman --sync --refresh --quiet --noconfirm --needed tailscale
# Enable tailscale service
sudo systemctl enable --now tailscaled.service
# Configure tailscale using local network
tailscale up

