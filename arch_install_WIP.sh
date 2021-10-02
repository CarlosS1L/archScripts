#!/bin/bash
# Arch Linux Installation Script
# Created by s1ln7m4s7r - Portugal




#
#efi
#------------------
#fdisk - l 
#cgdisk /dev/.?????
#create efi disk 512m file type ef00
#
#
#mkfs.fat -F32 /dev/<THAT_PARTITION>
#
#
#base

wayland 
gnome
mutter
#
#
#
#
#
#
#
#
#
#
#
#
#

working_space()
{
	clear
	echo -n "Keyboard Layout (Default: pt-latin1): "
	read klayout
	if [ -z $klayout ]
	then
		klayout=pt-latin1
	fi
	loadkeys $klayout
	echo ""
	echo -n "Language (Default: pt_PT): "
	read setlang
	if [ -z $setlang ]
	then
		setlang=pt_PT
	fi
	sed -i "s/#$setlang/$setlang/" "/etc/locale.gen"
	clear
	locale-gen
	echo ""
	echo -n "Set Locale (Default: $setlang.UTF-8): "
	read sellocal
	if [ -z $sellocal ]
	then
		sellocal=$setlang.UTF-8
	fi
	export LANG=$sellocal
	return
}

set_connection()
{
	optionnet=1
	while [ $optionnet != 0 ]
	do
		clear
		echo "*************************"
		echo "* Setup Internet Access *"
		echo "*************************"
		echo "* 1 - Local Network     *"
		echo "* 2 - Wireles Network   *"
		echo "*************************"
		echo "* 0 - Exit              *"
		echo "*************************"
		echo -n ": "
		read optionsel
		clear
		case $optionsel in
			1)dhcpcd;;
			2)
				ip addr
				echo ""
				echo -n "Choose Adapter: "
				read adapter
				wifi-menu $adapter
			;;
			0)optionnet=0;;
		esac
	done
	return
}

search_old_setups()
{
	option=1
	while [ $option != 0 ]
	do
		clear
		echo "*****************************"
		echo "*     Old disk layouts      *"
		echo "*****************************"
		echo "* 1 - Logical Volumes (LV)  *"
		echo "* 2 - Volume Groups (VG)    *"
		echo "* 3 - Physical Volumes (PV) *"
		echo "* 4 - Raid Arrays           *"
		echo "* 5 - Disks                 *"
		echo "* 6 - Partitions            *"
		echo "*****************************"
		echo "* 0 - Exit                  *"
		echo "*****************************"
		echo -n ": "
		read dellayouts
		clear
		case $dellayouts in
			1)
				echo "Logical Volumes"
				echo "*********************************************"
				lvs
				echo "*********************************************"
				echo ""
				option=1
				while [ $option != 0 ]
				do
					echo -n "Delete a Logical Volume? (yes/no): "
					read delopt
					if [ $delopt = yes ]
					then
						echo ""
						echo -n "VG: "
						read delvolgroup
						echo ""
						echo -n "LV: "
						read dellogvol
						lvremove -f /dev/$delvolgroup/$dellogvol
						option=0
					fi
					if [ $delopt = no ]
					then
						option=0
					fi
				done
			;;
			2)
				echo "Volume Groups"
				echo "*********************************************"
				vgs
				echo "*********************************************"
				echo ""
				option=1
				while [ $option != 0 ]
				do
					echo -n "Delete a Volume Group? (yes/no): "
					read delopt
					if [ $delopt = yes ]
					then
						echo ""
						echo -n "VG: "
						read delvolgroup
						vgremove -f /dev/$delvolgroup
						option=0
					fi
					if [ $delopt = no ]
					then
						option=0
					fi
				done
			;;
			3)
				echo "Physical Volumes"
				echo "*********************************************"
				pvs
				echo "*********************************************"
				echo ""
				option=1
				while [ $option != 0 ]
				do
					echo -n "Delete a Physical Volume? (yes/no): "
					read delopt
					if [ $delopt = yes ]
					then
						echo ""
						echo -n "PV: "
						read delfisgroup
						pvremove -f $delfisgroup
						option=0
					fi
					if [ $delopt = no ]
					then
						option=0
					fi
				done
			;;
			4)
				echo "Raid Arrays"
				echo "*********************************************"
				cat /proc/mdstat
				echo "*********************************************"
				echo ""
				option=1
				while [ $option != 0 ]
				do
					echo -n "Delete an array? (yes/no): "
					read delopt
					if [ $delopt = yes ]
					then
						echo ""
						echo -n "Raid Name: "
						read delraidarray
						echo ""
						echo -n "Raid Partitions (sd[][]): "
						read delraidpart
						mdadm --remove /dev/$delraidarray
						mdadm --stop /dev/$delraidarray
						mdadm --zero-superblock /dev/$delraidpart
						option=0
					fi
					if [ $delopt = no ]
					then
						option=0
					fi
				done	
			;;
			5)
				echo "Disks"
				echo "*********************************************"
				lsblk|grep disk
				echo "*********************************************"
				echo ""
				option=1
				while [ $option != 0 ]
				do
					echo -n "Delete a disk? (yes/no): "
					read delopt
					if [ $delopt = yes ]
					then
						echo ""
						echo -n "Disk: "
						read deletedisk
						sgdisk -Z /dev/$deletedisk
						sgdisk -o /dev/$deletedisk
						option=0
					fi
					if [ $delopt = no ]
					then
						option=0
					fi
				done
			;;
			6)
				echo "Disks"
				echo "*********************************************"
				lsblk|grep disk
				echo "*********************************************"
				echo ""
				echo -n "Disk: "
				read selectdisk
				clear
				echo "*********************************************"
				lsblk /dev/$selectdisk
				echo "*********************************************"
				echo ""
				option=1
				while [ $option != 0 ]
				do
					echo -n "Delete a partition? (yes/no): "
					read delopt
					if [ $delopt = yes ]
					then
						echo ""
						echo -n "Partition: "
						read selectpart
						opt=1
						while [ $opt != 0 ]
						do
							clear
							echo -n "The partition belongs to a raid array? (yes/no): "
							read delpartopt
							clear
							if [ $delpartopt = yes ]
							then
								mdadm --fail /dev/md0 /dev/$selectpart
								mdadm -r /dev/md0 /dev/$selectpart
								mdadm --zero-superblock /dev/$selectpart
								opt=0
							fi
							if [ $delpartopt = no ]
							then
								opt=0
							fi
						done
						sgdisk --delete=$selectpart /dev/$selectdisk
						option=0
					fi
					if [ $delopt = no ]
					then
						option=0
					fi
				done
			;;
			0)option=0;;
		esac
	done
	return
}

