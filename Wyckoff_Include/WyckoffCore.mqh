//+------------------------------------------------------------------+
//|                                          WyckoffCore.mqh         |
//|                         Wyckoff Unified Trading System - Core     |
//|                        Core indicators and structure detection    |
//+------------------------------------------------------------------+
#property copyright "Wyckoff UTS"
#property strict
#include <Object.mqh>

//+------------------------------------------------------------------+
//| Wyckoff Phase Enumeration                                         |
//+------------------------------------------------------------------+
enum ENUM_WYCKOFF_PHASE
{
   WYCKOFF_PHASE_UNKNOWN  = 0,  // Unknown/Transitional
   WYCKOFF_PHASE_A        = 1,  // Stopping (PS/SC/AR/ST)
   WYCKOFF_PHASE_B        = 2,  // Cause Building
   WYCKOFF_PHASE_C        = 3,  // Test (Spring/UTAD)
   WYCKOFF_PHASE_D        = 4,  // Trend Within Range
   WYCKOFF_PHASE_E        = 5   // Trend Out of Range
};

//+------------------------------------------------------------------+
//| Wyckoff Event Enumeration                                         |
//+------------------------------------------------------------------+
enum ENUM_WYCKOFF_EVENT
{
   WYCKOFF_EVENT_NONE     = 0,
   // Phase A Events
   WYCKOFF_EVENT_PS       = 1,   // Preliminary Support/Supply
   WYCKOFF_EVENT_SC       = 2,   // Selling Climax / AR for distribution
   WYCKOFF_EVENT_AR       = 3,   // Automatic Reaction
   WYCKOFF_EVENT_ST       = 4,   // Secondary Test
   WYCKOFF_EVENT_PS_LONG  = 11,  // Preliminary Support (accumulation)
   WYCKOFF_EVENT_BC       = 12,  // Buying Climax (distribution)
   // Phase B Events
   WYCKOFF_EVENT_UA       = 20,  // Upthrust After (failed breakout in B)
   WYCKOFF_EVENT_mSOW     = 21,  // Minor Sign of Weakness in B
   // Phase C Events
   WYCKOFF_EVENT_SPRING   = 30,  // Spring (accumulation)
   WYCKOFF_EVENT_UTAD     = 31,  // Upthrust After Distribution
   WYCKOFF_EVENT_LPS      = 32,  // Last Point of Support
   WYCKOFF_EVENT_LPSY     = 33,  // Last Point of Supply
   // Phase D Events
   WYCKOFF_EVENT_SOS      = 40,  // Sign of Strength
   WYCKOFF_EVENT_SOW      = 41,  // Sign of Weakness
   WYCKOFF_EVENT_MSOS     = 42,  // Major Sign of Strength
   WYCKOFF_EVENT_MSOW     = 43,  // Major Sign of Weakness
   WYCKOFF_EVENT_BUEC     = 44,  // Back Up to the Creek
   WYCKOFF_EVENT_JAC      = 45,  // Jump Across the Creek
   WYCKOFF_EVENT_FTI      = 46,  // Fall Through Ice
   // Phase E Events
   WYCKOFF_EVENT_LPS_EXT  = 50,  // Last Point of Support (Phase E)
   WYCKOFF_EVENT_LPSY_EXT = 51,  // Last Point of Supply (Phase E)
   WYCKOFF_EVENT_BO       = 52   // Breakout
};

//+------------------------------------------------------------------+
//| Structure Type Enumeration                                        |
//+------------------------------------------------------------------+
enum ENUM_STRUCTURE_TYPE
{
   STRUCT_NONE            = 0,
   STRUCT_ACCUMULATION_1  = 1,  // Accumulation with Spring
   STRUCT_ACCUMULATION_2  = 2,  // Accumulation without Spring
   STRUCT_DISTRIBUTION_1  = 3,  // Distribution with UTAD
   STRUCT_DISTRIBUTION_2  = 4,  // Distribution without UTAD
   STRUCT_REACCUMULATION  = 5,  // Reaccumulation (in uptrend)
   STRUCT_REDISTRIBUTION  = 6   // Redistribution (in downtrend)
};

//+------------------------------------------------------------------+
//| Market State Enumeration                                          |
//+------------------------------------------------------------------+
enum ENUM_MARKET_STATE
{
   STATE_NO_TRADE         = 0,  // Unclear - Do not trade
   STATE_OBSERVE          = 1,  // Observing - Phase A
   STATE_CONTRA_SHORT     = 2,  // Counter-trend short (range top)
   STATE_CONTRA_LONG      = 3,  // Counter-trend long (range bottom)
   STATE_PREPARE_LONG     = 4,  // Prepare for long (Phase C Spring)
   STATE_PREPARE_SHORT    = 5,  // Prepare for short (Phase C UTAD)
   STATE_ENTER_LONG       = 6,  // Enter long (Phase D/E)
   STATE_ENTER_SHORT      = 7,  // Enter short (Phase D/E)
   STATE_HOLD_LONG        = 8,  // Hold long position
   STATE_HOLD_SHORT       = 9,  // Hold short position
   STATE_EXIT_LONG        = 10, // Exit long
   STATE_EXIT_SHORT       = 11, // Exit short
   STATE_EMERGENCY_EXIT   = 12  // Emergency exit (stop hit)
};

