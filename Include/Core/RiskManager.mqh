#ifndef __RISK_MANAGER_H__
#define __RISK_MANAGER_H__
//+------------------------------------------------------------------+
//| RiskManager.mqh                                                  |
//| Calculates lot size and SL/TP prices from risk settings.         |
//| Dependencies: Include\Utils\Helpers.mqh                          |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+
#include "..\Utils\Helpers.mqh"

class CRiskManager
{
private:
   string m_symbol;

public:
   CRiskManager() { m_symbol = _Symbol; }
   ~CRiskManager() {}

   bool Initialize(const string symbol)
   {
      m_symbol = symbol;
      return true;
   }

   // Calculates order volume based on account risk percent and stop loss pips.
   double CalculateLot(const double riskPercent, const double stopLossPips) const
   {
      const double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      const double riskMoney = balance * (riskPercent / 100.0);

      const double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
      const double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
      const double slPriceDistance = XAUHelpers::PipsToPrice(m_symbol, stopLossPips);

      if(tickValue <= 0.0 || tickSize <= 0.0 || slPriceDistance <= 0.0)
         return 0.0;

      const double valuePerPriceUnit = tickValue / tickSize;
      const double lossPerLot = slPriceDistance * valuePerPriceUnit;
      if(lossPerLot <= 0.0)
         return 0.0;

      double rawLots = riskMoney / lossPerLot;

      const double lotMin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      const double lotMax = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      const double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      if(lotStep <= 0.0)
         return 0.0;

      rawLots = MathFloor(rawLots / lotStep) * lotStep;
      if(rawLots < lotMin)
         rawLots = lotMin;
      if(rawLots > lotMax)
         rawLots = lotMax;

      return rawLots;
   }

   // Generates absolute SL and TP prices from current quote and trade direction.
   bool BuildStops(const int direction,
                   const double stopLossPips,
                   const double takeProfitPips,
                   double &slPrice,
                   double &tpPrice) const
   {
      const double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      const double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      const int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

      const double slDistance = XAUHelpers::PipsToPrice(m_symbol, stopLossPips);
      const double tpDistance = XAUHelpers::PipsToPrice(m_symbol, takeProfitPips);

      if(direction > 0)
      {
         slPrice = NormalizeDouble(ask - slDistance, digits);
         tpPrice = NormalizeDouble(ask + tpDistance, digits);
         return true;
      }

      if(direction < 0)
      {
         slPrice = NormalizeDouble(bid + slDistance, digits);
         tpPrice = NormalizeDouble(bid - tpDistance, digits);
         return true;
      }

      return false;
   }
};

#endif
