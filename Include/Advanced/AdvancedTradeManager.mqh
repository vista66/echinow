#ifndef __ADVANCED_TRADE_MANAGER_H__
#define __ADVANCED_TRADE_MANAGER_H__
//+------------------------------------------------------------------+
//| AdvancedTradeManager.mqh                                         |
//| Break-even, trailing, and early-exit management.                 |
//| Dependencies: Trade/Trade.mqh                                    |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include "..\Utils\Helpers.mqh"

class CAdvancedTradeManager
{
private:
   string m_symbol;
   CTrade m_trade;

public:
   CAdvancedTradeManager() { m_symbol = _Symbol; }
   ~CAdvancedTradeManager() {}

   bool Initialize(const string symbol)
   {
      m_symbol = symbol;
      return true;
   }

   void Manage(const bool useBreakEven,
               const double breakEvenTrigger,
               const bool useTrailing,
               const double trailingTrigger,
               const int trailingStep,
               const bool useEarlyExit,
               const double currentScore,
               const double previousScore,
               const double earlyExitScoreDrop)
   {
      if(!PositionSelect(m_symbol))
         return;

      const long type = PositionGetInteger(POSITION_TYPE);
      const double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      const double sl = PositionGetDouble(POSITION_SL);
      const double tp = PositionGetDouble(POSITION_TP);
      const double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      const double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

      const double currentPrice = (type == POSITION_TYPE_BUY) ? bid : ask;
      const double profitDistance = MathAbs(currentPrice - openPrice);
      const double targetDistance = MathAbs(tp - openPrice);
      if(targetDistance <= 0.0)
         return;

      const double progressPct = (profitDistance / targetDistance) * 100.0;

      if(useBreakEven && progressPct >= breakEvenTrigger)
      {
         if((type == POSITION_TYPE_BUY && (sl < openPrice || sl == 0.0)) ||
            (type == POSITION_TYPE_SELL && (sl > openPrice || sl == 0.0)))
         {
            m_trade.PositionModify(m_symbol, NormalizeDouble(openPrice, digits), tp);
         }
      }

      if(useTrailing && progressPct >= trailingTrigger)
      {
         const double stepPrice = XAUHelpers::PipsToPrice(m_symbol, (double)trailingStep);
         double newSL = sl;
         if(type == POSITION_TYPE_BUY)
         {
            newSL = currentPrice - stepPrice;
            if(newSL > sl)
               m_trade.PositionModify(m_symbol, NormalizeDouble(newSL, digits), tp);
         }
         else
         {
            newSL = currentPrice + stepPrice;
            if(sl == 0.0 || newSL < sl)
               m_trade.PositionModify(m_symbol, NormalizeDouble(newSL, digits), tp);
         }
      }

      if(useEarlyExit)
      {
         const double drop = previousScore - currentScore;
         if(drop >= earlyExitScoreDrop)
            m_trade.PositionClose(m_symbol);
      }
   }

   void CloseAll()
   {
      if(PositionSelect(m_symbol))
         m_trade.PositionClose(m_symbol);
   }
};

#endif
