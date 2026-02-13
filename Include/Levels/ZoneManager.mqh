#ifndef __ZONE_MANAGER_H__
#define __ZONE_MANAGER_H__
//+------------------------------------------------------------------+
//| ZoneManager.mqh                                                  |
//| Manages support/resistance levels and chart drawing.             |
//| Dependencies: Include\Utils\Helpers.mqh                          |
//| Created: 2026-01-01 | Version: 1.10                              |
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

   void DeleteDrawnObjects() const
   {
      const int total = ObjectsTotal(0, 0, -1);
      for(int i = total - 1; i >= 0; i--)
      {
         const string name = ObjectName(0, i, 0, -1);
         if(StringFind(name, m_prefix) == 0)
            ObjectDelete(0, name);
      }
   }

public:
   CZoneManager()
   {
      m_symbol = _Symbol;
      m_prefix = "XAU_Level_";
   }

   ~CZoneManager()
   {
      DeleteDrawnObjects();
   }

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

   void DrawFiltered(const double currentPrice,
                     const int minTouches,
                     const int maxLevelsToDraw,
                     const color supportColor,
                     const color resistanceColor)
   {
      DeleteDrawnObjects();

      int selected[];
      double distances[];
      const int totalLevels = ArraySize(m_levels);
      const int maxLevels = MathMax(maxLevelsToDraw, 1);

      for(int i = 0; i < totalLevels; i++)
      {
         if(m_touches[i] < minTouches)
            continue;

         const int n = ArraySize(selected);
         ArrayResize(selected, n + 1);
         ArrayResize(distances, n + 1);
         selected[n] = i;
         distances[n] = MathAbs(m_levels[i] - currentPrice);
      }

      // Sort by distance to current price (nearest first)
      for(int i = 0; i < ArraySize(selected); i++)
      {
         int best = i;
         for(int j = i + 1; j < ArraySize(selected); j++)
         {
            if(distances[j] < distances[best])
               best = j;
         }
         if(best != i)
         {
            const int tmpIdx = selected[i];
            selected[i] = selected[best];
            selected[best] = tmpIdx;

            const double tmpDist = distances[i];
            distances[i] = distances[best];
            distances[best] = tmpDist;
         }
      }

      const int drawCount = MathMin(ArraySize(selected), maxLevels);
      for(int k = 0; k < drawCount; k++)
      {
         const int i = selected[k];
         const string name = m_prefix + IntegerToString(k);
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, m_levels[i]);
         ObjectSetDouble(0, name, OBJPROP_PRICE, m_levels[i]);
         ObjectSetInteger(0, name, OBJPROP_COLOR, m_isSupport[i] ? supportColor : resistanceColor);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      }
   }
};

#endif