create_efipart()
{
	echo "*********************************************"
	lsblk|grep disk
	echo "*********************************************"
	echo ""
	echo -n "Disk: "
	read diskefiex
	clear
	echo "*********************************************"
	lsblk /dev/$diskefi
	echo "*********************************************"
	echo ""
	echo -n "Partition number: "
	read diskefinum
	echo ""
	echo -n "EFI Size (MB): "
	read diskefisize
	sgdisk -n $diskefinum:$(sgdisk -f $1):+$diskefisize\M -t $diskefinum:ef00 -p /dev/$diskefi
	mkfs.vfat -F32 /dev/$diskefi$diskefinum
	return
}

activate_swap()
{
	option=1
	while [ $option != 0 ]
	do
		clear
		echo "*****************************"
		echo "*    Create SWAP from:      *"
		echo "*****************************"
		echo "* 1 - Logical Volume (LV)   *"
		echo "* 2 - Raid Array            *"
		echo "* 3 - Partition             *"
		echo "*****************************"
		echo "* 0 - Exit                  *"
		echo "*****************************"
		echo -n ": "
		read dellayouts
		clear
		case $dellayouts in
			1)
				clear
				echo "*********************************************"
				lvs
				echo "*********************************************"
				echo ""
				echo -n "VG: "
				read vgswapvol
				echo ""
				echo -n "SWAP Volume: "
				read swapvol
				mkswap /dev/$vgswapvol/$swapvol
				swapon /dev/$vgswapvol/$swapvol
			;;
			2)
				clear
				echo "*********************************************"
				cat /proc/mdstat
				echo "*********************************************"
				echo ""
				echo -n "SWAP Volume: "
				read swapvol
				mkswap /dev/$swapvol
				swapon /dev/$swapvol
			;;
			3)
				clear
				echo "*********************************************"
				lsblk | grep part
				echo "*********************************************"
				echo ""
				echo -n "SWAP Volume: "
				read swapvol
				mkswap /dev/$swapvol
				swapon /dev/$swapvol
			;;
			0)option=0;;
		esac
	done
	return
}

