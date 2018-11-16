<#
    .SYNOPSIS
    Script for mounting raw binary disk images in Windows
	.DESCRIPTION
    This script allows to mount raw binary disk images (eg. created by GNU/Linux
    tool 'dd' or by Windows application 'Win32DiskImager').
    Script first appends a VHD footer at the end of the image file and then acts
    as a wrapper for DISKPART Windows tool that mounts the image as a VHD fixed
    hard disk image visible in Windows filesystem as a new disk.
    In order to un-mount the disk image and obtain the resulting disk image in
    a pristine raw binary format, the accompanying raw-umount.ps1 should be used.
    .NOTES
    Version    : 0.1
    Date       : 2018-11-09
    Author     : Filip Kurzyk - nathanel13@gmail.com
    .LINK
    - TBD -
	.EXAMPLE
	.\raw-mount.ps1 -imageFile sd_card.bin
	This command mounts raw binary image file sd_card.bin in Windows as disk.
  #>


[CmdletBinding()]

param(
	[string]$imageFile,
    [bool]$mount=$True,
	[switch]$preserveOriginalImageFile
)

$imageFile = "$(Resolve-Path -Path $imageFile)"

Write-Verbose "calculating vhd footer..."

[byte[]]$vhdFooter = (
#  0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15

0x63, 0x6F, 0x6E, 0x65, 0x63, 0x74, 0x69, 0x78, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0x00, 0x00,
#                cookie                        |        feats          |       fmt ver        |

0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x22, 0xA6, 0xEA, 0xE7, 0x68, 0x61, 0x63, 0x6B,
#             data offset                      |      time stamp       |      creator app     |

0x00, 0x01, 0x00, 0x00, 0x57, 0x69, 0x32, 0x6B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
#       creator ver    |    creator host os    |                original size                 |

0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xEC, 0x10, 0x3F, 0x00, 0x00, 0x00, 0x02,
#                 current size                 |     disk geometry     |     disk type        |

0x00, 0x00, 0x00, 0x00, 0xBB, 0x5B, 0x63, 0x5D, 0x4D, 0xE4, 0x31, 0x46, 0xAA, 0x78, 0x0B, 0xB7,
#      checksum        |                           unique id...

0x71, 0x9B, 0xDF, 0x86, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
#    ...unique id      | svd |                      reserved......

0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
)

function substituteBytes {
    param(
        $targetBytes,   # what to change
        $targetOffset,  # where to change
        $inputLength,   # how long is the substitiution
        $inputBytes     # new bytes to put in
    )

    # Substitution in target happens from last byte to be changed towards the first one
    for ($i = 0; $i -lt $inputLength; $i++) {
        $targetBytes[($targetOffset+$inputLength-1-$i)]=$inputBytes[($i)]
    }

    return $targetBytes
}

#filesize

$fileLen = (Get-Item $imageFile).Length
$fileLenBytes = [BitConverter]::GetBytes($fileLen)
$sizeOffset = 40  # where 'original size' field starts

$vhdFooter = substituteBytes -targetBytes $vhdFooter -targetOffset $sizeOffset -inputLength 8 -inputBytes $fileLenBytes

$sizeOffset = 48  # where 'current size' field starts

$vhdFooter = substituteBytes -targetBytes $vhdFooter -targetOffset $sizeOffset -inputLength 8 -inputBytes $fileLenBytes

#checksum

$checksum = 0
for ($i = 0; $i -lt $vhdFooter.length; $i++) {
    $checksum = $checksum + $vhdFooter[$i]
}

$checksum = (-bnot $checksum)
$checksumBytes = [BitCOnverter]::GetBytes($checksum)
$checksumOffset = 64  # where 'checksum' field starts

$vhdFooter = substituteBytes -targetBytes $vhdFooter -targetOffset $checksumOffset -inputLength 4 -inputBytes $checksumBytes

if ($preserveOriginalImageFile) {
    Write-Verbose "preserving original image file (without vhd footer)..."
    Copy-Item -Path $imageFile -Destination "$($imageFile)_original"
}

Write-Verbose "adding vhd footer to image file..."

Add-Content -Path $imageFile -Value $vhdFooter -Encoding Byte

#mount

Write-Verbose "attempting to mount the image with vhd footer..."

New-Item -Path "$env:temp" -Name "diskpart_mount_script.txt" -Itemtype file -Force | Out-Null
Add-Content -Path "$env:temp\diskpart_mount_script.txt" "SELECT VDISK FILE=$imageFile"
Add-Content -Path "$env:temp\diskpart_mount_script.txt" "ATTACH VDISK"

#diskpart /s $env:temp\diskpart_mount_script.txt

Remove-Item -Path "$env:temp\diskpart_mount_script.txt"