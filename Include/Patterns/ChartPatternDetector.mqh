#ifndef __CHART_PATTERN_DETECTOR_H__
#define __CHART_PATTERN_DETECTOR_H__
//+------------------------------------------------------------------+
//| ChartPatternDetector.mqh                                         |
//| Detects simple triangle/channel/rectangle breakout conditions.   |
//| Dependencies: none                                                |
//| Created: 2026-01-01 | Version: 1.10                              |
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
   string            m_objectPrefix;

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
      m_objectPrefix = "XAU_ChartPattern_";
   }

   ~CChartPatternDetector()
   {
      ObjectDelete(0, m_objectPrefix + "Label");
   }

   bool Initialize(const string symbol,
                   const ENUM_TIMEFRAMES tf,
                   const bool enableTriangle,
                   const bool enableChannel,
                   const bool enableRectangle,
                   const double weight,
                   const int lookbackBars,
                   const string objectPrefix)
   {
      m_symbol = symbol;
      m_tf = tf;
      m_enableTriangle = enableTriangle;
      m_enableChannel = enableChannel;
      m_enableRectangle = enableRectangle;
      m_weight = weight;
      m_lookbackBars = lookbackBars;
      m_objectPrefix = objectPrefix;
      return true;
   }

   // Returns weighted score after simple breakout tests.
   double Update()
   {
      m_lastPattern = "None";
      const int bars = Bars(m_symbol, m_tf);
      if(bars <= m_lookbackBars + 3)
      {
         DrawStatus();
         return 0.0;
      }

      const int half = MathMax(m_lookbackBars / 2, 2);
      const double highNow = Highest(2, half);
      const double highPrev = Highest(2 + half, half);
      const double lowNow = Lowest(2, half);
      const double lowPrev = Lowest(2 + half, half);
      const double closePrice = iClose(m_symbol, m_tf, 1);
      const double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

      if(m_enableTriangle)
      {
         const bool converging = (highNow < highPrev) && (lowNow > lowPrev);
         if(converging && closePrice > highNow + point)
         {
            m_lastPattern = "Triangle Breakout Up";
            DrawStatus();
            return m_weight;
         }
         if(converging && closePrice < lowNow - point)
         {
            m_lastPattern = "Triangle Breakout Down";
            DrawStatus();
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
            DrawStatus();
            return m_weight;
         }
         if(fallingChannel && closePrice < lowNow - point)
         {
            m_lastPattern = "Channel Breakout Down";
            DrawStatus();
            return -m_weight;
         }
      }

      if(m_enableRectangle)
      {
         const double top = Highest(2, m_lookbackBars);
         const double bottom = Lowest(2, m_lookbackBars);
         if(closePrice > top + point)
         {
            m_lastPattern = "Rectangle Breakout Up";
            DrawStatus();
            return m_weight;
         }
         if(closePrice < bottom - point)
         {
            m_lastPattern = "Rectangle Breakout Down";
            DrawStatus();
            return -m_weight;
         }
      }

      DrawStatus();
      return 0.0;
   }

   void DrawStatus() const
   {
      const string name = m_objectPrefix + "Label";
      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
      }

      const color c = (m_lastPattern == "None") ? clrSilver : clrGold;
      ObjectSetInteger(0, name, OBJPROP_COLOR, c);
      ObjectSetString(0, name, OBJPROP_TEXT, "ChartPattern: " + m_lastPattern);
   }

   string GetLastPattern() const { return m_lastPattern; }
};

#endif