create_partitions()
{
	questionopt=1
	while [ $questionopt = 1 ]
	do
		clear
		echo "*************************"
		echo "*    Setup Partitions   *"
		echo "*************************"
		echo "* 1 - Edit Disk         *"
		echo "* 2 - Format Partitions *"
		echo "*************************"
		echo "* 0 - Exit              *"
		echo "*************************"
		echo -n ": "
		read option
		clear
		case $option in
			1)
				echo "*********************************************"
				lsblk | grep disk
				echo "*********************************************"
				echo ""
				echo -n "Disk: "
				read disk
				cgdisk /dev/$disk
			;;
			2)
				echo "*********************************************"
				lsblk | grep disk
				echo "*********************************************"
				echo ""
				echo -n "Disk: "
				read disk
				clear
				echo "************************************************"
				lsblk /dev/$disk
				echo "************************************************"
				echo ""
				echo -n "Partition: "
				read part
				echo ""	
				echo -n "Format: "
				read formatpart
				mkfs.$formatpart /dev/$part
			;;
			0)questionopt=0;;
		esac
	done
	return
}

create_raid()
{
	questionopt=1
	while [ $questionopt = 1 ]
	do
		clear
		echo "*************************"
		echo "*      Setup Raid       *"
		echo "*************************"
		echo "* 1 - Create Raid Array *"
		echo "* 2 - Format Raid Array *"
		echo "*************************"
		echo "* 0 - Exit              *"
		echo "*************************"
		echo -n ": "
		read option
		clear
		case $option in
			1)
				echo "*******************************************"
				echo " NOTE: Your Raid Array must look like this "
				echo "*******************************************"
				echo "* For /boot: raid1 & metadata 1.0         *"
				echo "* For swap: raid0                         *"
				echo "* For all others: Raid0, 1, 10            *"
				echo "*******************************************"
				read ok
				clear
				echo "*********************************************"
				cat /proc/mdstat
				echo "*********************************************"
				lsblk | grep part
				echo "*********************************************"
				echo ""
				echo -n "Raid Name: "
				read raidname
				echo ""
				echo -n "Raid Level: "
				read raidlevel
				echo ""
				echo -n "Number of Partitions: "
				read numpart
				echo ""
				echo -n "Partitions (sd[][]): "
				read part
				echo ""
				echo -n "Metadata (Press Enter for default): "
				read metadatasel
				if [ -z $metadatasel ]
				then
					mdadm -v --create /dev/$raidname --level=raid$raidlevel --raid-devices=$numpart /dev/$part
				else
					mdadm -v --create /dev/$raidname --level=raid$raidlevel --raid-devices=$numpart --metadata=$metadatasel /dev/$part
				fi
			;;
			2)
				echo "*********************************************"
				cat /proc/mdstat
				echo "*********************************************"
				echo ""
				echo -n "Raid Array: "
				read disk
				echo ""
				echo -n "Format: "
				read formatpart
				mkfs.$formatpart /dev/$disk
			;;	
			0)questionopt=0;;
		esac
	done
	return
}

create_lvm()
{
	questionopt=1
	while [ $questionopt = 1 ]
	do
		clear
		echo "******************************"
		echo "*         Setup LVM          *"
		echo "******************************"
		echo "* 1 - Create Physical Volume *"
		echo "* 2 - Create Volume Group    *"
		echo "* 3 - Create Logical Volume  *"
		echo "******************************"
		echo "* 0 - Exit                   *"
		echo "******************************"
		echo -n ": "
		read option
		clear
		case $option in
			1)
				questiono=1
				while [ $questiono = 1 ]
				do
					clear
					echo "******************************"
					echo "*       Physical Volume      *"
					echo "******************************"
					echo "* 1 - Create from Partition  *"
					echo "* 2 - Create from Raid Array *"
					echo "******************************"
					echo "* 0 - Exit                   *"
					echo "******************************"
					echo -n ": "
					read optionpv
					clear
					case $optionpv in
						1)
							clear
							echo "*********************************************"
							lsblk | grep disk
							echo "*********************************************"
							echo ""
							echo -n "Disk: "
							read disk
							clear
							echo "************************************************"
							lsblk /dev/$disk
							echo "************************************************"
							echo ""
							echo -n "Partition: "
							read part
							pvcreate /dev/$part
						;;
						2)
							clear
							echo "*********************************************"
							cat /proc/mdstat
							echo "*********************************************"
							echo ""
							echo -n "Raid Array: "
							read raidarray
							pvcreate /dev/$raidarray
						;;
						0)questiono=0;;
					esac
				done
			;;
			2)
				clear
				echo "*********************************************"
				pvs
				echo "*********************************************"
				echo ""
				echo -n "PV: "
				read physvolume
				echo ""
				echo -n "VG Name: "
				read volumegroupname
				vgcreate $volumegroupname $physvolume
			;;
			3)
				clear
				echo "*********************************************"
				vgs
				echo "*********************************************"
				echo ""
				echo -n "VG: "
				read volumegroup
				echo ""
				echo -n "LV Name: "
				read volumeNAME
				echo ""
				echo -n "LV Size [XXXm (Megabytes)/XXXg(Gigabytes)]: "
				read volumeSIZE
				echo ""
				echo -n "Format: "
				read formattype
				lvcreate -L $volumeSIZE -n $volumeNAME /dev/$volumegroup
				vgchange -ay
				mkfs.$formattype /dev/$volumegroup/$volumeNAME
			;;
			0)questionopt=0;;
		esac
	done
	return
}

