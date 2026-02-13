#ifndef __EXTERNAL_DATA_MODULE_H__
#define __EXTERNAL_DATA_MODULE_H__
//+------------------------------------------------------------------+
//| ExternalDataModule.mqh                                           |
//| Loads economic/sentiment/COT data from CSV bridge files.         |
//| Dependencies: Include\Utils\CSVReader.mqh                        |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+
#include "..\Utils\CSVReader.mqh"

class CExternalDataModule
{
private:
   bool      m_enabled;
   string    m_economicFile;
   string    m_sentimentFile;
   string    m_cotFile;
   double    m_weight;
   CCSVReader m_reader;
   string    m_lastSummary;
   bool      m_blockAutoTrading;

   int FindColumn(const string &headers[], const string name) const
   {
      for(int i = 0; i < ArraySize(headers); i++)
      {
         if(headers[i] == name)
            return i;
      }
      return -1;
   }

public:
   CExternalDataModule()
   {
      m_enabled = false;
      m_economicFile = "Data\\economic_calendar.csv";
      m_sentimentFile = "Data\\sentiment.csv";
      m_cotFile = "Data\\cot.csv";
      m_weight = 5.0;
      m_lastSummary = "No data";
      m_blockAutoTrading = false;
   }

   ~CExternalDataModule() {}

   bool Initialize(const bool enabled,
                   const string economicFile,
                   const string sentimentFile,
                   const string cotFile,
                   const double weight)
   {
      m_enabled = enabled;
      m_economicFile = economicFile;
      m_sentimentFile = sentimentFile;
      m_cotFile = cotFile;
      m_weight = weight;
      return true;
   }

   double UpdateAndScore(const int direction)
   {
      m_blockAutoTrading = false;
      m_lastSummary = "No data";
      if(!m_enabled || direction == 0)
         return 0.0;

      double score = 0.0;
      string h[];
      string v[];

      if(m_reader.ReadLastRecord(m_sentimentFile, h, v))
      {
         const int opIdx = FindColumn(h, "technical_opinion");
         const int longIdx = FindColumn(h, "trader_long_pct");
         const int shortIdx = FindColumn(h, "trader_short_pct");

         if(opIdx >= 0 && opIdx < ArraySize(v))
         {
            const string op = v[opIdx];
            if((direction > 0 && op == "Buy") || (direction < 0 && op == "Sell"))
               score += 1.0;
         }

         if(longIdx >= 0 && shortIdx >= 0 && longIdx < ArraySize(v) && shortIdx < ArraySize(v))
         {
            const double lp = StringToDouble(v[longIdx]);
            const double sp = StringToDouble(v[shortIdx]);
            if(direction > 0 && sp > lp)
               score += 1.0;
            if(direction < 0 && lp > sp)
               score += 1.0;
         }
      }

      if(m_reader.ReadLastRecord(m_cotFile, h, v))
      {
         const int longIdx = FindColumn(h, "long_positions");
         const int shortIdx = FindColumn(h, "short_positions");
         if(longIdx >= 0 && shortIdx >= 0 && longIdx < ArraySize(v) && shortIdx < ArraySize(v))
         {
            const double net = StringToDouble(v[longIdx]) - StringToDouble(v[shortIdx]);
            if(direction > 0 && net > 0)
               score += 1.0;
            if(direction < 0 && net < 0)
               score += 1.0;
         }
      }

      if(m_reader.ReadLastRecord(m_economicFile, h, v))
      {
         const int impactIdx = FindColumn(h, "impact");
         if(impactIdx >= 0 && impactIdx < ArraySize(v))
         {
            const string impact = v[impactIdx];
            if(impact == "HIGH")
               m_blockAutoTrading = true;
         }
      }

      m_lastSummary = "FundScoreRaw=" + DoubleToString(score, 1) + " BlockAuto=" + (m_blockAutoTrading ? "Yes" : "No");
      return score * m_weight;
   }

   bool ShouldBlockAutoTrading() const { return m_blockAutoTrading; }
   string GetLastSummary() const { return m_lastSummary; }
};

#endif