//+------------------------------------------------------------------+
//| Price-Volume Harmony Enumeration                                  |
//+------------------------------------------------------------------+
enum ENUM_PV_HARMONY
{
   PV_HARMONY_UNKNOWN     = 0,
   PV_HARMONY_BULLISH     = 1,  // Price up + volume up / Price down + volume down
   PV_HARMONY_BEARISH     = 2,  // Price down + volume up / Price up + volume down
   PV_DIVERGENCE_WARNING  = 3,  // Potential divergence
   PV_DIVERGENCE_CONFIRM  = 4,  // Confirmed divergence
   PV_CLIMAX_ACTIVITY     = 5,  // Climax behavior detected
   PV_NO_INTEREST         = 6   // Lack of interest
};

//+------------------------------------------------------------------+
//| Structure Boundaries Structure                                    |
//+------------------------------------------------------------------+
struct WyckoffStructure
{
   ENUM_STRUCTURE_TYPE    type;          // Structure type
   ENUM_WYCKOFF_PHASE     currentPhase;  // Current phase
   ENUM_WYCKOFF_EVENT     lastEvent;     // Last detected event
   
   double                 levelSC;       // Selling Climax low
   double                 levelAR;       // Automatic Reaction high
   double                 levelST;       // Secondary Test level
   double                 levelBC;       // Buying Climax high (distribution)
   double                 levelSpring;   // Spring low
   double                 levelUTAD;     // UTAD high
   double                 levelCreek;    // Resistance (high of range)
   double                 levelIce;      // Support (low of range)
   
   double                 rangeHigh;     // Range high
   double                 rangeLow;      // Range low
   double                 rangeMidpoint; // Range midpoint
   double                 rangeSize;     // Range size in points
   
   datetime               phaseAStart;   // Phase A start time
   datetime               phaseBStart;   // Phase B start time
   datetime               phaseCStart;   // Phase C start time
   datetime               phaseDStart;   // Phase D start time
   datetime               phaseEStart;   // Phase E start time
   
   int                    barsInPhaseB;  // Bars spent in Phase B
   int                    barsInPhaseC;  // Bars spent in Phase C
   int                    barsInPhaseD;  // Bars spent in Phase D
   int                    barsInPhaseE;  // Bars spent in Phase E
   
   bool                   isValid;       // Is structure valid
   bool                   isSpringTested;// Spring has been tested
   bool                   isUTADTested;  // UTAD has been tested
   bool                   isCreekBroken; // Creek has been broken
   bool                   isIceBroken;   // Ice has been broken
   int                    confidence;    // Confidence score (0-10)
   
   void Reset()
   {
      type = STRUCT_NONE;
      currentPhase = WYCKOFF_PHASE_UNKNOWN;
      lastEvent = WYCKOFF_EVENT_NONE;
      levelSC = 0; levelAR = 0; levelST = 0;
      levelBC = 0; levelSpring = 0; levelUTAD = 0;
      levelCreek = 0; levelIce = 0;
      rangeHigh = 0; rangeLow = 0; rangeMidpoint = 0; rangeSize = 0;
      phaseAStart = 0; phaseBStart = 0; phaseCStart = 0;
      phaseDStart = 0; phaseEStart = 0;
      barsInPhaseB = 0; barsInPhaseC = 0;
      barsInPhaseD = 0; barsInPhaseE = 0;
      isValid = false; isSpringTested = false; isUTADTested = false;
      isCreekBroken = false; isIceBroken = false;
      confidence = 0;
   }
};

//+------------------------------------------------------------------+
//| Trend Health Structure                                            |
//+------------------------------------------------------------------+
struct TrendHealth
{
   int                    direction;     // 1 = up, -1 = down, 0 = sideways
   double                 speed;         // Trend speed (angle)
   double                 projection;    // Impulse projection ratio
   double                 depth;         // Pullback depth ratio
   ENUM_PV_HARMONY        pvHarmony;     // Price-volume harmony
   bool                   isHealthy;     // Overall health
   bool                   isDiverging;   // Divergence detected
   bool                   isClimax;      // Climax detected
   int                    consecutiveHH; // Consecutive higher highs
   int                    consecutiveHL; // Consecutive higher lows
   int                    consecutiveLH; // Consecutive lower highs
   int                    consecutiveLL; // Consecutive lower lows
   
   void Reset()
   {
      direction = 0; speed = 0; projection = 0; depth = 0;
      pvHarmony = PV_HARMONY_UNKNOWN;
      isHealthy = false; isDiverging = false; isClimax = false;
      consecutiveHH = 0; consecutiveHL = 0;
      consecutiveLH = 0; consecutiveLL = 0;
   }
};

//+------------------------------------------------------------------+
//| Volume Analysis Structure                                         |
//+------------------------------------------------------------------+
struct VolumeAnalysis
{
   double                 avgVolume;     // Average volume
   double                 currentVolume; // Current bar volume
   double                 relativeVolume;// Current / Average ratio
   double                 volumeTrend;   // Volume trend direction
   bool                   isClimaxVol;   // Climax volume detected
   bool                   isLowVol;      // Low volume (lack of interest)
   bool                   isRisingVol;   // Volume rising
   bool                   isFallingVol;  // Volume falling
   double                 volAtHighs;    // Volume at recent highs
   double                 volAtLows;     // Volume at recent lows
   double                 volDelta;      // Volume delta (buy vs sell estimate)
   
   void Reset()
   {
      avgVolume = 0; currentVolume = 0; relativeVolume = 0;
      volumeTrend = 0; isClimaxVol = false; isLowVol = false;
      isRisingVol = false; isFallingVol = false;
      volAtHighs = 0; volAtLows = 0; volDelta = 0;
   }
};

