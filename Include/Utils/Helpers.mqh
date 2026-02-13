#ifndef __HELPERS_H__
#define __HELPERS_H__
//+------------------------------------------------------------------+
//| Helpers.mqh                                                      |
//| Utility helper functions for parsing and symbol math.            |
//| Dependencies: Standard MQL5 runtime only                         |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+

namespace XAUHelpers
{
   // Parses a semicolon-separated string into trimmed string array.
   int SplitSemicolon(const string source, string &result[])
   {
      string normalized = source;
      StringReplace(normalized, " ", "");
      string raw[];
      const int rawCount = StringSplit(normalized, ';', raw);
      ArrayResize(result, 0);

      if(rawCount <= 0)
         return 0;

      int validCount = 0;
      for(int i = 0; i < rawCount; i++)
      {
         if(StringLen(raw[i]) == 0)
            continue;

         ArrayResize(result, validCount + 1);
         result[validCount] = raw[i];
         validCount++;
      }

      return validCount;
   }

   // Converts timeframe text (M1, M5, H1, D1...) into ENUM_TIMEFRAMES.
   ENUM_TIMEFRAMES ParseTimeframe(const string tfText)
   {
      if(tfText == "M1")  return PERIOD_M1;
      if(tfText == "M2")  return PERIOD_M2;
      if(tfText == "M3")  return PERIOD_M3;
      if(tfText == "M4")  return PERIOD_M4;
      if(tfText == "M5")  return PERIOD_M5;
      if(tfText == "M6")  return PERIOD_M6;
      if(tfText == "M10") return PERIOD_M10;
      if(tfText == "M12") return PERIOD_M12;
      if(tfText == "M15") return PERIOD_M15;
      if(tfText == "M20") return PERIOD_M20;
      if(tfText == "M30") return PERIOD_M30;
      if(tfText == "H1")  return PERIOD_H1;
      if(tfText == "H2")  return PERIOD_H2;
      if(tfText == "H3")  return PERIOD_H3;
      if(tfText == "H4")  return PERIOD_H4;
      if(tfText == "H6")  return PERIOD_H6;
      if(tfText == "H8")  return PERIOD_H8;
      if(tfText == "H12") return PERIOD_H12;
      if(tfText == "D1")  return PERIOD_D1;
      if(tfText == "W1")  return PERIOD_W1;
      if(tfText == "MN1") return PERIOD_MN1;
      return PERIOD_CURRENT;
   }

   // Converts pip distance into price distance for the symbol.
   double PipsToPrice(const string symbol, const double pips)
   {
      const int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      const double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(digits == 3 || digits == 5)
         return pips * point * 10.0;
      return pips * point;
   }
}

#endif
