//+------------------------------------------------------------------+
//|                                                   XAUUSD_EA.mq5  |
//|                                      (c) Copyright 2026, AI-gen  |
//+------------------------------------------------------------------+
#property copyright "AI-generated EA for XAUUSD"
#property version   "1.30"
#property strict

#include "Include\Core\MTFAnalyzer.mqh"
#include "Include\Core\ScoreCalculator.mqh"
#include "Include\Core\RiskManager.mqh"
#include "Include\Core\TradeExecutor.mqh"
#include "Include\Levels\LevelDetector.mqh"
#include "Include\Levels\ZoneManager.mqh"
#include "Include\Patterns\PatternDetector.mqh"
#include "Include\Patterns\ChartPatternDetector.mqh"
#include "Include\Advanced\AdvancedTradeManager.mqh"
#include "Include\Advanced\ExternalDataModule.mqh"
#include "Include\Advanced\Dashboard.mqh"
#include "Include\Advanced\Logger.mqh"

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
input int            PatternScanBars = 8;              // configurable scan range

// === Chart Patterns ===
input bool           EnableTriangle = true;
input bool           EnableChannel = true;
input bool           EnableRectangle = true;
input double         ChartPatternWeight = 4.0;
input int            ChartPatternLookbackBars = 30;    // configurable scan range

// === Advanced Trade Management ===
input bool           UseBreakEven = true;
input double         BreakEvenTrigger = 50;
input bool           UseTrailing = true;
input double         TrailingTrigger = 30;
input int            TrailingStep = 20;
input bool           UseEarlyExit = true;
input double         EarlyExitScoreDrop = 5.0;

// === External Data Module ===
input bool           UseFundamentalData = true;
input string         EconomicCalendarFile = "Data\\economic_calendar.csv";
input string         SentimentFile = "Data\\sentiment.csv";
input string         COTFile = "Data\\cot.csv";
input double         FundamentalWeight = 5.0;

// === Panel Settings ===
input bool           ShowPanel = true;
input int            PanelX = 10;
input int            PanelY = 20;
input color          PanelBgColor = clrBlack;
input color          PanelTextColor = clrWhite;

// === Logger Settings ===
input bool           EnableLogging = true;
input string         LogPath = "Data\\logs\\";

CMTFAnalyzer           *MTF;
CScoreCalculator       *Scorer;
CRiskManager           *Risk;
CTradeExecutor         *Trader;
CZoneManager           *Zones;
CLevelDetector         *Levels;
CPatternDetector       *Patterns;
CChartPatternDetector  *ChartPatterns;
CAdvancedTradeManager  *AdvManager;
CExternalDataModule    *External;
CDashboard             *Dash;
CLogger                *Logger;

