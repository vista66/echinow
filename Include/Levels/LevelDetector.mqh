#ifndef __LEVEL_DETECTOR_H__
#define __LEVEL_DETECTOR_H__
//+------------------------------------------------------------------+
//| LevelDetector.mqh                                                |
//| Detects swing highs/lows and feeds levels into zone manager.     |
//| Dependencies: Include\Levels\ZoneManager.mqh                      |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+
#include "ZoneManager.mqh"

class CLevelDetector
{
private:
   string         m_symbol;
   ENUM_TIMEFRAMES m_tf;
   int            m_swingStrength;
   int            m_lookbackBars;
   double         m_minDistancePips;
   CZoneManager   *m_zoneManager;

   bool IsSwingHigh(const int shift) const
   {
      const double center = iHigh(m_symbol, m_tf, shift);
      for(int j = 1; j <= m_swingStrength; j++)
      {
         if(iHigh(m_symbol, m_tf, shift - j) >= center)
            return false;
         if(iHigh(m_symbol, m_tf, shift + j) > center)
            return false;
      }
      return true;
   }

   bool IsSwingLow(const int shift) const
   {
      const double center = iLow(m_symbol, m_tf, shift);
      for(int j = 1; j <= m_swingStrength; j++)
      {
         if(iLow(m_symbol, m_tf, shift - j) <= center)
            return false;
         if(iLow(m_symbol, m_tf, shift + j) < center)
            return false;
      }
      return true;
   }

public:
   CLevelDetector()
   {
      m_symbol = _Symbol;
      m_tf = PERIOD_H1;
      m_swingStrength = 3;
      m_lookbackBars = 300;
      m_minDistancePips = 50.0;
      m_zoneManager = NULL;
   }

   ~CLevelDetector() {}

   bool Initialize(const string symbol,
                   const ENUM_TIMEFRAMES tf,
                   const int swingStrength,
                   const int lookbackBars,
                   const double minDistancePips,
                   CZoneManager *zoneManager)
   {
      m_symbol = symbol;
      m_tf = tf;
      m_swingStrength = swingStrength;
      m_lookbackBars = lookbackBars;
      m_minDistancePips = minDistancePips;
      m_zoneManager = zoneManager;

      if(m_zoneManager == NULL)
      {
         Print("CLevelDetector.Initialize: zone manager is null");
         return false;
      }
      return true;
   }

   bool Update()
   {
      if(m_zoneManager == NULL)
         return false;

      const int totalBars = Bars(m_symbol, m_tf);
      if(totalBars <= (2 * m_swingStrength + 2))
         return false;

      m_zoneManager.Clear();

      const int upperShift = MathMin(m_lookbackBars, totalBars - m_swingStrength - 1);
      for(int shift = m_swingStrength; shift <= upperShift; shift++)
      {
         if(IsSwingHigh(shift))
         {
            const double levelPrice = iHigh(m_symbol, m_tf, shift);
            m_zoneManager.AddOrUpdateLevel(levelPrice, false, m_minDistancePips);
         }

         if(IsSwingLow(shift))
         {
            const double levelPrice = iLow(m_symbol, m_tf, shift);
            m_zoneManager.AddOrUpdateLevel(levelPrice, true, m_minDistancePips);
         }
      }
      return true;
   }
};

#endif
