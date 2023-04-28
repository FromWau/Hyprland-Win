# Boot into the windows iso, press SHIFT + F10 and run: diskpart

## DISKPART
### list disk
list disk

### select disk
select disk <NO.>

### clean disk
clean

### convert disk to gpt for efi partition
convert gpt

### create efi partition
create partition efi size=200
format quick fs=fat32 label=”EFI”

### create MSR partition
create partition msr size=16

### create windows partition
create partition primary size=250000
shrink minimum=450
format quick fs=ntfs label=”WIN”

### create recovery partition (optional) IKD if this works
create partition primary
format quick fs=ntfs label=”WinRE”
set id=”de94bba4-06d1-4d40-a16a-bfd50179d6ac”
