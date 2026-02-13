//+------------------------------------------------------------------+
//|                                                   XAUUSD_EA.mq5  |
//|                                      (c) Copyright 2026, AI-gen  |
//+------------------------------------------------------------------+
#property copyright "AI-generated EA for XAUUSD"
#property version   "1.20"
#property strict

#include "Include\Core\MTFAnalyzer.mqh"
#include "Include\Core\ScoreCalculator.mqh"
#include "Include\Core\RiskManager.mqh"
#include "Include\Core\TradeExecutor.mqh"
#include "Include\Levels\LevelDetector.mqh"
#include "Include\Levels\ZoneManager.mqh"
#include "Include\Patterns\PatternDetector.mqh"
#include "Include\Patterns\ChartPatternDetector.mqh"

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

// === Level Detection ===
input int            SwingStrength = 3;
input int            MinPipsBetweenLevels = 50;
input int            LevelLookbackBars = 250;
input int            MinTouchCount = 2;
input double         LevelWeight = 2.0;
input int            MaxLevelsToDraw = 12;

// === Dynamic SL/TP ===
input bool           UseATRforSL = true;
input int            ATRPeriod = 14;
input double         ATRExtraMultiplier = 1.5;

// === Price Action Patterns ===
input bool           EnableEngulfing = true;
input bool           EnablePinBar = true;
input bool           EnableDoji = true;
input bool           EnableTweezer = true;
input double         PatternWeight = 3.0;
input int            MaxPatternDistanceFromLevel = 5;
input int            PatternScanBars = 8;

// === Chart Patterns ===
input bool           EnableTriangle = true;
input bool           EnableChannel = true;
input bool           EnableRectangle = true;
input double         ChartPatternWeight = 4.0;

CMTFAnalyzer           *MTF;
CScoreCalculator       *Scorer;
CRiskManager           *Risk;
CTradeExecutor         *Trader;
CZoneManager           *Zones;
CLevelDetector         *Levels;
CPatternDetector       *Patterns;
CChartPatternDetector  *ChartPatterns;

int OnInit()
{
   MTF = new CMTFAnalyzer();
   Scorer = new CScoreCalculator();
   Risk = new CRiskManager();
   Trader = new CTradeExecutor();
   Zones = new CZoneManager();
   Levels = new CLevelDetector();
   Patterns = new CPatternDetector();
   ChartPatterns = new CChartPatternDetector();

   if(!MTF.Initialize(_Symbol, Timeframes, IndicatorType, MAPeriod))
      return INIT_FAILED;
   if(!Scorer.Initialize(MTF, Weights, Threshold))
      return INIT_FAILED;
   if(!Risk.Initialize(_Symbol))
      return INIT_FAILED;
   if(!Trader.Initialize(_Symbol))
      return INIT_FAILED;
   if(!Zones.Initialize(_Symbol, "XAU_Level_"))
      return INIT_FAILED;
   if(!Levels.Initialize(_Symbol, PERIOD_H1, SwingStrength, LevelLookbackBars, (double)MinPipsBetweenLevels, Zones))
      return INIT_FAILED;
   if(!Patterns.Initialize(_Symbol,
                           PERIOD_H1,
                           EnableEngulfing,
                           EnablePinBar,
                           EnableDoji,
                           EnableTweezer,
                           PatternWeight,
                           (double)MaxPatternDistanceFromLevel,
                           PatternScanBars))
      return INIT_FAILED;
   if(!ChartPatterns.Initialize(_Symbol,
                                PERIOD_H1,
                                EnableTriangle,
                                EnableChannel,
                                EnableRectangle,
                                ChartPatternWeight,
                                30,
                                "XAU_ChartPattern_"))
      return INIT_FAILED;

   return(INIT_SUCCEEDED);
}

void OnTick()
{
   if(!MTF.Update())
      return;
   if(!Levels.Update())
      return;

   const double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double nearestSupport = Zones.GetNearestSupport(currentPrice, MinTouchCount);
   const double nearestResistance = Zones.GetNearestResistance(currentPrice, MinTouchCount);
   const double patternSupport = Zones.GetNearestSupport(currentPrice, 1);
   const double patternResistance = Zones.GetNearestResistance(currentPrice, 1);

   if(!Scorer.Update())
      return;

   Scorer.ApplyLevelBias(currentPrice, nearestSupport, nearestResistance, LevelWeight);

   const double patternScore = Patterns.Update(patternSupport, patternResistance);
   Scorer.ApplyPatternScore(patternScore);

   const double chartPatternScore = ChartPatterns.Update();
   Scorer.ApplyChartPatternScore(chartPatternScore);

   Zones.DrawFiltered(currentPrice, MinTouchCount, MaxLevelsToDraw, clrLime, clrTomato);

   Print(Scorer.BuildScoreLog(),
         " | LevelScore=", DoubleToString(Scorer.GetLevelScore(), 2),
         " | PatternScore=", DoubleToString(Scorer.GetPatternScore(), 2),
         " | ChartPatternScore=", DoubleToString(Scorer.GetChartPatternScore(), 2),
         " | PA=", Patterns.GetLastPattern(),
         " | CP=", ChartPatterns.GetLastPattern());

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

   if(lot <= 0.0 || !Risk.BuildDynamicStops(direction,
                                             (double)FixedSL,
                                             (double)FixedTP,
                                             UseATRforSL,
                                             ATRPeriod,
                                             ATRExtraMultiplier,
                                             nearestSupport,
                                             nearestResistance,
                                             slPrice,
                                             tpPrice))
   {
      Print("Trade skipped: invalid lot or dynamic SL/TP calculation.");
      return;
   }

   if(Trader.Open(direction, lot, slPrice, tpPrice))
      Print("Trade opened. Dir=", direction,
            " Lot=", DoubleToString(lot, 2),
            " SL=", slPrice,
            " TP=", tpPrice,
            " Support=", nearestSupport,
            " Resistance=", nearestResistance,
            " PA=", Patterns.GetLastPattern(),
            " CP=", ChartPatterns.GetLastPattern());
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
   delete Zones;
   delete Levels;
   delete Patterns;
   delete ChartPatterns;
}
//+------------------------------------------------------------------+