mount_filesystem()
{
	partprobe -s
	optionmount=1
	while [ $optionmount != 0 ]
	do
		clear
		echo ""
		echo "*********************"
		echo "* Mount File System *"
		echo "*********************"
		echo "* 1 - Partition     *"
		echo "* 2 - Raid          *"
		echo "* 3 - LVM           *"
		echo "*********************"
		echo "* 0 - Exit          *"
		echo "*********************"
		echo -n ": "
		read optionmount
		clear
		case $optionmount in
			1)
				clear
				echo "************************************************"
				lsblk | grep part
				echo "************************************************"
				echo ""
				echo -n "Partition: "
				read mountpart
				echo ""
				echo -n "Mount Point (Default: / -> /mnt)]: "
				read mountpoint
				checkout=$(lsblk --fs /dev/$mountpart | grep btrfs)
				clear
				echo ""
				echo "Mount Options"
				echo "************************************************"
				echo ""
				if [ -z "$checkout" ]
				then
					echo -n "(ex.defaults,remount,noatime,etc...): "
				else
					echo "(ex.defaults,remount,noatime,"
					echo "space_cache,compress=lzo,autodefrag,"
					echo -n "ssd,recovery,degraded,etc...): "
				fi
				read mountopt
				if [ -z $mountpoint ]
				then
					mountpoint="/mnt"
				fi
				if [ $mountpoint = "/mnt" ]
				then
					if [ -z "$checkout" ]
					then
						btrfsopt=0
					else
						btrfsopt=1
					fi
				fi
				if [ $mountpoint != "/mnt" ]
				then
					if [ $btrfsopt = 1 ]
					then
						subvolopt=1
						while [ $subvolopt = 1 ]
						do
							clear
							echo ""
							echo -n "Create subvolume? (yes/no): "
							read subvolpart
							if [ $subvolpart = "yes" ]
							then
								btrfs subvolume create $mountpoint
								subvolopt=0
							fi
							if [ $subvolpart = "no" ]
							then
								subvolopt=0
								mkdir -p $mountpoint
							fi
						done
					else
						mkdir -p $mountpoint
					fi
				fi
				if [ -z $mountopt ]
				then
					mount /dev/$mountpart $mountpoint
				else
					mount /dev/$mountpart $mountpoint -o $mountopt
				fi
			;;
			2)
				clear
				echo "************************************************"
				cat /proc/mdstat
				echo "************************************************"
				echo ""
				echo -n "Raid Array: "
				read mountpart
				echo ""
				echo -n "Mount Point (Default: / -> /mnt)]: "
				read mountpoint
				checkout=$(lsblk --fs /dev/$mountpart | grep btrfs)
				clear
				echo ""
				echo "Mount Options"
				echo "************************************************"
				echo ""
				if [ -z "$checkout" ]
				then
					echo -n "(ex.defaults,remount,noatime,etc...): "
				else
					echo "(ex.defaults,remount,noatime,"
					echo "space_cache,compress=lzo,autodefrag,"
					echo -n "ssd,recovery,degraded,etc...): "
				fi
				read mountopt
				if [ -z $mountpoint ]
				then
					mountpoint="/mnt"
				fi
				if [ $mountpoint = "/mnt" ]
				then
					if [ -z "$checkout" ]
					then
						btrfsopt=0
					else
						btrfsopt=1
					fi
				fi
				if [ $mountpoint != "/mnt" ]
				then
					if [ $btrfsopt = 1 ]
					then
						subvolopt=1
						while [ $subvolopt = 1 ]
						do
							clear
							echo ""
							echo -n "Create subvolume? (yes/no): "
							read subvolpart
							if [ $subvolpart = "yes" ]
							then
								btrfs subvolume create $mountpoint
								subvolopt=0
							fi
							if [ $subvolpart = "no" ]
							then
								subvolopt=0
								mkdir -p $mountpoint
							fi
						done
					else
						mkdir -p $mountpoint
					fi
				fi
				if [ -z $mountopt ]
				then
					mount /dev/$mountpart $mountpoint
				else
					mount /dev/$mountpart $mountpoint -o $mountopt
				fi
			;;
			3)
				echo "************************************************"
				lvs
				echo "************************************************"
				echo ""
				echo -n "VG: "
				read mountVG
				echo ""
				echo -n "LV: "
				read mountpart
				echo ""
				echo -n "Mount Point (Default: / -> /mnt)]: "
				read mountpoint
				checkout=$(lsblk --fs /dev/$mountVG/$mountpart | grep btrfs)
				clear
				echo "Mount Options"
				echo "************************************************"
				echo ""
				if [ -z "$checkout" ]
				then
					echo -n "(ex.defaults,remount,noatime,etc...): "
				else
					echo "(ex.defaults,remount,noatime,"
					echo "space_cache,compress=lzo,autodefrag,"
					echo -n "ssd,recovery,degraded,etc...): "
				fi
				read mountopt
				if [ -z $mountpoint ]
				then
					mountpoint="/mnt"
				fi
				if [ $mountpoint = "/mnt" ]
				then
					if [ -z "$checkout" ]
					then
						btrfsopt=0
					else
						btrfsopt=1
					fi
				fi
				if [ $mountpoint != "/mnt" ]
				then
					if [ $btrfsopt = 1 ]
					then
						subvolopt=1
						while [ $subvolopt = 1 ]
						do
							clear
							echo ""
							echo -n "Create subvolume? (yes/no): "
							read subvolpart
							if [ $subvolpart = "yes" ]
							then
								btrfs subvolume create $mountpoint
								subvolopt=0
							fi
							if [ $subvolpart = "no" ]
							then
								subvolopt=0
								mkdir -p $mountpoint
							fi
						done
					else
						mkdir -p $mountpoint
					fi
				fi
				if [ -z $mountopt ]
				then
					mount /dev/$mountVG/$mountpart $mountpoint
				else
					mount /dev/$mountVG/$mountpart $mountpoint -o $mountopt
				fi
				;;
			0)optionmount=0;;
		esac
	done
	return
}

