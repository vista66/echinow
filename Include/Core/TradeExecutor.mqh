#ifndef __TRADE_EXECUTOR_H__
#define __TRADE_EXECUTOR_H__
//+------------------------------------------------------------------+
//| TradeExecutor.mqh                                                |
//| Executes buy/sell orders and prevents duplicate direction trades.|
//| Dependencies: Trade/Trade.mqh                                    |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

class CTradeExecutor
{
private:
   string m_symbol;
   CTrade m_trade;

public:
   CTradeExecutor() { m_symbol = _Symbol; }
   ~CTradeExecutor() {}

   bool Initialize(const string symbol)
   {
      m_symbol = symbol;
      return true;
   }

   // Returns true if there is already a position in the requested direction.
   bool HasPositionInDirection(const int direction) const
   {
      if(!PositionSelect(m_symbol))
         return false;

      const long posType = PositionGetInteger(POSITION_TYPE);
      if(direction > 0 && posType == POSITION_TYPE_BUY)
         return true;
      if(direction < 0 && posType == POSITION_TYPE_SELL)
         return true;

      return false;
   }

   // Opens an order with provided direction, volume and stop prices.
   bool Open(const int direction, const double lot, const double slPrice, const double tpPrice)
   {
      if(direction == 0 || lot <= 0.0)
         return false;

      bool result = false;
      if(direction > 0)
         result = m_trade.Buy(lot, m_symbol, 0.0, slPrice, tpPrice, "XAUUSD_EA Buy");
      else if(direction < 0)
         result = m_trade.Sell(lot, m_symbol, 0.0, slPrice, tpPrice, "XAUUSD_EA Sell");

      if(!result)
      {
         Print("CTradeExecutor.Open failed. retcode=", m_trade.ResultRetcode(),
               " comment=", m_trade.ResultRetcodeDescription());
      }
      return result;
   }
};

#endif
