#!/bin/bash

echo "---------------- Update and Upgrade ---------------- "
apt update -y && apt upgrade -y

echo "---------------- install linux-image-amd64 ---------------- "
sudo apt install linux-image-amd64

echo "---------------- reinstall initramfs-tools ---------------- "
sudo apt install --reinstall initramfs-tools

echo "---------------- install grub2, wimtools, ntfs-3g ---------------- "
apt install grub2 wimtools ntfs-3g -y

echo "---------------- Get the disk size in GB and convert to MB ---------------- "
disk_size_gb=$(parted /dev/sda --script print | awk '/^Disk \/dev\/sda:/ {print int($3)}')
disk_size_mb=$((disk_size_gb * 1024))

echo "---------------- Calculate partition size (50% of total size) ---------------- "
part_size_mb=$((disk_size_mb / 2))

echo "---------------- Create GPT partition table ---------------- "
parted /dev/sda --script -- mklabel gpt

echo "---------------- Create two partitions ---------------- "
parted /dev/sda --script -- mkpart primary ntfs 1MB ${part_size_mb}MB
parted /dev/sda --script -- mkpart primary ntfs ${part_size_mb}MB 100%

echo "---------------- Inform kernel of partition table changes ---------------- "
sudo partprobe /dev/sda

sleep 90

partprobe /dev/sda

sleep 90

partprobe /dev/sda

sleep 90 

echo "---------------- Verify partitions ---------------- "
fdisk -l /dev/sda

# Check if partitions are created and formatted successfully
if lsblk /dev/sda1 && lsblk /dev/sda2; then
    echo "---------------- Partitions created and formatted successfully ----------------"
else
    echo "Error: Partitions were not created or formatted successfully"
    read -p "Press any key to exit..." -n1 -s
    exit 1
fi

echo "---------------- Format the partitions ---------------- "
mkfs.ntfs -f /dev/sda1
mkfs.ntfs -f /dev/sda2

echo "NTFS partitions created"

echo "---------------- Install gdisk ---------------- "
sudo apt-get install gdisk

echo "---------------- Run gdisk commands ---------------- "
echo -e "r\ng\np\nw\nY\n" | gdisk /dev/sda

echo "---------------- Mount /dev/sda1 to /mnt ---------------- "
mount /dev/sda1 /mnt

echo "---------------- Prepare directory for the Windows disk ---------------- "
cd ~
mkdir -p windisk

echo "---------------- Mount /dev/sda2 to windisk ---------------- "
mount /dev/sda2 windisk

echo "---------------- Install GRUB ---------------- "
grub-install --root-directory=/mnt /dev/sda

echo "---------------- Edit GRUB configuration ---------------- "
cd /mnt/boot/grub
cat <<EOF > grub.cfg
menuentry "windows installer" {
	insmod ntfs
	search --no-floppy --set=root --file=/bootmgr
	ntldr /bootmgr
	boot
}
EOF

echo "---------------- Prepare winfile directory ---------------- "
cd /root/windisk
mkdir -p winfile

# Ask if the user wants to download Windows.iso
read -p "Do you want to download Windows.iso? (Y/N): " download_choice

if [[ "$download_choice" == "Y" || "$download_choice" == "y" ]]; then
    # Ask for the URL to download Windows.iso
    read -p "Enter the URL for Windows.iso (leave blank to use default): " windows_url
    if [ -z "$windows_url" ]; then
        windows_url="https://bit.ly/3UGzNcB"  # Replace with the actual default URL
    fi
    
    wget -O Windows.iso --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" "$windows_url"
    echo "---------------- Download completed.---------------- "
else
    echo "Please upload the Windows operating system image in 'root/windisk' folder and rename as 'Windows.iso'."
    read -p "Press any key to continue once you have uploaded the image..." -n1 -s
    echo "---------------- Continuing with the script execution .---------------- "
fi

# Continue with the script execution
echo "---------------- Executing the rest of the script... ---------------- "

# Check if the ISO was downloaded successfully
echo "---------------- Check if the ISO of windows ---------------- "
if [ -f "Windows.iso" ]; then
    mount -o loop Windows.iso winfile
    rsync -avz --progress winfile/* /mnt
    umount winfile
else
    echo "Failed to download Windows.iso"
    read -p "Press any key to exit..." -n1 -s
    exit 1
fi

# Ask if the user wants to download the ISO image of Virtio drivers
read -p "Do you want to download the ISO image of Virtio drivers? (Y/N): " download_choice

if [[ "$download_choice" == "Y" || "$download_choice" == "y" ]]; then
    # Ask for the URL to download Virtio.iso
    read -p "Enter the URL for Virtio.iso (leave blank to use default): " virtio_url
    if [ -z "$virtio_url" ]; then
        virtio_url="https://default-url-for-virtio.iso"  # Replace with the actual default URL
    fi
    
    wget -O Virtio.iso --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" "$virtio_url"
    echo "---------------- Download completed.----------------"
else
    echo "Please upload the Windows operating system image in the 'root/windisk' folder and rename it as 'Virtio.iso'."
    read -p "Press any key to continue once you have uploaded the image..." -n1 -s
    echo "---------------- Continuing with the script execution.----------------"
fi

# Check if the ISO was downloaded successfully
echo "---------------- Check if the ISO of drivers ---------------- "
if [ -f "Virtio.iso" ]; then
    mount -o loop Virtio.iso winfile
    mkdir -p /mnt/sources/virtio
    rsync -avz --progress winfile/* /mnt/sources/virtio
    umount winfile
else
    echo "Failed to download Virtio.iso"
    read -p "Press any key to exit..." -n1 -s
    exit 1
fi

cd /mnt/sources

touch cmd.txt

echo 'add virtio /virtio_drivers' >> cmd.txt

# List images in boot.wim
wimlib-imagex info boot.wim

# Prompt user to enter a valid image index
echo "Please enter a valid image index from the list above:"
read image_index

# Check if boot.wim exists before updating
if [ -f boot.wim ]; then
    wimlib-imagex update boot.wim $image_index < cmd.txt
else
    echo "boot.wim not found"
    read -p "Press any key to exit..." -n1 -s
    exit 1
fi

# Ask if the user wants to reboot
read -p "Do you want to reboot the system now? (Y/N): " reboot_choice

if [[ "$reboot_choice" == "Y" || "$reboot_choice" == "y" ]]; then
    echo "---------------- Rebooting the system... ---------------- "
    sudo reboot
else
    echo "Continuing without rebooting."
fi