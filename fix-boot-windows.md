# Fix bootrec /rebuildbcd "Total identified Windows installations: 0"
Boot into Windows Install USB > Press Shift+F10 and type:
```
bootrec /fixmbr
bootsect /nt60 sys
bootrec /fixboot
diskpart
sel dis 0 // system disk
lis vol
sel vol 2 // hidden EFI volume*
ass letter=m
exit
m:
cd m:\EFI\Microsoft\Boot
attrib bcd -s -h -r
ren bcd bcd.old
bootrec /rebuildbcd
wpeutil reboot
```

* if 100MB ESP volume is missing
```
sel par 2 // primary partition
shr desired=100
cre par efi size=100
for fs=fat32
ass letter=m
bcdboot C:\Windows /s M: /f UEFI
```
