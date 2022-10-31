# Fix bootrec /rebuildbcd "Total identified Windows installations: 0"
Boot into Windows Install USB > Press Shift+F10 and type:
```
bootrec /fixmbr
BOOTSECT /NT60 SYS
bootrec /fixboot
diskpart
sel dis 0 // system disk
lis vol
sel vol 2 // hidden EFI volume
assign letter=m
exit
m:
cd m:\EFI\Microsoft\Boot
attrib bcd -s -h -r
ren bcd bcd.old
bootrec /RebuildBcd
wpeutil reboot
```
