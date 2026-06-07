//+------------------------------------------------------------------+
//|                                        WyckoffPhaseEngine.mqh    |
//|                         Wyckoff Unified Trading System            |
//|                     Five-Phase Automatic Recognition Engine        |
//+------------------------------------------------------------------+
#property copyright "Wyckoff UTS"
#property strict

#ifndef WYCKOFF_PHASE_ENGINE_MQH
#define WYCKOFF_PHASE_ENGINE_MQH


#include "WyckoffCore.mqh"
#include <Object.mqh>

//+------------------------------------------------------------------+
//| Constants                                                         |
//+------------------------------------------------------------------+
#define WYCKOFF_MIN_RANGE_BARS     10
#define WYCKOFF_MIN_PHASE_B_BARS   20
#define WYCKOFF_MAX_LOOKBACK       200
#define WYCKOFF_RANGE_ATR_FACTOR   0.5
#define WYCKOFF_VOL_CLIMAX_MULT    2.5
#define WYCKOFF_VOL_LOW_MULT       0.3
#define WYCKOFF_SPRING_ATR_FACTOR  0.5
#define WYCKOFF_UTAD_ATR_FACTOR    0.5
#define WYCKOFF_CONFIRM_BARS       2
#define WYCKOFF_TRANSITION_BARS    3

//+------------------------------------------------------------------+
//| Phase Detection Result Structure                                  |
//+------------------------------------------------------------------+
struct PhaseDetectionResult
{
   ENUM_WYCKOFF_PHASE    detectedPhase;
   ENUM_WYCKOFF_EVENT    detectedEvent;
   double                eventLevel;
   int                   confidence;
   bool                  isValid;
   string                description;
   datetime              phaseStartTime;
   int                   barsSincePhaseStart;
   
   void Reset()
   {
      detectedPhase = WYCKOFF_PHASE_UNKNOWN;
      detectedEvent = WYCKOFF_EVENT_NONE;
      eventLevel = 0;
      confidence = 0;
      isValid = false;
      description = "";
      phaseStartTime = 0;
      barsSincePhaseStart = 0;
   }
};

//+------------------------------------------------------------------+
//| Wyckoff Phase Engine Class                                        |
//+------------------------------------------------------------------+
class CWyckoffPhaseEngine : public CObject
{
private:
   string               m_symbol;
   ENUM_TIMEFRAMES      m_timeframe;
   CWyckoffCore*        m_core;
   
   WyckoffStructure     m_structure;
   PhaseDetectionResult m_lastResult;
   
   int                  m_rangeLookback;
   int                  m_minRangeBars;
   double               m_minRangeATR;
   
   double               m_highs[];
   double               m_lows[];
   double               m_closes[];
   long                 m_volumes[];
   datetime             m_times[];
   
   //--- Internal Methods
   bool                 CachePriceData(int lookback);
   double               FindSwingHigh(int startBar, int searchBars);
   double               FindSwingLow(int startBar, int searchBars);
   int                  FindSwingHighBar(int startBar, int searchBars);
   int                  FindSwingLowBar(int startBar, int searchBars);
   double               CalculateAverageRange(int bars);
   bool                 IsConsolidating(int startBar, int numBars, double rangeHigh, double rangeLow);
   bool                 IsClimaxBar(int shift, bool isSelling);
   bool                 IsPriceInRange(double price, double rangeHigh, double rangeLow, double tolerance);
   int                  CountBarsInRange(double rangeHigh, double rangeLow, int startBar, int numBars);
   double               GetVolatility(int period);
   
public:
                     CWyckoffPhaseEngine();
                    ~CWyckoffPhaseEngine();
   
   bool                 Init(string symbol, ENUM_TIMEFRAMES timeframe);
   void                 Deinit();
   
   PhaseDetectionResult DetectCurrentPhase();
   
