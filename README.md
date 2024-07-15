# Any-Windows-Contabo-VPS
Easy installation of any version of Windows for your Contabo VPS.

# Installation Guide
Introduction
This guide provides step-by-step instructions for installing any Windows on a Contabo VPS. Please be aware that you assume full responsibility for all risks associated with this installation.

Prerequisites
VNC Viewer application installed. Download it from here.
A Contabo VPS
Microsoft Remote Desktop for RDP connection to the machine.
Steps for installation
1. Prepare the VPS for installation
Purchase a new Ubuntu VPS
Log in to the Contabo user panel and navigate to the "Your services" section.
On your VPS click the "Manage" button and select "Rescue System".
Choose "Debian 10 - Live" from the "Rescue System Version" dropdown menu.
Set a password and start the Rescue System.
From the control panel go to "VPS control".
Click the "Manage" button and select "VNC password".
Set the VNC password. It must be 8 characters long, containing at least one uppercase and one lowercase character, and one number. Avoid using any special characters.
2. Connect to the VPS via SSH
Open Terminal on MacOS or PuTTY on Windows.
Log in with the command ssh root@<MACHINE-IP> and enter your Rescue System password.
Execute the following commands:
apt install git -y
git clone https://github.com/ombadr/Windows-Server-Contabo-VPS.git
cd Windows-Server-Contabo-VPS
chmod +x windows-install.sh
./windows-install.sh
The process takes approximately 15 minutes and completes when the ssh session disconnects due to the machine rebooting.
3. Connnect to the VPS with VNC to install Windows
Open your VNC app and create a new connection using the IP and PORT found on the VPS control page. Hover over "Manage" and click on "VNC Information"

Upon connecting, you will see a screen as shown in the image. Press Enter.

text

Follow the on-screen prompts to install Windows.

Install the virtIO drivers as shown in the following images.

Click on "Browse"

text

From Boot select virtio_drivers

text

Select amd64\w10 and click on "Ok"

text

Click on "Next"

text

Click on "Custom: Install Windows Only (advanced)"

text

For the installation, select the partition Drive 0 Partition 1

text

Choose the operating system and then click on "Next"

text

4. Install the Ethernet adapter for internet connection
Open the Device Manager

text

Right-click on Ethernet Controller and select Update Driver

text

Choose Browse my computer for drivers

text

Click on Browse and select the path C:\sources\virtio, and click "Next"

text

Click on Install

text

5. Allow Remote Access Connection for RDP
Search for allow remote connections to this computer and select the first option.

text

In the Remote Desktop section, click on Show settings

text

Choose Allow remote connections to this computer, click "Apply" and then "Ok"

text

Now, connect remotely using your Remote Desktop Connection program with the credentials created during the Windows installation.

Conclusions
Congratulations! You should now have a fully operational Windows 10 installation on your Contabo VPS. Remember to proceed with these instructions at your own risk and ensure that all software and applications used are legal and compliant with the respective licenses.