//+------------------------------------------------------------------+
//| Trading Signal Structure                                          |
//+------------------------------------------------------------------+
struct WyckoffSignal
{
   int                    direction;     // 1 = buy, -1 = sell, 0 = none
   double                 entryPrice;    // Suggested entry price
   double                 stopLoss;      // Stop loss price
   double                 takeProfit1;   // First take profit (50%)
   double                 takeProfit2;   // Second take profit (30%)
   double                 takeProfit3;   // Third take profit (20% trailing)
   ENUM_WYCKOFF_EVENT     triggerEvent;  // Event that triggered signal
   ENUM_MARKET_STATE      targetState;   // Target market state
   int                    confidence;    // Signal confidence (0-10)
   string                 reason;        // Human-readable reason
   datetime               signalTime;    // Signal generation time
   bool                   isValid;       // Is signal valid
   
   void Reset()
   {
      direction = 0; entryPrice = 0; stopLoss = 0;
      takeProfit1 = 0; takeProfit2 = 0; takeProfit3 = 0;
      triggerEvent = WYCKOFF_EVENT_NONE;
      targetState = STATE_NO_TRADE;
      confidence = 0; reason = ""; signalTime = 0; isValid = false;
   }
};

//+------------------------------------------------------------------+
//| Multi-Timeframe Analysis Structure                                |
//+------------------------------------------------------------------+
struct MTFAnalysis
{
   ENUM_TIMEFRAMES        htfs;          // Higher timeframe
   ENUM_TIMEFRAMES        mtfs;          // Medium timeframe
   ENUM_TIMEFRAMES        ltfs;          // Lower timeframe
   
   ENUM_WYCKOFF_PHASE     htfPhase;      // HTF phase
   ENUM_WYCKOFF_PHASE     mtfPhase;      // MTF phase
   ENUM_WYCKOFF_PHASE     ltfPhase;      // LTF phase
   
   int                    htfDirection;  // HTF trend direction
   int                    mtfDirection;  // MTF trend direction
   int                    ltfDirection;  // LTF trend direction
   
   bool                   isAligned;     // All three aligned
   int                    alignmentScore;// Alignment score (0-3)
   int                    alignedDirection; // Aligned direction (1=long, -1=short)
   double                 trendStrength;  // ADX trend strength
   bool                   isTrending;     // Is market trending
   
   void Reset()
   {
      htfPhase = WYCKOFF_PHASE_UNKNOWN;
      mtfPhase = WYCKOFF_PHASE_UNKNOWN;
      ltfPhase = WYCKOFF_PHASE_UNKNOWN;
      htfDirection = 0; mtfDirection = 0; ltfDirection = 0;
      isAligned = false; alignmentScore = 0; alignedDirection = 0;
      trendStrength = 0; isTrending = false;
   }
};

//+------------------------------------------------------------------+
//| Core Utility Functions                                            |
//+------------------------------------------------------------------+

//--- Calculate Average True Range
double CalcATR(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   int atrHandle = iATR(symbol, timeframe, period);
   if(atrHandle == INVALID_HANDLE) return 0;
   
   double atrValue[];
   ArraySetAsSeries(atrValue, true);
   if(CopyBuffer(atrHandle, 0, shift, 1, atrValue) <= 0)
   {
      IndicatorRelease(atrHandle);
      return 0;
   }
   IndicatorRelease(atrHandle);
   return atrValue[0];
}

//--- Calculate Volume Weighted Average Price
double CalcVWAP(string symbol, ENUM_TIMEFRAMES timeframe, int shift)
{
   double sumPV = 0;
   double sumV = 0;
   
   for(int i = shift; i < shift + 20; i++)
   {
      double high[], low[], close[];
      long volume[];
      ArraySetAsSeries(high, true);
      ArraySetAsSeries(low, true);
      ArraySetAsSeries(close, true);
      ArraySetAsSeries(volume, true);
      
      if(CopyHigh(symbol, timeframe, i, 1, high) <= 0) continue;
      if(CopyLow(symbol, timeframe, i, 1, low) <= 0) continue;
      if(CopyClose(symbol, timeframe, i, 1, close) <= 0) continue;
      if(CopyTickVolume(symbol, timeframe, i, 1, volume) <= 0) continue;
      
      double typicalPrice = (high[0] + low[0] + close[0]) / 3.0;
      sumPV += typicalPrice * (double)volume[0];
      sumV += (double)volume[0];
   }
   
   if(sumV == 0) return 0;
   return sumPV / sumV;
}

//--- Calculate Relative Volume (current vs average)
double CalcRelativeVolume(string symbol, ENUM_TIMEFRAMES timeframe, int avgPeriod, int shift)
{
   long volumes[];
   ArraySetAsSeries(volumes, true);
   if(CopyTickVolume(symbol, timeframe, shift, avgPeriod + 1, volumes) <= avgPeriod + 1)
      return 1.0;
   
   double sum = 0;
   for(int i = 1; i <= avgPeriod; i++)
      sum += (double)volumes[i];
   
   double avg = sum / avgPeriod;
   if(avg == 0) return 1.0;
   
   return (double)volumes[0] / avg;
}

//--- Calculate Volume Trend (rising/falling)
double CalcVolumeTrend(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   long volumes[];
   ArraySetAsSeries(volumes, true);
   if(CopyTickVolume(symbol, timeframe, shift, period, volumes) < period)
      return 0;
   
   // Simple linear regression slope of volume
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   int n = period;
   
   for(int i = 0; i < n; i++)
   {
      sumX += i;
      sumY += (double)volumes[i];
      sumXY += i * (double)volumes[i];
      sumX2 += i * i;
   }
   
   double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
   double avgVol = sumY / n;
   
   if(avgVol == 0) return 0;
   return slope / avgVol; // Normalized slope
}