   bool                 DetectPhaseA(int &startBar, double &scLevel, double &arLevel, double &stLevel, bool &isAccumulation);
   bool                 DetectPhaseB(int startBar, double rangeHigh, double rangeLow);
   bool                 DetectPhaseC(int startBar, double rangeHigh, double rangeLow, bool isAccumulation,
                                     ENUM_WYCKOFF_EVENT &detectedEvent, double &eventLevel);
   bool                 DetectPhaseD(int startBar, double rangeHigh, double rangeLow, bool isAccumulation,
                                     ENUM_WYCKOFF_EVENT &detectedEvent, double &eventLevel);
   bool                 DetectPhaseE(int startBar, double rangeHigh, double rangeLow, bool isAccumulation,
                                     ENUM_WYCKOFF_EVENT &detectedEvent);
   
   bool                 DetectRange(double &rangeHigh, double &rangeLow, int &startBar, int &numBars);
   
   bool                 IsSpringEvent(int shift, double rangeLow);
   bool                 IsUTADEvent(int shift, double rangeHigh);
   bool                 IsSOSEvent(int shift);
   bool                 IsSOWEvent(int shift);
   bool                 IsLPS(int shift, double level, bool isSupport);
   bool                 IsBreakoutEvent(int shift, double level, bool isUp);
   bool                 IsClimaxActivity(int shift, bool &isBuying);
   
   WyckoffStructure     GetStructure() { return m_structure; }
   PhaseDetectionResult GetLastResult() { return m_lastResult; }
   CWyckoffCore*        GetCore() { return m_core; }
   