bool   g_autoTradingState = true;
double g_prevGlobalScore = 0.0;

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
   AdvManager = new CAdvancedTradeManager();
   External = new CExternalDataModule();
   Dash = new CDashboard();
   Logger = new CLogger();

   g_autoTradingState = AutoTrading;

   if(!MTF.Initialize(_Symbol, Timeframes, IndicatorType, MAPeriod)) return INIT_FAILED;
   if(!Scorer.Initialize(MTF, Weights, Threshold)) return INIT_FAILED;
   if(!Risk.Initialize(_Symbol)) return INIT_FAILED;
   if(!Trader.Initialize(_Symbol)) return INIT_FAILED;
   if(!Zones.Initialize(_Symbol, "XAU_Level_")) return INIT_FAILED;
   if(!Levels.Initialize(_Symbol, PERIOD_H1, SwingStrength, LevelLookbackBars, (double)MinPipsBetweenLevels, Zones)) return INIT_FAILED;
   if(!Patterns.Initialize(_Symbol, PERIOD_H1, EnableEngulfing, EnablePinBar, EnableDoji, EnableTweezer,
                           PatternWeight, (double)MaxPatternDistanceFromLevel, PatternScanBars)) return INIT_FAILED;
   if(!ChartPatterns.Initialize(_Symbol, PERIOD_H1, EnableTriangle, EnableChannel, EnableRectangle,
                                ChartPatternWeight, ChartPatternLookbackBars, "XAU_ChartPattern_")) return INIT_FAILED;
   if(!AdvManager.Initialize(_Symbol)) return INIT_FAILED;
   if(!External.Initialize(UseFundamentalData, EconomicCalendarFile, SentimentFile, COTFile, FundamentalWeight)) return INIT_FAILED;
   if(!Dash.Initialize(ShowPanel, PanelX, PanelY, PanelBgColor, PanelTextColor)) return INIT_FAILED;
   if(!Logger.Initialize(EnableLogging, LogPath)) return INIT_FAILED;

   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   if(!MTF.Update() || !Levels.Update())
      return;

   const double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double nearestSupport = Zones.GetNearestSupport(currentPrice, MinTouchCount);
   const double nearestResistance = Zones.GetNearestResistance(currentPrice, MinTouchCount);
   const double patternSupport = Zones.GetNearestSupport(currentPrice, 1);
   const double patternResistance = Zones.GetNearestResistance(currentPrice, 1);

   if(!Scorer.Update())
      return;

   Scorer.ApplyLevelBias(currentPrice, nearestSupport, nearestResistance, LevelWeight);
   Scorer.ApplyPatternScore(Patterns.Update(patternSupport, patternResistance));
   Scorer.ApplyChartPatternScore(ChartPatterns.Update());

   const int direction = Scorer.GetDirection();
   const double fundamentalScore = External.UpdateAndScore(direction);
   Scorer.ApplyFundamentalScore(fundamentalScore);

   Zones.DrawFiltered(currentPrice, MinTouchCount, MaxLevelsToDraw, clrLime, clrTomato);

   string logLine = Scorer.BuildScoreLog() +
                    " | LevelScore=" + DoubleToString(Scorer.GetLevelScore(), 2) +
                    " | PatternScore=" + DoubleToString(Scorer.GetPatternScore(), 2) +
                    " | ChartPatternScore=" + DoubleToString(Scorer.GetChartPatternScore(), 2) +
                    " | FundamentalScore=" + DoubleToString(Scorer.GetFundamentalScore(), 2) +
                    " | PA=" + Patterns.GetLastPattern() +
                    " | CP=" + ChartPatterns.GetLastPattern();
   Print(logLine);
   Logger.LogInfo("امتیاز کلی: " + DoubleToString(Scorer.GetGlobalScore(), 2) + " | " + External.GetLastSummary());

   if(External.ShouldBlockAutoTrading())
   {
      Logger.LogFundamental("به دلیل خبر HIGH معاملات خودکار موقتاً متوقف شد.");
      return;
   }

   AdvManager.Manage(UseBreakEven, BreakEvenTrigger,
                     UseTrailing, TrailingTrigger, TrailingStep,
                     UseEarlyExit, Scorer.GetGlobalScore(), g_prevGlobalScore, EarlyExitScoreDrop);

   if(!g_autoTradingState)
      return;

   if(!Scorer.ShouldOpenTrade())
      return;

   const int finalDirection = Scorer.GetDirection();
   if(Trader.HasPositionInDirection(finalDirection))
      return;

   const double lot = Risk.CalculateLot(RiskPercent, (double)FixedSL);
   double slPrice = 0.0;
   double tpPrice = 0.0;
   if(lot <= 0.0 || !Risk.BuildDynamicStops(finalDirection, (double)FixedSL, (double)FixedTP,
                                             UseATRforSL, ATRPeriod, ATRExtraMultiplier,
                                             nearestSupport, nearestResistance,
                                             slPrice, tpPrice))
   {
      Logger.LogRisk("محاسبه حجم/حدضرر/حدسود معتبر نبود.");
      return;
   }

   if(Trader.Open(finalDirection, lot, slPrice, tpPrice))
      Logger.LogTrade("معامله باز شد. جهت=" + IntegerToString(finalDirection) + " حجم=" + DoubleToString(lot, 2));

   g_prevGlobalScore = Scorer.GetGlobalScore();
}

void OnTimer()
{
   if(!ShowPanel)
      return;

   string tradeInfo = "No Position";
   if(PositionSelect(_Symbol))
   {
      const long type = PositionGetInteger(POSITION_TYPE);
      const double vol = PositionGetDouble(POSITION_VOLUME);
      const double profit = PositionGetDouble(POSITION_PROFIT);
      tradeInfo = (type == POSITION_TYPE_BUY ? "BUY" : "SELL") +
                  (" Vol=" + DoubleToString(vol, 2) + " P/L=" + DoubleToString(profit, 2));
   }

   Dash.Update(Scorer.GetGlobalScore(),
               Scorer.BuildScoreLog(),
               g_autoTradingState,
               tradeInfo,
               External.GetLastSummary());
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(Dash.IsAutoButton(sparam))
   {
      g_autoTradingState = !g_autoTradingState;
      Logger.LogInfo(g_autoTradingState ? "AutoTrading فعال شد." : "AutoTrading غیرفعال شد.");
   }
   else if(Dash.IsCloseAllButton(sparam))
   {
      AdvManager.CloseAll();
      Logger.LogTrade("بستن همه معاملات توسط پنل انجام شد.");
   }
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   delete MTF;
   delete Scorer;
   delete Risk;
   delete Trader;
   delete Zones;
   delete Levels;
   delete Patterns;
   delete ChartPatterns;
   delete AdvManager;
   delete External;
   delete Dash;
   delete Logger;
}
//+------------------------------------------------------------------+
