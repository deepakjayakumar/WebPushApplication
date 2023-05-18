using System;
using System.Configuration;
using System.IO;  
  
namespace PackageTrackingClient
{  
    public class LogWriter  
    {  
        public static bool WriteLog(string logString)  
        {
            FileStream objFilestream;
            StreamWriter objStreamWriter;
            var configuration = new ConfigurationBuilder().AddJsonFile(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "appsettings.json")).Build();
            try  
            {
                string filename = String.Format("{0}.txt",DateTime.Now.ToString("yyyy-MM-dd HH-mm-ss"));
                string fileDirectory = string.Empty;
                //fileDirectory = ConfigurationManager.AppSettings["LogFilePath"];
                fileDirectory = "\\kamisapp1\\wwwroot$\\InfoView\\PackageTracking\\Log\\";// ConfigurationManager.AppSettings["LogFilePath"];
                fileDirectory = "\\kamisapp1\\wwwroot$\\InfoView\\ATab\\Log";// ConfigurationManager.AppSettings["LogFilePath"];
                objFilestream = new FileStream(string.Format("{0}\\{1}", fileDirectory, filename), FileMode.Append, FileAccess.Write);  
                objStreamWriter = new StreamWriter((Stream)objFilestream);  
                objStreamWriter.WriteLine(logString);  
                objStreamWriter.Close();  
                objFilestream.Close();  
                return true;  
            }  
            catch(Exception ex)  
            {
                throw ex; 
            }  
            finally
            { 

             }
        }
        public static bool UpdateResultsToFile(string logString, string fileFormat,string fileName,string folderPath)
        {
            FileStream objFilestream;
            StreamWriter objStreamWriter;
            string outputFileName = string.Empty;
            //string folderPath = string.Empty;
            try
            {
                outputFileName = String.Format("{0}_{1}.{2}", fileName, DateTime.Now.ToString("yyyy-MM-dd HH-mm-ss"), fileFormat);
                //folderPath = ConfigurationManager.AppSettings["LogFilePath"];
                objFilestream = new FileStream(string.Format("{0}\\{1}", folderPath, outputFileName), FileMode.Append, FileAccess.Write);
                objStreamWriter = new StreamWriter((Stream)objFilestream);
                objStreamWriter.WriteLine(logString);
                objStreamWriter.Close();
                objFilestream.Close();
                return true;
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {

            }
        }
    }  
} 