refind_setup()
{
	questionopt=1
	while [ $questionopt = 1 ]
	do
		clear
		echo "************"
		echo "*  Refind  *"
		echo "************"
		echo "* 1 - ia32 *"
		echo "* 2 - x64  *"
		echo "************"
		echo -n ": "
		read option
		clear
		case $option in
			1)
				pacstrap /mnt refind-efi
				arch-chroot /mnt /bin/bash -c 'mkdir -p /boot/efi/EFI/refind/'
				arch-chroot /mnt /bin/bash -c 'mkdir -p /boot/efi/EFI/tools/drivers/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/lib/refind/config/refind.conf /boot/efi/EFI/refind/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/share/refind/icons /boot/efi/EFI/refind/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/lib/refind/config/refind_linux.conf /boot/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/lib/refind/refind_ia32.efi /boot/efi/EFI/refind/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/lib/refind/drivers_ia32/* /boot/efi/EFI/tools/drivers/'
				arch-chroot /mnt /bin/bash -c 'sed -i "s/#textonly/textonly/" "/boot/efi/EFI/refind/refind.conf"'
				arch-chroot /mnt /bin/bash -c 'sed -i "s/#scan_driver_dirs EFI\/tools\/drivers,drivers/scan_driver_dirs EFI\/tools\/drivers,drivers/" "/boot/efi/EFI/refind/refind.conf"'
				# arch-chroot /mnt /bin/bash -c 'sed -i "s/#scan_delay 5/scan_delay 5/" "/boot/efi/EFI/refind/refind.conf"'
				arch-chroot /mnt /bin/bash -c 'sed -i "s/codepage=cp437/codepage=437/" "/etc/fstab"'
				rootpart=$(df -k /mnt)
				uuidcode=$(blkid -s UUID -o value $rootpart)
				typecode=$(blkid -s TYPE -o value $rootpart)
				arch-chroot /mnt /bin/bash -c "sed -i 's/root=PARTUUID=XXXXXXXX rootfstype=XXXX ro/root=UUID=$uuidcode rootfstype=$typecode ro/' '/boot/refind_linux.conf'"
				# arch-chroot /mnt /bin/bash -c 'sed -i "s/#dont_scan_dirs ESP:\/EFI\/boot,EFI\/Dell/dont_scan_dirs \/EFI\/boot/" "/boot/efi/EFI/refind/refind.conf"'
				arch-chroot /mnt /bin/bash -c 'echo "\EFI\refind\refind_ia32.efi" > /boot/efi/startup.nsh'
				arch-chroot /mnt /bin/bash -c "efibootmgr -c -g -d /dev/$diskefi -p $diskefinum -w -L "rEFInd" -l '\EFI\refind\refind_ia32.efi'"
				questionopt=0
			;;
			2)
				pacstrap /mnt refind-efi
				arch-chroot /mnt /bin/bash -c 'mkdir -p /boot/efi/EFI/refind/'
				arch-chroot /mnt /bin/bash -c 'mkdir -p /boot/efi/EFI/tools/drivers/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/lib/refind/config/refind.conf /boot/efi/EFI/refind/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/share/refind/icons /boot/efi/EFI/refind/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/lib/refind/config/refind_linux.conf /boot/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/lib/refind/refind_x64.efi /boot/efi/EFI/refind/'
				arch-chroot /mnt /bin/bash -c 'cp -r /usr/lib/refind/drivers_x64/* /boot/efi/EFI/tools/drivers/'
				arch-chroot /mnt /bin/bash -c 'sed -i "s/#textonly/textonly/" "/boot/efi/EFI/refind/refind.conf"'
				arch-chroot /mnt /bin/bash -c 'sed -i "s/#scan_driver_dirs EFI\/tools\/drivers,drivers/scan_driver_dirs EFI\/tools\/drivers,drivers/" "/boot/efi/EFI/refind/refind.conf"'
				# arch-chroot /mnt /bin/bash -c 'sed -i "s/#scan_delay 5/scan_delay 5/" "/boot/efi/EFI/refind/refind.conf"'
				arch-chroot /mnt /bin/bash -c 'sed -i "s/codepage=cp437/codepage=437/" "/etc/fstab"'
				rootpart=$(df -k /mnt)
				uuidcode=$(blkid -s UUID -o value $rootpart)
				typecode=$(blkid -s TYPE -o value $rootpart)
				arch-chroot /mnt /bin/bash -c "sed -i 's/root=PARTUUID=XXXXXXXX rootfstype=XXXX ro/root=UUID=$uuidcode rootfstype=$typecode ro/' '/boot/refind_linux.conf'"
				# arch-chroot /mnt /bin/bash -c 'sed -i "s/#dont_scan_dirs ESP:\/EFI\/boot,EFI\/Dell/dont_scan_dirs \/EFI\/boot/" "/boot/efi/EFI/refind/refind.conf"'
				arch-chroot /mnt /bin/bash -c 'echo "\EFI\refind\refind_x64.efi" > /boot/efi/startup.nsh'
				arch-chroot /mnt /bin/bash -c "efibootmgr -c -g -d /dev/$diskefi -p $diskefinum -w -L "rEFInd" -l '\EFI\refind\refind_x64.efi'"
				questionopt=0
			;;
		esac
	done
	return
}

