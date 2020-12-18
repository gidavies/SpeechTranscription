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
# AzCopy installed and added to system path (see https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10?WT.mc_id=thomasmaurer-blog-thmaure)
# PowerShell Azure module installed (see https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.2.0)

# File locations and languages
$translationsfolder = "C:\audio\transcripts"
# Azure storage blob related variables
$subscriptionId = "REPLACE_WITH_AZURE_SUBSCRIPTION_ID"
$storageAccountRG = "audio-rg"
$storageAccountName = "gdaudiostorage"
$storageContainerName = "translations"
# Number of seconds this script will be able to access the storage blob containing the translations
# 86400 secs (24 hours) but change to the minimum time needed
$sastokenlength = 86400 

Write-Output ("`nUpload transcription files from " + $translationsfolder + " to Azure blob storage")
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
$filestoupload = $translationsfolder + "\*\*.csv"
azcopy copy $filestoupload $containerSASURI --recursive

Write-Output ("`nComplete. Transcriptions copied to Azure storage " + $storageAccountName + "\" + $storageContainerName)
Write-Output ("============================================================================================`n")