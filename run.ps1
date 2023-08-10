# Set the path to the MKVToolNix installation directory
$mkvtoolnixPath = "C:\Program Files\MKVToolNix"

# Set the directory containing input MKV files and image files
$directoryPath = ".\"

# Loop through each MKV file in the directory
$mkvFiles = Get-ChildItem -Path $directoryPath -Filter "*.mkv" -File
foreach ($mkvFile in $mkvFiles) {

    # Set the input MKV file path
    $inputFile = $mkvFile.FullName

    # Get audio and subtitle track information using mkvmerge
    $audioInfo = & "$mkvtoolnixPath\mkvmerge.exe" -J "$inputFile" | ConvertFrom-Json
    Write-Output "Updating $inputFile"
    $audioTracks = $audioInfo.tracks | Where-Object { 
        $_.type -eq "audio" 
    }

    # Determine audio type and set the new audio title
    foreach ($audioTrack in $audioTracks) {
        $audioType = $audioTrack.properties.track_name
        # You might need to adjust the conditions below to match your audio type labels
        if ($audioType -like "*stereo*") {
            $newAudioTitle = "Feature (Stereo)"
        } elseif ($audioType -like "*surround*") {
            $newAudioTitle = "Feature (Surround)"
        } elseif ($audioType -like "*mono*") {
            $newAudioTitle = "Feature (Mono)"
        } else {
            $newAudioTitle = "Feature (Unknown)"
        }

        # Build the command to update the audio track title using mkvpropedit
        $audioTrackNumber = $audioTrack.properties.uid
        $audioCommand = "$mkvtoolnixPath\mkvpropedit.exe"
        $audioArguments = "--edit track:$audioTrackNumber --set name=`"$newAudioTitle`" `"$inputFile`""

        # Execute the audio track command
        Start-Process -FilePath $audioCommand -ArgumentList $audioArguments -Wait
    }

    # Get subtitle track information using mkvmerge
    $subtitleInfo = & "$mkvtoolnixPath\mkvmerge.exe" -J "$inputFile" | ConvertFrom-Json
    $subtitleTrack = $subtitleInfo.tracks | Where-Object { $_.type -eq "subtitles" } | Select-Object -First 1

    # Build the command to update the subtitle track title and set it as the default track using mkvpropedit
    $subtitleTrackNumber = $subtitleTrack.properties.uid
    $subtitleCommand = "$mkvtoolnixPath\mkvpropedit.exe"
    $subtitleArguments = "--edit track:$subtitleTrackNumber --set name=`"Feature`" --set flag-default=1 `"$inputFile`""

    # Execute the subtitle track command
    Start-Process -FilePath $subtitleCommand -ArgumentList $subtitleArguments -Wait

    # Set the path to the image file for attachment
    $imageFileName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile) + "-Poster.png"
    $imageFilePath = Join-Path -Path $directoryPath -ChildPath $imageFileName

    #Write-Output $imageFilePath

    # Build the command to attach the image using mkvpropedit
    #$imageAttachmentCommand = "$mkvtoolnixPath\mkvpropedit.exe"
    #$imageAttachmentArguments = "--edit attachments --add `"$imageFilePath`" `"$inputFile`""

    # Execute the image attachment command
    #Start-Process -FilePath $imageAttachmentCommand -ArgumentList $imageAttachmentArguments -Wait

    # Build the command to update the title using mkvpropedit
    $titleCommand = "$mkvtoolnixPath\mkvpropedit.exe"
    $titleArguments = "--edit info --set title=`"$inputFile`" `"$inputFile`""

    # Execute the command
    Start-Process -FilePath $titleCommand -ArgumentList $titleArguments -Wait

}
