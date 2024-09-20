#!/usr/bin/env bash

set -e

# Settings
LOG_FILE='hyprland-setup.log'

KEYLAYOUT='en'
ROOT_PASS='root'
USER_NAME='fromml'
USER_PASS='2556'
TIMEZONE='Europe/Vienna'
HOST='archner'
COUNTRY='AT'
LOCALE='en_US.UTF-8'

DISK_BOOT='/dev/nvme1n1p1'
DISK_ARCH_ROOT='/dev/nvme1n1p2'
DISK_ARCH_HOME='/dev/nvme1n1p3'

DISK_VAULT='/dev/sda3'
DISK_WIN='/dev/nvme0n1p3'

PKG_PACMAN='amd-ucode base base-devel bash bat blueberry bluedevil bluez bluez-utils btop btrfs-progs cliphist curl dash efibootmgr eza fastfetch fd firefox fish fwupd fzf git git-delta grim grub-btrfs iwd jq kdeconnect kitty lazygit linux linux-firmware linux-headers man neovim networkmanager noto-fonts-emoji nvidia-dkms ntfs-3g sddm os-prober openssh pacman pavucontrol pipewire pipewire-alsa pipewire-audio pipewire-pulse playerctl polkit-kde-agent procs reflector ripgrep rsync slurp starship sudo thunderbird tldr ttf-firacode-nerd ttf-joypixels wget wireplumber wl-clipboard xdg-desktop-portal-hyprland zoxide zram-generator zstd'
PKG_AUR='aylurs-gtk-shell-git cava dracula-gtk-theme dracula-icons-theme hyprland anyrun-git bun-bin gnome-bluetooth-3.0 mpc mpd mpv npm nwg-look sddm sddm-astronaut-theme steam schedtoold timeshift timeshift-autosnap python-pywal16 python-pywalfox swww systemd-swap udiskie-systemd-git ueberzugpp wlroots-nvidia xwaylandvideobridge'

SETUP_GAMING='true'
# =====================================================================

LOGO=$(
	cat <<'END_HEREDOC'
 _   _                  _                 _ ____       _               
| | | |_   _ _ __  _ __| | __ _ _ __   __| / ___|  ___| |_ _   _ _ __  
| |_| | | | | '_ \| '__| |/ _` | '_ \ / _` \___ \ / _ \ __| | | | '_ \ 
|  _  | |_| | |_) | |  | | (_| | | | | (_| |___) |  __/ |_| |_| | |_) |
|_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|____/ \___|\__|\__,_| .__/ 
       |___/|_|                                                 |_|    
=======================================================================
END_HEREDOC
)

# Symbols
CHECK='✔'
CROSS='✗'

# echos and logs
function log {
	[[ ! -d /mnt/arch/log ]] && mkdir -p /mnt/arch/log
	echo -e "$1" | tee -a /mnt/arch/log/$LOG_FILE
}

log "$LOGO

---------------------------- Set Variables ----------------------------
CONFIGS:
KEYLAYOUT=$KEYLAYOUT
ROOT_PASS=$ROOT_PASS
USER_NAME=$USER_NAME
USER_PASS=$USER_PASS
TIMEZONE=$TIMEZONE
HOST=$HOST
COUNTRY=$COUNTRY
LOCALE=$LOCALE
-----------------------------------------------------------------------

DISKS:
DISK_BOOT=$DISK_BOOT
DISK_ARCH_ROOT=$DISK_ARCH_ROOT
DISK_ARCH_HOME=$DISK_ARCH_HOME
DISK_VAULT=$DISK_VAULT
DISK_WIN=$DISK_WIN

-----------------------------------------------------------------------

PKGS:
PACMAN: $PKG_PACMAN
AUR: $PKG_AUR
-----------------------------------------------------------------------
-----------------------------------------------------------------------

"

# whiptail colors
export NEWT_COLORS='
root=black,black
window=black,black
border=black,black
textbox=white,black
button=black,blue
'

