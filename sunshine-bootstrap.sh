TEMPDIR="/tmp/sunshine-bootstrap"
USER="archie"

# also, after nvidia driver install, you need to remove
# the kms item from the HOOKS list in /etc/mkinitcpio.conf

mkdir -p ${TEMPDIR}

pacman --sync --refresh --quiet --noconfirm --needed wget tailscale which nvidia lib32-nvidia-utils nvidia-utils xorg-server
# Enable tailscale service
sudo systemctl enable --now tailscaled.service
# Configure tailscale using local network
tailscale up

# Download latest sunshine package

wget -P ${TEMPDIR} https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine.pkg.tar.zst &>/dev/null
pacman -U --noconfirm --needed ${TEMPDIR}/sunshine.pkg.tar.zst

echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' > /etc/udev/rules.d/60-sunshine-bootstrap.rules
udevadm control --reload-rules
udevadm trigger
modprobe uinput

setcap cap_sys_admin+p $(readlink -f $(which sunshine))

printf '%s' '
Section "ServerLayout"
    Identifier "TwinLayout"
    Screen 0 "metaScreen" 0 0
EndSection

Section "Monitor"
    Identifier "Monitor0"
    Option "Enable" "true"
EndSection

Section "Device"
    Identifier "Card0"
    Driver "nvidia"
    VendorName "NVIDIA Corporation"
    Option "MetaModes" "2732x2048"
    Option "ConnectedMonitor" "HDMI-0"
    Option "ModeValidation" "NoDFPNativeResolutionCheck,NoVirtualSizeCheck,NoMaxPClkCheck,NoHorizSyncCheck,NoVertRefreshCheck,NoWidthAlignmentCheck"
EndSection

Section "Screen"
    Identifier "metaScreen"
    Device "Card0"
    Monitor "Monitor0"
    DefaultDepth 24
    Option "TwinView" "True"
    SubSection "Display"
        Modes "2732x2048"
    EndSubSection
EndSection
' > /etc/X11/xorg.conf.d/60-sunshine-bootstrap.conf

systemctl enable --now avahi-daemon
# MUST RUN THIS COMMAND AS REGULAR USER WHEN DONE.
# I can't figure out how to automate.
####systemctl --user enable --now sunshine

rm -rf ${TEMPDIR}
