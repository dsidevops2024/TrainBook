# Get the folder path
$folderPath = "E:\Priyadarshini\Drive E\github"

# Check if the folder exists
if (Test-Path $folderPath -PathType Container) {
    Write-Host "Folder exists: $folderPath"
} else {
    Write-Host "Folder does not exist: $folderPath"
}
