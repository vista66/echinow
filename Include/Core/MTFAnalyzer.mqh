#ifndef __MTF_ANALYZER_H__
#define __MTF_ANALYZER_H__
//+------------------------------------------------------------------+
//| MTFAnalyzer.mqh                                                  |
//| Multi-timeframe trend analyzer based on moving average relation. |
//| Dependencies: Include\Utils\Helpers.mqh                          |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+
#include "..\Utils\Helpers.mqh"

class CMTFAnalyzer
{
private:
   string            m_symbol;
   ENUM_MA_METHOD    m_maMethod;
   int               m_maPeriod;
   ENUM_TIMEFRAMES   m_timeframes[];
   string            m_timeframeLabels[];
   int               m_scores[];
   int               m_maHandles[];
   int               m_count;

public:
   CMTFAnalyzer()
   {
      m_symbol = _Symbol;
      m_maMethod = MODE_SMA;
      m_maPeriod = 20;
      m_count = 0;
   }

   ~CMTFAnalyzer()
   {
      for(int i = 0; i < ArraySize(m_maHandles); i++)
      {
         if(m_maHandles[i] != INVALID_HANDLE)
            IndicatorRelease(m_maHandles[i]);
      }
   }

   // Initializes analyzer settings and parsed timeframe list.
   bool Initialize(const string symbol,
                   const string timeframeList,
                   const ENUM_MA_METHOD maMethod,
                   const int maPeriod)
   {
      m_symbol = symbol;
      m_maMethod = maMethod;
      m_maPeriod = maPeriod;

      string tokens[];
      m_count = XAUHelpers::SplitSemicolon(timeframeList, tokens);
      if(m_count <= 0)
      {
         Print("CMTFAnalyzer.Initialize: invalid timeframe list");
         return false;
      }

      ArrayResize(m_timeframes, m_count);
      ArrayResize(m_timeframeLabels, m_count);
      ArrayResize(m_scores, m_count);
      ArrayResize(m_maHandles, m_count);

      for(int i = 0; i < m_count; i++)
      {
         m_timeframeLabels[i] = tokens[i];
         m_timeframes[i] = XAUHelpers::ParseTimeframe(tokens[i]);
         m_scores[i] = 0;

         if(m_timeframes[i] == PERIOD_CURRENT && tokens[i] != "CURRENT")
            Print("CMTFAnalyzer.Initialize: unknown timeframe token=", tokens[i]);

         m_maHandles[i] = iMA(m_symbol, m_timeframes[i], m_maPeriod, 0, m_maMethod, PRICE_CLOSE);
         if(m_maHandles[i] == INVALID_HANDLE)
         {
            Print("CMTFAnalyzer.Initialize: iMA handle failed for ", tokens[i], " error=", GetLastError());
            return false;
         }
      }
      return true;
   }

   // Recalculates per-timeframe directional score: +1 bull, -1 bear, 0 neutral.
   bool Update()
   {
      if(m_count <= 0)
         return false;

      for(int i = 0; i < m_count; i++)
      {
         const ENUM_TIMEFRAMES tf = m_timeframes[i];
         const int bars = Bars(m_symbol, tf);
         if(bars <= m_maPeriod)
         {
            m_scores[i] = 0;
            continue;
         }

         double maBuff[];
         ArraySetAsSeries(maBuff, true);
         const int copied = CopyBuffer(m_maHandles[i], 0, 0, 1, maBuff);
         const double closePrice = iClose(m_symbol, tf, 0);
         if(copied <= 0 || closePrice == 0.0)
         {
            m_scores[i] = 0;
            continue;
         }

         const double ma = maBuff[0];
         if(closePrice > ma)
            m_scores[i] = 1;
         else if(closePrice < ma)
            m_scores[i] = -1;
         else
            m_scores[i] = 0;
      }

      return true;
   }

   int GetCount() const { return m_count; }
   int GetScore(const int index) const
   {
      if(index < 0 || index >= m_count)
         return 0;
      return m_scores[index];
   }

   string GetLabel(const int index) const
   {
      if(index < 0 || index >= m_count)
         return "";
      return m_timeframeLabels[index];
   }
};

#endif
