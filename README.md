# raw-mount

## Overview

Raw-mount and raw-umount are simple Powershell scripts for mounting and unmounting raw binary disk images (like created by GNU/Linux tool 'dd'), mainly of SD cards, on Windows.

As I could not find a way to mount such raw binary disk images in Windows, I created raw-mount. It first appends a 512 byte VHD footer (fixed size type) at the end of the image file and then serves as a wrapper for Windows' DISKPART tool, that can mount VHD image files.

The raw-umount script does the opposite: First it makes DISKPART unmount the VHD image file and then attempts to strip the VHD footer from the image file, resulting in an image in the original, raw binary format.

## Limitations

Note: This code has been used and tested with very limited number of FAT-formatted SD card disk images. It may not work correctly or at all with image of, say, a partitioned Ext4 1TB disk. More testing and features may come in the future.

Note: DISKPART will prompt for right elevation. Execute as Administrator for no prompt.

## Usage examples

Typical use case:

1. Mount the image as a disk in Windows:

`.\raw-mount.ps1 -imageFile sd_card.bin`

2. Use the mounted disk in Windows, change the disk contents (edit files, add new files, etc.)

3. Unmount the image (resulting image file will contain your changes done to disk):

`.\raw-umount.ps1 -imageFile sd_card.bin`

raw-mount adheres to Powershell's Get-Help:

`Get-Help -Full .\raw-mount.ps1`

raw-mount adheres to Powershell's verbose output flag:

`.\raw-mount.ps1 -Verbose -imageFile sd_card.bin`
