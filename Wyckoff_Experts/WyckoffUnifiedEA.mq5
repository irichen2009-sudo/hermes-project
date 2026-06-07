//+------------------------------------------------------------------+
//|                                      WyckoffUnifiedEA.mq5        |
//|                         Wyckoff Unified Trading System            |
//|                    Five-Phase Auto Recognition + Panel UI         |
//+------------------------------------------------------------------+
#property copyright "Wyckoff UTS"
#property link      ""
#property version   "3.00"
#property strict
#property description "Wyckoff Unified Trading System v3 - Professional Dashboard"

#include <Wyckoff/WyckoffCore.mqh>
#include <Wyckoff/WyckoffPhaseEngine.mqh>
#include <Wyckoff/WyckoffSignalEngine.mqh>
#include <Wyckoff/WyckoffRiskManager.mqh>
#include <Trade/Trade.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Panel.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input group "=== Wyckoff Phase Detection ==="
input int      InpRangeLookback     = 100;    // Range lookback bars
input int      InpMinRangeBars      = 10;     // Minimum range bars
input double   InpRangeATRFactor    = 0.5;    // Range ATR factor
input double   InpVolClimaxMult     = 2.5;    // Volume climax multiplier
input double   InpVolLowMult        = 0.3;    // Low volume multiplier

input group "=== Signal Settings ==="
input ENUM_SIGNAL_MODE InpSignalMode = SIGNAL_MODE_MODERATE; // Signal mode
input double   InpRiskRewardMin     = 2.0;    // Min risk:reward ratio
input double   InpATR_SL_Mult       = 1.5;    // ATR stop loss multiplier
input double   InpATR_TP1_Mult      = 2.0;    // ATR TP1 multiplier
input double   InpATR_TP2_Mult      = 3.5;    // ATR TP2 multiplier
input double   InpATR_TP3_Mult      = 5.0;    // ATR TP3 multiplier

input group "=== Risk Management ==="
input ENUM_RISK_LEVEL InpRiskLevel  = RISK_MODERATE; // Risk level
input double   InpMaxDailyLossPct  = 3.0;    // Max daily loss %
input int      InpMaxOpenPositions = 3;      // Max open positions
input int      InpMaxTradesPerDay  = 5;      // Max trades per day
input double   InpMaxSpreadPoints  = 30;     // Max spread (points)

input group "=== Trading Settings ==="
input double   InpLotSize          = 0.01;   // Lot size (0=auto)
input bool     InpUseAutoLot       = true;   // Use auto lot sizing
input int      InpMagicNumber      = 202401; // Magic number
input int      InpSlippage         = 30;     // Max slippage (points)
input bool     InpEnableTrading    = true;   // Enable live trading

input group "=== Panel Settings ==="
input int      InpPanelX           = 10;     // Panel X position
input int      InpPanelY           = 30;     // Panel Y position
input int      InpPanelWidth       = 380;    // Panel width
input color    InpPanelBgColor     = C'18,18,28';     // Panel background (dark navy)
input color    InpHeaderColor      = clrGold;          // Header color
input color    InpTextColor        = clrWhite;         // Text color
input color    InpBullColor        = clrLime;          // Bullish color
input color    InpBearColor        = clrRed;           // Bearish color
input color    InpNeutralColor     = clrYellow;        // Neutral color
input color    InpSectionColor     = clrDodgerBlue;    // Section header color
input color    InpDividerColor     = C'45,45,65';      // Divider line color
input color    InpValueColor       = clrWhite;         // Value text color
input color    InpLabelColor       = C'180,180,200';   // Label text color

//+------------------------------------------------------------------+
//| Layout constants                                                  |
//+------------------------------------------------------------------+
#define PADDING_L         14
#define PADDING_R         14
#define PADDING_T         8
#define SECTION_GAP       6
#define ROW_H             17
#define SECT_HDR_H        19
#define DIVIDER_H         1
#define HEADER_H          26
#define BTN_H             20
#define BTN_W             72
#define STATUS_H          18

//+------------------------------------------------------------------+
//| Professional Dashboard Panel Class                                |
//| Draggable, Resizable, Dark Theme                                  |
//+------------------------------------------------------------------+
class CWyckoffPanel : public CAppDialog
{
private:
   int               m_x1, m_y1, m_x2, m_y2;
   int               m_panelW;
   bool              m_dragging;
   int               m_dragOffsetX;
   int               m_dragOffsetY;
   bool              m_resizing;
   int               m_resizeMinW;
   bool              m_detailExpanded;

   //--- Background
   CPanel            m_bgMain;

   //--- Header
   CLabel            m_headerLabel;
   CButton           m_btnToggle;