   void                 ResetStructure() { m_structure.Reset(); }
   ENUM_WYCKOFF_PHASE   GetCurrentPhase() { return m_structure.currentPhase; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CWyckoffPhaseEngine::CWyckoffPhaseEngine()
{
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_core = NULL;
   m_rangeLookback = WYCKOFF_MAX_LOOKBACK;
   m_minRangeBars = WYCKOFF_MIN_PHASE_B_BARS;
   m_lastResult.Reset();
   m_structure.Reset();
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CWyckoffPhaseEngine::~CWyckoffPhaseEngine()
{
   Deinit();
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::Init(string symbol, ENUM_TIMEFRAMES timeframe)
{
   m_symbol = symbol;
   m_timeframe = timeframe;
   
   m_core = new CWyckoffCore();
   if(!m_core.Init(m_symbol, m_timeframe))
   {
      Print("ERROR: Failed to initialize WyckoffCore");
      delete m_core;
      m_core = NULL;
      return false;
   }
   
   m_minRangeATR = m_core.GetATR(0) * 3.0;
   
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                      |
//+------------------------------------------------------------------+
void CWyckoffPhaseEngine::Deinit()
{
   if(m_core != NULL)
   {
      m_core.Deinit();
      delete m_core;
      m_core = NULL;
   }
}

//+------------------------------------------------------------------+
//| Cache price data for analysis                                     |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::CachePriceData(int lookback)
{
   ArraySetAsSeries(m_highs, true);
   ArraySetAsSeries(m_lows, true);
   ArraySetAsSeries(m_closes, true);
   ArraySetAsSeries(m_volumes, true);
   ArraySetAsSeries(m_times, true);
   
   if(CopyHigh(m_symbol, m_timeframe, 0, lookback, m_highs) < lookback) return false;
   if(CopyLow(m_symbol, m_timeframe, 0, lookback, m_lows) < lookback) return false;
   if(CopyClose(m_symbol, m_timeframe, 0, lookback, m_closes) < lookback) return false;
   if(CopyTickVolume(m_symbol, m_timeframe, 0, lookback, m_volumes) < lookback) return false;
   if(CopyTime(m_symbol, m_timeframe, 0, lookback, m_times) < lookback) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Find Swing High                                                   |
//+------------------------------------------------------------------+
double CWyckoffPhaseEngine::FindSwingHigh(int startBar, int searchBars)
{
   double highest = 0;
   for(int i = startBar; i < startBar + searchBars && i < ArraySize(m_highs); i++)
   {
      if(m_highs[i] > highest) highest = m_highs[i];
   }
   return highest;
}

//+------------------------------------------------------------------+
//| Find Swing Low                                                    |
//+------------------------------------------------------------------+
double CWyckoffPhaseEngine::FindSwingLow(int startBar, int searchBars)
{
   double lowest = DBL_MAX;
   for(int i = startBar; i < startBar + searchBars && i < ArraySize(m_lows); i++)
   {
      if(m_lows[i] < lowest) lowest = m_lows[i];
   }
   return (lowest == DBL_MAX) ? 0 : lowest;
}

//+------------------------------------------------------------------+
//| Find Swing High Bar Index                                         |
//+------------------------------------------------------------------+
int CWyckoffPhaseEngine::FindSwingHighBar(int startBar, int searchBars)
{
   double highest = 0;
   int bar = startBar;
   for(int i = startBar; i < startBar + searchBars && i < ArraySize(m_highs); i++)
   {
      if(m_highs[i] > highest) { highest = m_highs[i]; bar = i; }
   }
   return bar;
}

//+------------------------------------------------------------------+
//| Find Swing Low Bar Index                                          |
//+------------------------------------------------------------------+
int CWyckoffPhaseEngine::FindSwingLowBar(int startBar, int searchBars)
{
   double lowest = DBL_MAX;
   int bar = startBar;
   for(int i = startBar; i < startBar + searchBars && i < ArraySize(m_lows); i++)
   {
      if(m_lows[i] < lowest) { lowest = m_lows[i]; bar = i; }
   }
   return bar;
}

//+------------------------------------------------------------------+
//| Calculate Average Range                                           |
//+------------------------------------------------------------------+
double CWyckoffPhaseEngine::CalculateAverageRange(int bars)
{
   double sum = 0;
   int count = MathMin(bars, ArraySize(m_highs) - 1);
   for(int i = 0; i < count; i++)
      sum += (m_highs[i] - m_lows[i]);
   return (count > 0) ? sum / count : 0;
}

//+------------------------------------------------------------------+
//| Check if price is consolidating                                   |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsConsolidating(int startBar, int numBars, double rangeHigh, double rangeLow)
{
   int inRangeCount = 0;
   for(int i = startBar; i < startBar + numBars && i < ArraySize(m_closes); i++)
   {
      if(m_closes[i] >= rangeLow && m_closes[i] <= rangeHigh)
         inRangeCount++;
   }
   return (numBars > 0 && (double)inRangeCount / numBars >= 0.7);
}

//+------------------------------------------------------------------+
//| Check if bar is climax bar                                        |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsClimaxBar(int shift, bool isSelling)
{
   if(shift >= ArraySize(m_highs) - 1) return false;
   
   double range = m_highs[shift] - m_lows[shift];
   double avgRange = CalculateAverageRange(20);
   double vol = (double)m_volumes[shift];
   
   double avgVol = 0;
   for(int i = shift + 1; i <= shift + 20 && i < ArraySize(m_volumes); i++)
      avgVol += (double)m_volumes[i];
   avgVol /= 20.0;
   
   bool isWideRange = (range > avgRange * 2.0);
   bool isHighVolume = (vol > avgVol * WYCKOFF_VOL_CLIMAX_MULT);
   
   if(isSelling)
   {
      bool closesNearLow = (m_closes[shift] < m_lows[shift] + range * 0.3);
      return (isWideRange && isHighVolume && closesNearLow);
   }
   else
   {
      bool closesNearHigh = (m_closes[shift] > m_highs[shift] - range * 0.3);
      return (isWideRange && isHighVolume && closesNearHigh);
   }
}

//+------------------------------------------------------------------+
//| Check if price is in range                                        |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsPriceInRange(double price, double rangeHigh, double rangeLow, double tolerance)
{
   return (price >= rangeLow - tolerance && price <= rangeHigh + tolerance);
}

//+------------------------------------------------------------------+
//| Count bars in range                                               |
//+------------------------------------------------------------------+
int CWyckoffPhaseEngine::CountBarsInRange(double rangeHigh, double rangeLow, int startBar, int numBars)
{
   int count = 0;
   double tolerance = (rangeHigh - rangeLow) * 0.1;
   
   for(int i = startBar; i < startBar + numBars && i < ArraySize(m_closes); i++)
   {
      if(IsPriceInRange(m_closes[i], rangeHigh, rangeLow, tolerance))
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Get Volatility                                                    |
//+------------------------------------------------------------------+
double CWyckoffPhaseEngine::GetVolatility(int period)
{
   return m_core.GetATR(0);
}

//+------------------------------------------------------------------+
//| Detect Range                                                      |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::DetectRange(double &rangeHigh, double &rangeLow, int &startBar, int &numBars)
{
   if(!CachePriceData(m_rangeLookback)) return false;
   
   double atr = m_core.GetATR(0);
   double tolerance = atr * WYCKOFF_RANGE_ATR_FACTOR;
   
   for(int lookback = 50; lookback >= m_minRangeBars; lookback -= 10)
   {
      rangeHigh = FindSwingHigh(0, lookback);
      rangeLow = FindSwingLow(0, lookback);
      
      double rangeSize = rangeHigh - rangeLow;
      if(rangeSize < m_minRangeATR) continue;
      
      if(IsConsolidating(0, lookback, rangeHigh + tolerance, rangeLow - tolerance))
      {
         startBar = 0;
         for(int i = 0; i < lookback; i++)
         {
            if(m_closes[i] > rangeHigh || m_closes[i] < rangeLow)
            {
               startBar = i;
               break;
            }
         }
         
         numBars = lookback - startBar;
         if(numBars >= m_minRangeBars)
         {
            m_structure.rangeHigh = rangeHigh;
            m_structure.rangeLow = rangeLow;
            m_structure.rangeMidpoint = (rangeHigh + rangeLow) / 2.0;
            m_structure.rangeSize = rangeSize;
            m_structure.levelCreek = rangeHigh;
            m_structure.levelIce = rangeLow;
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Detect Phase A - Stopping Phase                                   |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::DetectPhaseA(int &startBar, double &scLevel, double &arLevel, double &stLevel, bool &isAccumulation)
{
   if(!CachePriceData(m_rangeLookback)) return false;
   
   double atr = m_core.GetATR(0);
   
   for(int i = 30; i > 2; i--)
   {
      bool isSellingClimax = IsClimaxBar(i, true);
      bool isBuyingClimax = IsClimaxBar(i, false);
      
      if(!isSellingClimax && !isBuyingClimax) continue;
      
      if(isSellingClimax)
      {
         scLevel = m_lows[i];
         isAccumulation = true;
         
         for(int j = i - 1; j > 0; j--)
         {
            if(m_highs[j] > scLevel + atr && m_closes[j] > m_closes[j + 1])
            {
               arLevel = m_highs[j];
               break;
            }
         }
         if(arLevel == 0) arLevel = m_highs[MathMax(0, i - 1)];
         
         for(int j = i - 1; j > 0; j--)
         {
            if(IsPriceInRange(m_lows[j], scLevel - atr * 0.5, scLevel + atr * 0.5, 0))
            {
               double stVol = (double)m_volumes[j];
               double scVol = (double)m_volumes[i];
               if(stVol < scVol * 0.7)
               {
                  stLevel = m_lows[j];
                  startBar = j;
                  m_structure.levelSC = scLevel;
                  m_structure.levelAR = arLevel;
                  m_structure.levelST = stLevel;
                  m_structure.phaseAStart = m_times[j];
                  m_lastResult.detectedEvent = WYCKOFF_EVENT_ST;
                  m_lastResult.eventLevel = stLevel;
                  m_lastResult.isValid = true;
                  m_lastResult.phaseStartTime = m_times[j];
                  return true;
               }
            }
         }
      }
      
      if(isBuyingClimax)
      {
         scLevel = m_highs[i];
         isAccumulation = false;
         
         for(int j = i - 1; j > 0; j--)
         {
            if(m_lows[j] < scLevel - atr && m_closes[j] < m_closes[j + 1])
            {
               arLevel = m_lows[j];
               break;
            }
         }
         if(arLevel == 0) arLevel = m_lows[MathMax(0, i - 1)];
         
         for(int j = i - 1; j > 0; j--)
         {
            if(IsPriceInRange(m_highs[j], scLevel - atr * 0.5, scLevel + atr * 0.5, 0))
            {
               double stVol = (double)m_volumes[j];
               double bcVol = (double)m_volumes[i];
               if(stVol < bcVol * 0.7)
               {
                  stLevel = m_highs[j];
                  startBar = j;
                  m_structure.levelBC = scLevel;
                  m_structure.levelAR = arLevel;
                  m_structure.levelST = stLevel;
                  m_structure.phaseAStart = m_times[j];
                  m_lastResult.detectedEvent = WYCKOFF_EVENT_ST;
                  m_lastResult.eventLevel = stLevel;
                  m_lastResult.isValid = true;
                  m_lastResult.phaseStartTime = m_times[j];
                  return true;
               }
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Detect Phase B - Cause Building Phase                             |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::DetectPhaseB(int startBar, double rangeHigh, double rangeLow)
{
   if(!CachePriceData(m_rangeLookback)) return false;
   
   int barsInRange = 0;
   int totalBars = 0;
   double tolerance = (rangeHigh - rangeLow) * 0.1;
   
   for(int i = startBar; i >= 0 && i < ArraySize(m_closes); i++)
   {
      if(IsPriceInRange(m_closes[i], rangeHigh + tolerance, rangeLow - tolerance, 0))
         barsInRange++;
      totalBars++;
   }
   
   if(barsInRange >= WYCKOFF_MIN_PHASE_B_BARS && IsConsolidating(0, totalBars, rangeHigh, rangeLow))
   {
      m_structure.barsInPhaseB = barsInRange;
      m_structure.phaseBStart = m_times[MathMax(0, ArraySize(m_times) - barsInRange)];
      m_lastResult.detectedPhase = WYCKOFF_PHASE_B;
      m_lastResult.barsSincePhaseStart = barsInRange;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Detect Phase C - Test Phase (Spring/UTAD)                        |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::DetectPhaseC(int startBar, double rangeHigh, double rangeLow, bool isAccumulation,
                                        ENUM_WYCKOFF_EVENT &detectedEvent, double &eventLevel)
{
   if(!CachePriceData(m_rangeLookback)) return false;
   
   detectedEvent = WYCKOFF_EVENT_NONE;
   eventLevel = 0;
   
   double atr = m_core.GetATR(0);
   double tolerance = atr * 0.3;
   
   for(int i = 0; i < 10 && i < ArraySize(m_lows) - 1; i++)
   {
      if(isAccumulation)
      {
         if(m_lows[i] < rangeLow - tolerance && m_closes[i] >= rangeLow - tolerance * 0.5)
         {
            double springVol = (double)m_volumes[i];
            double avgVol = 0;
            int volCount = 0;
            for(int j = i + 1; j < i + 20 && j < ArraySize(m_volumes); j++)
            {
               avgVol += (double)m_volumes[j];
               volCount++;
            }
            if(volCount > 0) avgVol /= volCount;
            
            bool isTestPending = (springVol < avgVol * 2.0);
            bool isRecovery = (m_closes[i] > m_closes[i + 1]);
            
            if(isTestPending && isRecovery)
            {
               detectedEvent = WYCKOFF_EVENT_SPRING;
               eventLevel = m_lows[i];
               m_structure.levelSpring = m_lows[i];
               m_structure.phaseCStart = m_times[i];
               m_structure.isSpringTested = false;
               m_lastResult.detectedEvent = WYCKOFF_EVENT_SPRING;
               m_lastResult.eventLevel = eventLevel;
               m_lastResult.isValid = true;
               return true;
            }
         }
      }
      else
      {
         if(m_highs[i] > rangeHigh + tolerance && m_closes[i] <= rangeHigh + tolerance * 0.5)
         {
            double utadVol = (double)m_volumes[i];
            double avgVol = 0;
            int volCount = 0;
            for(int j = i + 1; j < i + 20 && j < ArraySize(m_volumes); j++)
            {
               avgVol += (double)m_volumes[j];
               volCount++;
            }
            if(volCount > 0) avgVol /= volCount;
            
            bool isTestPending = (utadVol < avgVol * 2.0);
            bool isRejection = (m_closes[i] < m_closes[i + 1]);
            
            if(isTestPending && isRejection)
            {
               detectedEvent = WYCKOFF_EVENT_UTAD;
               eventLevel = m_highs[i];
               m_structure.levelUTAD = m_highs[i];
               m_structure.phaseCStart = m_times[i];
               m_structure.isUTADTested = false;
               m_lastResult.detectedEvent = WYCKOFF_EVENT_UTAD;
               m_lastResult.eventLevel = eventLevel;
               m_lastResult.isValid = true;
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Detect Phase D - Trend Within Range                               |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::DetectPhaseD(int startBar, double rangeHigh, double rangeLow, bool isAccumulation,
                                        ENUM_WYCKOFF_EVENT &detectedEvent, double &eventLevel)
{
   if(!CachePriceData(m_rangeLookback)) return false;
   
   detectedEvent = WYCKOFF_EVENT_NONE;
   eventLevel = 0;
   
   if(isAccumulation)
   {
      for(int i = 0; i < 5 && i < ArraySize(m_highs) - 1; i++)
      {
         double barRange = m_highs[i] - m_lows[i];
         double avgRange = CalculateAverageRange(20);
         double barVol = (double)m_volumes[i];
         
         double avgVol = 0;
         int volCount = 0;
         for(int j = i + 1; j < i + 20 && j < ArraySize(m_volumes); j++)
         {
            avgVol += (double)m_volumes[j];
            volCount++;
         }
         if(volCount > 0) avgVol /= volCount;
         
         bool isWideBar = (barRange > avgRange * 1.5);
         bool isHighVol = (barVol > avgVol * 1.3);
         bool closesNearHigh = (m_closes[i] > m_highs[i] - barRange * 0.3);
         bool isAboveMid = (m_closes[i] > (rangeHigh + rangeLow) / 2.0);
         
         if(isWideBar && isHighVol && closesNearHigh && isAboveMid)
         {
            detectedEvent = WYCKOFF_EVENT_SOS;
            eventLevel = m_closes[i];
            m_structure.phaseDStart = m_times[i];
            m_lastResult.detectedEvent = WYCKOFF_EVENT_SOS;
            m_lastResult.eventLevel = eventLevel;
            m_lastResult.isValid = true;
            return true;
         }
      }
   }
   else
   {
      for(int i = 0; i < 5 && i < ArraySize(m_highs) - 1; i++)
      {
         double barRange = m_highs[i] - m_lows[i];
         double avgRange = CalculateAverageRange(20);
         double barVol = (double)m_volumes[i];
         
         double avgVol = 0;
         int volCount = 0;
         for(int j = i + 1; j < i + 20 && j < ArraySize(m_volumes); j++)
         {
            avgVol += (double)m_volumes[j];
            volCount++;
         }
         if(volCount > 0) avgVol /= volCount;
         
         bool isWideBar = (barRange > avgRange * 1.5);
         bool isHighVol = (barVol > avgVol * 1.3);
         bool closesNearLow = (m_closes[i] < m_lows[i] + barRange * 0.3);
         bool isBelowMid = (m_closes[i] < (rangeHigh + rangeLow) / 2.0);
         
         if(isWideBar && isHighVol && closesNearLow && isBelowMid)
         {
            detectedEvent = WYCKOFF_EVENT_SOW;
            eventLevel = m_closes[i];
            m_structure.phaseDStart = m_times[i];
            m_lastResult.detectedEvent = WYCKOFF_EVENT_SOW;
            m_lastResult.eventLevel = eventLevel;
            m_lastResult.isValid = true;
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Detect Phase E - Trend Out of Range                               |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::DetectPhaseE(int startBar, double rangeHigh, double rangeLow, bool isAccumulation,
                                        ENUM_WYCKOFF_EVENT &detectedEvent)
{
   if(!CachePriceData(m_rangeLookback)) return false;
   
   detectedEvent = WYCKOFF_EVENT_NONE;
   
   double atr = m_core.GetATR(0);
   double tolerance = atr * 0.5;
   
   if(isAccumulation)
   {
      if(m_closes[0] > rangeHigh + tolerance)
      {
         int barsAbove = 0;
         for(int i = 0; i < 5 && i < ArraySize(m_closes); i++)
         {
            if(m_closes[i] > rangeHigh) barsAbove++;
         }
         if(barsAbove >= 2)
         {
            detectedEvent = WYCKOFF_EVENT_BO;
            m_structure.phaseEStart = m_times[0];
            m_structure.isCreekBroken = true;
            m_lastResult.detectedEvent = WYCKOFF_EVENT_BO;
            m_lastResult.eventLevel = rangeHigh;
            m_lastResult.isValid = true;
            return true;
         }
      }
   }
   else
   {
      if(m_closes[0] < rangeLow - tolerance)
      {
         int barsBelow = 0;
         for(int i = 0; i < 5 && i < ArraySize(m_closes); i++)
         {
            if(m_closes[i] < rangeLow) barsBelow++;
         }
         if(barsBelow >= 2)
         {
            detectedEvent = WYCKOFF_EVENT_BO;
            m_structure.phaseEStart = m_times[0];
            m_structure.isIceBroken = true;
            m_lastResult.detectedEvent = WYCKOFF_EVENT_BO;
            m_lastResult.eventLevel = rangeLow;
            m_lastResult.isValid = true;
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Main Phase Detection Entry Point                                  |
//+------------------------------------------------------------------+
PhaseDetectionResult CWyckoffPhaseEngine::DetectCurrentPhase()
{
   PhaseDetectionResult result;
   result.Reset();
   
   if(!CachePriceData(m_rangeLookback))
   {
      result.description = "Failed to cache price data";
      return result;
   }
   
   double rangeHigh = 0, rangeLow = 0;
   int rangeStartBar = 0, rangeNumBars = 0;
   
   bool hasRange = DetectRange(rangeHigh, rangeLow, rangeStartBar, rangeNumBars);
   
   if(!hasRange)
   {
      double scLevel = 0, arLevel = 0, stLevel = 0;
      bool isAccumulation = true;
      int phaseAStart = 0;
      
      if(DetectPhaseA(phaseAStart, scLevel, arLevel, stLevel, isAccumulation))
      {
         result.detectedPhase = WYCKOFF_PHASE_A;
         result.detectedEvent = m_lastResult.detectedEvent;
         result.eventLevel = m_lastResult.eventLevel;
         result.isValid = true;
         result.phaseStartTime = m_lastResult.phaseStartTime;
         result.description = "Phase A detected - Trend stopping";
         m_structure.currentPhase = WYCKOFF_PHASE_A;
         m_lastResult = result;
         return result;
      }
   }
   
   if(hasRange)
   {
      ENUM_WYCKOFF_EVENT detectedEvent;
      double eventLevel;
      bool isAccumulation = (m_structure.levelSC > 0);
      
      if(DetectPhaseE(rangeStartBar, rangeHigh, rangeLow, isAccumulation, detectedEvent))
      {
         result.detectedPhase = WYCKOFF_PHASE_E;
         result.detectedEvent = detectedEvent;
         result.eventLevel = m_lastResult.eventLevel;
         result.isValid = true;
         result.phaseStartTime = m_structure.phaseEStart;
         result.description = "Phase E detected - Trend out of range";
         m_structure.currentPhase = WYCKOFF_PHASE_E;
         m_lastResult = result;
         return result;
      }
      
      if(DetectPhaseD(rangeStartBar, rangeHigh, rangeLow, isAccumulation, detectedEvent, eventLevel))
      {
         result.detectedPhase = WYCKOFF_PHASE_D;
         result.detectedEvent = detectedEvent;
         result.eventLevel = eventLevel;
         result.isValid = true;
         result.phaseStartTime = m_structure.phaseDStart;
         result.description = "Phase D detected - Trend within range";
         m_structure.currentPhase = WYCKOFF_PHASE_D;
         m_lastResult = result;
         return result;
      }
      
      if(DetectPhaseC(rangeStartBar, rangeHigh, rangeLow, isAccumulation, detectedEvent, eventLevel))
      {
         result.detectedPhase = WYCKOFF_PHASE_C;
         result.detectedEvent = detectedEvent;
         result.eventLevel = eventLevel;
         result.isValid = true;
         result.phaseStartTime = m_structure.phaseCStart;
         result.description = "Phase C detected - Test event";
         m_structure.currentPhase = WYCKOFF_PHASE_C;
         m_lastResult = result;
         return result;
      }
      
      if(DetectPhaseB(rangeStartBar, rangeHigh, rangeLow))
      {
         result.detectedPhase = WYCKOFF_PHASE_B;
         result.isValid = true;
         result.phaseStartTime = m_structure.phaseBStart;
         result.description = "Phase B detected - Cause building";
         m_structure.currentPhase = WYCKOFF_PHASE_B;
         m_lastResult = result;
         return result;
      }
      
      result.detectedPhase = WYCKOFF_PHASE_UNKNOWN;
      result.isValid = true;
      result.description = "Range detected but phase unclear";
   }
   
   result.description = "No Wyckoff structure detected";
   m_lastResult = result;
   return result;
}

//+------------------------------------------------------------------+
//| Check for Spring Event                                            |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsSpringEvent(int shift, double rangeLow)
{
   return (m_core.DetectSpring(rangeLow, shift) > 0);
}

//+------------------------------------------------------------------+
//| Check for UTAD Event                                              |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsUTADEvent(int shift, double rangeHigh)
{
   return (m_core.DetectUTAD(rangeHigh, shift) > 0);
}

//+------------------------------------------------------------------+
//| Check for SOS Event                                               |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsSOSEvent(int shift)
{
   return (m_core.DetectSignificantBar(1.5, shift) == 1);
}

//+------------------------------------------------------------------+
//| Check for SOW Event                                               |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsSOWEvent(int shift)
{
   return (m_core.DetectSignificantBar(1.5, shift) == -1);
}

//+------------------------------------------------------------------+
//| Check for LPS/LPSY                                                |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsLPS(int shift, double level, bool isSupport)
{
   if(shift >= ArraySize(m_closes)) return false;
   
   double atr = m_core.GetATR(shift);
   double tolerance = atr * 0.3;
   
   if(isSupport)
   {
      return (IsPriceInRange(m_lows[shift], level - tolerance, level + tolerance, 0) &&
              m_closes[shift] > m_closes[shift + 1]);
   }
   else
   {
      return (IsPriceInRange(m_highs[shift], level - tolerance, level + tolerance, 0) &&
              m_closes[shift] < m_closes[shift + 1]);
   }
}

//+------------------------------------------------------------------+
//| Check for Breakout Event                                          |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsBreakoutEvent(int shift, double level, bool isUp)
{
   int result = m_core.DetectBreakout(level, isUp, shift);
   return ((isUp && result == 1) || (!isUp && result == -1));
}

//+------------------------------------------------------------------+
//| Check for Climax Activity                                         |
//+------------------------------------------------------------------+
bool CWyckoffPhaseEngine::IsClimaxActivity(int shift, bool &isBuying)
{
   if(shift >= ArraySize(m_highs) - 1) return false;
   
   double range = m_highs[shift] - m_lows[shift];
   double avgRange = CalculateAverageRange(20);
   double vol = (double)m_volumes[shift];
   
   double avgVol = 0;
   for(int i = shift + 1; i <= shift + 20 && i < ArraySize(m_volumes); i++)
      avgVol += (double)m_volumes[i];
   avgVol /= 20.0;
   
   bool isWideRange = (range > avgRange * 2.0);
   bool isHighVolume = (vol > avgVol * WYCKOFF_VOL_CLIMAX_MULT);
   
   if(isWideRange && isHighVolume)
   {
      isBuying = (m_closes[shift] > m_highs[shift] - range * 0.3);
      return true;
   }
   
   return false;
}
//+------------------------------------------------------------------+
#endif // WYCKOFF_PHASE_ENGINE_MQH
