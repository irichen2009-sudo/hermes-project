//+------------------------------------------------------------------+
//|                                        WyckoffRiskManager.mqh    |
//|                         Wyckoff Unified Trading System            |
//|                    Risk Management & Position Sizing               |
//+------------------------------------------------------------------+
#property copyright "Wyckoff UTS"
#ifndef WYCKOFFRISKMANAGER_MQH
#define WYCKOFFRISKMANAGER_MQH

#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Object.mqh>

//+------------------------------------------------------------------+
//| Risk Level Enumeration                                            |
//+------------------------------------------------------------------+
enum ENUM_RISK_LEVEL
{
   RISK_VERY_LOW   = 0,  // 0.25% per trade
   RISK_LOW        = 1,  // 0.5% per trade
   RISK_MODERATE   = 2,  // 1.0% per trade
   RISK_HIGH       = 3,  // 2.0% per trade
   RISK_VERY_HIGH  = 4   // 3.0% per trade (max)
};

//+------------------------------------------------------------------+
//| Daily Statistics Structure                                        |
//+------------------------------------------------------------------+
struct DailyStats
{
   datetime             date;
   int                  totalTrades;
   int                  winningTrades;
   int                  losingTrades;
   double               grossProfit;
   double               grossLoss;
   double               netProfit;
   double               maxDrawdown;
   double               peakBalance;
   bool                 limitHit;
   
   void Reset()
   {
      date = 0;
      totalTrades = 0;
      winningTrades = 0;
      losingTrades = 0;
      grossProfit = 0;
      grossLoss = 0;
      netProfit = 0;
      maxDrawdown = 0;
      peakBalance = 0;
      limitHit = false;
   }
   
   void UpdatePeak(double balance)
   {
      if(balance > peakBalance) peakBalance = balance;
      double dd = (peakBalance > 0) ? (peakBalance - balance) / peakBalance * 100.0 : 0;
      if(dd > maxDrawdown) maxDrawdown = dd;
   }
};

//+------------------------------------------------------------------+
//| Wyckoff Risk Manager Class                                        |
//+------------------------------------------------------------------+
class CWyckoffRiskManager : public CObject
{
private:
   string               m_symbol;
   ENUM_RISK_LEVEL      m_riskLevel;
   double               m_riskPercent;        // Risk per trade (% of balance)
   double               m_maxDailyLossPercent; // Max daily loss (% of balance)
   double               m_maxDailyLossFixed;   // Max daily loss (fixed amount)
   int                  m_maxOpenPositions;    // Max concurrent positions
   int                  m_maxTradesPerDay;     // Max trades per day
   double               m_maxSpreadPoints;     // Max allowed spread in points
   bool                 m_useDailyLossLimit;   // Enable daily loss limit
   bool                 m_useTrailingStop;     // Enable equity trailing stop
   
   //--- State
   DailyStats           m_todayStats;
   double               m_startingBalance;
   double               m_startingEquity;
   double               m_totalProfit;
   datetime             m_lastTradeDate;
   
   //--- Internal Methods
   double               GetRiskPercent();
   bool                 IsNewDay();
   void                 ResetDailyStats();
   double               CalculatePositionRisk(double entry, double stopLoss, double lotSize);
   
public:
                     CWyckoffRiskManager();
                    ~CWyckoffRiskManager();
   
   bool                 Init(string symbol, ENUM_RISK_LEVEL level);
   void                 Deinit();
   
   //--- Position Sizing
   double               CalculateLotSize(double entryPrice, double stopLossPrice);
   double               CalculateLotSizeFixedRisk(double stopLossDistance);
   double               CalculateLotSizeFixedLot(double lotSize);
   
   //--- Risk Checks
   bool                 CanOpenTrade();
   bool                 IsDailyLimitHit();
   bool                 IsSpreadAcceptable();
   bool                 IsPositionLimitReached();
   bool                 ValidateStopLoss(double entry, double stopLoss, int direction);
   bool                 ValidateTakeProfit(double entry, double tp1, double tp2, double tp3, int direction);
   
   //--- Updates
   void                 OnTradeOpened();
   void                 OnTradeClosed(double profit);
   void                 OnTick(); // Update equity tracking
   
   //--- Stop Management
   double               CalculateBreakEvenStop(double entryPrice, int direction);
   double               CalculateTrailingStop(double entryPrice, double currentPrice, int direction);
   bool                 ShouldMoveToBreakEven(double entryPrice, double currentPrice, int direction);
   
