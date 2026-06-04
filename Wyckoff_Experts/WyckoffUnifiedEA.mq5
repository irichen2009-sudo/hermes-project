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
//+------------------------------------------------------------------+
class CWyckoffPanel : public CAppDialog
{
private:
   int               m_panelW;
   int               m_baseY;       // Bottom Y when collapsed
   int               m_expandedY;   // Bottom Y when expanded
   bool              m_detailExpanded;

   //--- Background panels for visual grouping
   CPanel            m_bgMain;
   CPanel            m_bgAnalysis;
   CPanel            m_bgSignal;
   CPanel            m_bgTrade;
   CPanel            m_bgRisk;
   CPanel            m_bgDetail;

   //--- Header
   CLabel            m_headerLabel;
   CButton           m_btnToggle;

   //--- Section: Market Analysis
   CLabel            m_lblAnalysisHdr;
   CLabel            m_lblPhase;
   CLabel            m_lblEvent;
   CLabel            m_lblState;
   CLabel            m_lblConfidence;
   CLabel            m_lblStructure;
   CLabel            m_lblRange;

   //--- Section: Signal
   CLabel            m_lblSignalHdr;
   CLabel            m_lblSignal;
   CLabel            m_lblDirection;

   //--- Section: Trade Setup
   CLabel            m_lblTradeHdr;
   CLabel            m_lblEntry;
   CLabel            m_lblSL;
   CLabel            m_lblTP;
   CLabel            m_lblRR;
   CLabel            m_lblLot;

   //--- Section: Risk
   CLabel            m_lblRiskHdr;
   CLabel            m_lblDailyPnL;
   CLabel            m_lblPositions;
   CLabel            m_lblSpread;

   //--- Detail section (expandable)
   CLabel            m_lblDetailHdr;
   CLabel            m_lblATR;
   CLabel            m_lblVol;
   CLabel            m_lblTrend;
   CLabel            m_lblPV;

   //--- Status bar
   CLabel            m_lblStatus;

   //--- Helpers
   void              CreateSectionBackground(CPanel &bg, int x1, int y1, int x2, int y2);
   void              CreateDivider(int x1, int y, int x2);
   void              CreateSectionHeader(CLabel &lbl, string name, int x1, int y, int x2, string text);
   void              CreateRowLabel(CLabel &lbl, string name, int x1, int y, int x2, string text, color clr, int fontSize);

public:
                     CWyckoffPanel(void);
                    ~CWyckoffPanel(void);

   bool              Create(const long chart, const string name, const int subwin,
                            const int x1, const int y1, const int x2, const int y2);
   virtual bool      OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam);

   void              ToggleDetail();
   bool              IsDetailExpanded() { return m_detailExpanded; }

   //--- Update methods
   void              UpdateStatus(string text, color clr);
   void              UpdatePhase(string phase);
   void              UpdateEvent(string evt);
   void              UpdateState(string state);
   void              UpdateConfidence(int conf);
   void              UpdateSignal(string sig);
   void              UpdateDirection(string dir);
   void              UpdateRange(string range);
   void              UpdateStructure(string structType);
   void              UpdateDetailATR(double atr);
   void              UpdateDetailVol(string vol);
   void              UpdateDetailTrend(string trend);
   void              UpdateDetailPV(string pv);
   void              UpdateDetailEntry(double entry);
   void              UpdateDetailSL(double sl);
   void              UpdateDetailTP(double tp1, double tp2, double tp3);
   void              UpdateDetailRR(double rr);
   void              UpdateDetailLot(double lot);
   void              UpdateDetailDailyPnL(double pnl);
   void              UpdateDetailPositions(int count);
   void              UpdateDetailSpread(double spread);

protected:
   void              OnClickToggle();
};

//+------------------------------------------------------------------+
//| Event Map                                                         |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CWyckoffPanel)
   ON_EVENT(ON_CLICK, m_btnToggle, OnClickToggle)
