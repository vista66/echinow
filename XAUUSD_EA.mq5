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

input group "تنظیمات چند تایم‌فریم (MTF)"
input string         Timeframes   = "M1;M5;M15;H1;H4;D1;W1";      // تایم‌فریم‌ها (پیشنهادی برای اپتیمایز: M1 تا W1)
input string         Weights      = "1;2;3;4;5;6;7";              // وزن تایم‌فریم‌ها (پیشنهادی: 1 تا 10)
input ENUM_MA_METHOD IndicatorType = MODE_SMA;                     // نوع میانگین متحرک (پیشنهادی: SMA/EMA)
input int            MAPeriod     = 20;                            // دوره MA (پیشنهادی: 10 تا 100)
input double         Threshold    = 3.0;                           // آستانه ورود امتیاز (پیشنهادی: 1.0 تا 15.0)

input group "مدیریت ریسک"
input double         RiskPercent  = 2.0;                           // درصد ریسک (پیشنهادی: 0.5 تا 3.0)
input int            FixedSL      = 200;                           // حد ضرر ثابت (پیشنهادی: 80 تا 500)
input int            FixedTP      = 400;                           // حد سود ثابت (پیشنهادی: 120 تا 900)

input group "تنظیمات معامله"
input bool           AutoTrading  = true;                          // معاملات خودکار (پیشنهادی: true/false)

input group "تشخیص سطوح"
input int            SwingStrength = 3;                            // قدرت سوئینگ (پیشنهادی: 2 تا 8)
input int            MinPipsBetweenLevels = 50;                    // حداقل فاصله سطوح (پیشنهادی: 20 تا 250)
input int            LevelLookbackBars = 250;                      // بازه اسکن سطوح (پیشنهادی: 100 تا 1000)
input int            MinTouchCount = 2;                            // حداقل برخورد سطح (پیشنهادی: 1 تا 5)
input double         LevelWeight = 2.0;                            // وزن سطوح (پیشنهادی: 0.5 تا 6.0)
input int            MaxLevelsToDraw = 12;                         // حداکثر خطوط روی چارت (پیشنهادی: 4 تا 20)

input group "حد ضرر/سود پویا"
input bool           UseATRforSL = true;                           // استفاده از ATR برای SL (پیشنهادی: true/false)
input int            ATRPeriod = 14;                               // دوره ATR (پیشنهادی: 7 تا 50)
input double         ATRExtraMultiplier = 1.5;                     // ضریب ATR (پیشنهادی: 0.8 تا 3.0)

input group "الگوهای پرایس‌اکشن"
input bool           EnableEngulfing = true;                        // فعال‌سازی انگالفینگ (پیشنهادی: true/false)
input bool           EnablePinBar = true;                           // فعال‌سازی پین‌بار (پیشنهادی: true/false)
input bool           EnableDoji = true;                             // فعال‌سازی دوجی (پیشنهادی: true/false)
input bool           EnableTweezer = true;                          // فعال‌سازی تویزر (پیشنهادی: true/false)
input double         PatternWeight = 3.0;                           // وزن الگوهای کندلی (پیشنهادی: 0.5 تا 8.0)
input int            MaxPatternDistanceFromLevel = 5;               // فاصله مجاز از سطح (پیشنهادی: 2 تا 30)
input int            PatternScanBars = 8;                           // بازه اسکن پترن کندلی (پیشنهادی: 3 تا 50)

input group "الگوهای نموداری"
input bool           EnableTriangle = true;                        // فعال‌سازی مثلث (پیشنهادی: true/false)
input bool           EnableChannel = true;                         // فعال‌سازی کانال (پیشنهادی: true/false)
input bool           EnableRectangle = true;                       // فعال‌سازی مستطیل (پیشنهادی: true/false)
input double         ChartPatternWeight = 4.0;                     // وزن الگوهای نموداری (پیشنهادی: 0.5 تا 10.0)
input int            ChartPatternLookbackBars = 30;                // بازه اسکن الگوی نموداری (پیشنهادی: 10 تا 200)

input group "مدیریت پیشرفته معامله"
input bool           UseBreakEven = true;                          // فعال‌سازی سر‌به‌سر (پیشنهادی: true/false)
input double         BreakEvenTrigger = 50;                        // تریگر BE درصدی (پیشنهادی: 10 تا 90)
input bool           UseTrailing = true;                           // فعال‌سازی تریلینگ (پیشنهادی: true/false)
input double         TrailingTrigger = 30;                         // تریگر تریلینگ درصدی (پیشنهادی: 10 تا 90)
input int            TrailingStep = 20;                            // گام تریلینگ (پیشنهادی: 5 تا 100)
input bool           UseEarlyExit = true;                          // خروج زودهنگام (پیشنهادی: true/false)
input double         EarlyExitScoreDrop = 5.0;                     // افت امتیاز خروج زودهنگام (پیشنهادی: 1.0 تا 20.0)