   //--- Getters
   DailyStats           GetTodayStats() { return m_todayStats; }
   double               GetRiskPercentValue() { return m_riskPercent; }
   double               GetDailyPnL() { return m_todayStats.netProfit; }
   double               GetTotalPnL() { return m_totalProfit; }
   double               GetDailyMaxLoss() { return m_startingBalance * m_maxDailyLossPercent / 100.0; }
   int                  GetOpenPositionCount();
   int                  GetRemainingTrades() { return m_maxTradesPerDay - m_todayStats.totalTrades; }
   
   //--- Setters
   void                 SetRiskLevel(ENUM_RISK_LEVEL level);
   void                 SetMaxDailyLossPercent(double percent) { m_maxDailyLossPercent = percent; }
   void                 SetMaxDailyLossFixed(double amount) { m_maxDailyLossFixed = amount; }
   void                 SetMaxOpenPositions(int max) { m_maxOpenPositions = max; }
   void                 SetMaxTradesPerDay(int max) { m_maxTradesPerDay = max; }
   void                 SetMaxSpreadPoints(double points) { m_maxSpreadPoints = points; }
   
   //--- Utility
   string               GetRiskReport();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CWyckoffRiskManager::CWyckoffRiskManager()
{
   m_symbol = "";
   m_riskLevel = RISK_MODERATE;
   m_riskPercent = 1.0;
   m_maxDailyLossPercent = 3.0;
   m_maxDailyLossFixed = 0;
   m_maxOpenPositions = 3;
   m_maxTradesPerDay = 5;
   m_maxSpreadPoints = 30;
   m_useDailyLossLimit = true;
   m_useTrailingStop = true;
   m_startingBalance = 0;
   m_startingEquity = 0;
   m_totalProfit = 0;
   m_lastTradeDate = 0;
   m_todayStats.Reset();
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CWyckoffRiskManager::~CWyckoffRiskManager()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::Init(string symbol, ENUM_RISK_LEVEL level)
{
   m_symbol = symbol;
   m_riskLevel = level;
   m_riskPercent = GetRiskPercent();
   
   m_startingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_startingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Check if new day
   IsNewDay();
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                      |
//+------------------------------------------------------------------+
void CWyckoffRiskManager::Deinit()
{
}

//+------------------------------------------------------------------+
//| Get Risk Percent from Level                                       |
//+------------------------------------------------------------------+
double CWyckoffRiskManager::GetRiskPercent()
{
   switch(m_riskLevel)
   {
      case RISK_VERY_LOW:  return 0.25;
      case RISK_LOW:       return 0.50;
      case RISK_MODERATE:  return 1.00;
      case RISK_HIGH:      return 2.00;
      case RISK_VERY_HIGH: return 3.00;
      default:             return 1.00;
   }
}

//+------------------------------------------------------------------+
//| Set Risk Level                                                    |
//+------------------------------------------------------------------+
void CWyckoffRiskManager::SetRiskLevel(ENUM_RISK_LEVEL level)
{
   m_riskLevel = level;
   m_riskPercent = GetRiskPercent();
}

//+------------------------------------------------------------------+
//| Check if new trading day                                          |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::IsNewDay()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   
   datetime today = StringToTime(IntegerToString(dt.year) + "." + 
                                 IntegerToString(dt.mon) + "." + 
                                 IntegerToString(dt.day));
   
   if(today != m_lastTradeDate)
   {
      ResetDailyStats();
      m_startingBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_lastTradeDate = today;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Reset daily statistics                                            |
//+------------------------------------------------------------------+
void CWyckoffRiskManager::ResetDailyStats()
{
   m_todayStats.Reset();
   MqlDateTime dt;
   TimeCurrent(dt);
   m_todayStats.date = StringToTime(IntegerToString(dt.year) + "." + 
                                     IntegerToString(dt.mon) + "." + 
                                     IntegerToString(dt.day));
   m_todayStats.peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
//| Get Open Position Count                                           |
//+------------------------------------------------------------------+
int CWyckoffRiskManager::GetOpenPositionCount()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == m_symbol)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Can Open Trade - Main Risk Gate                                   |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::CanOpenTrade()
{
   // Check new day
   IsNewDay();
   
   // Check daily loss limit
   if(m_useDailyLossLimit && IsDailyLimitHit())
   {
      Print("RISK: Daily loss limit reached - no new trades");
      return false;
   }
   
   // Check position limit
   if(IsPositionLimitReached())
   {
      Print("RISK: Maximum open positions reached");
      return false;
   }
   
   // Check trade count limit
   if(m_todayStats.totalTrades >= m_maxTradesPerDay)
   {
      Print("RISK: Maximum trades per day reached");
      return false;
   }
   
   // Check spread
   if(!IsSpreadAcceptable())
   {
      Print("RISK: Spread too wide - no new trades");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if daily loss limit is hit                                  |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::IsDailyLimitHit()
{
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   m_todayStats.UpdatePeak(currentBalance);
   
   // Calculate daily P&L
   double dailyPnL = currentBalance - m_startingBalance;
   m_todayStats.netProfit = dailyPnL;
   
   // Check percentage limit
   double maxLoss = m_startingBalance * m_maxDailyLossPercent / 100.0;
   if(dailyPnL < -maxLoss)
   {
      m_todayStats.limitHit = true;
      return true;
   }
   
   // Check fixed limit
   if(m_maxDailyLossFixed > 0 && dailyPnL < -m_maxDailyLossFixed)
   {
      m_todayStats.limitHit = true;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if spread is acceptable                                     |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::IsSpreadAcceptable()
{
   double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   
   if(point == 0) return false;
   
   double spreadPoints = (ask - bid) / point;
   return (spreadPoints <= m_maxSpreadPoints);
}

//+------------------------------------------------------------------+
//| Check if position limit is reached                                |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::IsPositionLimitReached()
{
   return (GetOpenPositionCount() >= m_maxOpenPositions);
}

//+------------------------------------------------------------------+
//| Validate Stop Loss                                                |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::ValidateStopLoss(double entry, double stopLoss, int direction)
{
   if(stopLoss <= 0) return false;
   
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double stopLevel = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
   
   double distance = 0;
   if(direction == 1) // Long
   {
      if(stopLoss >= entry) return false;
      distance = entry - stopLoss;
   }
   else if(direction == -1) // Short
   {
      if(stopLoss <= entry) return false;
      distance = stopLoss - entry;
   }
   
   if(distance < stopLevel)
   {
      Print("RISK: Stop loss too close to entry (", distance/point, " pts, min=", stopLevel/point, " pts)");
      return false;
   }
   
   // Check maximum risk
   double riskAmount = CalculatePositionRisk(entry, stopLoss, 1.0); // Per lot
   double maxRiskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * m_riskPercent / 100.0;
   
   // This is per-lot risk, actual lot size will be calculated
   if(riskAmount > maxRiskAmount * 2)
   {
      Print("RISK: Stop loss too wide (risk per lot: ", riskAmount, " > max: ", maxRiskAmount * 2, ")");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Validate Take Profit                                              |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::ValidateTakeProfit(double entry, double tp1, double tp2, double tp3, int direction)
{
   if(direction == 1) // Long
   {
      if(tp1 <= entry) return false;
      if(tp2 <= tp1) return false;
      if(tp3 <= tp2) return false;
   }
   else if(direction == -1) // Short
   {
      if(tp1 >= entry) return false;
      if(tp2 >= tp1) return false;
      if(tp3 >= tp2) return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Based on Risk                                  |
//+------------------------------------------------------------------+
double CWyckoffRiskManager::CalculateLotSize(double entryPrice, double stopLossPrice)
{
   double stopDistance = MathAbs(entryPrice - stopLossPrice);
   return CalculateLotSizeFixedRisk(stopDistance);
}

//+------------------------------------------------------------------+
//| Calculate Lot Size for Fixed Risk                                 |
//+------------------------------------------------------------------+
double CWyckoffRiskManager::CalculateLotSizeFixedRisk(double stopLossDistance)
{
   if(stopLossDistance <= 0) return 0;
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * m_riskPercent / 100.0;
   
   // Get tick value and size
   double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   
   if(tickValue == 0 || tickSize == 0 || point == 0) return 0;
   
   // Calculate value per point per lot
   double pointValue = tickValue * point / tickSize;
   
   if(pointValue == 0) return 0;
   
   // Lot size = risk amount / (stop distance in points * point value)
   double stopPoints = stopLossDistance / point;
   double lotSize = riskAmount / (stopPoints * pointValue);
   
   // Normalize lot size
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   
   if(lotStep == 0) lotStep = 0.01;
   
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   
   return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Fixed                                          |
//+------------------------------------------------------------------+
double CWyckoffRiskManager::CalculateLotSizeFixedLot(double lotSize)
{
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   
   if(lotStep == 0) lotStep = 0.01;
   
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
   
   return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate Position Risk                                           |
//+------------------------------------------------------------------+
double CWyckoffRiskManager::CalculatePositionRisk(double entry, double stopLoss, double lotSize)
{
   double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   
   if(tickSize == 0 || point == 0) return 0;
   
   double stopPoints = MathAbs(entry - stopLoss) / point;
   double risk = stopPoints * tickValue * lotSize * point / tickSize;
   
   return risk;
}

//+------------------------------------------------------------------+
//| On Trade Opened                                                   |
//+------------------------------------------------------------------+
void CWyckoffRiskManager::OnTradeOpened()
{
   m_todayStats.totalTrades++;
}

//+------------------------------------------------------------------+
//| On Trade Closed                                                   |
//+------------------------------------------------------------------+
void CWyckoffRiskManager::OnTradeClosed(double profit)
{
   if(profit > 0)
   {
      m_todayStats.winningTrades++;
      m_todayStats.grossProfit += profit;
   }
   else
   {
      m_todayStats.losingTrades++;
      m_todayStats.grossLoss += MathAbs(profit);
   }
   
   m_todayStats.netProfit += profit;
   m_totalProfit += profit;
}

//+------------------------------------------------------------------+
//| On Tick - Update equity tracking                                  |
//+------------------------------------------------------------------+
void CWyckoffRiskManager::OnTick()
{
   IsNewDay(); // Check for new day
   
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_todayStats.UpdatePeak(currentBalance);
   m_todayStats.netProfit = currentBalance - m_startingBalance;
   
   // Check daily limit
   if(m_useDailyLossLimit)
      IsDailyLimitHit();
}

//+------------------------------------------------------------------+
//| Calculate Break-Even Stop                                         |
//+------------------------------------------------------------------+
double CWyckoffRiskManager::CalculateBreakEvenStop(double entryPrice, int direction)
{
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * point;
   
   if(direction == 1) // Long
      return entryPrice + spread + point * 2; // Entry + spread + small buffer
   else
      return entryPrice - spread - point * 2;
   
   return entryPrice;
}

//+------------------------------------------------------------------+
//| Should Move to Break-Even                                        |
//+------------------------------------------------------------------+
bool CWyckoffRiskManager::ShouldMoveToBreakEven(double entryPrice, double currentPrice, int direction)
{
   double atr = iATR(m_symbol, PERIOD_CURRENT, 14);
   
   if(direction == 1) // Long
   {
      // Move to BE when price has moved 1 ATR in profit
      return (currentPrice >= entryPrice + atr * 1.0);
   }
   else if(direction == -1) // Short
   {
      return (currentPrice <= entryPrice - atr * 1.0);
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Trailing Stop                                           |
//+------------------------------------------------------------------+
double CWyckoffRiskManager::CalculateTrailingStop(double entryPrice, double currentPrice, int direction)
{
   double atr = iATR(m_symbol, PERIOD_CURRENT, 14);
   double trailDistance = atr * 2.0;
   
   if(direction == 1) // Long
   {
      double newStop = currentPrice - trailDistance;
      // Only move stop up, never down
      double prevStop = CalculateBreakEvenStop(entryPrice, direction);
      return MathMax(newStop, prevStop);
   }
   else if(direction == -1) // Short
   {
      double newStop = currentPrice + trailDistance;
      double prevStop = CalculateBreakEvenStop(entryPrice, direction);
      return MathMin(newStop, prevStop);
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get Risk Report                                                   |
//+------------------------------------------------------------------+
string CWyckoffRiskManager::GetRiskReport()
{
   string report = "";
   
   report += "=== Risk Report ===\n";
   report += "Risk Level: " + IntegerToString(m_riskLevel) + " (" + DoubleToString(m_riskPercent, 1) + "% per trade)\n";
   report += "Daily P&L: " + DoubleToString(m_todayStats.netProfit, 2) + "\n";
   report += "Daily Max Loss: " + DoubleToString(GetDailyMaxLoss(), 2) + "\n";
   report += "Trades Today: " + IntegerToString(m_todayStats.totalTrades) + "/" + IntegerToString(m_maxTradesPerDay) + "\n";
   report += "W/L: " + IntegerToString(m_todayStats.winningTrades) + "/" + IntegerToString(m_todayStats.losingTrades) + "\n";
   report += "Open Positions: " + IntegerToString(GetOpenPositionCount()) + "/" + IntegerToString(m_maxOpenPositions) + "\n";
   report += "Daily Limit Hit: " + (m_todayStats.limitHit ? "YES" : "NO") + "\n";
   report += "Max Drawdown: " + DoubleToString(m_todayStats.maxDrawdown, 2) + "%\n";
   
   return report;
}
//+------------------------------------------------------------------+
#endif // WYCKOFFRISKMANAGER_MQH
