//+------------------------------------------------------------------+
//|                                       WyckoffSignalEngine.mqh   |
//|                         Wyckoff Unified Trading System            |
//|                    Unified Signal Generator & Trade Manager        |
//+------------------------------------------------------------------+
#property copyright "Wyckoff UTS"
#ifndef WYCKOFFSIGNALENGINE_MQH
#define WYCKOFFSIGNALENGINE_MQH

#property strict

#include "WyckoffPhaseEngine.mqh"
#include <Object.mqh>
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>

//+------------------------------------------------------------------+
//| Signal Strength Constants                                         |
//+------------------------------------------------------------------+
#define SIGNAL_STRONG          8
#define SIGNAL_MODERATE        5
#define SIGNAL_WEAK            3
#define SIGNAL_NONE            0

//+------------------------------------------------------------------+
//| Trade Direction Constants                                         |
//+------------------------------------------------------------------+
#define TRADE_DIR_NONE         0
#define TRADE_DIR_LONG         1
#define TRADE_DIR_SHORT       -1

//+------------------------------------------------------------------+
//| Signal Filter Mode                                                |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_MODE
{
   SIGNAL_MODE_CONSERVATIVE = 0,  // Only highest confidence signals
   SIGNAL_MODE_MODERATE     = 1,  // Moderate+ signals
   SIGNAL_MODE_AGGRESSIVE   = 2   // All valid signals
};

//+------------------------------------------------------------------+
//| Wyckoff Signal Engine Class                                       |
//+------------------------------------------------------------------+
class CWyckoffSignalEngine : public CObject
{
private:
   string               m_symbol;
   ENUM_TIMEFRAMES      m_timeframe;
   CWyckoffPhaseEngine* m_phaseEngine;
   ENUM_SIGNAL_MODE     m_signalMode;
   
   WyckoffSignal        m_lastSignal;
   WyckoffSignal        m_pendingSignal;
   
   //--- Signal Parameters
   double               m_riskRewardMin;     // Minimum risk:reward ratio
   double               m_atrSLMultiplier;   // Stop loss ATR multiplier
   double               m_atrTP1Multiplier;  // TP1 ATR multiplier (50% position)
   double               m_atrTP2Multiplier;  // TP2 ATR multiplier (30% position)
   double               m_atrTP3Multiplier;  // TP3 ATR multiplier (20% trailing)
   
   //--- Internal Methods
   WyckoffSignal        GenerateSpringSignal(PhaseDetectionResult &phaseResult);
   WyckoffSignal        GenerateUTADSignal(PhaseDetectionResult &phaseResult);
   WyckoffSignal        GenerateSOSSignal(PhaseDetectionResult &phaseResult);
   WyckoffSignal        GenerateSOWSignal(PhaseDetectionResult &phaseResult);
   WyckoffSignal        GeneratePhaseBSignal(PhaseDetectionResult &phaseResult);
   WyckoffSignal        GeneratePhaseESignal(PhaseDetectionResult &phaseResult);
   WyckoffSignal        GenerateReaccumSignal(PhaseDetectionResult &phaseResult);
   WyckoffSignal        GenerateRedistSignal(PhaseDetectionResult &phaseResult);
   
   double               CalculateStopLoss(int direction, double entry, WyckoffStructure &structure);
   double               CalculateTakeProfit(int direction, double entry, double stopLoss, int tpLevel);
   bool                 ValidateSignal(WyckoffSignal &signal);
   int                  CalculateConfidence(ENUM_WYCKOFF_EVENT event, WyckoffStructure &structure, 
                                            VolumeAnalysis &va, TrendHealth &th);
   
public:
                     CWyckoffSignalEngine();
                    ~CWyckoffSignalEngine();
   
   bool                 Init(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_SIGNAL_MODE mode);
   void                 Deinit();
   
   //--- Main Signal Generation
   WyckoffSignal        GenerateSignal(PhaseDetectionResult &phaseResult, 
                                       WyckoffStructure &structure,
                                       VolumeAnalysis &va, TrendHealth &th);
   