   //--- Row labels
   CLabel            m_lblServerTime;
   CLabel            m_lblSymbol;
   CLabel            m_lblEntryCond;
   CLabel            m_lblEntryPrice;
   CLabel            m_lblSL;
   CLabel            m_lblTP1;
   CLabel            m_lblTP2;
   CLabel            m_lblTP3;
   CLabel            m_lblDailyPnL;
   CLabel            m_lblTotalPnL;
   CLabel            m_lblLotSize;
   CLabel            m_lblPositions;

   //--- Detail section
   CLabel            m_lblDetailHdr;
   CLabel            m_lblATR;
   CLabel            m_lblVol;
   CLabel            m_lblTrend;
   CLabel            m_lblPV;
   CPanel            m_bgDetail;

   //--- Resize handle
   CPanel            m_dragHandle;

   //--- Status
   CLabel            m_lblStatus;

   //--- Toggle button hit-test area
   int               m_toggleX1, m_toggleY1, m_toggleX2, m_toggleY2;

   void              CreateLabel(CLabel &lbl, string name, int x1, int y, int x2, string text, color clr, int fontSize);
   void              CreateDivider(int x1, int y, int x2);

public:
                     CWyckoffPanel(void);
                    ~CWyckoffPanel(void);

   bool              Create(const long chart, const string name, const int subwin,
                            const int x1, const int y1, const int x2, const int y2);
   void              ProcessMouseEvents(const int id, const long &lparam, const double &dparam, const string &sparam);

   void              ToggleDetail();
   bool              IsDetailExpanded() { return m_detailExpanded; }

   void              UpdateServerTime(string timeStr);
   void              UpdateSymbol(string sym);
   void              UpdateEntryCondition(string cond);
   void              UpdateEntryPrice(double entry);
   void              UpdateSL(double sl);
   void              UpdateTP(double tp1, double tp2, double tp3);
   void              UpdateDailyPnL(double pnl);
   void              UpdateTotalPnL(double pnl);
   void              UpdateLotSize(double lot);
   void              UpdatePositions(int count);
   void              UpdateStatus(string text, color clr);

