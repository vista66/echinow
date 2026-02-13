#ifndef __CHART_PATTERN_DETECTOR_H__
#define __CHART_PATTERN_DETECTOR_H__
//+------------------------------------------------------------------+
//| ChartPatternDetector.mqh                                         |
//| Detects simple triangle/channel/rectangle breakout conditions.   |
//| Dependencies: none                                                |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+

class CChartPatternDetector
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;
   bool              m_enableTriangle;
   bool              m_enableChannel;
   bool              m_enableRectangle;
   double            m_weight;
   int               m_lookbackBars;
   string            m_lastPattern;

   double Highest(const int fromShift, const int count) const
   {
      double highValue = iHigh(m_symbol, m_tf, fromShift);
      for(int i = fromShift; i < fromShift + count; i++)
      {
         const double h = iHigh(m_symbol, m_tf, i);
         if(h > highValue)
            highValue = h;
      }
      return highValue;
   }

   double Lowest(const int fromShift, const int count) const
   {
      double lowValue = iLow(m_symbol, m_tf, fromShift);
      for(int i = fromShift; i < fromShift + count; i++)
      {
         const double l = iLow(m_symbol, m_tf, i);
         if(l < lowValue)
            lowValue = l;
      }
      return lowValue;
   }

public:
   CChartPatternDetector()
   {
      m_symbol = _Symbol;
      m_tf = PERIOD_H1;
      m_enableTriangle = true;
      m_enableChannel = true;
      m_enableRectangle = true;
      m_weight = 4.0;
      m_lookbackBars = 30;
      m_lastPattern = "None";
   }

   ~CChartPatternDetector() {}

   bool Initialize(const string symbol,
                   const ENUM_TIMEFRAMES tf,
                   const bool enableTriangle,
                   const bool enableChannel,
                   const bool enableRectangle,
                   const double weight,
                   const int lookbackBars)
   {
      m_symbol = symbol;
      m_tf = tf;
      m_enableTriangle = enableTriangle;
      m_enableChannel = enableChannel;
      m_enableRectangle = enableRectangle;
      m_weight = weight;
      m_lookbackBars = lookbackBars;
      return true;
   }

   // Returns weighted score after simple breakout tests.
   double Update()
   {
      m_lastPattern = "None";
      const int bars = Bars(m_symbol, m_tf);
      if(bars <= m_lookbackBars + 3)
         return 0.0;

      const double highNow = Highest(1, m_lookbackBars / 2);
      const double highPrev = Highest(1 + m_lookbackBars / 2, m_lookbackBars / 2);
      const double lowNow = Lowest(1, m_lookbackBars / 2);
      const double lowPrev = Lowest(1 + m_lookbackBars / 2, m_lookbackBars / 2);
      const double closePrice = iClose(m_symbol, m_tf, 1);
      const double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

      if(m_enableTriangle)
      {
         const bool converging = (highNow < highPrev) && (lowNow > lowPrev);
         if(converging && closePrice > highNow + point)
         {
            m_lastPattern = "Triangle Breakout Up";
            return m_weight;
         }
         if(converging && closePrice < lowNow - point)
         {
            m_lastPattern = "Triangle Breakout Down";
            return -m_weight;
         }
      }

      if(m_enableChannel)
      {
         const bool risingChannel = (highNow > highPrev) && (lowNow > lowPrev);
         const bool fallingChannel = (highNow < highPrev) && (lowNow < lowPrev);
         if(risingChannel && closePrice > highNow + point)
         {
            m_lastPattern = "Channel Breakout Up";
            return m_weight;
         }
         if(fallingChannel && closePrice < lowNow - point)
         {
            m_lastPattern = "Channel Breakout Down";
            return -m_weight;
         }
      }

      if(m_enableRectangle)
      {
         const double top = Highest(1, m_lookbackBars);
         const double bottom = Lowest(1, m_lookbackBars);
         if(closePrice > top + point)
         {
            m_lastPattern = "Rectangle Breakout Up";
            return m_weight;
         }
         if(closePrice < bottom - point)
         {
            m_lastPattern = "Rectangle Breakout Down";
            return -m_weight;
         }
      }

      return 0.0;
   }

   string GetLastPattern() const { return m_lastPattern; }
};

#endif
