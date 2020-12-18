# SpeechTranscription
Example script and code to use the Azure Speech Cognitive Service to translate and transcribe multiple audio files.

# Script

processfiles.ps1 is a single file that sequentially converts the audio files, transcribes via Azure Speech Services and then uploads to Azure Storage. Alternatively the sames steps have been broken out into:
- transcribe.ps1: loops through the audio files, converting, transcribing and then deleting the converted audio file to avoid doubling the audio file storage requirements
- upload.ps1: uploads the transcribed text files to Azure storage 

# Function

An example function with a Blob trigger that takes new files, extracts the transcription data and writes it to CosmosDB