   //--- Legacy compatibility
   void              UpdateDetailATR(double atr);
   void              UpdateDetailVol(string vol);
   void              UpdateDetailTrend(string trend);
   void              UpdateDetailPV(string pv);
   void              UpdateDetailLot(double lot);
   void              UpdateDetailDailyPnL(double pnl);

protected:
   // void              OnClickToggle();  // handled via ProcessMouseEvents
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CWyckoffPanel::CWyckoffPanel(void)
{
   m_x1 = m_y1 = m_x2 = m_y2 = 0;
   m_panelW = 360;
   m_dragging = false;
   m_resizing = false;
   m_detailExpanded = false;
   m_resizeMinW = 260;
   m_dragOffsetX = 0;
   m_dragOffsetY = 0;
   m_toggleX1 = m_toggleY1 = m_toggleX2 = m_toggleY2 = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CWyckoffPanel::~CWyckoffPanel(void)
{
}

//+------------------------------------------------------------------+
//| Helper: Create label                                              |
//+------------------------------------------------------------------+
void CWyckoffPanel::CreateLabel(CLabel &lbl, string name, int x1, int y, int x2, string text, color clr, int fontSize)
{
   lbl.Create(0, name, 0, x1, y, x2, y + ROW_H);
   lbl.Text(text);
   lbl.Color(clr);
   lbl.FontSize(fontSize);
   Add(lbl);
}

//+------------------------------------------------------------------+
//| Helper: Create divider                                            |
//+------------------------------------------------------------------+
void CWyckoffPanel::CreateDivider(int x1, int y, int x2)
{
   CPanel div;
   div.Create(0, "WyckoffDiv_" + IntegerToString(y), 0, x1, y, x2, y + DIVIDER_H);
   div.ColorBackground(InpDividerColor);
   div.ColorBorder(InpDividerColor);
   Add(div);
}

//+------------------------------------------------------------------+
//| Create the panel                                                  |
//+------------------------------------------------------------------+
bool CWyckoffPanel::Create(const long chart, const string name, const int subwin,
                            const int x1, const int y1, const int x2, const int y2)
{
   m_x1 = x1; m_y1 = y1; m_x2 = x2; m_y2 = y2;
   m_panelW = x2 - x1;

   if(!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2))
      return false;

   //--- Main background
   m_bgMain.Create(0, "WyckoffMainBG", 0, x1, y1, x2, y2);
   m_bgMain.ColorBackground(InpPanelBgColor);
   m_bgMain.ColorBorder(C'60,60,80');
   Add(m_bgMain);

   int cx1 = x1 + PADDING_L;
   int cx2 = x2 - PADDING_R;
   int cy = y1 + PADDING_T;

   //--- HEADER
   m_headerLabel.Create(0, "WyckoffHdr", 0, cx1, cy, cx2 - BTN_W - 6, cy + HEADER_H);
   m_headerLabel.Text("Wyckoff UTS");
   m_headerLabel.Color(InpHeaderColor);
   m_headerLabel.FontSize(10);
   Add(m_headerLabel);

   m_btnToggle.Create(0, "WyckoffToggle", 0, cx2 - BTN_W, cy + 3, cx2, cy + 3 + BTN_H);
   m_btnToggle.Text("-");
   m_btnToggle.Color(C'200,200,220');
   m_btnToggle.ColorBackground(C'35,35,55');
   m_btnToggle.FontSize(8);
   Add(m_btnToggle);

   cy += HEADER_H + 2;
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 4;

   //--- SERVER TIME
   CreateLabel(m_lblServerTime, "WyckoffTime", cx1, cy, cx2, "Server: --:--:--", InpLabelColor, 9);
   cy += ROW_H;
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 4;

   //--- ACTIVE MARKET
   CreateLabel(m_lblSymbol, "WyckoffSym", cx1, cy, cx2, "Market: --", InpLabelColor, 9);
   cy += ROW_H;
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 4;

   //--- ENTRY CONDITIONS
   CreateLabel(m_lblEntryCond, "WyckoffEntryC", cx1, cy, cx2, "Entry Signal: --", InpSectionColor, 9);
   cy += ROW_H;
   CreateLabel(m_lblEntryPrice, "WyckoffEntryP", cx1 + 10, cy, cx2, "Price: --", InpValueColor, 9);
   cy += ROW_H;
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 4;

   //--- STOP LOSS
   CreateLabel(m_lblSL, "WyckoffSL", cx1, cy, cx2, "SL: --", C'255,100,100', 9);
   cy += ROW_H;
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 4;

   //--- TAKE PROFIT TIERS
   CreateLabel(m_lblTP1, "WyckoffTP1", cx1, cy, cx2, "TP1: --", C'100,255,100', 9);
   cy += ROW_H;
   CreateLabel(m_lblTP2, "WyckoffTP2", cx1, cy, cx2, "TP2: --", C'100,200,255', 9);
   cy += ROW_H;
   CreateLabel(m_lblTP3, "WyckoffTP3", cx1, cy, cx2, "TP3: --", C'180,100,255', 9);
   cy += ROW_H;
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 4;

   //--- DAILY PnL
   CreateLabel(m_lblDailyPnL, "WyckoffDailyPL", cx1, cy, cx2, "Daily P&L: $0.00", InpValueColor, 10);
   cy += ROW_H;

   //--- TOTAL PnL
   CreateLabel(m_lblTotalPnL, "WyckoffTotalPL", cx1, cy, cx2, "Total P&L: $0.00", InpValueColor, 10);
   cy += ROW_H;
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 4;

   //--- LOT SIZE
   CreateLabel(m_lblLotSize, "WyckoffLot", cx1, cy, cx2, "Lot: --", InpValueColor, 9);
   cy += ROW_H;

   //--- POSITIONS
   CreateLabel(m_lblPositions, "WyckoffPos", cx1, cy, cx2, "Positions: 0", InpValueColor, 9);
   cy += ROW_H;

   int baseY = cy;

   //--- DETAIL SECTION (expandable)
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 3;

   CreateLabel(m_lblDetailHdr, "WyckoffDHdr", cx1, cy, cx2, "  \x25C6  DETAILS", InpSectionColor, 9);
   cy += ROW_H;

   CreateLabel(m_lblATR, "WyckoffATR", cx1 + 10, cy, cx2, "ATR: --", InpLabelColor, 8);
   cy += ROW_H;
   CreateLabel(m_lblVol, "WyckoffVol", cx1 + 10, cy, cx2, "Volume: --", InpLabelColor, 8);
   cy += ROW_H;
   CreateLabel(m_lblTrend, "WyckoffTrend", cx1 + 10, cy, cx2, "Trend: --", InpLabelColor, 8);
   cy += ROW_H;
   CreateLabel(m_lblPV, "WyckoffPV", cx1 + 10, cy, cx2, "P-V: --", InpLabelColor, 8);
   cy += ROW_H;

   //--- Detail background
   m_bgDetail.Create(0, "WyckoffDetailBG", 0, x1, baseY + DIVIDER_H + 4, x2, cy + 3);
   m_bgDetail.ColorBackground(C'20,20,35');
   m_bgDetail.ColorBorder(InpDividerColor);
   Add(m_bgDetail);

   //--- Hide detail initially
   m_bgDetail.Hide();
   m_lblDetailHdr.Hide();
   m_lblATR.Hide();
   m_lblVol.Hide();
   m_lblTrend.Hide();
   m_lblPV.Hide();

   //--- Resize handle
   int handleSize = 14;
   m_dragHandle.Create(0, "WyckoffResize", 0, x2 - handleSize, cy + 2, x2, cy + 2 + handleSize);
   m_dragHandle.ColorBackground(C'80,80,100');
   m_dragHandle.ColorBorder(C'100,100,120');
   Add(m_dragHandle);

   //--- Store toggle button click area for manual hit-testing
   m_toggleX1 = cx2 - BTN_W;
   m_toggleY1 = cy + 3;
   m_toggleX2 = cx2;
   m_toggleY2 = cy + 3 + BTN_H;

   //--- STATUS BAR
   int statusY = cy + handleSize + 4;
   m_lblStatus.Create(0, "WyckoffStatus", 0, x1, statusY, x2, statusY + STATUS_H);
   m_lblStatus.Text("Initializing...");
   m_lblStatus.Color(InpNeutralColor);
   m_lblStatus.FontSize(8);
   Add(m_lblStatus);

   m_y2 = statusY + STATUS_H + 2;

   return true;
}

//+------------------------------------------------------------------+
//| Mouse event handler for drag/resize                               |
//+------------------------------------------------------------------+
void CWyckoffPanel::ProcessMouseEvents(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      int mouseX = (int)lparam;
      int mouseY = (int)dparam;
      int handleSize = 14;

      //--- Check resize handle
      if(mouseX >= m_x2 - handleSize && mouseX <= m_x2 &&
         mouseY >= m_y2 - handleSize - STATUS_H - 4 && mouseY <= m_y2)
      {
         if(sparam == "1")
         {
            m_resizing = true;
            return;
         }
      }
      //--- Check toggle button click
      if(mouseX >= m_toggleX1 && mouseX <= m_toggleX2 &&
         mouseY >= m_toggleY1 && mouseY <= m_toggleY2)
      {
         if(sparam == "1")
         {
            ToggleDetail();
            return;
         }
      }
      //--- Check header for drag
      else if(mouseY >= m_y1 && mouseY <= m_y1 + HEADER_H + PADDING_T)
      {
         if(sparam == "1")
         {
            m_dragging = true;
            m_dragOffsetX = mouseX - m_x1;
            m_dragOffsetY = mouseY - m_y1;
            return;
         }
      }

      //--- Mouse button up
      if(sparam == "0")
      {
         m_dragging = false;
         m_resizing = false;
      }

      //--- Dragging
      if(m_dragging)
      {
         int newX = mouseX - m_dragOffsetX;
         int newY = mouseY - m_dragOffsetY;
         int w = m_x2 - m_x1;
         int h = m_y2 - m_y1;
         Move(newX, newY);
         m_x1 = newX; m_y1 = newY;
         m_x2 = newX + w; m_y2 = newY + h;
         ChartRedraw(0);
         return;
      }

      //--- Resizing
      if(m_resizing)
      {
         int newW = mouseX - m_x1;
         int newH = mouseY - m_y1;
         if(newW < m_resizeMinW) newW = m_resizeMinW;
         int newX2 = m_x1 + newW;
         int newY2 = m_y1 + newH;
         // Resize by destroying and recreating the dialog
         long chartId = ChartID();
         Destroy(0);
         Create(chartId, "WyckoffPanel", 0, m_x1, m_y1, newX2, newY2);
         m_x2 = newX2; m_y2 = newY2;
         m_panelW = newW;
         Show();
         ChartRedraw(0);
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Toggle detail                                                     |
//+------------------------------------------------------------------+
void CWyckoffPanel::ToggleDetail()
{
   m_detailExpanded = !m_detailExpanded;

   if(m_detailExpanded)
   {
      m_bgDetail.Show();
      m_lblDetailHdr.Show();
      m_lblATR.Show();
      m_lblVol.Show();
      m_lblTrend.Show();
      m_lblPV.Show();
      m_btnToggle.Text("-");
   }
   else
   {
      m_bgDetail.Hide();
      m_lblDetailHdr.Hide();
      m_lblATR.Hide();
      m_lblVol.Hide();
      m_lblTrend.Hide();
      m_lblPV.Hide();
      m_btnToggle.Text("+");
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Update methods                                                    |
//+------------------------------------------------------------------+
void CWyckoffPanel::UpdateServerTime(string timeStr)
{
   m_lblServerTime.Text("Server: " + timeStr);
}

void CWyckoffPanel::UpdateSymbol(string sym)
{
   m_lblSymbol.Text("Market: " + sym);
}

void CWyckoffPanel::UpdateEntryCondition(string cond)
{
   m_lblEntryCond.Text("Entry Signal: " + cond);
   color c = InpLabelColor;
   if(StringFind(cond, "LONG") >= 0 || StringFind(cond, "Spring") >= 0 || StringFind(cond, "SOS") >= 0)
      c = clrLime;
   else if(StringFind(cond, "SHORT") >= 0 || StringFind(cond, "UTAD") >= 0 || StringFind(cond, "SOW") >= 0)
      c = clrRed;
   else if(StringFind(cond, "Prepare") >= 0)
      c = clrYellow;
   m_lblEntryCond.Color(c);
}

void CWyckoffPanel::UpdateEntryPrice(double entry)
{
   if(entry > 0)
      m_lblEntryPrice.Text("Price: " + DoubleToString(entry, _Digits));
   else
      m_lblEntryPrice.Text("Price: --");
}

void CWyckoffPanel::UpdateSL(double sl)
{
   if(sl > 0)
      m_lblSL.Text("SL: " + DoubleToString(sl, _Digits));
   else
      m_lblSL.Text("SL: --");
}

void CWyckoffPanel::UpdateTP(double tp1, double tp2, double tp3)
{
   if(tp1 > 0)
   {
      m_lblTP1.Text("TP1: " + DoubleToString(tp1, _Digits));
      m_lblTP2.Text("TP2: " + DoubleToString(tp2, _Digits));
      m_lblTP3.Text("TP3: " + DoubleToString(tp3, _Digits));
   }
   else
   {
      m_lblTP1.Text("TP1: --");
      m_lblTP2.Text("TP2: --");
      m_lblTP3.Text("TP3: --");
   }
}

void CWyckoffPanel::UpdateDailyPnL(double pnl)
{
   m_lblDailyPnL.Text("Daily P&L: $" + DoubleToString(pnl, 2));
   m_lblDailyPnL.Color((pnl >= 0) ? clrLime : clrRed);
}

void CWyckoffPanel::UpdateTotalPnL(double pnl)
{
   m_lblTotalPnL.Text("Total P&L: $" + DoubleToString(pnl, 2));
   m_lblTotalPnL.Color((pnl >= 0) ? clrLime : clrRed);
}

void CWyckoffPanel::UpdateLotSize(double lot)
{
   m_lblLotSize.Text("Lot: " + DoubleToString(lot, 2));
}

void CWyckoffPanel::UpdatePositions(int count)
{
   m_lblPositions.Text("Positions: " + IntegerToString(count));
}

void CWyckoffPanel::UpdateStatus(string text, color clr)
{
   m_lblStatus.Text(text);
   m_lblStatus.Color(clr);
}

//--- Legacy compatibility methods
void CWyckoffPanel::UpdateDetailATR(double atr)
{
   m_lblATR.Text("ATR: " + DoubleToString(atr, _Digits));
}

void CWyckoffPanel::UpdateDetailVol(string vol)
{
   m_lblVol.Text("Volume: " + vol);
}

void CWyckoffPanel::UpdateDetailTrend(string trend)
{
   m_lblTrend.Text("Trend: " + trend);
}

void CWyckoffPanel::UpdateDetailPV(string pv)
{
   m_lblPV.Text("P-V: " + pv);
}

void CWyckoffPanel::UpdateDetailLot(double lot)
{
   UpdateLotSize(lot);
}

void CWyckoffPanel::UpdateDetailDailyPnL(double pnl)
{
   UpdateDailyPnL(pnl);
}


//+------------------------------------------------------------------+
//| Global variables                                                  |
//+------------------------------------------------------------------+
CWyckoffPanel*        g_panel         = NULL;
CWyckoffPhaseEngine*  g_phaseEngine   = NULL;
CWyckoffSignalEngine* g_signalEngine  = NULL;
CWyckoffRiskManager*  g_riskManager    = NULL;
CTrade                g_trade;

//+------------------------------------------------------------------+
//| Phase name mapping                                                |
//+------------------------------------------------------------------+
string PhaseName(ENUM_WYCKOFF_PHASE phase)
{
   switch(phase)
   {
      case WYCKOFF_PHASE_A:       return "A (Stopping)";
      case WYCKOFF_PHASE_B:       return "B (Cause)";
      case WYCKOFF_PHASE_C:       return "C (Test)";
      case WYCKOFF_PHASE_D:       return "D (Trend In)";
      case WYCKOFF_PHASE_E:       return "E (Trend Out)";
      default:                    return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Event name mapping                                                |
//+------------------------------------------------------------------+
string EventName(ENUM_WYCKOFF_EVENT evt)
{
   switch(evt)
   {
      case WYCKOFF_EVENT_PS:      return "PS (Prelim Support)";
      case WYCKOFF_EVENT_SC:      return "SC (Selling Climax)";
      case WYCKOFF_EVENT_AR:      return "AR (Auto Reaction)";
      case WYCKOFF_EVENT_ST:      return "ST (Secondary Test)";
      case WYCKOFF_EVENT_PS_LONG: return "PS Long";
      case WYCKOFF_EVENT_BC:      return "BC (Buying Climax)";
      case WYCKOFF_EVENT_UA:      return "UA (Upthrust After)";
      case WYCKOFF_EVENT_mSOW:    return "mSOW";
      case WYCKOFF_EVENT_SPRING:  return "Spring";
      case WYCKOFF_EVENT_UTAD:    return "UTAD";
      case WYCKOFF_EVENT_LPS:     return "LPS";
      case WYCKOFF_EVENT_LPSY:    return "LPSY";
      case WYCKOFF_EVENT_SOS:     return "SOS";
      case WYCKOFF_EVENT_SOW:     return "SOW";
      case WYCKOFF_EVENT_MSOS:    return "MSOS";
      case WYCKOFF_EVENT_MSOW:    return "MSOW";
      case WYCKOFF_EVENT_BUEC:    return "BUEC";
      case WYCKOFF_EVENT_JAC:     return "JAC";
      case WYCKOFF_EVENT_FTI:     return "FTI";
      case WYCKOFF_EVENT_BO:      return "Breakout";
      default:                    return "None";
   }
}

//+------------------------------------------------------------------+
//| State name mapping                                                |
//+------------------------------------------------------------------+
string StateName(ENUM_MARKET_STATE state)
{
   switch(state)
   {
      case STATE_NO_TRADE:        return "No Trade";
      case STATE_OBSERVE:         return "Observe";
      case STATE_CONTRA_SHORT:    return "Contra Short";
      case STATE_CONTRA_LONG:     return "Contra Long";
      case STATE_PREPARE_LONG:    return "Prepare Long";
      case STATE_PREPARE_SHORT:   return "Prepare Short";
      case STATE_ENTER_LONG:      return "ENTER LONG";
      case STATE_ENTER_SHORT:     return "ENTER SHORT";
      case STATE_HOLD_LONG:       return "Hold Long";
      case STATE_HOLD_SHORT:      return "Hold Short";
      case STATE_EXIT_LONG:       return "Exit Long";
      case STATE_EXIT_SHORT:      return "Exit Short";
      case STATE_EMERGENCY_EXIT:  return "EMERGENCY EXIT";
      default:                    return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Structure type name mapping                                       |
//+------------------------------------------------------------------+
string StructureName(ENUM_STRUCTURE_TYPE st)
{
   switch(st)
   {
      case STRUCT_ACCUMULATION_1: return "Accumulation (w/ Spring)";
      case STRUCT_ACCUMULATION_2: return "Accumulation (no Spring)";
      case STRUCT_DISTRIBUTION_1: return "Distribution (w/ UTAD)";
      case STRUCT_DISTRIBUTION_2: return "Distribution (no UTAD)";
      case STRUCT_REACCUMULATION: return "Reaccumulation";
      case STRUCT_REDISTRIBUTION: return "Redistribution";
      default:                    return "None";
   }
}

//+------------------------------------------------------------------+
//| PV Harmony name mapping                                           |
//+------------------------------------------------------------------+
string PVHarmonyName(ENUM_PV_HARMONY pv)
{
   switch(pv)
   {
      case PV_HARMONY_BULLISH:    return "Bullish";
      case PV_HARMONY_BEARISH:    return "Bearish";
      case PV_DIVERGENCE_WARNING: return "Divergence!";
      default:                    return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Initialize trade object
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);

   //--- Create panel
   g_panel = new CWyckoffPanel();
   if(g_panel == NULL)
   {
      Print("ERROR: Failed to create panel");
      return INIT_FAILED;
   }

   int x1 = InpPanelX;
   int y1 = InpPanelY;
   int x2 = x1 + InpPanelWidth;
   int y2 = y1 + 420; // initial height, will be adjusted by content

   if(!g_panel.Create(0, "WyckoffPanel", 0, x1, y1, x2, y2))
   {
      Print("ERROR: Failed to create panel dialog");
      delete g_panel;
      g_panel = NULL;
      return INIT_FAILED;
   }

   //--- Initialize phase engine
   g_phaseEngine = new CWyckoffPhaseEngine();
   if(g_phaseEngine == NULL || !g_phaseEngine.Init(_Symbol, PERIOD_CURRENT))
   {
      Print("ERROR: Failed to initialize phase engine");
      return INIT_FAILED;
   }

   //--- Initialize signal engine
   g_signalEngine = new CWyckoffSignalEngine();
   if(g_signalEngine == NULL || !g_signalEngine.Init(_Symbol, PERIOD_CURRENT, InpSignalMode))
   {
      Print("ERROR: Failed to initialize signal engine");
      return INIT_FAILED;
   }

   //--- Initialize risk manager
   g_riskManager = new CWyckoffRiskManager();
   if(g_riskManager == NULL || !g_riskManager.Init(_Symbol, InpRiskLevel))
   {
      Print("ERROR: Failed to initialize risk manager");
      return INIT_FAILED;
   }

   //--- Configure risk parameters
   g_riskManager.SetMaxDailyLossPercent(InpMaxDailyLossPct);
   g_riskManager.SetMaxOpenPositions(InpMaxOpenPositions);
   g_riskManager.SetMaxTradesPerDay(InpMaxTradesPerDay);
   g_riskManager.SetMaxSpreadPoints(InpMaxSpreadPoints);

   //--- Configure signal parameters
   g_signalEngine.SetRiskRewardMin(InpRiskRewardMin);
   g_signalEngine.SetATRMultiplierSL(InpATR_SL_Mult);
   g_signalEngine.SetATRMultiplierTP(InpATR_TP1_Mult, InpATR_TP2_Mult, InpATR_TP3_Mult);

   //--- Show panel
   g_panel.Show();

   //--- Initial status
   g_panel.UpdateStatus("System Ready", clrLime);

   Print("Wyckoff Unified Trading System v3 initialized successfully");
   Print("Panel: ", InpPanelWidth, "px wide, collapsible detail section");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_panel != NULL)
   {
      g_panel.Destroy(reason);
      delete g_panel;
      g_panel = NULL;
   }

   if(g_phaseEngine != NULL)
   {
      g_phaseEngine.Deinit();
      delete g_phaseEngine;
      g_phaseEngine = NULL;
   }

   if(g_signalEngine != NULL)
   {
      g_signalEngine.Deinit();
      delete g_signalEngine;
      g_signalEngine = NULL;
   }

   if(g_riskManager != NULL)
   {
      g_riskManager.Deinit();
      delete g_riskManager;
      g_riskManager = NULL;
   }

   ObjectsDeleteAll(0, "Wyckoff");

   Print("Wyckoff Unified Trading System v3 deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(g_panel == NULL || g_phaseEngine == NULL ||
      g_signalEngine == NULL || g_riskManager == NULL)
      return;

   g_riskManager.OnTick();

   PhaseDetectionResult phaseResult = g_phaseEngine.DetectCurrentPhase();
   WyckoffStructure structure = g_phaseEngine.GetStructure();
   CWyckoffCore* core = g_phaseEngine.GetCore();

   WyckoffSignal signal;
   signal.Reset();

   if(phaseResult.isValid)
   {
      VolumeAnalysis va = core.AnalyzeVolume();
      TrendHealth th = core.AnalyzeTrendHealth();
      signal = g_signalEngine.GenerateSignal(phaseResult, structure, va, th);
   }

   //--- Server time
   MqlDateTime dt;
   TimeCurrent(dt);
   string timeStr = StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec);
   g_panel.UpdateServerTime(timeStr);

   //--- Active market
   g_panel.UpdateSymbol(_Symbol);

   //--- Entry condition
   string entryCond = "No Signal";
   ENUM_MARKET_STATE marketState = STATE_NO_TRADE;
   if(phaseResult.isValid)
   {
      if(phaseResult.detectedEvent == WYCKOFF_EVENT_SPRING)
         { marketState = STATE_PREPARE_LONG; entryCond = "Prepare LONG (Spring)"; }
      else if(phaseResult.detectedEvent == WYCKOFF_EVENT_UTAD)
         { marketState = STATE_PREPARE_SHORT; entryCond = "Prepare SHORT (UTAD)"; }
      else if(phaseResult.detectedEvent == WYCKOFF_EVENT_SOS)
         { marketState = STATE_ENTER_LONG; entryCond = "ENTER LONG (SOS)"; }
      else if(phaseResult.detectedEvent == WYCKOFF_EVENT_SOW)
         { marketState = STATE_ENTER_SHORT; entryCond = "ENTER SHORT (SOW)"; }
      else if(phaseResult.detectedPhase == WYCKOFF_PHASE_B)
         { marketState = STATE_OBSERVE; entryCond = "Phase B - Observe"; }
      else if(phaseResult.detectedPhase == WYCKOFF_PHASE_D)
         { marketState = STATE_OBSERVE; entryCond = "Phase D - Observe"; }
      else if(phaseResult.detectedPhase == WYCKOFF_PHASE_E)
      {
         if(structure.levelSC > 0)
            { marketState = STATE_ENTER_LONG; entryCond = "Phase E LONG"; }
         else
            { marketState = STATE_ENTER_SHORT; entryCond = "Phase E SHORT"; }
      }
      else
      {
         entryCond = PhaseName(phaseResult.detectedPhase);
      }
   }
   g_panel.UpdateEntryCondition(entryCond);

   //--- Signal details
   if(signal.isValid)
   {
      g_panel.UpdateEntryPrice(signal.entryPrice);
      g_panel.UpdateSL(signal.stopLoss);
      g_panel.UpdateTP(signal.takeProfit1, signal.takeProfit2, signal.takeProfit3);

      double lot = InpUseAutoLot ?
                   g_riskManager.CalculateLotSize(signal.entryPrice, signal.stopLoss) :
                   InpLotSize;
      g_panel.UpdateLotSize(lot);
   }
   else
   {
      g_panel.UpdateEntryPrice(0);
      g_panel.UpdateSL(0);
      g_panel.UpdateTP(0, 0, 0);
      g_panel.UpdateLotSize(InpLotSize);
   }

   //--- PnL
   g_panel.UpdateDailyPnL(g_riskManager.GetDailyPnL());
   g_panel.UpdateTotalPnL(g_riskManager.GetTotalPnL());
   g_panel.UpdatePositions(g_riskManager.GetOpenPositionCount());

   //--- Detail fields (expandable section)
   double atr = core.GetATR(0);
   g_panel.UpdateDetailATR(atr);

   VolumeAnalysis va = core.AnalyzeVolume();
   g_panel.UpdateDetailVol("Avg:" + DoubleToString(va.avgVolume, 0) +
                           " Cur:" + DoubleToString(va.currentVolume, 0));

   TrendHealth th = core.AnalyzeTrendHealth();
   string trendStr = "Dir:" + IntegerToString(th.direction) +
                        " Speed:" + DoubleToString(th.speed, 4);
   g_panel.UpdateDetailTrend(trendStr);

   ENUM_PV_HARMONY pv = core.AnalyzePVHarmony();
   g_panel.UpdateDetailPV(PVHarmonyName(pv));

   //--- Status bar
   if(phaseResult.isValid)
   {
      color statusColor = clrLime;
      if(marketState == STATE_ENTER_LONG || marketState == STATE_ENTER_SHORT)
         statusColor = clrLime;
      else if(marketState == STATE_PREPARE_LONG || marketState == STATE_PREPARE_SHORT)
         statusColor = clrYellow;
      else
         statusColor = clrWhite;

      g_panel.UpdateStatus(StateName(marketState), statusColor);
   }
   else
   {
      g_panel.UpdateStatus("Analyzing...", clrYellow);
   }

   //--- Execute trades
   if(InpEnableTrading && signal.isValid && g_riskManager.CanOpenTrade())
   {
      double lot = InpUseAutoLot ?
                   g_riskManager.CalculateLotSize(signal.entryPrice, signal.stopLoss) :
                   InpLotSize;

      if(lot > 0)
      {
         bool success = false;
         if(signal.direction == TRADE_DIR_LONG)
         {
            success = g_trade.Buy(lot, _Symbol, signal.entryPrice,
                                  signal.stopLoss, signal.takeProfit1,
                                  signal.reason);
         }
         else if(signal.direction == TRADE_DIR_SHORT)
         {
            success = g_trade.Sell(lot, _Symbol, signal.entryPrice,
                                   signal.stopLoss, signal.takeProfit1,
                                   signal.reason);
         }

         if(success)
         {
            g_riskManager.OnTradeOpened();
            Print("TRADE: ", signal.reason, " Lot=", lot);
         }
         else
         {
            Print("TRADE FAILED: ", signal.reason, " Error=", GetLastError());
         }
      }
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Chart event handler (for panel drag/resize)                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(g_panel != NULL)
      g_panel.ProcessMouseEvents(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| Trade transaction handler                                         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(g_riskManager == NULL) return;

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      if(trans.deal_type == DEAL_TYPE_BUY || trans.deal_type == DEAL_TYPE_SELL)
      {
         double dealProfit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
         g_riskManager.OnTradeClosed(dealProfit);
      }
   }
}
//+------------------------------------------------------------------+