//--- Detect Climax Volume
bool DetectClimaxVolume(string symbol, ENUM_TIMEFRAMES timeframe, int shift, double threshold = 2.5)
{
   double relVol = CalcRelativeVolume(symbol, timeframe, 20, shift);
   return (relVol >= threshold);
}

//--- Detect Lack of Interest (very low volume)
bool DetectLowVolume(string symbol, ENUM_TIMEFRAMES timeframe, int shift, double threshold = 0.3)
{
   double relVol = CalcRelativeVolume(symbol, timeframe, 20, shift);
   return (relVol <= threshold);
}

//--- Calculate Price Range Statistics
void CalcRangeStats(string symbol, ENUM_TIMEFRAMES timeframe, int startBar, int numBars,
                    double &rangeHigh, double &rangeLow, double &rangeMid, double &avgRange)
{
   rangeHigh = 0;
   rangeLow = 1e308;
   double sumRange = 0;
  
   double highs[], lows[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
  
   if(CopyHigh(symbol, timeframe, startBar, numBars, highs) < numBars) return;
   if(CopyLow(symbol, timeframe, startBar, numBars, lows) < numBars) return;
  
   for(int i = 0; i < numBars; i++)
   {
      if(highs[i] > rangeHigh) rangeHigh = highs[i];
      if(lows[i] < rangeLow) rangeLow = lows[i];
   }
  
   rangeMid = (rangeHigh + rangeLow) / 2.0;
   avgRange = sumRange / numBars;
}
}

//--- Calculate Trend Speed (angle)
double CalcTrendSpeed(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   double closes[];
   ArraySetAsSeries(closes, true);
   if(CopyClose(symbol, timeframe, shift, period, closes) < period)
      return 0;
   
   // Simple slope calculation
   double firstPrice = closes[period - 1];
   double lastPrice = closes[0];
   double priceChange = lastPrice - firstPrice;
   
   // Normalize by ATR to get comparable measure
   double atr = CalcATR(symbol, timeframe, 14, shift);
   if(atr == 0) return 0;
   
   return (priceChange / period) / atr;
}

