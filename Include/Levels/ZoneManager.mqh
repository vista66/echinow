#ifndef __ZONE_MANAGER_H__
#define __ZONE_MANAGER_H__
//+------------------------------------------------------------------+
//| ZoneManager.mqh                                                  |
//| Manages support/resistance levels and chart drawing.             |
//| Dependencies: Include\Utils\Helpers.mqh                          |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+
#include "..\Utils\Helpers.mqh"

class CZoneManager
{
private:
   string   m_symbol;
   string   m_prefix;
   double   m_levels[];
   int      m_touches[];
   bool     m_isSupport[];

public:
   CZoneManager()
   {
      m_symbol = _Symbol;
      m_prefix = "XAU_Level_";
   }

   ~CZoneManager() {}

   bool Initialize(const string symbol, const string objectPrefix)
   {
      m_symbol = symbol;
      m_prefix = objectPrefix;
      return true;
   }

   void Clear()
   {
      ArrayResize(m_levels, 0);
      ArrayResize(m_touches, 0);
      ArrayResize(m_isSupport, 0);
   }

   int Count() const { return ArraySize(m_levels); }

   double GetLevel(const int index) const
   {
      if(index < 0 || index >= ArraySize(m_levels))
         return 0.0;
      return m_levels[index];
   }

   int GetTouchCount(const int index) const
   {
      if(index < 0 || index >= ArraySize(m_touches))
         return 0;
      return m_touches[index];
   }

   bool IsSupport(const int index) const
   {
      if(index < 0 || index >= ArraySize(m_isSupport))
         return false;
      return m_isSupport[index];
   }

   void AddOrUpdateLevel(const double price, const bool isSupport, const double minDistancePips)
   {
      const double minDistancePrice = XAUHelpers::PipsToPrice(m_symbol, minDistancePips);
      for(int i = 0; i < ArraySize(m_levels); i++)
      {
         if(m_isSupport[i] != isSupport)
            continue;

         if(MathAbs(m_levels[i] - price) <= minDistancePrice)
         {
            m_levels[i] = (m_levels[i] * m_touches[i] + price) / (double)(m_touches[i] + 1);
            m_touches[i]++;
            return;
         }
      }

      const int n = ArraySize(m_levels);
      ArrayResize(m_levels, n + 1);
      ArrayResize(m_touches, n + 1);
      ArrayResize(m_isSupport, n + 1);
      m_levels[n] = price;
      m_touches[n] = 1;
      m_isSupport[n] = isSupport;
   }

   double GetNearestSupport(const double currentPrice, const int minTouches) const
   {
      double best = 0.0;
      for(int i = 0; i < ArraySize(m_levels); i++)
      {
         if(!m_isSupport[i] || m_touches[i] < minTouches)
            continue;
         if(m_levels[i] > currentPrice)
            continue;
         if(best == 0.0 || m_levels[i] > best)
            best = m_levels[i];
      }
      return best;
   }

   double GetNearestResistance(const double currentPrice, const int minTouches) const
   {
      double best = 0.0;
      for(int i = 0; i < ArraySize(m_levels); i++)
      {
         if(m_isSupport[i] || m_touches[i] < minTouches)
            continue;
         if(m_levels[i] < currentPrice)
            continue;
         if(best == 0.0 || m_levels[i] < best)
            best = m_levels[i];
      }
      return best;
   }

   void Draw(const int minTouches, const color supportColor, const color resistanceColor) const
   {
      for(int i = 0; i < ArraySize(m_levels); i++)
      {
         const string name = m_prefix + IntegerToString(i);
         if(ObjectFind(0, name) < 0)
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, m_levels[i]);

         ObjectSetDouble(0, name, OBJPROP_PRICE, m_levels[i]);
         ObjectSetInteger(0, name, OBJPROP_COLOR, m_isSupport[i] ? supportColor : resistanceColor);
         ObjectSetInteger(0, name, OBJPROP_STYLE, m_touches[i] >= minTouches ? STYLE_SOLID : STYLE_DOT);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, m_touches[i] >= minTouches ? 2 : 1);
      }
   }
};

#endif
