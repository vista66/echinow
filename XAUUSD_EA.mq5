//+------------------------------------------------------------------+
//|                                                   XAUUSD_EA.mq5  |
//|                                      (c) Copyright 2026, AI-gen  |
//+------------------------------------------------------------------+
#property copyright "AI-generated EA for XAUUSD"
#property version   "1.00"
#property strict

#include "Include\Core\MTFAnalyzer.mqh"
#include "Include\Core\ScoreCalculator.mqh"
#include "Include\Core\RiskManager.mqh"
#include "Include\Core\TradeExecutor.mqh"

// === MTF Settings ===
input string         Timeframes   = "M1;M5;M15;H1;H4;D1;W1";
input string         Weights      = "1;2;3;4;5;6;7";
input ENUM_MA_METHOD IndicatorType = MODE_SMA;
input int            MAPeriod     = 20;
input double         Threshold    = 3.0;

// === Risk Management ===
input double         RiskPercent  = 2.0;
input int            FixedSL      = 200;
input int            FixedTP      = 400;

// === Trade Settings ===
input bool           AutoTrading  = true;

CMTFAnalyzer      *MTF;
CScoreCalculator  *Scorer;
CRiskManager      *Risk;
CTradeExecutor    *Trader;

int OnInit()
{
   MTF = new CMTFAnalyzer();
   Scorer = new CScoreCalculator();
   Risk = new CRiskManager();
   Trader = new CTradeExecutor();

   if(!MTF.Initialize(_Symbol, Timeframes, IndicatorType, MAPeriod))
      return INIT_FAILED;
   if(!Scorer.Initialize(MTF, Weights, Threshold))
      return INIT_FAILED;
   if(!Risk.Initialize(_Symbol))
      return INIT_FAILED;
   if(!Trader.Initialize(_Symbol))
      return INIT_FAILED;

   return(INIT_SUCCEEDED);
}

void OnTick()
{
   if(!MTF.Update())
      return;
   if(!Scorer.Update())
      return;

   Print(Scorer.BuildScoreLog());

   if(!AutoTrading)
   {
      Print("AutoTrading is disabled.");
      return;
   }

   if(!Scorer.ShouldOpenTrade())
   {
      Print("No trade signal: score does not cross threshold.");
      return;
   }

   const int direction = Scorer.GetDirection();
   if(Trader.HasPositionInDirection(direction))
   {
      Print("Trade skipped: same direction position already exists.");
      return;
   }

   const double lot = Risk.CalculateLot(RiskPercent, (double)FixedSL);
   double slPrice = 0.0;
   double tpPrice = 0.0;
   if(lot <= 0.0 || !Risk.BuildStops(direction, (double)FixedSL, (double)FixedTP, slPrice, tpPrice))
   {
      Print("Trade skipped: invalid lot or SL/TP calculation.");
      return;
   }

   if(Trader.Open(direction, lot, slPrice, tpPrice))
      Print("Trade opened. Dir=", direction, " Lot=", DoubleToString(lot, 2), " SL=", slPrice, " TP=", tpPrice);
}

void OnTimer()
{
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
}

void OnDeinit(const int reason)
{
   delete MTF;
   delete Scorer;
   delete Risk;
   delete Trader;
}
//+------------------------------------------------------------------+
