#ifndef __SCORE_CALCULATOR_H__
#define __SCORE_CALCULATOR_H__
//+------------------------------------------------------------------+
//| ScoreCalculator.mqh                                              |
//| Weighted score aggregation and entry decision helper.            |
//| Dependencies: Include\Core\MTFAnalyzer.mqh, Include\Utils\Helpers|
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+
#include "MTFAnalyzer.mqh"
#include "..\Utils\Helpers.mqh"

class CScoreCalculator
{
private:
   CMTFAnalyzer      *m_analyzer;
   double            m_threshold;
   double            m_globalScore;
   int               m_direction;
   double            m_weights[];
   int               m_count;

public:
   CScoreCalculator()
   {
      m_analyzer = NULL;
      m_threshold = 0.0;
      m_globalScore = 0.0;
      m_direction = 0;
      m_count = 0;
   }

   ~CScoreCalculator() {}

   // Initializes with analyzer pointer, weight list and threshold.
   bool Initialize(CMTFAnalyzer *analyzer, const string weightList, const double threshold)
   {
      m_analyzer = analyzer;
      m_threshold = threshold;

      string tokens[];
      m_count = XAUHelpers::SplitSemicolon(weightList, tokens);
      if(m_count <= 0)
      {
         Print("CScoreCalculator.Initialize: invalid weight list");
         return false;
      }

      ArrayResize(m_weights, m_count);
      for(int i = 0; i < m_count; i++)
      {
         m_weights[i] = StringToDouble(tokens[i]);
      }
      return true;
   }

   // Rebuilds global weighted score and direction.
   bool Update()
   {
      if(m_analyzer == NULL)
         return false;

      const int analyzerCount = m_analyzer.GetCount();
      if(analyzerCount <= 0)
         return false;

      if(analyzerCount != m_count)
      {
         Print("CScoreCalculator.Update: weights/timeframes size mismatch");
         return false;
      }

      m_globalScore = 0.0;
      for(int i = 0; i < analyzerCount; i++)
      {
         m_globalScore += (double)m_analyzer.GetScore(i) * m_weights[i];
      }

      if(m_globalScore > m_threshold)
         m_direction = 1;
      else if(m_globalScore < (-m_threshold))
         m_direction = -1;
      else
         m_direction = 0;

      return true;
   }

   // Returns true if signal is strong enough for a new trade.
   bool ShouldOpenTrade() const { return m_direction != 0; }
   int GetDirection() const { return m_direction; }
   double GetGlobalScore() const { return m_globalScore; }

   // Human-readable diagnostic string for Expert log.
   string BuildScoreLog() const
   {
      if(m_analyzer == NULL)
         return "Analyzer=null";

      string log = "Scores: ";
      for(int i = 0; i < m_analyzer.GetCount(); i++)
      {
         if(i > 0)
            log += ", ";
         log += m_analyzer.GetLabel(i) + ":" + IntegerToString(m_analyzer.GetScore(i));
      }
      log += " | Global=" + DoubleToString(m_globalScore, 2);
      return log;
   }
};

#endif
