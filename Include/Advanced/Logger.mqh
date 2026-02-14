#ifndef __LOGGER_H__
#define __LOGGER_H__
//+------------------------------------------------------------------+
//| Logger.mqh                                                       |
//| Persian daily logger with multiple levels.                       |
//| Dependencies: none                                                |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+

class CLogger
{
private:
   bool   m_enabled;
   string m_logPath;

   string BuildFileName() const
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      return m_logPath + StringFormat("%04d%02d%02d.log", dt.year, dt.mon, dt.day);
   }

   void WriteLine(const string level, const string message) const
   {
      if(!m_enabled)
         return;

      const string fileName = BuildFileName();
      const int h = FileOpen(fileName, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_SHARE_WRITE | FILE_COMMON);
      if(h == INVALID_HANDLE)
      {
         Print("Logger open failed: ", fileName, " err=", GetLastError());
         return;
      }

      FileSeek(h, 0, SEEK_END);
      const string line = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + " - " + level + " - " + message;
      FileWriteString(h, line + "\r\n");
      FileClose(h);
   }

public:
   CLogger()
   {
      m_enabled = true;
      m_logPath = "Data\\logs\\";
   }

   ~CLogger() {}

   bool Initialize(const bool enabled, const string logPath)
   {
      m_enabled = enabled;
      m_logPath = logPath;
      return true;
   }

   void LogInfo(const string message) const { WriteLine("INFO", message); }
   void LogTrade(const string message) const { WriteLine("TRADE", message); }
   void LogRisk(const string message) const { WriteLine("RISK", message); }
   void LogError(const string message) const { WriteLine("ERROR", message); }
   void LogFundamental(const string message) const { WriteLine("FUNDAMENTAL", message); }
};

#endif