input group "ماژول داده‌های خارجی"
input bool           UseFundamentalData = true;                    // فعال‌سازی داده بنیادی (پیشنهادی: true/false)
input string         EconomicCalendarFile = "Data\\economic_calendar.csv"; // فایل تقویم اقتصادی (پیشنهادی: مسیر CSV معتبر)
input string         SentimentFile = "Data\\sentiment.csv";      // فایل سنتیمنت (پیشنهادی: مسیر CSV معتبر)
input string         COTFile = "Data\\cot.csv";                  // فایل COT (پیشنهادی: مسیر CSV معتبر)
input double         FundamentalWeight = 5.0;                      // وزن بنیادی (پیشنهادی: 0.5 تا 12.0)

input group "تنظیمات پنل"
input bool           ShowPanel = true;                             // نمایش پنل (پیشنهادی: true/false)
input int            PanelX = 10;                                  // موقعیت افقی پنل (پیشنهادی: 0 تا 1000)
input int            PanelY = 20;                                  // موقعیت عمودی پنل (پیشنهادی: 0 تا 1000)
input color          PanelBgColor = clrBlack;                      // رنگ پس‌زمینه پنل (پیشنهادی: clrBlack/دلخواه)
input color          PanelTextColor = clrWhite;                    // رنگ متن پنل (پیشنهادی: clrWhite/دلخواه)

input group "تنظیمات لاگر"
input bool           EnableLogging = true;                         // فعال‌سازی لاگ (پیشنهادی: true/false)
input string         LogPath = "Data\\logs\\";                  // مسیر لاگ (پیشنهادی: Data\\logs\\)

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
string g_lastNoTradeReason = "";
datetime g_lastNoTradeLogTime = 0;

void LogNoTradeReason(const string reason)
{
   const datetime nowTime = TimeCurrent();
   if(reason != g_lastNoTradeReason || (nowTime - g_lastNoTradeLogTime) >= 60)
   {
      Print("NoTrade: ", reason);
      Logger.LogInfo("عدم ورود: " + reason);
      g_lastNoTradeReason = reason;
      g_lastNoTradeLogTime = nowTime;
   }
}

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
   {
      LogNoTradeReason("به‌روزرسانی MTF/Levels ناموفق بود.");
      return;
   }

   const double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const double nearestSupport = Zones.GetNearestSupport(currentPrice, MinTouchCount);
   const double nearestResistance = Zones.GetNearestResistance(currentPrice, MinTouchCount);
   const double patternSupport = Zones.GetNearestSupport(currentPrice, 1);
   const double patternResistance = Zones.GetNearestResistance(currentPrice, 1);

   if(!Scorer.Update())
   {
      LogNoTradeReason("به‌روزرسانی Score ناموفق بود.");
      return;
   }

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
      LogNoTradeReason("مسدود توسط خبر بنیادی HIGH.");
      g_prevGlobalScore = Scorer.GetGlobalScore();
      return;
   }

   AdvManager.Manage(UseBreakEven, BreakEvenTrigger,
                     UseTrailing, TrailingTrigger, TrailingStep,
                     UseEarlyExit, Scorer.GetGlobalScore(), g_prevGlobalScore, EarlyExitScoreDrop);

   if(!g_autoTradingState)
   {
      LogNoTradeReason("AutoTrading غیرفعال است.");
      g_prevGlobalScore = Scorer.GetGlobalScore();
      return;
   }

   if(!Scorer.ShouldOpenTrade())
   {
      LogNoTradeReason("امتیاز به آستانه ورود نرسید.");
      g_prevGlobalScore = Scorer.GetGlobalScore();
      return;
   }

   const int finalDirection = Scorer.GetDirection();
   if(Trader.HasPositionInDirection(finalDirection))
   {
      LogNoTradeReason("پوزیشن هم‌جهت از قبل باز است.");
      g_prevGlobalScore = Scorer.GetGlobalScore();
      return;
   }

   const double lot = Risk.CalculateLot(RiskPercent, (double)FixedSL);
   double slPrice = 0.0;
   double tpPrice = 0.0;
   if(lot <= 0.0 || !Risk.BuildDynamicStops(finalDirection, (double)FixedSL, (double)FixedTP,
                                             UseATRforSL, ATRPeriod, ATRExtraMultiplier,
                                             nearestSupport, nearestResistance,
                                             slPrice, tpPrice))
   {
      Logger.LogRisk("محاسبه حجم/حدضرر/حدسود معتبر نبود.");
      LogNoTradeReason("حجم یا SL/TP معتبر نبود.");
      g_prevGlobalScore = Scorer.GetGlobalScore();
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
