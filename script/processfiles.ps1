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
# AzCopy installed and added to system path (see https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10?WT.mc_id=thomasmaurer-blog-thmaure)
# PowerShell Azure module installed (see https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.2.0)
# Install ffmpeg or equivalent to convert audio file formats

# Speech service settings
$speechkey = "REPLACE_WITH_AZURE_SPEECH_COG_SERVICE_KEY"
$speechregion = "uksouth"
# File locations and languages
$spxcli = "C:\spx-netcore30-win-x64\spx"
$originalaudiofolder = "C:\audio\original"
$convertedaudiofolder = "C:\audio\converted" # Need to consider disk space, could change script to delete files after translation?
$translationsfolder = "C:\audio\transcripts"
$originallang = "de-DE"
$translationlang = "en-UK"
# Azure storage blob related variables
$subscriptionId = "REPLACE_WITH_AZURE_SUBSCRIPTION_ID"
$storageAccountRG = "audio-rg"
$storageAccountName = "gdaudiostorage"
$storageContainerName = "translations"
# Number of seconds this script will be able to access the storage blob containing the translations
# 86400 secs (24 hours) but change to the minimum time needed
$sastokenlength = 86400 

Write-Output ("`nStep 1/3: Convert Opus OGG files from $originalaudiofolder to Wav file format")
Write-Output ("============================================================================================`n")

$opusfiles = Get-ChildItem ($originalaudiofolder + "\*.ogg")

foreach ($opusfile in $opusfiles) {
	try {
        $convertedfile = $convertedaudiofolder + "\" + $opusfile.BaseName + ".wav"
        Write-Output ("Converting: " + $opusfile + " to: " + $convertedfile)
        ffmpeg -i $opusfile $convertedfile -y
    }
	catch {
		Write-Output "$opusfile - $($_.Exception.Message)"
	}
}

Write-Output ("`nStep 2/3: Translating and transcribing audio from " + $convertedaudiofolder)
Write-Output ("============================================================================================`n")

# Set the Speech Cognitive Service subscription key and region
# Appears to be a bug with setting these in PowerShell so using cmd
cmd /c "$spxcli config @key --set $speechkey"
cmd /c "$spxcli config @region --set $speechregion"

$audiofiles = Get-ChildItem ($convertedaudiofolder + "\*.wav")

foreach ($audiofile in $audiofiles) {
	try {
        $translatedoutput = ($translationsfolder + "\" + $audiofile.BaseName + ".en.csv")
        Write-Output ("Translating and transcribing " + $audiofile + " to " + $translatedoutput)
        cmd /c "$spxcli translate --file $audiofile --source $originallang --target $translationlang --output file $translatedoutput"
    }
	catch {
		Write-Output "$audiofile - $($_.Exception.Message)"
	}
}

Write-Output ("`nStep 3/3: Copying output files to Azure blob storage")
Write-Output ("============================================================================================`n")

# Mostly copied from this blog post: https://techcommunity.microsoft.com/t5/itops-talk-blog/how-to-upload-files-to-azure-blob-storage-using-powershell-and/ba-p/650309
# Connect to Azure
Connect-AzAccount
# List Azure Subscriptions
Get-AzSubscription
# Select right Azure Subscription
Select-AzSubscription -SubscriptionId $SubscriptionId
# Get Storage Account Key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccountRG -AccountName $storageAccountName).Value[0]
# Set AzStorageContext
$destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
# Generate SAS URI
$containerSASURI = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds($sastokenlength) -FullUri -Name $storageContainerName -Permission rw
# Upload files in folder matching specified extension using AzCopy
azcopy copy "$translationsfolder/*.csv" $containerSASURI --recursive

Write-Output ("`nComplete. Transcriptions copied to Azure storage " + $storageAccountName + "\" + $storageContainerName)
Write-Output ("============================================================================================`n")