# Hermes Project

MT5 Wyckoff Trading System and related projects.

## Structure

- `Wyckoff_Experts/` — Main EA files (.mq5) for MetaTrader 5
- `Wyckoff_Include/` — Include library files (.mqh) for the EA

## Project: Wyckoff Unified Trading System (UTS)

A Wyckoff Method-based automated trading system for MetaTrader 5.

### Components

| File | Description |
|------|-------------|
| `WyckoffUnifiedEA.mq5` | Main Expert Advisor entry point |
| `WyckoffCore.mqh` | Core utility functions (ATR, range stats, trend) |
| `WyckoffPhaseEngine.mqh` | Wyckoff Phase Detection (A/B/C/D/E) |
| `WyckoffSignalEngine.mqh` | Trade signal generation |
| `WyckoffRiskManager.mqh` | Risk management and position sizing |

### Compile

Open in MetaTrader 5 MetaEditor and press F7 to compile.
