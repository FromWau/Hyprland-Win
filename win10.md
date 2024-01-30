## We need a bigger System (/boot) partition for both windows and linux. And also we want to setup windows.
### Windows partitioning. 

1) Select target and make sure it has no partitions.
2) Click 'new' and then the 'apply' buttons. The windows installer will create the partitions.
3) Delete 'System', 'MBR' and 'Primary'. Leave 'Recovery' (if exists) alone.
4) Press SHIFT + F10 and run: diskpart.exe
5) To list the disks: 'list disk'
6) To select the disk we want to install: 'select disk <disk_number>'
7) Create efi partition with: 'create partition efi size=1024'
8) Format the efi partition: 'format quick fs=fat32 label=System'
9) 'exit' to close diskpart and 'exit' to close cmd.
10) Click again 'new' and 'apply'.

Windows should now have the standart partition scheme but with a bigger System partition.

https://wiki.archlinux.org/title/Dual_boot_with_Windows in Section 2.3.5 describes this.

### Debloat Tool

1) Launch Powershell WITH Admin Priviliges.
2) Run to allow script execution: 'Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Confirm -Force' and hit enter to accept.
3) Run the utility: 'irm https://christitus.com/win | iex'

#### Install software
In Install header:

1) Pick programs to install and click 'Install selected'

#### Tweaks
In Tweaks check:
- Create Restore Point
- Disable Telemetry
- Disable Wifi-Sense
- Disable Active History
- Disable Location Tracking
- Disable Homegroup
- Disable Hibernation (DO NOT select this on a laptop)
- Disable GameDVR
- Set Services to Manual
- Set Time to UTC (ONLY for dual boot)
- Remove all MS Store Apps
- Remove OneDrive

#### Customize Preference
- Enable Dark theme
- Disable Bing Search in Start menu
- Enable NumLock on Startup
- Enable Show File extensions
- Disable Mouse acceleration

#### Performance Plan (Skip on Laptop)
Click 'Add and Activate Ultimate Performance Profile'

### Create a free partition for linux
1) Open Disk Manager by pressing 'Win' + 'x' and running: 'diskmgmt.msc'
2) Resize the windows(primary) partition to make place for linux.

### Post Setup
- Run NVCleanstall (install via winutil)
- Remove missed bloated software
- Check for Updates

### Bluetooth for dual boot setup
TODO
