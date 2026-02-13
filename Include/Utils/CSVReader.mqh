#ifndef __CSV_READER_H__
#define __CSV_READER_H__
//+------------------------------------------------------------------+
//| CSVReader.mqh                                                    |
//| Lightweight CSV reader for last-record extraction.               |
//| Dependencies: none                                                |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+

class CCSVReader
{
public:
   CCSVReader() {}
   ~CCSVReader() {}

   bool ReadLastRecord(const string filePath, string &headers[], string &values[])
   {
      const int h = FileOpen(filePath, FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ | FILE_COMMON);
      if(h == INVALID_HANDLE)
      {
         Print("CCSVReader.ReadLastRecord open failed: ", filePath, " err=", GetLastError());
         return false;
      }

      if(FileIsEnding(h))
      {
         FileClose(h);
         return false;
      }

      const string headerLine = FileReadString(h);
      if(StringLen(headerLine) == 0)
      {
         FileClose(h);
         return false;
      }

      StringSplit(headerLine, ',', headers);

      string lastLine = "";
      while(!FileIsEnding(h))
      {
         const string line = FileReadString(h);
         if(StringLen(line) > 0)
            lastLine = line;
      }
      FileClose(h);

      if(StringLen(lastLine) == 0)
         return false;

      StringSplit(lastLine, ',', values);
      return ArraySize(values) > 0;
   }
};

#endif