grub_setup()
{
	questionopt=1
	while [ $questionopt = 1 ]
	do
		clear
		echo "************"
		echo "*   Grub   *"
		echo "************"
		echo "* 1 - ia32 *"
		echo "* 2 - x64  *"
		echo "************"
		echo -n ": "
		read option
		clear
		case $option in
			1)
				pacstrap /mnt grub-efi-i386 os-prober
				arch-chroot /mnt /bin/bash -c 'sed -i "s/codepage=cp437/codepage=437/" "/etc/fstab"'
				arch-chroot /mnt /bin/bash -c 'grub-install --target=i386-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck --debug'
				arch-chroot /mnt /bin/bash -c 'mkdir -p /boot/grub/locale'
				arch-chroot /mnt /bin/bash -c 'cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo'
				arch-chroot /mnt /bin/bash -c 'echo "\EFI\arch_grub\grubia32.efi" > /boot/efi/startup.nsh'
				arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
				questionopt=0
			;;
			2)
				pacstrap /mnt grub-efi-x86_64 os-prober
				arch-chroot /mnt /bin/bash -c 'sed -i "s/codepage=cp437/codepage=437/" "/etc/fstab"'
				arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck --debug'
				arch-chroot /mnt /bin/bash -c 'mkdir -p /boot/grub/locale'
				arch-chroot /mnt /bin/bash -c 'cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo'
				arch-chroot /mnt /bin/bash -c 'echo "\EFI\arch_grub\grubx64.efi" > /boot/efi/startup.nsh'
				arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
				questionopt=0
			;;
		esac
	done
	
	return
}

