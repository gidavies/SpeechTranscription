# ============================================================
#
# Example script to transcribe and translate audio files from 
# one spoken language to another using the Azure Speech CLI.
# The output files are then uploaded to an Azure storage blob
# for onward processing (e.g. into CosmosDB for searching).
# 
# Not tested or checked for production use.
# 
# ============================================================

# Pre-requisites:
# Azure Speech CLI installed (see https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/spx-basics?tabs=windowsinstall#download-and-install)
# Speech Cognitive service created in Azure
# Install ffmpeg or equivalent to convert audio file formats

# Speech service settings
$speechkey = "REPLACE_WITH_AZURE_SPEECH_COG_SERVICE_KEY"
$speechregion = "uksouth"
# File locations and languages
$spxcli = "C:\spx-netcore30-win-x64\spx"
$originalaudiofolder = "C:\audio\original"
$convertedaudiofolder = "C:\audio\converted"
$translationsfolder = "C:\audio\transcripts"
$originallang = "de-DE"
$translationlang = "en-UK"

Write-Output ("`nTranslate and Transcribe audio files")
Write-Output ("============================================================================================`n")

# Set the Speech Cognitive Service subscription key and region
# Appears to be a bug with setting these in PowerShell so using cmd
cmd /c "$spxcli config @key --set $speechkey"
cmd /c "$spxcli config @region --set $speechregion"

# Get all audio files including in sub folders
$opusfiles = Get-ChildItem -Recurse ($originalaudiofolder + "\*.ogg")

foreach ($opusfile in $opusfiles) {
	try {
        # Get the parent folder (not full path) to mirror the source structure
        $parentpath = $(Get-Item $opusfile).DirectoryName
        $parentfolder = Split-Path $parentpath -Leaf
        
        # Make sure there is an equivalent folder in the converted file path
        $convertedfolder = $convertedaudiofolder + "\" + $parentfolder
        if (!(Test-Path -path $convertedfolder))
        {
            New-Item -Path $convertedfolder -ItemType Directory
        }
        
        # Convert file format
        $convertedfile =  $convertedfolder + "\" + $opusfile.BaseName + ".wav"
        Write-Output ("Converting: " + $opusfile + " to: " + $convertedfile)
        ffmpeg -i $opusfile $convertedfile -y
        
        # Make sure there is an equivalent folder in the translations file path
        $translatedfolder = $translationsfolder + "\" + $parentfolder
        if (!(Test-Path -path $translatedfolder))
        {
            New-Item -Path $translatedfolder -ItemType Directory
        }

        # Transcribe and translate with Azure Speech Services
        $translatedoutput = ($translatedfolder + "\" + $opusfile.BaseName + ".en.csv")
        Write-Output ("Translating and transcribing " + $convertedfile + " to " + $translatedoutput)
        cmd /c "$spxcli translate --file $convertedfile --source $originallang --target $translationlang --output file $translatedoutput"
        
        # Remove the converted sound file. Only space required is for one converted audio file at a time, plus transcriptions
        Remove-Item $convertedfile
    }
	catch {
		Write-Output "$opusfile - $($_.Exception.Message)"
	}
}

Write-Output ("`nComplete. Transcriptions saveed to " + $translatedfolder)
Write-Output ("============================================================================================`n")