//--- Calculate Projection Ratio (current impulse vs previous)
double CalcProjectionRatio(string symbol, ENUM_TIMEFRAMES timeframe, int shift)
{
   double highs[], lows[], closes[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(closes, true);
   
   if(CopyHigh(symbol, timeframe, shift, 10, highs) < 10) return 1;
   if(CopyLow(symbol, timeframe, shift, 10, lows) < 10) return 1;
   if(CopyClose(symbol, timeframe, shift, 10, closes) < 10) return 1;
   
   // Find recent impulse and previous impulse
   double currentImpulse = 0;
   double previousImpulse = 0;
   
   // Current impulse: from shift+5 to shift
   currentImpulse = MathAbs(closes[0] - closes[5]);
   
   // Previous impulse: from shift+9 to shift+5
   previousImpulse = MathAbs(closes[5] - closes[9]);
   
   if(previousImpulse == 0) return 1;
   return currentImpulse / previousImpulse;
}

//--- Calculate Pullback Depth Ratio
double CalcPullbackDepth(string symbol, ENUM_TIMEFRAMES timeframe, int shift)
{
   double highs[], lows[], closes[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(closes, true);
   
   if(CopyHigh(symbol, timeframe, shift, 15, highs) < 15) return 0;
   if(CopyLow(symbol, timeframe, shift, 15, lows) < 15) return 0;
   if(CopyClose(symbol, timeframe, shift, 15, closes) < 15) return 0;
   
   // Find the recent swing high and swing low
   double recentHigh = highs[0];
   double recentLow = lows[0];
   int highBar = 0, lowBar = 0;
   
   for(int i = 1; i < 10; i++)
   {
      if(highs[i] > recentHigh) { recentHigh = highs[i]; highBar = i; }
      if(lows[i] < recentLow) { recentLow = lows[i]; lowBar = i; }
   }
   
   double totalMove = recentHigh - recentLow;
   if(totalMove == 0) return 0;
   
   // Pullback depth
   double pullback = 0;
   if(highBar < lowBar)
      pullback = recentHigh - closes[0]; // Uptrend pullback
   else
      pullback = closes[0] - recentLow; // Downtrend pullback
   
   return pullback / totalMove;
}

//--- Check if price is near a level (within ATR-based tolerance)
bool IsPriceNearLevel(double price, double level, double atrTolerance)
{
   double atr = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(atr == 0) return false;
   
   return (MathAbs(price - level) <= atrTolerance * atr);
}

//--- Calculate Significant Bar (SOS/SOW detection)
// Returns: 1 = SOS (bullish), -1 = SOW (bearish), 0 = normal
int DetectSignificantBar(string symbol, ENUM_TIMEFRAMES timeframe, int shift, double rangeMultiplier = 1.5)
{
   double highs[], lows[], closes[];
   long volumes[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(closes, true);
   ArraySetAsSeries(volumes, true);
   
   if(CopyHigh(symbol, timeframe, shift, 21, highs) < 21) return 0;
   if(CopyLow(symbol, timeframe, shift, 21, lows) < 21) return 0;
   if(CopyClose(symbol, timeframe, shift, 21, closes) < 21) return 0;
   if(CopyTickVolume(symbol, timeframe, shift, 21, volumes) < 21) return 0;
   
   double currentRange = highs[0] - lows[0];
   double currentClose = closes[0];
   double currentOpen = closes[1]; // Approximation
   double currentVolume = (double)volumes[0];
   
   // Calculate average range and volume
   double avgRange = 0;
   double avgVolume = 0;
   for(int i = 1; i <= 20; i++)
   {
      avgRange += (highs[i] - lows[i]);
      avgVolume += (double)volumes[i];
   }
   avgRange /= 20.0;
   avgVolume /= 20.0;
   
   if(avgRange == 0 || avgVolume == 0) return 0;
   
   // Check if current bar is significant
   bool isWideRange = (currentRange >= rangeMultiplier * avgRange);
   bool isHighVolume = (currentVolume >= 1.5 * avgVolume);
   bool isBullish = (currentClose > currentOpen);
   bool isBearish = (currentClose < currentOpen);
   
   if(isWideRange && isHighVolume)
   {
      if(isBullish && currentClose > highs[1]) return 1;  // SOS
      if(isBearish && currentClose < lows[1]) return -1;   // SOW
   }
   
   return 0;
}

//--- Detect Spring Pattern
// Returns: 1 = Spring detected, 0 = none
int DetectSpring(string symbol, ENUM_TIMEFRAMES timeframe, int shift, 
                 double rangeLow, double atrMultiplier = 0.5)
{
   double highs[], lows[], closes[];
   long volumes[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(closes, true);
   ArraySetAsSeries(volumes, true);
   
   if(CopyHigh(symbol, timeframe, shift, 5, highs) < 5) return 0;
   if(CopyLow(symbol, timeframe, shift, 5, lows) < 5) return 0;
   if(CopyClose(symbol, timeframe, shift, 5, closes) < 5) return 0;
   if(CopyTickVolume(symbol, timeframe, shift, 5, volumes) < 5) return 0;
   
   double atr = CalcATR(symbol, timeframe, 14, shift);
   if(atr == 0) return 0;
   
   // Spring: current low breaks below range low, but close is back above
   bool brokeBelow = (lows[0] < rangeLow - atrMultiplier * atr);
   bool closedAbove = (closes[0] > rangeLow);
   
   if(brokeBelow && closedAbove)
   {
      // Check volume: Spring should have moderate volume
      double avgVol = 0;
      for(int i = 1; i <= 20; i++)
      {
         long vol[];
         ArraySetAsSeries(vol, true);
         if(CopyTickVolume(symbol, timeframe, shift + i, 1, vol) > 0)
            avgVol += (double)vol[0];
      }
      avgVol /= 20.0;
      
      double springVol = (double)volumes[0];
      
      // Spring #3 (low volume) is best for direct entry
      if(springVol < avgVol * 1.2) return 3;  // Low volume spring
      if(springVol < avgVol * 2.0) return 2;  // Medium volume spring
      return 1;  // High volume spring (needs test)
   }
   
   return 0;
}

//--- Detect UTAD Pattern (Upthrust After Distribution)
// Returns: 1 = UTAD detected, 0 = none
int DetectUTAD(string symbol, ENUM_TIMEFRAMES timeframe, int shift,
               double rangeHigh, double atrMultiplier = 0.5)
{
   double highs[], lows[], closes[];
   long volumes[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(closes, true);
   ArraySetAsSeries(volumes, true);
   
   if(CopyHigh(symbol, timeframe, shift, 5, highs) < 5) return 0;
   if(CopyLow(symbol, timeframe, shift, 5, lows) < 5) return 0;
   if(CopyClose(symbol, timeframe, shift, 5, closes) < 5) return 0;
   if(CopyTickVolume(symbol, timeframe, shift, 5, volumes) < 5) return 0;
   
   double atr = CalcATR(symbol, timeframe, 14, shift);
   if(atr == 0) return 0;
   
   // UTAD: current high breaks above range high, but close is back below
   bool brokeAbove = (highs[0] > rangeHigh + atrMultiplier * atr);
   bool closedBelow = (closes[0] < rangeHigh);
   
   if(brokeAbove && closedBelow)
   {
      double avgVol = 0;
      for(int i = 1; i <= 20; i++)
      {
         long vol[];
         ArraySetAsSeries(vol, true);
         if(CopyTickVolume(symbol, timeframe, shift + i, 1, vol) > 0)
            avgVol += (double)vol[0];
      }
      avgVol /= 20.0;
      
      double utadVol = (double)volumes[0];
      
      if(utadVol < avgVol * 1.2) return 3;
      if(utadVol < avgVol * 2.0) return 2;
      return 1;
   }
   
   return 0;
}

//--- Detect Breakout
// Returns: 1 = bullish breakout, -1 = bearish breakout, 0 = none
int DetectBreakout(string symbol, ENUM_TIMEFRAMES timeframe, int shift,
                   double level, bool isResistance, double atrMultiplier = 0.3)
{
   double highs[], lows[], closes[];
   long volumes[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(closes, true);
   ArraySetAsSeries(volumes, true);
   
   if(CopyHigh(symbol, timeframe, shift, 3, highs) < 3) return 0;
   if(CopyLow(symbol, timeframe, shift, 3, lows) < 3) return 0;
   if(CopyClose(symbol, timeframe, shift, 3, closes) < 3) return 0;
   if(CopyTickVolume(symbol, timeframe, shift, 3, volumes) < 3) return 0;
   
   double atr = CalcATR(symbol, timeframe, 14, shift);
   if(atr == 0) return 0;
   
   if(isResistance) // Bullish breakout above resistance
   {
      bool brokeAbove = (closes[0] > level + atrMultiplier * atr);
      bool confirmed = (closes[1] > level); // Confirmation bar
      bool highVolume = ((double)volumes[0] > 1.2 * (double)volumes[1]);
      
      if(brokeAbove && confirmed && highVolume)
         return 1;
   }
   else // Bearish breakout below support
   {
      bool brokeBelow = (closes[0] < level - atrMultiplier * atr);
      bool confirmed = (closes[1] < level);
      bool highVolume = ((double)volumes[0] > 1.2 * (double)volumes[1]);
      
      if(brokeBelow && confirmed && highVolume)
         return -1;
   }
   
   return 0;
}

//--- Calculate Price-Volume Harmony
ENUM_PV_HARMONY CalcPVHarmony(string symbol, ENUM_TIMEFRAMES timeframe, int period, int shift)
{
   double closes[];
   long volumes[];
   ArraySetAsSeries(closes, true);
   ArraySetAsSeries(volumes, true);
   
   if(CopyClose(symbol, timeframe, shift, period, closes) < period) return PV_HARMONY_UNKNOWN;
   if(CopyTickVolume(symbol, timeframe, shift, period, volumes) < period) return PV_HARMONY_UNKNOWN;
   
   // Calculate price change and volume correlation
   double priceChanges[];
   double volChanges[];
   ArrayResize(priceChanges, period - 1);
   ArrayResize(volChanges, period - 1);
   
   for(int i = 0; i < period - 1; i++)
   {
      priceChanges[i] = closes[i] - closes[i + 1];
      volChanges[i] = (double)volumes[i] - (double)volumes[i + 1];
   }
   
   // Calculate correlation
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
   int n = period - 1;
   
   for(int i = 0; i < n; i++)
   {
      sumX += priceChanges[i];
      sumY += volChanges[i];
      sumXY += priceChanges[i] * volChanges[i];
      sumX2 += priceChanges[i] * priceChanges[i];
      sumY2 += volChanges[i] * volChanges[i];
   }
   
   double denom = MathSqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
   if(denom == 0) return PV_HARMONY_UNKNOWN;
   
   double correlation = (n * sumXY - sumX * sumY) / denom;
   
   // Check for climax
   double avgVol = 0;
   for(int i = 0; i < period; i++) avgVol += (double)volumes[i];
   avgVol /= period;
   
   if((double)volumes[0] > avgVol * 2.5)
      return PV_CLIMAX_ACTIVITY;
   
   // Check for low interest
   if((double)volumes[0] < avgVol * 0.3)
      return PV_NO_INTEREST;
   
   // Determine harmony
   if(correlation > 0.3)
   {
      // Positive correlation: price up + vol up = bullish harmony
      if(closes[0] > closes[period - 1])
         return PV_HARMONY_BULLISH;
      else
         return PV_HARMONY_BEARISH;
   }
   else if(correlation < -0.3)
   {
      // Negative correlation: divergence
      if(MathAbs(closes[0] - closes[period - 1]) < CalcATR(symbol, timeframe, 14, shift) * 0.5)
         return PV_DIVERGENCE_CONFIRM;
      else
         return PV_DIVERGENCE_WARNING;
   }
   
   return PV_HARMONY_UNKNOWN;
}

//--- Format price for logging
string FormatPrice(double price)
{
   return DoubleToString(price, _Digits);
}

//--- Format time for logging
string FormatTime(datetime time)
{
   return TimeToString(time, TIME_DATE | TIME_MINUTES);
}

//+------------------------------------------------------------------+
//| Wyckoff Core Class                                                |
//+------------------------------------------------------------------+
class CWyckoffCore : public CObject
{
private:
   string               m_symbol;
   ENUM_TIMEFRAMES      m_timeframe;
   
   // Indicator handles
   int                  m_atrHandle;
   int                  m_maFastHandle;
   int                  m_maSlowHandle;
   int                  m_rsiHandle;
   int                  m_volMAHandle;
   
   // Indicator buffers
   double               m_atrBuffer[];
   double               m_maFastBuffer[];
   double               m_maSlowBuffer[];
   double               m_rsiBuffer[];
   
public:
                     CWyckoffCore();
                    ~CWyckoffCore();
   
   bool                 Init(string symbol, ENUM_TIMEFRAMES timeframe);
   void                 Deinit();
   
   //--- Getters
   double               GetATR(int shift = 0);
   double               GetMAFast(int shift = 0);
   double               GetMASlow(int shift = 0);
   double               GetRSI(int shift = 0);
   double               GetATRValue() { return GetATR(0); }
   
   //--- Analysis
   ENUM_PV_HARMONY      AnalyzePVHarmony(int period = 20, int shift = 0);
   int                  AnalyzeTrend(int period = 20, int shift = 0);
   VolumeAnalysis       AnalyzeVolume(int period = 20, int shift = 0);
   TrendHealth          AnalyzeTrendHealth(int period = 20, int shift = 0);
   
   //--- Pattern Detection
   int                  DetectSpring(double rangeLow, int shift = 0);
   int                  DetectUTAD(double rangeHigh, int shift = 0);
   int                  DetectSignificantBar(double rangeMult = 1.5, int shift = 0);
   int                  DetectBreakout(double level, bool isResistance, int shift = 0);
   
   //--- Utility
   string               GetSymbol()    const { return m_symbol; }
   ENUM_TIMEFRAMES      GetTimeframe() const { return m_timeframe; }
   double               CalcRangeSize(double rangeHigh, double rangeLow) { return rangeHigh - rangeLow; }
   bool                 IsRangeValid(double rangeHigh, double rangeLow, double minRange);
   double               NormalizePrice(double price, double rangeHigh, double rangeLow);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CWyckoffCore::CWyckoffCore()
{
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_atrHandle = INVALID_HANDLE;
   m_maFastHandle = INVALID_HANDLE;
   m_maSlowHandle = INVALID_HANDLE;
   m_rsiHandle = INVALID_HANDLE;
   m_volMAHandle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CWyckoffCore::~CWyckoffCore()
{
   Deinit();
}

//+------------------------------------------------------------------+
//| Initialize indicators                                             |
//+------------------------------------------------------------------+
bool CWyckoffCore::Init(string symbol, ENUM_TIMEFRAMES timeframe)
{
   m_symbol = symbol;
   m_timeframe = timeframe;
   
   m_atrHandle = iATR(m_symbol, m_timeframe, 14);
   m_maFastHandle = iMA(m_symbol, m_timeframe, 10, 0, MODE_EMA, PRICE_CLOSE);
   m_maSlowHandle = iMA(m_symbol, m_timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_rsiHandle = iRSI(m_symbol, m_timeframe, 14, PRICE_CLOSE);
   
   if(m_atrHandle == INVALID_HANDLE || m_maFastHandle == INVALID_HANDLE ||
      m_maSlowHandle == INVALID_HANDLE || m_rsiHandle == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create indicator handles");
      return false;
   }
   
   ArraySetAsSeries(m_atrBuffer, true);
   ArraySetAsSeries(m_maFastBuffer, true);
   ArraySetAsSeries(m_maSlowBuffer, true);
   ArraySetAsSeries(m_rsiBuffer, true);
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                      |
//+------------------------------------------------------------------+
void CWyckoffCore::Deinit()
{
   if(m_atrHandle != INVALID_HANDLE) { IndicatorRelease(m_atrHandle); m_atrHandle = INVALID_HANDLE; }
   if(m_maFastHandle != INVALID_HANDLE) { IndicatorRelease(m_maFastHandle); m_maFastHandle = INVALID_HANDLE; }
   if(m_maSlowHandle != INVALID_HANDLE) { IndicatorRelease(m_maSlowHandle); m_maSlowHandle = INVALID_HANDLE; }
   if(m_rsiHandle != INVALID_HANDLE) { IndicatorRelease(m_rsiHandle); m_rsiHandle = INVALID_HANDLE; }
   if(m_volMAHandle != INVALID_HANDLE) { IndicatorRelease(m_volMAHandle); m_volMAHandle = INVALID_HANDLE; }
}

//+------------------------------------------------------------------+
//| Get ATR value                                                     |
//+------------------------------------------------------------------+
double CWyckoffCore::GetATR(int shift)
{
   if(CopyBuffer(m_atrHandle, 0, shift, 1, m_atrBuffer) <= 0) return 0;
   return m_atrBuffer[0];
}

//+------------------------------------------------------------------+
//| Get Fast MA value                                                 |
//+------------------------------------------------------------------+
double CWyckoffCore::GetMAFast(int shift)
{
   if(CopyBuffer(m_maFastHandle, 0, shift, 1, m_maFastBuffer) <= 0) return 0;
   return m_maFastBuffer[0];
}

//+------------------------------------------------------------------+
//| Get Slow MA value                                                 |
//+------------------------------------------------------------------+
double CWyckoffCore::GetMASlow(int shift)
{
   if(CopyBuffer(m_maSlowHandle, 0, shift, 1, m_maSlowBuffer) <= 0) return 0;
   return m_maSlowBuffer[0];
}

//+------------------------------------------------------------------+
//| Get RSI value                                                     |
//+------------------------------------------------------------------+
double CWyckoffCore::GetRSI(int shift)
{
   if(CopyBuffer(m_rsiHandle, 0, shift, 1, m_rsiBuffer) <= 0) return 50;
   return m_rsiBuffer[0];
}

//+------------------------------------------------------------------+
//| Analyze Price-Volume Harmony                                      |
//+------------------------------------------------------------------+
ENUM_PV_HARMONY CWyckoffCore::AnalyzePVHarmony(int period, int shift)
{
   return CalcPVHarmony(m_symbol, m_timeframe, period, shift);
}

//+------------------------------------------------------------------+
//| Analyze Trend Direction                                           |
//+------------------------------------------------------------------+
int CWyckoffCore::AnalyzeTrend(int period, int shift)
{
   double maFast = GetMAFast(shift);
   double maSlow = GetMASlow(shift);
   double rsi = GetRSI(shift);
   
   int maSignal = 0;
   if(maFast > maSlow) maSignal = 1;
   else if(maFast < maSlow) maSignal = -1;
   
   int rsiSignal = 0;
   if(rsi > 55) rsiSignal = 1;
   else if(rsi < 45) rsiSignal = -1;
   
   // Combined signal
   if(maSignal == 1 && rsiSignal >= 0) return 1;
   if(maSignal == -1 && rsiSignal <= 0) return -1;
   if(maSignal == 1 && rsiSignal == -1) return 1; // MA dominant
   if(maSignal == -1 && rsiSignal == 1) return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Analyze Volume                                                    |
//+------------------------------------------------------------------+
VolumeAnalysis CWyckoffCore::AnalyzeVolume(int period, int shift)
{
   VolumeAnalysis va;
   va.Reset();
   
   long volumes[];
   ArraySetAsSeries(volumes, true);
   if(CopyTickVolume(m_symbol, m_timeframe, shift, period + 1, volumes) < period + 1)
      return va;
   
   va.currentVolume = (double)volumes[0];
   
   // Calculate average
   double sum = 0;
   for(int i = 1; i <= period; i++)
      sum += (double)volumes[i];
   va.avgVolume = sum / period;
   
   if(va.avgVolume > 0)
      va.relativeVolume = va.currentVolume / va.avgVolume;
   
   // Volume trend
   va.volumeTrend = CalcVolumeTrend(m_symbol, m_timeframe, period, shift);
   va.isRisingVol = (va.volumeTrend > 0.05);
   va.isFallingVol = (va.volumeTrend < -0.05);
   
   // Climax detection
   va.isClimaxVol = (va.relativeVolume >= 2.5);
   va.isLowVol = (va.relativeVolume <= 0.3);
   
   // Volume at highs/lows
   double highs[], lows[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   
   if(CopyHigh(m_symbol, m_timeframe, shift, period, highs) >= period &&
      CopyLow(m_symbol, m_timeframe, shift, period, lows) >= period)
   {
      double highestHigh = highs[0];
      double lowestLow = lows[0];
      int highBar = 0, lowBar = 0;
      
      for(int i = 1; i < period; i++)
      {
         if(highs[i] > highestHigh) { highestHigh = highs[i]; highBar = i; }
         if(lows[i] < lowestLow) { lowestLow = lows[i]; lowBar = i; }
      }
      
      va.volAtHighs = (double)volumes[highBar];
      va.volAtLows = (double)volumes[lowBar];
   }
   
   return va;
}

//+------------------------------------------------------------------+
//| Analyze Trend Health                                              |
//+------------------------------------------------------------------+
TrendHealth CWyckoffCore::AnalyzeTrendHealth(int period, int shift)
{
   TrendHealth th;
   th.Reset();
   
   th.direction = AnalyzeTrend(period, shift);
   th.speed = CalcTrendSpeed(m_symbol, m_timeframe, period, shift);
   th.projection = CalcProjectionRatio(m_symbol, m_timeframe, shift);
   th.depth = CalcPullbackDepth(m_symbol, m_timeframe, shift);
   th.pvHarmony = AnalyzePVHarmony(period, shift);
   
   // Count consecutive HH/HL/LH/LL
   double highs[], lows[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   
   if(CopyHigh(m_symbol, m_timeframe, shift, period, highs) >= period &&
      CopyLow(m_symbol, m_timeframe, shift, period, lows) >= period)
   {
      for(int i = 0; i < period - 1; i++)
      {
         if(highs[i] > highs[i + 1]) th.consecutiveHH++;
         else break;
      }
      
      for(int i = 0; i < period - 1; i++)
      {
         if(lows[i] > lows[i + 1]) th.consecutiveHL++;
         else break;
      }
      
      for(int i = 0; i < period - 1; i++)
      {
         if(highs[i] < highs[i + 1]) th.consecutiveLH++;
         else break;
      }
      
      for(int i = 0; i < period - 1; i++)
      {
         if(lows[i] < lows[i + 1]) th.consecutiveLL++;
         else break;
      }
   }
   
   // Health assessment
   th.isHealthy = false;
   if(th.direction == 1) // Uptrend
   {
      th.isHealthy = (th.consecutiveHH > 0 && th.consecutiveHL > 0 &&
                      th.pvHarmony == PV_HARMONY_BULLISH);
   }
   else if(th.direction == -1) // Downtrend
   {
      th.isHealthy = (th.consecutiveLH > 0 && th.consecutiveLL > 0 &&
                      th.pvHarmony == PV_HARMONY_BEARISH);
   }
   
   // Divergence detection
   th.isDiverging = (th.pvHarmony == PV_DIVERGENCE_WARNING ||
                     th.pvHarmony == PV_DIVERGENCE_CONFIRM);
   
   // Climax detection
   th.isClimax = (th.pvHarmony == PV_CLIMAX_ACTIVITY);
   
   return th;
}

//+------------------------------------------------------------------+
//| Detect Spring                                                     |
//+------------------------------------------------------------------+
int CWyckoffCore::DetectSpring(double rangeLow, int shift)
{
   return ::DetectSpring(m_symbol, m_timeframe, shift, rangeLow, 0.5);
}

//+------------------------------------------------------------------+
//| Detect UTAD                                                       |
//+------------------------------------------------------------------+
int CWyckoffCore::DetectUTAD(double rangeHigh, int shift)
{
   return ::DetectUTAD(m_symbol, m_timeframe, shift, rangeHigh, 0.5);
}

//+------------------------------------------------------------------+
//| Detect Significant Bar                                            |
//+------------------------------------------------------------------+
int CWyckoffCore::DetectSignificantBar(double rangeMult, int shift)
{
   return ::DetectSignificantBar(m_symbol, m_timeframe, shift, rangeMult);
}

//+------------------------------------------------------------------+
//| Detect Breakout                                                   |
//+------------------------------------------------------------------+
int CWyckoffCore::DetectBreakout(double level, bool isResistance, int shift)
{
   return ::DetectBreakout(m_symbol, m_timeframe, shift, level, isResistance, 0.3);
}

//+------------------------------------------------------------------+
//| Check if range is valid (not too narrow)                          |
//+------------------------------------------------------------------+
bool CWyckoffCore::IsRangeValid(double rangeHigh, double rangeLow, double minRange)
{
   return ((rangeHigh - rangeLow) >= minRange);
}

//+------------------------------------------------------------------+
//| Normalize price to 0-100 scale within range                       |
//+------------------------------------------------------------------+
double CWyckoffCore::NormalizePrice(double price, double rangeHigh, double rangeLow)
{
   double range = rangeHigh - rangeLow;
   if(range == 0) return 50;
   return ((price - rangeLow) / range) * 100.0;
}
//+------------------------------------------------------------------+
