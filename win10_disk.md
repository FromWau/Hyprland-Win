# We need a bigger System (/boot) partition for both windows and linux.
1) First we install Windows until we reach the partition screen. 
2) Select target and make sure it has no partitions.
3) Click 'new' and then the 'apply' buttons. The windows installer will create the partitions.
4) Delete 'System', 'MBR' and 'Primary'. Leave 'Recovery' (if exists) alone.
5) Press SHIFT + F10 and run: diskpart.exe
6) To list the disks: 'list disk'
7) To select the disk we want to install: 'select disk <disk_number>'
8) Create efi partition with: 'create partition efi size=1024'
9) Format the efi partition: 'format quick fs=fat32 label=System'
10) 'exit' to close diskpart and 'exit' to close cmd.
11) Click again 'new' and 'apply'.

Windows should now have the standart partition scheme but with a bigger System partition.

https://wiki.archlinux.org/title/Dual_boot_with_Windows in Section 2.3.5 describes this.
