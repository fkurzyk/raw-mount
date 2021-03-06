<#
    .SYNOPSIS
    Script for un-mounting raw binary disk images mounted with raw-mount.ps1 in Windows
	.DESCRIPTION
    This script un-mounts VHD fixed hard disk images and the attempts to remove
    the VHD footer.
    This script is supposed to be used for un-mounting raw binary images mounted by
    the raw-mount.ps1 script.
    Script first acts as a wrapper for DISKPART Windows tool that un-mounts the VHD
    fixed hard disk image file and then attempts to truncate the VHD footer from the
    image file. Resulting image file is raw binary disk image which then can be used
    for writing on a physical medium with tools like GNU/Linux 'dd' or Windows
    'Win32DiskImager').
    .NOTES
    Version    : 0.1
    Date       : 2018-11-09
    Author     : Filip Kurzyk - nathanel13@gmail.com
    .LINK
    - TBD -
	.EXAMPLE
	.\raw-umount.ps1 -imageFile sd_card.bin
	This command un-mounts raw binary image file sd_card.bin and attempts to scrip the VHD footer from it.
  #>


[CmdletBinding()]

param(
    [string]$imageFile,
	[bool]$umount=$True,
	[switch]$preserveVhdFooter,
    [switch]$preserveVhdFile
)

$imageFile = "$(Resolve-Path -Path $imageFile)"

#umount

Write-Verbose "attempting to un-mount the image with vhd footer..."

new-item -path "$env:temp" -name "diskpart_umount_script.txt" -itemtype file -force | out-null
add-content -path "$env:temp\diskpart_umount_script.txt" "SELECT VDISK FILE=$imageFile"
add-content -path "$env:temp\diskpart_umount_script.txt" "DETACH VDISK"

diskpart /s $env:temp\diskpart_umount_script.txt

Remove-Item -Path "$env:temp\diskpart_umount_script.txt" 

# wait until file no longer used...
Start-Sleep 5

#truncate vhd footer at the end of the file

if (-not $preserveVhdFooter) {

    Write-Verbose "attempting to truncate vhd footer..."

	[byte[]]$cookieBuffer = @(0)*8
    
    $cookie = ( 0x63, 0x6F, 0x6E, 0x65, 0x63, 0x74, 0x69, 0x78 )
	
	$reader = [IO.File]::OpenRead($imageFile)
    $truncatedImageLength = $reader.Length - 512
	
	$reader.Seek(-512, 'End') | Out-Null
	$readBytesCount = $reader.Read($cookieBuffer, 0, 8)
	
    if ( ($cookieBuffer -join ",") -eq ($cookie -join ",") ) {
    
        $bufferSize = 1024
        [byte[]]$buffer = @(0)*$bufferSize
		
        Write-Verbose "found vhd footer, truncating..."
        
        $writer = [IO.File]::OpenWrite("$($imageFile)_truncated")

        $reader.Seek(0, 'Begin') | Out-Null
        
        while ($reader.Position -lt $truncatedImageLength-$bufferSize) {
            $readBytesCount = $reader.Read($buffer, 0, $bufferSize)
            $writer.Write($buffer, 0, $readBytesCount)
        }
        $remainingBytesCount = $truncatedImageLength - $reader.Position
        $readBytesCount = $reader.Read($buffer, 0, $remainingBytesCount)
        $writer.Write($buffer, 0, $readBytesCount)
        
        $reader.Close()
        $writer.Close()
        

        if (-not $preserveVhdFile) {
            Move-Item -Force -Path "$($imageFile)_truncated" -Destination $imageFile
        }
    
    } else {
    
        Write-Verbose "no vhd footer found! nothing truncated"

    }
}