   //--- Signal Validation
   bool                 IsSignalValid(WyckoffSignal &signal);
   bool                 IsSignalExpired(WyckoffSignal &signal, int maxBars);
   
   //--- Getters
   WyckoffSignal        GetLastSignal() { return m_lastSignal; }
   WyckoffSignal        GetPendingSignal() { return m_pendingSignal; }
   ENUM_SIGNAL_MODE     GetSignalMode() { return m_signalMode; }
   
   //--- Setters
   void                 SetSignalMode(ENUM_SIGNAL_MODE mode) { m_signalMode = mode; }
   void                 SetRiskRewardMin(double rr) { m_riskRewardMin = rr; }
   void                 SetATRMultiplierSL(double mult) { m_atrSLMultiplier = mult; }
   void                 SetATRMultiplierTP(double tp1, double tp2, double tp3);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CWyckoffSignalEngine::CWyckoffSignalEngine()
{
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_phaseEngine = NULL;
   m_signalMode = SIGNAL_MODE_MODERATE;
   m_riskRewardMin = 2.0;
   m_atrSLMultiplier = 1.5;
   m_atrTP1Multiplier = 2.0;
   m_atrTP2Multiplier = 3.5;
   m_atrTP3Multiplier = 5.0;
   m_lastSignal.Reset();
   m_pendingSignal.Reset();
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CWyckoffSignalEngine::~CWyckoffSignalEngine()
{
   Deinit();
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CWyckoffSignalEngine::Init(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_SIGNAL_MODE mode)
{
   m_symbol = symbol;
   m_timeframe = timeframe;
   m_signalMode = mode;
   
   m_phaseEngine = new CWyckoffPhaseEngine();
   if(!m_phaseEngine.Init(m_symbol, m_timeframe))
   {
      Print("ERROR: Failed to initialize PhaseEngine");
      delete m_phaseEngine;
      m_phaseEngine = NULL;
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                      |
//+------------------------------------------------------------------+
void CWyckoffSignalEngine::Deinit()
{
   if(m_phaseEngine != NULL)
   {
      m_phaseEngine.Deinit();
      delete m_phaseEngine;
      m_phaseEngine = NULL;
   }
}

//+------------------------------------------------------------------+
//| Set ATR TP Multipliers                                            |
//+------------------------------------------------------------------+
void CWyckoffSignalEngine::SetATRMultiplierTP(double tp1, double tp2, double tp3)
{
   m_atrTP1Multiplier = tp1;
   m_atrTP2Multiplier = tp2;
   m_atrTP3Multiplier = tp3;
}

//+------------------------------------------------------------------+
//| Main Signal Generation Entry Point                                |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GenerateSignal(PhaseDetectionResult &phaseResult,
                                                     WyckoffStructure &structure,
                                                     VolumeAnalysis &va, TrendHealth &th)
{
   WyckoffSignal signal;
   signal.Reset();
   
   if(!phaseResult.isValid) return signal;
   
   // Route to appropriate signal generator based on detected event
   switch(phaseResult.detectedEvent)
   {
      case WYCKOFF_EVENT_SPRING:
         signal = GenerateSpringSignal(phaseResult);
         break;
      case WYCKOFF_EVENT_UTAD:
         signal = GenerateUTADSignal(phaseResult);
         break;
      case WYCKOFF_EVENT_SOS:
         signal = GenerateSOSSignal(phaseResult);
         break;
      case WYCKOFF_EVENT_SOW:
         signal = GenerateSOWSignal(phaseResult);
         break;
      case WYCKOFF_EVENT_LPS:
      case WYCKOFF_EVENT_LPSY:
         if(phaseResult.detectedPhase == WYCKOFF_PHASE_E)
            signal = GeneratePhaseESignal(phaseResult);
         break;
      default:
         // Phase-based signals
         if(phaseResult.detectedPhase == WYCKOFF_PHASE_B)
            signal = GeneratePhaseBSignal(phaseResult);
         else if(phaseResult.detectedPhase == WYCKOFF_PHASE_E)
            signal = GeneratePhaseESignal(phaseResult);
         break;
   }
   
   // Validate and finalize
   if(signal.direction != 0)
   {
      signal.confidence = CalculateConfidence(phaseResult.detectedEvent, structure, va, th);
      signal.isValid = ValidateSignal(signal);
      signal.signalTime = TimeCurrent();
      
      if(signal.isValid)
      {
         m_lastSignal = signal;
      }
   }
   
   return signal;
}

//+------------------------------------------------------------------+
//| Generate Spring Buy Signal                                        |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GenerateSpringSignal(PhaseDetectionResult &phaseResult)
{
   WyckoffSignal signal;
   signal.Reset();
   
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   WyckoffStructure structure = m_phaseEngine.GetStructure();
   
   // Spring is a long signal
   signal.direction = TRADE_DIR_LONG;
   signal.triggerEvent = WYCKOFF_EVENT_SPRING;
   signal.targetState = STATE_ENTER_LONG;
   
   // Entry: At or above the Spring low (conservative: wait for confirmation)
   double springLow = phaseResult.eventLevel;
   signal.entryPrice = springLow + atr * 0.1; // Slightly above Spring low
   
   // Stop loss: Below Spring low
   signal.stopLoss = springLow - atr * m_atrSLMultiplier;
   
   // Take profits based on range projection
   double rangeSize = structure.rangeHigh - structure.rangeLow;
   signal.takeProfit1 = signal.entryPrice + rangeSize * 0.5;  // 50% of range
   signal.takeProfit2 = signal.entryPrice + rangeSize * 0.8;  // 80% of range
   signal.takeProfit3 = signal.entryPrice + rangeSize * 1.2;  // 120% of range (runner)
   
   signal.reason = "Spring detected - Accumulation Phase C";
   
   return signal;
}

//+------------------------------------------------------------------+
//| Generate UTAD Sell Signal                                         |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GenerateUTADSignal(PhaseDetectionResult &phaseResult)
{
   WyckoffSignal signal;
   signal.Reset();
   
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   WyckoffStructure structure = m_phaseEngine.GetStructure();
   
   signal.direction = TRADE_DIR_SHORT;
   signal.triggerEvent = WYCKOFF_EVENT_UTAD;
   signal.targetState = STATE_ENTER_SHORT;
   
   double utadHigh = phaseResult.eventLevel;
   signal.entryPrice = utadHigh - atr * 0.1;
   signal.stopLoss = utadHigh + atr * m_atrSLMultiplier;
   
   double rangeSize = structure.rangeHigh - structure.rangeLow;
   signal.takeProfit1 = signal.entryPrice - rangeSize * 0.5;
   signal.takeProfit2 = signal.entryPrice - rangeSize * 0.8;
   signal.takeProfit3 = signal.entryPrice - rangeSize * 1.2;
   
   signal.reason = "UTAD detected - Distribution Phase C";
   
   return signal;
}

//+------------------------------------------------------------------+
//| Generate SOS Buy Signal (Phase D)                                 |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GenerateSOSSignal(PhaseDetectionResult &phaseResult)
{
   WyckoffSignal signal;
   signal.Reset();
   
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   WyckoffStructure structure = m_phaseEngine.GetStructure();
   
   signal.direction = TRADE_DIR_LONG;
   signal.triggerEvent = WYCKOFF_EVENT_SOS;
   signal.targetState = STATE_ENTER_LONG;
   
   // Entry: At SOS bar close or on pullback
   signal.entryPrice = phaseResult.eventLevel;
   signal.stopLoss = structure.levelSpring - atr * 0.5; // Below Spring
   
   double rangeSize = structure.rangeHigh - structure.rangeLow;
   signal.takeProfit1 = signal.entryPrice + rangeSize * 0.6;
   signal.takeProfit2 = signal.entryPrice + rangeSize * 1.0;
   signal.takeProfit3 = signal.entryPrice + rangeSize * 1.5;
   
   signal.reason = "SOS detected - Accumulation Phase D";
   
   return signal;
}

//+------------------------------------------------------------------+
//| Generate SOW Sell Signal (Phase D)                                |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GenerateSOWSignal(PhaseDetectionResult &phaseResult)
{
   WyckoffSignal signal;
   signal.Reset();
   
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   WyckoffStructure structure = m_phaseEngine.GetStructure();
   
   signal.direction = TRADE_DIR_SHORT;
   signal.triggerEvent = WYCKOFF_EVENT_SOW;
   signal.targetState = STATE_ENTER_SHORT;
   
   signal.entryPrice = phaseResult.eventLevel;
   signal.stopLoss = structure.levelUTAD + atr * 0.5;
   
   double rangeSize = structure.rangeHigh - structure.rangeLow;
   signal.takeProfit1 = signal.entryPrice - rangeSize * 0.6;
   signal.takeProfit2 = signal.entryPrice - rangeSize * 1.0;
   signal.takeProfit3 = signal.entryPrice - rangeSize * 1.5;
   
   signal.reason = "SOW detected - Distribution Phase D";
   
   return signal;
}

//+------------------------------------------------------------------+
//| Generate Phase B Counter-Trend Signal                             |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GeneratePhaseBSignal(PhaseDetectionResult &phaseResult)
{
   WyckoffSignal signal;
   signal.Reset();
   
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   WyckoffStructure structure = m_phaseEngine.GetStructure();
   double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   // Only trade Phase B counter-trend in moderate/aggressive mode
   if(m_signalMode == SIGNAL_MODE_CONSERVATIVE) return signal;
   
   // Check if price is near range bottom (buy) or top (sell)
   double rangePos = core.NormalizePrice(currentPrice, structure.rangeHigh, structure.rangeLow);
   double rangeSize = structure.rangeHigh - structure.rangeLow;
   
   if(rangePos < 20) // Near bottom
   {
      signal.direction = TRADE_DIR_LONG;
      signal.targetState = STATE_CONTRA_LONG;
      signal.entryPrice = currentPrice;
      signal.stopLoss = structure.rangeLow - atr * 0.5;
      signal.takeProfit1 = structure.rangeMidpoint;
      signal.takeProfit2 = structure.rangeHigh - atr * 0.3;
      signal.triggerEvent = WYCKOFF_EVENT_NONE;
      signal.reason = "Phase B counter-trend long (range bottom)";
   }
   else if(rangePos > 80) // Near top
   {
      signal.direction = TRADE_DIR_SHORT;
      signal.targetState = STATE_CONTRA_SHORT;
      signal.entryPrice = currentPrice;
      signal.stopLoss = structure.rangeHigh + atr * 0.5;
      signal.takeProfit1 = structure.rangeMidpoint;
      signal.takeProfit2 = structure.rangeLow + atr * 0.3;
      signal.triggerEvent = WYCKOFF_EVENT_NONE;
      signal.reason = "Phase B counter-trend short (range top)";
   }
   
   return signal;
}

//+------------------------------------------------------------------+
//| Generate Phase E Trend Following Signal                           |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GeneratePhaseESignal(PhaseDetectionResult &phaseResult)
{
   WyckoffSignal signal;
   signal.Reset();
   
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   WyckoffStructure structure = m_phaseEngine.GetStructure();
   double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   
   // Determine direction from structure type
   bool isAccumulation = (structure.levelSC > 0);
   double rangeSize = structure.rangeHigh - structure.rangeLow;
   
   if(isAccumulation)
   {
      signal.direction = TRADE_DIR_LONG;
      signal.targetState = STATE_ENTER_LONG;
      signal.entryPrice = currentPrice;
      signal.stopLoss = structure.rangeHigh - atr * 0.3; // Just below creek
      signal.takeProfit1 = currentPrice + rangeSize * 0.5;
      signal.takeProfit2 = currentPrice + rangeSize * 1.0;
      signal.takeProfit3 = currentPrice + rangeSize * 2.0;
      signal.reason = "Phase E trend following - Accumulation breakout";
   }
   else
   {
      signal.direction = TRADE_DIR_SHORT;
      signal.targetState = STATE_ENTER_SHORT;
      signal.entryPrice = currentPrice;
      signal.stopLoss = structure.rangeLow + atr * 0.3;
      signal.takeProfit1 = currentPrice - rangeSize * 0.5;
      signal.takeProfit2 = currentPrice - rangeSize * 1.0;
      signal.takeProfit3 = currentPrice - rangeSize * 2.0;
      signal.reason = "Phase E trend following - Distribution breakdown";
   }
   
   signal.triggerEvent = WYCKOFF_EVENT_BO;
   
   return signal;
}

//+------------------------------------------------------------------+
//| Generate Reaccumulation Signal (Phase E pullback)                 |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GenerateReaccumSignal(PhaseDetectionResult &phaseResult)
{
   WyckoffSignal signal;
   signal.Reset();
   
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   WyckoffStructure structure = m_phaseEngine.GetStructure();
   
   signal.direction = TRADE_DIR_LONG;
   signal.targetState = STATE_ENTER_LONG;
   signal.triggerEvent = WYCKOFF_EVENT_LPS_EXT;
   
   double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   signal.entryPrice = currentPrice;
   signal.stopLoss = structure.rangeHigh - atr * 0.3;
   
   double rangeSize = structure.rangeHigh - structure.rangeLow;
   signal.takeProfit1 = currentPrice + rangeSize * 0.5;
   signal.takeProfit2 = currentPrice + rangeSize * 1.0;
   signal.takeProfit3 = currentPrice + rangeSize * 1.5;
   
   signal.reason = "Reaccumulation - Phase E pullback to support";
   
   return signal;
}

//+------------------------------------------------------------------+
//| Generate Redistribution Signal (Phase E pullback)                 |
//+------------------------------------------------------------------+
WyckoffSignal CWyckoffSignalEngine::GenerateRedistSignal(PhaseDetectionResult &phaseResult)
{
   WyckoffSignal signal;
   signal.Reset();
   
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   WyckoffStructure structure = m_phaseEngine.GetStructure();
   
   signal.direction = TRADE_DIR_SHORT;
   signal.targetState = STATE_ENTER_SHORT;
   signal.triggerEvent = WYCKOFF_EVENT_LPSY_EXT;
   
   double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   signal.entryPrice = currentPrice;
   signal.stopLoss = structure.rangeLow + atr * 0.3;
   
   double rangeSize = structure.rangeHigh - structure.rangeLow;
   signal.takeProfit1 = currentPrice - rangeSize * 0.5;
   signal.takeProfit2 = currentPrice - rangeSize * 1.0;
   signal.takeProfit3 = currentPrice - rangeSize * 1.5;
   
   signal.reason = "Redistribution - Phase E pullback to resistance";
   
   return signal;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                               |
//+------------------------------------------------------------------+
double CWyckoffSignalEngine::CalculateStopLoss(int direction, double entry, WyckoffStructure &structure)
{
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   
   if(direction == TRADE_DIR_LONG)
   {
      // For long: stop below structure support
      double structStop = structure.levelIce - atr * 0.5;
      double atrStop = entry - atr * m_atrSLMultiplier;
      return MathMin(structStop, atrStop); // Tighter of the two
   }
   else if(direction == TRADE_DIR_SHORT)
   {
      double structStop = structure.levelCreek + atr * 0.5;
      double atrStop = entry + atr * m_atrSLMultiplier;
      return MathMax(structStop, atrStop);
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                             |
//+------------------------------------------------------------------+
double CWyckoffSignalEngine::CalculateTakeProfit(int direction, double entry, double stopLoss, int tpLevel)
{
   double risk = MathAbs(entry - stopLoss);
   
   if(direction == TRADE_DIR_LONG)
   {
      switch(tpLevel)
      {
         case 1: return entry + risk * m_atrTP1Multiplier;
         case 2: return entry + risk * m_atrTP2Multiplier;
         case 3: return entry + risk * m_atrTP3Multiplier;
      }
   }
   else if(direction == TRADE_DIR_SHORT)
   {
      switch(tpLevel)
      {
         case 1: return entry - risk * m_atrTP1Multiplier;
         case 2: return entry - risk * m_atrTP2Multiplier;
         case 3: return entry - risk * m_atrTP3Multiplier;
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Validate Signal                                                   |
//+------------------------------------------------------------------+
bool CWyckoffSignalEngine::ValidateSignal(WyckoffSignal &signal)
{
   if(signal.direction == 0) return false;
   if(signal.entryPrice <= 0) return false;
   if(signal.stopLoss <= 0) return false;
   if(signal.takeProfit1 <= 0) return false;
   
   // Check risk:reward
   double risk = MathAbs(signal.entryPrice - signal.stopLoss);
   double reward = MathAbs(signal.takeProfit1 - signal.entryPrice);
   
   if(risk <= 0) return false;
   double rr = reward / risk;
   if(rr < m_riskRewardMin) return false;
   
   // Check signal mode confidence threshold
   switch(m_signalMode)
   {
      case SIGNAL_MODE_CONSERVATIVE:
         if(signal.confidence < SIGNAL_STRONG) return false;
         break;
      case SIGNAL_MODE_MODERATE:
         if(signal.confidence < SIGNAL_MODERATE) return false;
         break;
      case SIGNAL_MODE_AGGRESSIVE:
         if(signal.confidence < SIGNAL_WEAK) return false;
         break;
   }
   
   // Validate stop loss is reasonable (not too wide)
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   if(risk > atr * 5.0)
   {
      signal.reason += " [WARNING: Wide stop]";
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate Signal Confidence                                       |
//+------------------------------------------------------------------+
int CWyckoffSignalEngine::CalculateConfidence(ENUM_WYCKOFF_EVENT event, WyckoffStructure &structure,
                                                VolumeAnalysis &va, TrendHealth &th)
{
   int confidence = 5; // Base confidence
   
   // Event type scoring
   switch(event)
   {
      case WYCKOFF_EVENT_SPRING:
      case WYCKOFF_EVENT_UTAD:
         confidence += 2; // Phase C events are high confidence
         break;
      case WYCKOFF_EVENT_SOS:
      case WYCKOFF_EVENT_SOW:
         confidence += 1; // Phase D events
         break;
      case WYCKOFF_EVENT_BO:
         confidence += 1; // Breakout
         break;
      default:
         break;
   }
   
   // Volume confirmation
   if(va.relativeVolume > 1.5 && va.relativeVolume < 3.0)
      confidence += 1; // Good volume
   else if(va.relativeVolume >= 3.0)
      confidence -= 1; // Too much volume (possible climax)
   
   // Trend health
   if(th.isHealthy) confidence += 1;
   if(th.isDiverging) confidence -= 2;
   if(th.isClimax) confidence -= 1;
   
   // Structure quality
   if(structure.barsInPhaseB >= 30) confidence += 1; // Well-developed cause
   if(structure.rangeSize > 0)
   {
      CWyckoffCore* core = m_phaseEngine.GetCore();
      double atr = core.GetATR(0);
      if(structure.rangeSize > atr * 5) confidence += 1; // Meaningful range
   }
   
   // Clamp to 0-10
   if(confidence > 10) confidence = 10;
   if(confidence < 0) confidence = 0;
   
   return confidence;
}

//+------------------------------------------------------------------+
//| Check if signal is still valid                                    |
//+------------------------------------------------------------------+
bool CWyckoffSignalEngine::IsSignalValid(WyckoffSignal &signal)
{
   if(!signal.isValid) return false;
   if(signal.direction == 0) return false;
   
   // Check if price has moved too far from entry
   double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
   CWyckoffCore* core = m_phaseEngine.GetCore();
   double atr = core.GetATR(0);
   
   double distance = MathAbs(currentPrice - signal.entryPrice);
   if(distance > atr * 3.0) return false; // Too far from planned entry
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if signal has expired (too many bars since generation)      |
//+------------------------------------------------------------------+
bool CWyckoffSignalEngine::IsSignalExpired(WyckoffSignal &signal, int maxBars)
{
   if(signal.signalTime == 0) return true;
   
   datetime now = TimeCurrent();
   int elapsedBars = iBarShift(m_symbol, m_timeframe, signal.signalTime);
   
   return (elapsedBars > maxBars);
}
//+------------------------------------------------------------------+
#endif // WYCKOFFSIGNALENGINE_MQH