base_system()
{
	questionopt=1
	while [ $questionopt = 1 ]
	do
		clear
		echo -n "Activate UEFI Support? (yes/no): "
		read question
		if [ $question = yes ]
		then
			uefiopt=1
			questionopt=0
		fi
		if [ $question = no ]
		then
			uefiopt=0
			questionopt=0
		fi
	done
	questionopt=1
	while [ $questionopt = 1 ]
	do
		clear
		echo -n "Activate Raid Support? (yes/no): "
		read question
		if [ $question = yes ]
		then
			raidopt=1
			questionopt=0
		fi
		if [ $question = no ]
		then
			raidopt=0
			questionopt=0
		fi
	done
	questionopt=1
	while [ $questionopt = 1 ]
	do
		clear
		echo -n "Activate LVM Support? (yes/no): "
		read question
		if [ $question = yes ]
		then
			lvmopt=1
			questionopt=0
		fi
		if [ $question = no ]
		then
			lvmopt=0
			questionopt=0
		fi
	done
	clear
	echo "Installing Packages..."
	echo "************************************************"
	pacstrap /mnt base base-devel
	pacstrap /mnt syslinux gptfdisk sudo alsa-utils btrfs-progs dosfstools ntfsprogs wireless_tools wpa_supplicant rfkill linux-headers
	clear
	echo "Generating fstab..."
	echo "************************************************"
	genfstab -U -p /mnt > /mnt/etc/fstab
	clear
	echo "Setting Up mkinitcpio..."
	echo "************************************************"
	arch-chroot /mnt /bin/bash -c 'sed -i "s/HOOKS=\"base udev autodetect modconf block filesystems keyboard fsck\"/HOOKS=\"base udev autodetect block filesystems\"/" "/etc/mkinitcpio.conf"'
	arch-chroot /mnt /bin/bash -c 'sed -i "s/#COMPRESSION=\"xz\"/COMPRESSION=\"xz\"/" "/etc/mkinitcpio.conf"'
	if [ $lvmopt = 1 ]
	then
		arch-chroot /mnt /bin/bash -c 'sed -i "s/HOOKS=\"base udev autodetect block/HOOKS=\"base udev autodetect block lvm2/" "/etc/mkinitcpio.conf"'
	fi
	if [ $raidopt = 1 ]
	then
		clear
		echo "Adding RAID arrays for mdadm auto-dectection..."
		echo "************************************************"
		arch-chroot /mnt /bin/bash -c 'mdadm --examine --scan > /etc/mdadm.conf'
		arch-chroot /mnt /bin/bash -c 'sed -i "s/HOOKS=\"base udev autodetect block/HOOKS=\"base udev autodetect block mdadm_udev/" "/etc/mkinitcpio.conf"'
		arch-chroot /mnt /bin/bash -c 'sed -i "s/MODULES=\"\"/MODULES=\"dm_mod\"/" "/etc/mkinitcpio.conf"'
	fi
	arch-chroot /mnt /bin/bash -c "mkinitcpio -p linux"
	clear
	echo "Setting Up User Permittions..."
	echo "************************************************"
	arch-chroot /mnt /bin/bash -c "sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' '/etc/sudoers'"
	clear
	echo "Setting Up Boot Loader..."
	echo "************************************************"
	arch-chroot /mnt /bin/bash -c "syslinux-install_update -i -a -m"
	rootpart=$(df -k /mnt)
	uuidcode=$(blkid -s UUID -o value $rootpart)
	arch-chroot /mnt /bin/bash -c "sed -i 's/APPEND root=\/dev\/sda3 ro/APPEND root=UUID=$uuidcode ro/' '/boot/syslinux/syslinux.cfg'"
	if [ $uefiopt = 1 ]
	then
		questionopt=1
		while [ $questionopt = 1 ]
		do
			clear
			echo "**************"
			echo "*    UEFI    *"
			echo "**************"
			echo "* 1 - GRUB   *"
			echo "* 2 - rEFInd *"
			echo "**************"
			echo -n ": "
			read option
			clear
			case $option in
				1)
					grub_setup
					questionopt=0
				;;
				2)
					refind_setup
					questionopt=0;;
			esac
		done
	fi
	return
}

