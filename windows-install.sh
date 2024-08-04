#!/bin/bash

echo "*** Update and Upgrade ***"
apt update -y && apt upgrade -y
echo "Update and Upgrade finish ***"

echo "*** Install linux-image-amd64 ***"
apt install -y linux-image-amd64
echo "Install linux-image-amd64 finish ***"

echo "*** Reinstall initramfs-tools ***"
apt install --reinstall -y initramfs-tools
echo "Reinstall initramfs-tools finish ***"

echo "*** Install grub2, wimtools, ntfs-3g ***"
apt install -y grub2 wimtools ntfs-3g
echo "Install grub2, wimtools, ntfs-3g finish ***"

echo "*** Get the disk size in GB and convert to MB ***"
disk_size_gb=$(parted /dev/sda --script print | awk '/^Disk \/dev\/sda:/ {print int($3)}')
disk_size_mb=$((disk_size_gb * 1024))
echo "Get the disk size in GB and convert to MB finish ***"

echo "*** Calculate partition size (50% of total size) ***"
part_size_mb=$((disk_size_mb / 2))
echo "Calculate partition size (50% of total size) finish ***"

echo "*** Create GPT partition table ***"
parted /dev/sda --script -- mklabel gpt
echo "Create GPT partition table finish ***"

echo "*** Create two partitions ***"
parted /dev/sda --script -- mkpart primary ntfs 1MB ${part_size_mb}MB
echo "Create first partitions"
parted /dev/sda --script -- mkpart primary ntfs ${part_size_mb}MB 100%
echo "Create second partitions"
echo "Create two partitions finish ***"

echo "*** Inform kernel of partition table changes ***"
partprobe /dev/sda
sleep 60

partprobe /dev/sda
sleep 60

partprobe /dev/sda
sleep 60
echo "Inform kernel of partition table changes"

# Check if partitions are created and formatted successfully
echo "*** Check if partitions are created and formatted successfully ***"
if lsblk /dev/sda1 && lsblk /dev/sda2; then
    echo "Check if partitions are created and formatted successfully finish ***"
else
    echo "Error: Partitions were not created or formatted successfully"
    exit 1
fi

echo "*** Format the partitions ***"
mkfs.ntfs -f /dev/sda1
echo "Format the partitions sda1"
mkfs.ntfs -f /dev/sda2
echo "Format the partitions sda2"
echo "Format the partitions finish ***"

echo "NTFS partitions created"

echo "*** Install gdisk ***"
apt-get install -y gdisk
echo "Install gdisk finish ***"

echo "*** Run gdisk commands ***"
echo -e "r\ng\np\nw\nY\n" | gdisk /dev/sda
echo "Run gdisk commands finish ***"

echo "*** Mount /dev/sda1 to /mnt ***"
mount /dev/sda1 /mnt
echo "Mount /dev/sda1 to /mnt finish ***"

echo "*** Prepare directory for the Windows disk ***"
mkdir -p ~/windisk
echo "Prepare directory for the Windows disk finish ***"

echo "*** Mount /dev/sda2 to windisk ***"
mount /dev/sda2 ~/windisk
echo "Mount /dev/sda2 to windisk finish ***"

echo "*** Install GRUB ***"
grub-install --root-directory=/mnt /dev/sda
echo "Install GRUB finish ***"

echo "*** Edit GRUB configuration ***"
cat <<EOF > /mnt/boot/grub/grub.cfg
menuentry "windows installer" {
    insmod ntfs
    search --no-floppy --set=root --file=/bootmgr
    ntldr /bootmgr
    boot
}
EOF
echo "Edit GRUB configuration finish ***"

echo "*** Prepare winfile directory ***"
mkdir -p ~/windisk/winfile
echo "Prepare winfile directory finish ***"

# Automatically download Windows.iso
windows_url="https://bit.ly/3UGzNcB"  # Replace with the actual default URL
wget -O ~/windisk/Windows.iso --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" "$windows_url"
echo "Download completed"

# Check if the ISO was downloaded successfully
echo "*** Check if the ISO of windows ***"
if [ -f "~/windisk/Windows.iso" ]; then
    mount -o loop ~/windisk/Windows.iso ~/windisk/winfile
    rsync -avz --progress ~/windisk/winfile/* /mnt
    umount ~/windisk/winfile
    echo "Check if the ISO of windows finish ***"
else
    echo "Failed to download Windows.iso"
    exit 1
fi

# Automatically download Virtio.iso
virtio_url="https://bit.ly/4d1g7Ht"  # Replace with the actual default URL
wget -O ~/windisk/Virtio.iso --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" "$virtio_url"
echo "Download completed"

# Check if the ISO was downloaded successfully
echo "*** Check if the ISO of drivers ***"
if [ -f "~/windisk/Virtio.iso" ]; then
    mount -o loop ~/windisk/Virtio.iso ~/windisk/winfile
    mkdir -p /mnt/sources/virtio
    rsync -avz --progress ~/windisk/winfile/* /mnt/sources/virtio
    umount ~/windisk/winfile
    echo "Check if the ISO of drivers finish ***"
else
    echo "Failed to download Virtio.iso"
    exit 1
fi

cd /mnt/sources

touch cmd.txt

echo 'add virtio /virtio_drivers' >> cmd.txt

# List images in boot.wim and select the second image
echo "*** List images in boot.wim ***"
wimlib-imagex info boot.wim
image_index=2
echo "Selected image index: $image_index"
echo "List images in boot.wim finish ***"

# Check if boot.wim exists before updating
echo "*** Rebooting the system... ***"
if [ -f boot.wim ]; then
    wimlib-imagex update boot.wim $image_index < cmd.txt
    echo "Update boot.wim finish ***"
else
    echo "boot.wim not found"
    exit 1
fi

# Automatically reboot the system
echo "Rebooting the system..."
reboot
