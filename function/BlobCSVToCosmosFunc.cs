using System.IO;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace GD.Examples
{
    public static class BlobCSVToCosmosFunc
    {
        [FunctionName("BlobCSVToCosmosFunc")]
        public static void Run(
            [BlobTrigger("translations/{name}", Connection = "gdaudiostorage_STORAGE")] 
            Stream myBlob, string name, ILogger log, 
            [CosmosDB(databaseName: "speechdata", collectionName: "translations", CreateIfNotExists = true, ConnectionStringSetting = "CosmosDBConnection")]out dynamic document)
        {
            log.LogInformation($"Extracting speech data from: {name}");

            // Get the contents of the blob
            StreamReader reader = new StreamReader(myBlob);
            
            // Get the last line of the file, exclude header
            string content = "";
            while (reader.EndOfStream == false)
            {
                content = reader.ReadLine();
            }
            reader.Close();
            
            // Parse the content. Speech output files are tab separated.
            string[] values = content.Split('\t');
            
            // Write to CosmosDB
            document = new
            {
                AudioId = values[0], // file name (no extension)
                Sessionid = values[1], // guid from Speech services
                TranscribedText = values[2], // Original language transcription
                TranslatedText = values[3] // Translated language transcription
            };

            log.LogInformation($"Speech data from: {name} saved to database");
        }
    }
}