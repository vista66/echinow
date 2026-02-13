#ifndef __DASHBOARD_H__
#define __DASHBOARD_H__
//+------------------------------------------------------------------+
//| Dashboard.mqh                                                    |
//| Simple on-chart panel and control buttons.                       |
//| Dependencies: none                                                |
//| Created: 2026-01-01 | Version: 1.00                              |
//+------------------------------------------------------------------+

class CDashboard
{
private:
   bool  m_enabled;
   int   m_x;
   int   m_y;
   color m_bg;
   color m_text;
   string m_prefix;

public:
   CDashboard()
   {
      m_enabled = true;
      m_x = 10;
      m_y = 20;
      m_bg = clrBlack;
      m_text = clrWhite;
      m_prefix = "XAU_Dash_";
   }

   ~CDashboard() { Destroy(); }

   bool Initialize(const bool enabled, const int x, const int y, const color bg, const color text)
   {
      m_enabled = enabled;
      m_x = x;
      m_y = y;
      m_bg = bg;
      m_text = text;
      if(m_enabled)
         Create();
      return true;
   }

   void Create()
   {
      if(!m_enabled)
         return;

      const string label = m_prefix + "Info";
      if(ObjectFind(0, label) < 0)
      {
         ObjectCreate(0, label, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, label, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, label, OBJPROP_XDISTANCE, m_x);
         ObjectSetInteger(0, label, OBJPROP_YDISTANCE, m_y);
         ObjectSetInteger(0, label, OBJPROP_FONTSIZE, 10);
      }

      const string btnAuto = m_prefix + "Auto";
      if(ObjectFind(0, btnAuto) < 0)
      {
         ObjectCreate(0, btnAuto, OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, btnAuto, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, btnAuto, OBJPROP_XDISTANCE, m_x);
         ObjectSetInteger(0, btnAuto, OBJPROP_YDISTANCE, m_y + 50);
         ObjectSetInteger(0, btnAuto, OBJPROP_XSIZE, 120);
         ObjectSetInteger(0, btnAuto, OBJPROP_YSIZE, 20);
      }

      const string btnClose = m_prefix + "CloseAll";
      if(ObjectFind(0, btnClose) < 0)
      {
         ObjectCreate(0, btnClose, OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, btnClose, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, btnClose, OBJPROP_XDISTANCE, m_x + 130);
         ObjectSetInteger(0, btnClose, OBJPROP_YDISTANCE, m_y + 50);
         ObjectSetInteger(0, btnClose, OBJPROP_XSIZE, 120);
         ObjectSetInteger(0, btnClose, OBJPROP_YSIZE, 20);
         ObjectSetString(0, btnClose, OBJPROP_TEXT, "Close All");
      }
   }

   void Update(const double score,
               const string mtfInfo,
               const bool autoTrading,
               const string tradeInfo,
               const string fundamentalInfo)
   {
      if(!m_enabled)
         return;

      const string label = m_prefix + "Info";
      const color scoreColor = (score >= 0.0 ? clrLime : clrTomato);
      ObjectSetInteger(0, label, OBJPROP_COLOR, m_text);
      ObjectSetString(0, label, OBJPROP_TEXT,
                      "Global Score: " + DoubleToString(score, 2) + "\n" +
                      mtfInfo + "\n" +
                      tradeInfo + "\n" +
                      fundamentalInfo);
      ObjectSetInteger(0, label, OBJPROP_BGCOLOR, m_bg);

      const string btnAuto = m_prefix + "Auto";
      ObjectSetString(0, btnAuto, OBJPROP_TEXT, autoTrading ? "Auto Trade ON" : "Auto Trade OFF");
      ObjectSetInteger(0, btnAuto, OBJPROP_BGCOLOR, autoTrading ? clrGreen : clrRed);
      ObjectSetInteger(0, btnAuto, OBJPROP_COLOR, clrWhite);

      // small score marker
      const string mark = m_prefix + "ScoreMark";
      if(ObjectFind(0, mark) < 0)
      {
         ObjectCreate(0, mark, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, mark, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, mark, OBJPROP_XDISTANCE, m_x + 260);
         ObjectSetInteger(0, mark, OBJPROP_YDISTANCE, m_y);
         ObjectSetInteger(0, mark, OBJPROP_FONTSIZE, 14);
      }
      ObjectSetString(0, mark, OBJPROP_TEXT, "●");
      ObjectSetInteger(0, mark, OBJPROP_COLOR, scoreColor);
   }

   bool IsAutoButton(const string name) const { return name == m_prefix + "Auto"; }
   bool IsCloseAllButton(const string name) const { return name == m_prefix + "CloseAll"; }

   void Destroy() const
   {
      ObjectDelete(0, m_prefix + "Info");
      ObjectDelete(0, m_prefix + "Auto");
      ObjectDelete(0, m_prefix + "CloseAll");
      ObjectDelete(0, m_prefix + "ScoreMark");
   }
};

#endif