text=$(printf "%s\n\n%s\n%s\n%s" "$LOGO
" "This script will recreate the disks boot and arch.\nMake sure that the needed partitions already exists.
" "$(lsblk)
" "Everything correct and ready to go?")

if ! whiptail --yesno "$text " 40 100; then
	echo "$CROSS Aborted by user"
	exit 1
fi

echo "Starting setup..."

# Setup Filesystem
mkfs.btrfs -L ArchRoot -f $DISK_ARCH_ROOT &&
	echo "$CHECK Created linux filesystems" ||
	echo "$CROSS FAILED to create arch linux filesystems"

# Setup Filesystem
mkfs.btrfs -L ArchHome -f $DISK_ARCH_HOME &&
	echo "$CHECK Created linux filesystems" ||
	echo "$CROSS FAILED to create arch linux filesystems"
 
# Setup Filesystem
mkfs.vfat -n Boot $DISK_BOOT &&
	echo "$CHECK Created boot filesystems" ||
	echo "$CROSS FAILED to create arch boot filesystems"

# Create Sub volumes
mkdir -p /mnt/arch
mount $DISK_ARCH_ROOT /mnt/arch &&
	btrfs sub create /mnt/arch/@ &&
	btrfs sub create /mnt/arch/@.snapshots &&
	btrfs sub create /mnt/arch/@btrfs &&
	btrfs sub create /mnt/arch/@log &&
	btrfs sub create /mnt/arch/@pkg &&
	umount /mnt/arch &&
	echo "$CHECK Created subvolumes @, @.snapshots, @btrfs, @log, @pkg" ||
	echo "$CROSS FAILED to create subvolumes @, @.snapshots, @btrfs, @log, @pkg"

mkdir -p /mnt/home
mount $DISK_ARCH_HOME /mnt/home &&
	btrfs sub create /mnt/home/@home &&
	umount /mnt/home &&
	echo "$CHECK Created subvolumes @home" ||
	echo "$CROSS FAILED to create subvolumes @home"

# Mount sub volumes
mount -o noatime,compress-force=zstd,commit=120,space_cache=v2,ssd,discard=async,autodefrag,subvol=@ $DISK_ARCH_ROOT /mnt/arch &&
	mkdir -p /mnt/arch/{home,var/cache/pacman/pkg,var/log,.snapshots,btrfs} &&
	mount -o noatime,compress-force=zstd,commit=120,space_cache=v2,ssd,discard=async,autodefrag,subvol=@home $DISK_ARCH_HOME /mnt/arch/home &&
	mount -o nodev,nosuid,noexec,noatime,compress-force=zstd,commit=120,space_cache=v2,ssd,discard=async,autodefrag,subvol=@log $DISK_ARCH_ROOT /mnt/arch/var/log &&
	mount -o nodev,nosuid,noexec,noatime,compress-force=zstd,commit=120,space_cache=v2,ssd,discard=async,autodefrag,subvol=@pkg $DISK_ARCH_ROOT /mnt/arch/var/cache/pacman/pkg &&
	mount -o noatime,compress-force=zstd,commit=120,space_cache=v2,ssd,discard=async,autodefrag,subvol=@.snapshots $DISK_ARCH_ROOT /mnt/arch/.snapshots &&
	mount -o noatime,compress-force=zstd,commit=120,space_cache=v2,ssd,discard=async,autodefrag,subvolid=5 $DISK_ARCH_ROOT /mnt/arch/btrfs

# Disable Copy on Write for databases
mkdir -p /mnt/arch/var/lib/{docker,machines,mysql,postgres}
chattr +C /mnt/arch/var/lib/{docker,machines,mysql,postgres}

# Mount NTFS DISKS
mkdir -p /mnt/arch/{win,vault}
mount -o noatime,compress-force=zstd,commit=120,space_cache=v2,ssd,discard=async,autodefrag $DISK_WIN /mnt/arch/win &&
	mount -o noatime,compress-force=zstd,autodefrag $DISK_VAULT /mnt/arch/vault

# Mount boot
mkdir -p /mnt/arch/boot
mount -o nodev,nosuid,noexec $DISK_BOOT /mnt/arch/boot

# Setup pacman and update mirrorlist
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf &&
	sed -i "/Color/s/^#//" /etc/pacman.conf &&
	sed -i "/ParallelDownloads/s/^#//" /etc/pacman.conf &&
	reflector --country "$COUNTRY" --score 50 --sort rate --save /etc/pacman.d/mirrorlist

# install all non aur pkgs
echo "$PKG_PACMAN" | xargs pacstrap /mnt/arch

# generate fstab
genfstab -U /mnt/arch >/mnt/arch/etc/fstab

# copy pacman configs
cp -p /etc/pacman.d/mirrorlist /mnt/arch/etc/pacman.d/mirrorlist
cp -p /etc/pacman.conf /mnt/arch/etc

# Set locale
sed -i "/$LOCALE/s/^#//g" /mnt/arch/etc/locale.gen &&
	arch-chroot /mnt/arch /bin/bash -c "locale-gen" &&
	echo "LANG=$LOCALE" >/mnt/arch/etc/locale.conf

# Set vconsole
echo "KEYMAP=$KEYLAYOUT" >/mnt/arch/etc/vconsole.conf

# Configure system
timedatectl set-ntp true

# Set timezone
ln -sf /mnt/arch/usr/share/zoneinfo/$TIMEZONE /mnt/arch/etc/localtime &&
	arch-chroot /mnt/arch /bin/bash -c "hwclock -uw"

# Set hostname
echo "${HOST}" >/mnt/arch/etc/hostname

# Set hosts
cat <<EOF >>/mnt/arch/etc/hosts
# <ip-address>  <hostname.domain.org>   <hostname>
127.0.0.1       localhost
::1             localhost
127.0.1.1       $HOST.localdomain       $HOST
EOF

# Set root passwd
arch-chroot /mnt/arch /bin/bash -c "echo 'root:$ROOT_PASS' | chpasswd"

# Create user and add policies and passwd
arch-chroot /mnt/arch /bin/bash -c "useradd -mG wheel -s /bin/fish $USER_NAME && echo '$USER_NAME:$USER_PASS' | chpasswd"

# uncomment wheel nopasswd
arch-chroot /mnt/arch /bin/bash -c "chmod +w /etc/sudoers &&
    sed -i '/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^#//' /etc/sudoers &&
    chmod 0440 /etc/sudoers"

# Clone and copy dotfiles
arch-chroot /mnt/arch /bin/bash -c "runuser -l $USER_NAME -c 'git clone https://github.com/FromWau/dotfiles.git ~/dotfiles'" &&
	cp -rp /mnt/arch/home/"$USER_NAME"/dotfiles/.local /mnt/arch/home/"$USER_NAME" &&
	cp -rp /mnt/arch/home/"$USER_NAME"/dotfiles/.config /mnt/arch/home/"$USER_NAME" &&
	rm -rf /mnt/arch/home/"$USER_NAME"/dotfiles

# Create important dirs
arch-chroot /mnt/arch /bin/bash -c "runuser -l $USER_NAME -c 'mkdir -p ~/.local/share/gnupg/ &&
	find ~/.local/share/gnupg -type f -exec chmod 600 {} &&
	find ~/.local/share/gnupg -type d -exec chmod 700 {}'"

# install yay and aur pkgs
arch-chroot /mnt/arch /bin/bash -c "runuser -l $USER_NAME -c 'git clone https://aur.archlinux.org/yay-git.git ~/yay-git &&
    cd ~/yay-git &&
    makepkg -si --noconfirm &&
    yay -Syyyu --noconfirm --removemake --rebuild $PKG_AUR'"

# Clean up home
rm -rf /mnt/arch/home/"$USER_NAME"/{yay-git,.rustup,.cargo,.npm}

# Configure mkinicpio.conf
sed -i 's/MODULES=()/MODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf &&
	sed -i 's/BINARIES=()/BINARIES=("\/usr\/bin\/btrfs")/' /mnt/arch/etc/mkinitcpio.conf &&
	sed -i 's/#COMPRESSION="lz4"/COMPRESSION="lz4"/' /mnt/arch/etc/mkinitcpio.conf &&
	sed -i 's/#COMPRESSION_OPTIONS=()/COMPRESSION_OPTIONS=(-9)/' /mnt/arch/etc/mkinitcpio.conf &&
	sed -i 's/^HOOKS.*/HOOKS=(base systemd btrfs autodetect modconf kms keyboard sd-vconsole block filesystems fsck)/' /mnt/arch/etc/mkinitcpio.conf &&
	arch-chroot /mnt/arch /bin/bash -c "mkinitcpio -p linux"

# Install and configure grub
arch-chroot /mnt/arch /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB' &&
	sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=3|" /mnt/arch/etc/default/grub &&
	sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"rootfstype=btrfs nvidia_drm.modeset=1 rd.driver.blacklist=nouveau modprob.blacklist=nouveau\"|" /mnt/arch/etc/default/grub &&
	sed -i "/#GRUB_DISABLE_OS_PROBER=.*/s/^#//" /mnt/arch/etc/default/grub

# Add Reboot and Shutdown option to grub
cat <<EOF >>/mnt/arch/etc/grub.d/40_custom
menuentry "Reboot" {
    reboot
}
menuentry "Shutdown" {
    halt
}
EOF

# Theme grub
arch-chroot /mnt/arch /bin/bash -c "git clone https://github.com/vinceliuice/grub2-themes.git /grub2-themes" &&
	mkdir -p /mnt/arch/boot/grub/themes &&
	/mnt/arch/grub2-themes/install.sh -t vimix -g /mnt/arch/boot/grub/themes &&
	rm -rf /mnt/arch/grub2-themes &&
	sed -i "s|.*GRUB_THEME=.*|GRUB_THEME=\"boot\/grub\/themes\/vimix/theme.txt\"|" /mnt/arch/etc/default/grub &&
	sed -i "s|.*GRUB_GFXMODE=.*|GRUB_GFXMODE=1920x1080,auto|" /mnt/arch/etc/default/grub &&
	arch-chroot /mnt/arch /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

# create dash hook
arch-chroot /mnt/arch /bin/bash -c "ln -sfT dash /usr/bin/sh" &&
	echo '[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = bash
[Action]
Description = Re-pointing /usr/bin/sh symlink to dash...
When = PostTransaction
Exec = /usr/bin/ln -sfT dash /usr/bin/sh
Depends = dash' >/mnt/arch/usr/share/libalpm/hooks/update-bash.hook

# Set iwd as backend for networkmanager
cat <<EOF >>/mnt/arch/etc/NetworkManager/conf.d/nm.conf
[device]
wifi.backend=iwd
EOF

# Better IO Scheduler
cat <<EOF >/mnt/arch/etc/udev/rules.d/60-ioschedulers.rules
# set scheduler for NVMe
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# set scheduler for SSD and eMMC
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# set scheduler for rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF

# Create zram
cat <<EOF >/mnt/arch/etc/systemd/zram-generator.conf
[zram0]
zram-size = ram
compression-algorithm = zstd
EOF

# Enable services
arch-chroot /mnt/arch /bin/bash -c "runuser -l $USER_NAME -c 'sudo systemctl enable NetworkManager &&
    sudo systemctl enable sshd.service &&
    sudo systemctl enable sddm.service &&
    sudo systemctl enable bluetooth.service &&
    sudo systemctl enable grub-btrfsd.service &&
    sudo systemctl enable upower.service'"

# Gaming/Performance tweaks (https://wiki.archlinux.org/title/gaming)
if [ "$SETUP_GAMING" = "true" ]; then

	# Increase vm.max_map_count to default in SteamOS
	mkdir -p /mnt/arch/etc/sysctl.d/
	echo 'vm.max_map_count = 2147483642' >/mnt/arch/etc/sysctl.d/80-gamecompatibility.conf

	# INFO:
	# - Disable proactive compaction because it introduces jitter
	# - Reduce the watermark boost factor to defragment only one pageblock in case of memory fragmentation
	# - Avoid swapping (locking pages that introduces latency and uses disk IO)
	# - Enable Multi-Gen Least Recently Used (MGLRU)
	# - Disable zone reclaim
	# - Reduce the maximum page lock acquisition latency
	# - Tweak the scheduler settings
	mkdir -p /mnt/arch/etc/tmpfiles.d/
	cat <<EOF >/etc/tmpfiles.d/consistent-response-time-for-gaming.conf
#    Path                  Mode UID  GID  Age Argument
w /proc/sys/vm/compaction_proactiveness - - - - 0
w /proc/sys/vm/watermark_boost_factor - - - - 1
w /proc/sys/vm/swappiness - - - - 10
w /sys/kernel/mm/lru_gen/enabled - - - - 5
w /proc/sys/vm/zone_reclaim_mode - - - - 0
w /proc/sys/vm/page_lock_unfairness - - - - 1
w /proc/sys/kernel/sched_child_runs_first - - - - 0
w /proc/sys/kernel/sched_autogroup_enabled - - - - 1
w /proc/sys/kernel/sched_cfs_bandwidth_slice_us - - - - 3000
w /sys/kernel/debug/sched/base_slice_ns  - - - - 3000000
w /sys/kernel/debug/sched/migration_cost_ns - - - - 500000
w /sys/kernel/debug/sched/nr_migrate - - - - 8
EOF
	arch-chroot /mnt/arch /bin/bash -c "sysctl --system"

	arch-chroot /mnt/arch /bin/bash -c "runuser -l $USER_NAME -c 'yay -Syyyu --noconfirm --removemake --rebuild gamemode schedtoold'"

	arch-chroot /mnt/arch /bin/bash -c "usermod -a -G gamemode $USER_NAME"
fi

# Set wheel to passwd
arch-chroot /mnt/arch /bin/bash -c "chmod +w /etc/sudoers &&
    sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /etc/sudoers &&
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers &&
    chmod 0440 /etc/sudoers"

echo "done"
echo "before rebooting"
echo "run:"
echo "cd ~ && umount -a && reboot"
