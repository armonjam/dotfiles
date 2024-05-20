TEMPDIR="/tmp/sunshine-bootstrap"
USER="archie"


mkdir -p ${TEMPDIR}

pacman --sync --refresh --quiet --noconfirm --needed wget tailscale which
# Enable tailscale service
sudo systemctl enable --now tailscaled.service
# Configure tailscale using local network
tailscale up

# Download latest sunshine package

wget -P ${TEMPDIR} https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine.pkg.tar.zst
pacman -U --noconfirm ${TEMPDIR}/sunshine.pkg.tar.zst

echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' > /etc/udev/rules.d/60-sunshine-bootstrap.rules
udevadm control --reload-rules
udevadm trigger
modprobe uinput

setcap cap_sys_admin+p $(readlink -f $(which sunshine))

# MUST RUN THIS COMMAND AS REGULAR USER WHEN DONE.
# I can't figure out how to automate.
####systemctl --user enable --now sunshine

rm -rf ${TEMPDIR}