EVENT_MAP_END(CAppDialog)

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CWyckoffPanel::CWyckoffPanel(void)
{
   m_panelW = 380;
   m_baseY = 0;
   m_expandedY = 0;
   m_detailExpanded = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CWyckoffPanel::~CWyckoffPanel(void)
{
}

//+------------------------------------------------------------------+
//| Helper: Create section background panel                           |
//+------------------------------------------------------------------+
void CWyckoffPanel::CreateSectionBackground(CPanel &bg, int x1, int y1, int x2, int y2)
{
   bg.Create(0, "WyckoffBG_" + IntegerToString(y1), 0, x1, y1, x2, y2);
   bg.ColorBackground(C'16,16,26');
   bg.ColorBorder(InpDividerColor);
   Add(bg);
}

//+------------------------------------------------------------------+
//| Helper: Create divider line                                       |
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
//| Helper: Create section header                                     |
//+------------------------------------------------------------------+
void CWyckoffPanel::CreateSectionHeader(CLabel &lbl, string name, int x1, int y, int x2, string text)
{
   lbl.Create(0, name, 0, x1, y, x2, y + SECT_HDR_H);
   lbl.Text(text);
   lbl.Color(InpSectionColor);
   lbl.FontSize(9);
   Add(lbl);
}

//+------------------------------------------------------------------+
//| Helper: Create row label                                          |
//+------------------------------------------------------------------+
void CWyckoffPanel::CreateRowLabel(CLabel &lbl, string name, int x1, int y, int x2, string text, color clr, int fontSize)
{
   lbl.Create(0, name, 0, x1, y, x2, y + ROW_H);
   lbl.Text(text);
   lbl.Color(clr);
   lbl.FontSize(fontSize);
   Add(lbl);
}

//+------------------------------------------------------------------+
//| Create the panel                                                  |
//+------------------------------------------------------------------+
bool CWyckoffPanel::Create(const long chart, const string name, const int subwin,
                            const int x1, const int y1, const int x2, const int y2)
{
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

   //============================================================
   // HEADER
   //============================================================
   m_headerLabel.Create(0, "WyckoffHdr", 0, cx1, cy, cx2 - BTN_W - 6, cy + HEADER_H);
   m_headerLabel.Text("WYCKOFF UNIFIED TRADING SYSTEM");
   m_headerLabel.Color(InpHeaderColor);
   m_headerLabel.FontSize(10);
   Add(m_headerLabel);

   m_btnToggle.Create(0, "WyckoffToggle", 0, cx2 - BTN_W, cy + 3, cx2, cy + 3 + BTN_H);
   m_btnToggle.Text("Expand");
   m_btnToggle.Color(C'200,200,220');
   m_btnToggle.ColorBackground(C'35,35,55');
   m_btnToggle.FontSize(8);
   Add(m_btnToggle);

   cy += HEADER_H + 4;
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + SECTION_GAP;

   //============================================================
   // SECTION: MARKET ANALYSIS
   //============================================================
   int secTop = cy;
   CreateSectionHeader(m_lblAnalysisHdr, "WyckoffAHdr", cx1, cy, cx2, "  \x25C6  MARKET ANALYSIS");
   cy += SECT_HDR_H;

   CreateRowLabel(m_lblPhase, "WyckoffPhase", cx1 + 10, cy, cx2, "Phase: --", InpLabelColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblEvent, "WyckoffEvent", cx1 + 10, cy, cx2, "Event: --", InpLabelColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblState, "WyckoffState", cx1 + 10, cy, cx2, "State: --", InpLabelColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblConfidence, "WyckoffConf", cx1 + 10, cy, cx2, "Confidence: --", InpLabelColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblStructure, "WyckoffStruct", cx1 + 10, cy, cx2, "Structure: --", InpLabelColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblRange, "WyckoffRange", cx1 + 10, cy, cx2, "Range: --", InpLabelColor, 9);
   cy += ROW_H;

   CreateSectionBackground(m_bgAnalysis, cx1, secTop, cx2, cy + 3);
   cy += SECTION_GAP;

   //============================================================
   // SECTION: SIGNAL
   //============================================================
   secTop = cy;
   CreateSectionHeader(m_lblSignalHdr, "WyckoffSHdr", cx1, cy, cx2, "  \x25C6  SIGNAL");
   cy += SECT_HDR_H;

   CreateRowLabel(m_lblSignal, "WyckoffSignal", cx1 + 10, cy, cx2, "Signal: --", InpValueColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblDirection, "WyckoffDir", cx1 + 10, cy, cx2, "Direction: --", InpValueColor, 10);
   cy += ROW_H;

   CreateSectionBackground(m_bgSignal, cx1, secTop, cx2, cy + 3);
   cy += SECTION_GAP;

   //============================================================
   // SECTION: TRADE SETUP
   //============================================================
   secTop = cy;
   CreateSectionHeader(m_lblTradeHdr, "WyckoffTHdr", cx1, cy, cx2, "  \x25C6  TRADE SETUP");
   cy += SECT_HDR_H;

   CreateRowLabel(m_lblEntry, "WyckoffEntry", cx1 + 10, cy, cx2, "Entry: --", InpValueColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblSL, "WyckoffSL", cx1 + 10, cy, cx2, "Stop Loss: --", InpValueColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblTP, "WyckoffTP", cx1 + 10, cy, cx2, "Take Profit: --", InpValueColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblRR, "WyckoffRR", cx1 + 10, cy, cx2, "Risk:Reward: --", InpValueColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblLot, "WyckoffLot", cx1 + 10, cy, cx2, "Lot Size: --", InpValueColor, 9);
   cy += ROW_H;

   CreateSectionBackground(m_bgTrade, cx1, secTop, cx2, cy + 3);
   cy += SECTION_GAP;

   //============================================================
   // SECTION: RISK
   //============================================================
   secTop = cy;
   CreateSectionHeader(m_lblRiskHdr, "WyckoffRHdr", cx1, cy, cx2, "  \x25C6  RISK");
   cy += SECT_HDR_H;

   CreateRowLabel(m_lblDailyPnL, "WyckoffPnL", cx1 + 10, cy, cx2, "Daily P&L: --", InpValueColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblPositions, "WyckoffPos", cx1 + 10, cy, cx2, "Positions: --", InpValueColor, 9);
   cy += ROW_H;
   CreateRowLabel(m_lblSpread, "WyckoffSpread", cx1 + 10, cy, cx2, "Spread: --", InpValueColor, 9);
   cy += ROW_H;

   CreateSectionBackground(m_bgRisk, cx1, secTop, cx2, cy + 3);
   cy += SECTION_GAP;

   //--- Store base Y (collapsed, before detail section)
   m_baseY = cy;

   //============================================================
   // DETAIL SECTION (expandable)
   //============================================================
   CreateDivider(cx1, cy, cx2);
   cy += DIVIDER_H + 3;

   secTop = cy;
   CreateSectionHeader(m_lblDetailHdr, "WyckoffDHdr", cx1, cy, cx2, "  \x25C6  DETAILED ANALYSIS");
   cy += SECT_HDR_H;

   CreateRowLabel(m_lblATR, "WyckoffATR", cx1 + 10, cy, cx2, "ATR: --", InpLabelColor, 8);
   cy += ROW_H;
   CreateRowLabel(m_lblVol, "WyckoffVol", cx1 + 10, cy, cx2, "Volume: --", InpLabelColor, 8);
   cy += ROW_H;
   CreateRowLabel(m_lblTrend, "WyckoffTrend", cx1 + 10, cy, cx2, "Trend: --", InpLabelColor, 8);
   cy += ROW_H;
   CreateRowLabel(m_lblPV, "WyckoffPV", cx1 + 10, cy, cx2, "P-V Harmony: --", InpLabelColor, 8);
   cy += ROW_H;

   CreateSectionBackground(m_bgDetail, cx1, secTop, cx2, cy + 3);

   //--- Store expanded Y
   m_expandedY = cy + 3;

   //--- Hide detail section initially
   m_bgDetail.Hide();
   m_lblDetailHdr.Hide();
   m_lblATR.Hide();
   m_lblVol.Hide();
   m_lblTrend.Hide();
   m_lblPV.Hide();

   //============================================================
   // STATUS BAR
   //============================================================
   int statusY = m_baseY;
   m_lblStatus.Create(0, "WyckoffStatus", 0, x1, statusY, x2, statusY + STATUS_H);
   m_lblStatus.Text("Initializing...");
   m_lblStatus.Color(InpNeutralColor);
   m_lblStatus.FontSize(8);
   Add(m_lblStatus);

   return true;
}

//+------------------------------------------------------------------+
//| Toggle detail visibility                                          |
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
      m_btnToggle.Text("Collapse");
   }
   else
   {
      m_bgDetail.Hide();
      m_lblDetailHdr.Hide();
      m_lblATR.Hide();
      m_lblVol.Hide();
      m_lblTrend.Hide();
      m_lblPV.Hide();
      m_btnToggle.Text("Expand");
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Toggle button click handler                                       |
//+------------------------------------------------------------------+
void CWyckoffPanel::OnClickToggle()
{
   ToggleDetail();
}

//+------------------------------------------------------------------+
//| Update methods                                                    |
//+------------------------------------------------------------------+
void CWyckoffPanel::UpdateStatus(string text, color clr)
{
   m_lblStatus.Text(text);
   m_lblStatus.Color(clr);
}

void CWyckoffPanel::UpdatePhase(string phase)
{
   m_lblPhase.Text("Phase: " + phase);
   m_lblPhase.Color(InpLabelColor);
}

void CWyckoffPanel::UpdateEvent(string evt)
{
   m_lblEvent.Text("Event: " + evt);
   m_lblEvent.Color(InpLabelColor);
}

void CWyckoffPanel::UpdateState(string state)
{
   m_lblState.Text("State: " + state);
   color c = InpNeutralColor;
   if(StringFind(state, "ENTER") >= 0) c = clrLime;
   else if(StringFind(state, "EXIT") >= 0 || StringFind(state, "EMERGENCY") >= 0) c = clrRed;
   else if(StringFind(state, "PREPARE") >= 0) c = clrYellow;
   m_lblState.Color(c);
}

void CWyckoffPanel::UpdateConfidence(int conf)
{
   m_lblConfidence.Text("Confidence: " + IntegerToString(conf) + "/100");
   color c = InpLabelColor;
   if(conf >= 70) c = clrLime;
   else if(conf >= 40) c = clrYellow;
   else c = clrOrangeRed;
   m_lblConfidence.Color(c);
}

void CWyckoffPanel::UpdateSignal(string sig)
{
   m_lblSignal.Text("Signal: " + sig);
   color c = InpValueColor;
   if(StringFind(sig, "Spring") >= 0 || StringFind(sig, "SOS") >= 0) c = clrLime;
   else if(StringFind(sig, "UTAD") >= 0 || StringFind(sig, "SOW") >= 0) c = clrRed;
   m_lblSignal.Color(c);
}

void CWyckoffPanel::UpdateDirection(string dir)
{
   m_lblDirection.Text("Direction: " + dir);
   color c = InpValueColor;
   if(dir == "LONG") c = InpBullColor;
   else if(dir == "SHORT") c = InpBearColor;
   m_lblDirection.Color(c);
}

void CWyckoffPanel::UpdateRange(string range)
{
   m_lblRange.Text("Range: " + range);
   m_lblRange.Color(InpLabelColor);
}

void CWyckoffPanel::UpdateStructure(string structType)
{
   m_lblStructure.Text("Structure: " + structType);
   color c = InpLabelColor;
   if(StringFind(structType, "Accumulation") >= 0 || StringFind(structType, "Reaccumulation") >= 0) c = clrLime;
   else if(StringFind(structType, "Distribution") >= 0 || StringFind(structType, "Redistribution") >= 0) c = clrRed;
   m_lblStructure.Color(c);
}

void CWyckoffPanel::UpdateDetailATR(double atr)
{
   m_lblATR.Text("ATR: " + DoubleToString(atr, _Digits));
   m_lblATR.Color(InpLabelColor);
}

void CWyckoffPanel::UpdateDetailVol(string vol)
{
   m_lblVol.Text("Volume: " + vol);
   m_lblVol.Color(InpLabelColor);
}

void CWyckoffPanel::UpdateDetailTrend(string trend)
{
   m_lblTrend.Text("Trend: " + trend);
   m_lblTrend.Color(InpLabelColor);
}

void CWyckoffPanel::UpdateDetailPV(string pv)
{
   m_lblPV.Text("P-V Harmony: " + pv);
   color c = InpLabelColor;
   if(StringFind(pv, "Bullish") >= 0) c = clrLime;
   else if(StringFind(pv, "Bearish") >= 0) c = clrRed;
   else if(StringFind(pv, "Divergence") >= 0) c = clrOrangeRed;
   m_lblPV.Color(c);
}

void CWyckoffPanel::UpdateDetailEntry(double entry)
{
   m_lblEntry.Text("Entry: " + DoubleToString(entry, _Digits));
   m_lblEntry.Color(InpValueColor);
}

void CWyckoffPanel::UpdateDetailSL(double sl)
{
   m_lblSL.Text("Stop Loss: " + DoubleToString(sl, _Digits));
   m_lblSL.Color(InpValueColor);
}

void CWyckoffPanel::UpdateDetailTP(double tp1, double tp2, double tp3)
{
   m_lblTP.Text("TP: " + DoubleToString(tp1, _Digits) + " / " +
                DoubleToString(tp2, _Digits) + " / " + DoubleToString(tp3, _Digits));
   m_lblTP.Color(InpValueColor);
}

void CWyckoffPanel::UpdateDetailRR(double rr)
{
   m_lblRR.Text("Risk:Reward: 1:" + DoubleToString(rr, 2));
   color c = InpValueColor;
   if(rr >= 3.0) c = clrLime;
   else if(rr >= 2.0) c = clrYellow;
   else if(rr > 0) c = clrOrangeRed;
   m_lblRR.Color(c);
}

void CWyckoffPanel::UpdateDetailLot(double lot)
{
   m_lblLot.Text("Lot Size: " + DoubleToString(lot, 2));
   m_lblLot.Color(InpValueColor);
}

void CWyckoffPanel::UpdateDetailDailyPnL(double pnl)
{
   m_lblDailyPnL.Text("Daily P&L: " + DoubleToString(pnl, 2));
   m_lblDailyPnL.Color((pnl >= 0) ? InpBullColor : InpBearColor);
}

void CWyckoffPanel::UpdateDetailPositions(int count)
{
   m_lblPositions.Text("Positions: " + IntegerToString(count));
   m_lblPositions.Color(InpValueColor);
}

void CWyckoffPanel::UpdateDetailSpread(double spread)
{
   m_lblSpread.Text("Spread: " + DoubleToString(spread, 1) + " pts");
   color c = InpValueColor;
   if(spread > 30) c = clrOrangeRed;
   else if(spread > 20) c = clrYellow;
   m_lblSpread.Color(c);
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

   g_panel.UpdatePhase(PhaseName(phaseResult.detectedPhase));
   g_panel.UpdateEvent(EventName(phaseResult.detectedEvent));

   ENUM_MARKET_STATE marketState = STATE_NO_TRADE;
   if(phaseResult.isValid)
   {
      if(phaseResult.detectedEvent == WYCKOFF_EVENT_SPRING)
         marketState = STATE_PREPARE_LONG;
      else if(phaseResult.detectedEvent == WYCKOFF_EVENT_UTAD)
         marketState = STATE_PREPARE_SHORT;
      else if(phaseResult.detectedEvent == WYCKOFF_EVENT_SOS)
         marketState = STATE_ENTER_LONG;
      else if(phaseResult.detectedEvent == WYCKOFF_EVENT_SOW)
         marketState = STATE_ENTER_SHORT;
      else if(phaseResult.detectedPhase == WYCKOFF_PHASE_B)
         marketState = STATE_OBSERVE;
      else if(phaseResult.detectedPhase == WYCKOFF_PHASE_D)
         marketState = STATE_OBSERVE;
      else if(phaseResult.detectedPhase == WYCKOFF_PHASE_E)
      {
         if(structure.levelSC > 0)
            marketState = STATE_ENTER_LONG;
         else
            marketState = STATE_ENTER_SHORT;
      }
   }

   g_panel.UpdateState(StateName(marketState));
   g_panel.UpdateConfidence(phaseResult.confidence);

   if(signal.isValid)
   {
      g_panel.UpdateSignal(EventName(signal.triggerEvent));
      g_panel.UpdateDirection(signal.direction == TRADE_DIR_LONG ? "LONG" :
                               signal.direction == TRADE_DIR_SHORT ? "SHORT" : "NONE");
   }
   else
   {
      g_panel.UpdateSignal("No Signal");
      g_panel.UpdateDirection("--");
   }

   if(structure.rangeHigh > 0 && structure.rangeLow > 0)
   {
      string rangeStr = DoubleToString(structure.rangeLow, _Digits) + " - " +
                        DoubleToString(structure.rangeHigh, _Digits);
      g_panel.UpdateRange(rangeStr);
   }
   else
   {
      g_panel.UpdateRange("Detecting...");
   }

   g_panel.UpdateStructure(StructureName(structure.type));

   //--- Detail fields
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

   if(signal.isValid)
   {
      g_panel.UpdateDetailEntry(signal.entryPrice);
      g_panel.UpdateDetailSL(signal.stopLoss);
      g_panel.UpdateDetailTP(signal.takeProfit1, signal.takeProfit2, signal.takeProfit3);

      double risk = MathAbs(signal.entryPrice - signal.stopLoss);
      double reward = MathAbs(signal.takeProfit1 - signal.entryPrice);
      double rr = (risk > 0) ? reward / risk : 0;
      g_panel.UpdateDetailRR(rr);

      double lot = InpUseAutoLot ?
                   g_riskManager.CalculateLotSize(signal.entryPrice, signal.stopLoss) :
                   InpLotSize;
      g_panel.UpdateDetailLot(lot);
   }
   else
   {
      g_panel.UpdateDetailEntry(0);
      g_panel.UpdateDetailSL(0);
      g_panel.UpdateDetailTP(0, 0, 0);
      g_panel.UpdateDetailRR(0);
      g_panel.UpdateDetailLot(InpLotSize);
   }

   g_panel.UpdateDetailDailyPnL(g_riskManager.GetDailyPnL());
   g_panel.UpdateDetailPositions(g_riskManager.GetOpenPositionCount());

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double spread = (point > 0) ? (ask - bid) / point : 0;
   g_panel.UpdateDetailSpread(spread);

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