setup_system()
{
	clear
	echo -n "Choose Keyboard Layout (Default: pt-latin1): "
	read klayout
	if [ -z $klayout ]
	then
		klayout=pt-latin1
	fi
	arch-chroot /mnt /bin/bash -c "loadkeys $klayout"
	arch-chroot /mnt /bin/bash -c "echo KEYMAP=$klayout > /etc/vconsole.conf"
	clear
	echo ""
	echo -n "Choose Language (Default: pt_PT): "
	read setlang
	if [ -z $setlang ]
	then
		setlang="pt_PT"
	fi
	arch-chroot /mnt /bin/bash -c "sed -i 's/#$setlang/$setlang/' '/etc/locale.gen'"
	clear
	arch-chroot /mnt /bin/bash -c "locale-gen"
	echo ""
	echo -n "Select Locale (Default: $setlang.UTF-8): "
	read sellocal
	if [ -z $sellocal ]
	then
		sellocal=$setlang.UTF-8
	fi
	arch-chroot /mnt /bin/bash -c "echo LANG=$sellocal > /etc/locale.conf"
	arch-chroot /mnt /bin/bash -c "export LANG=$sellocal"
	echo ""
	echo -n "Localtime (Default: '/usr/share/zoneinfo/Europe/Lisbon'): "
	read setlocaltime
	if [ -z $setlocaltime ]
	then
		setlocaltime="/usr/share/zoneinfo/Europe/Lisbon"
	fi
	arch-chroot /mnt /bin/bash -c "ln -s $setlocaltime /etc/localtime"
	arch-chroot /mnt /bin/bash -c "hwclock --systohc --utc"
	clear
	echo -n "Hostname: "
	read htsname
	arch-chroot /mnt /bin/bash -c "echo $htsname > /etc/hostname"
	clear
	echo "Root"
	echo "*******************************************"
	arch-chroot /mnt /bin/bash -c "passwd"
	clear
	echo -n "New User: "
	read username
	arch-chroot /mnt /bin/bash -c "useradd -m -g users -G wheel -s /bin/bash $username"
	arch-chroot /mnt /bin/bash -c "passwd $username"
	return
}

create_filesystem()
{
	mainopt4=1
	while [ $mainopt4 = 1 ]
	do
		clear
		echo "****************************"
		echo "*        Disk Setup        *"
		echo "****************************"
		echo "* 1 - Create Partition     *"
		echo "* 2 - Create Raid Array    *"
		echo "* 3 - Create LVM           *"
		echo "* 4 - Create EFI Partition *"
		echo "* 5 - Activate SWAP        *"
		echo "****************************"
		echo "* 0 - Exit                 *"
		echo "****************************"
		echo -n ": "
		read options
		clear
		case $options in
			1)create_partitions;;
			2)create_raid;;
			3)create_lvm;;
			4)create_efipart;;
			5)activate_swap;;
			0)mainopt4=0;;
		esac
	done
	return
}

modprobe efivars
swapoff -a
mainopt=1
while [ $mainopt = 1 ]
do
	clear
	echo "***************************"
	echo "*      Arch Install       *"
	echo "***************************"
	echo "* 1 - Working Space       *"
	echo "* 2 - Network Connection  *"
	echo "* 3 - Delete Disk Layout  *"
	echo "* 4 - Edit Disk Layout    *"
	echo "* 5 - Mount File System   *"
	echo "* 6 - Install Base System *"
	echo "* 7 - Setup Base System   *"
	echo "***************************"
	echo "* 0 - Exit                *"
	echo "***************************"
	echo -n ": "
	read options
	clear
	case $options in
		1)working_space;;
		2)set_connection;;
		3)search_old_setups;;
		4)create_filesystem;;
		5)mount_filesystem;;
		6)base_system;;
		7)setup_system;;
		0)exit;;
	esac
	mainopt=1
done
