#ifndef __PATTERN_DETECTOR_H__
#define __PATTERN_DETECTOR_H__
//+------------------------------------------------------------------+
//| PatternDetector.mqh                                              |
//| Detects price-action candlestick patterns near key levels.       |
//| Dependencies: Include\Utils\Helpers.mqh                          |
//| Created: 2026-01-01 | Version: 1.10                              |
//+------------------------------------------------------------------+
#include "..\Utils\Helpers.mqh"

class CPatternDetector
{
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;
   bool              m_enableEngulfing;
   bool              m_enablePinBar;
   bool              m_enableDoji;
   bool              m_enableTweezer;
   double            m_patternWeight;
   double            m_maxDistancePips;
   int               m_scanBars;
   string            m_lastPattern;

   double DistanceToNearestLevel(const double price, const double support, const double resistance) const
   {
      double best = 0.0;
      if(support > 0.0)
         best = MathAbs(price - support);
      if(resistance > 0.0)
      {
         const double d = MathAbs(price - resistance);
         if(best == 0.0 || d < best)
            best = d;
      }
      return best;
   }

   int DetectEngulfing(const int shift) const
   {
      const double o1 = iOpen(m_symbol, m_tf, shift);
      const double c1 = iClose(m_symbol, m_tf, shift);
      const double o2 = iOpen(m_symbol, m_tf, shift + 1);
      const double c2 = iClose(m_symbol, m_tf, shift + 1);

      if(c1 > o1 && c2 < o2 && o1 <= c2 && c1 >= o2)
         return 1;
      if(c1 < o1 && c2 > o2 && o1 >= c2 && c1 <= o2)
         return -1;
      return 0;
   }

   int DetectPinBar(const int shift) const
   {
      const double h = iHigh(m_symbol, m_tf, shift);
      const double l = iLow(m_symbol, m_tf, shift);
      const double o = iOpen(m_symbol, m_tf, shift);
      const double c = iClose(m_symbol, m_tf, shift);

      const double body = MathAbs(c - o);
      const double range = h - l;
      if(range <= 0.0 || body <= 0.0)
         return 0;

      const double upperWick = h - MathMax(o, c);
      const double lowerWick = MathMin(o, c) - l;

      if(lowerWick >= body * 1.5 && upperWick <= body)
         return 1;
      if(upperWick >= body * 1.5 && lowerWick <= body)
         return -1;
      return 0;
   }

   int DetectDoji(const int shift) const
   {
      const double h = iHigh(m_symbol, m_tf, shift);
      const double l = iLow(m_symbol, m_tf, shift);
      const double o = iOpen(m_symbol, m_tf, shift);
      const double c = iClose(m_symbol, m_tf, shift);
      const double range = h - l;
      if(range <= 0.0)
         return 0;

      const double body = MathAbs(c - o);
      if(body <= range * 0.12)
      {
         const double prevClose = iClose(m_symbol, m_tf, shift + 1);
         return (c >= prevClose) ? 1 : -1;
      }
      return 0;
   }

   int DetectTweezer(const int shift) const
   {
      const double h1 = iHigh(m_symbol, m_tf, shift);
      const double h2 = iHigh(m_symbol, m_tf, shift + 1);
      const double l1 = iLow(m_symbol, m_tf, shift);
      const double l2 = iLow(m_symbol, m_tf, shift + 1);
      const double tolerance = XAUHelpers::PipsToPrice(m_symbol, 2.0);

      if(MathAbs(l1 - l2) <= tolerance)
         return 1;
      if(MathAbs(h1 - h2) <= tolerance)
         return -1;
      return 0;
   }

public:
   CPatternDetector()
   {
      m_symbol = _Symbol;
      m_tf = PERIOD_H1;
      m_enableEngulfing = true;
      m_enablePinBar = true;
      m_enableDoji = true;
      m_enableTweezer = true;
      m_patternWeight = 3.0;
      m_maxDistancePips = 5.0;
      m_scanBars = 8;
      m_lastPattern = "None";
   }

   ~CPatternDetector() {}

   bool Initialize(const string symbol,
                   const ENUM_TIMEFRAMES tf,
                   const bool enableEngulfing,
                   const bool enablePinBar,
                   const bool enableDoji,
                   const bool enableTweezer,
                   const double patternWeight,
                   const double maxDistancePips,
                   const int scanBars)
   {
      m_symbol = symbol;
      m_tf = tf;
      m_enableEngulfing = enableEngulfing;
      m_enablePinBar = enablePinBar;
      m_enableDoji = enableDoji;
      m_enableTweezer = enableTweezer;
      m_patternWeight = patternWeight;
      m_maxDistancePips = maxDistancePips;
      m_scanBars = MathMax(scanBars, 1);
      return true;
   }

   // Returns weighted pattern score, near levels only.
   double Update(const double nearestSupport, const double nearestResistance)
   {
      m_lastPattern = "None";
      const double maxDistancePrice = XAUHelpers::PipsToPrice(m_symbol, m_maxDistancePips);

      for(int shift = 1; shift <= m_scanBars; shift++)
      {
         const double closePrice = iClose(m_symbol, m_tf, shift);
         const double distance = DistanceToNearestLevel(closePrice, nearestSupport, nearestResistance);

         if(distance == 0.0 || distance > maxDistancePrice)
            continue;

         int signal = 0;
         if(m_enableEngulfing)
         {
            signal = DetectEngulfing(shift);
            if(signal != 0)
            {
               m_lastPattern = signal > 0 ? "Bullish Engulfing" : "Bearish Engulfing";
               return signal * m_patternWeight;
            }
         }

         if(m_enablePinBar)
         {
            signal = DetectPinBar(shift);
            if(signal != 0)
            {
               m_lastPattern = signal > 0 ? "Bullish PinBar" : "Bearish PinBar";
               return signal * m_patternWeight;
            }
         }

         if(m_enableDoji)
         {
            signal = DetectDoji(shift);
            if(signal != 0)
            {
               m_lastPattern = signal > 0 ? "Bullish Doji" : "Bearish Doji";
               return signal * m_patternWeight;
            }
         }

         if(m_enableTweezer)
         {
            signal = DetectTweezer(shift);
            if(signal != 0)
            {
               m_lastPattern = signal > 0 ? "Bullish Tweezer" : "Bearish Tweezer";
               return signal * m_patternWeight;
            }
         }
      }

      return 0.0;
   }

   string GetLastPattern() const { return m_lastPattern; }
};

#endif
