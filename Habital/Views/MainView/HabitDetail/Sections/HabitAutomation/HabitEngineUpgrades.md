# Habit Automation Engine Upgrades

## Overview
This document outlines the drop-in upgrades made to the `OldHabitEngine.swift` to improve realism and personalization in habit strength modeling. All changes maintain compatibility with existing Core Data entities and use only available fields.

## Key Improvements Implemented

### 1. Personalized Growth Rates from History
- **Function**: `personalizeGrowthRate()` and `personalizeAvoidanceRate()`
- **Logic**: Analyzes user's actual completion history to estimate their personal learning rate
- **Formula**: `k_fit = -ln(1 - completion_rate) / total_completions` (when ≥8 completions)
- **Blending**: `k_effective = 0.5 * k_base + 0.5 * k_fit`
- **Benefit**: Fast learners get accelerated progress, slow learners get realistic timelines

### 2. Humane Decay (Lighter First Miss)
- **Function**: `getHumaneDecayRate()`
- **Logic**: First miss after a streak gets reduced penalty (0.5x), subsequent misses increase penalty
- **Tiers**: 
  - 1st miss: 0.5x base decay
  - 2nd miss: 1.0x base decay  
  - 3rd+ miss: 1.25x base decay
- **Benefit**: Matches human psychology - one slip doesn't destroy all progress

### 3. Enhanced Experience-Based Floors
- **Function**: `computeExperienceFloor()`
- **Logic**: Rewards long-term practitioners with higher minimum strength retention
- **Base**: `0.05 + 0.002 * totalStreakDays` (capped at 0.50)
- **Bonus**: Extra floor for 60+ streak days: `0.10 + 0.001 * (days - 60)` (capped at 0.55)
- **Final**: `max(base_floor, bonus_floor, peak * residual_factor)`
- **Benefit**: Veterans maintain more habit strength even after breaks

### 4. Schedule Frequency-Aware Drift
- **Function**: `computeFrequencyPerWeek()`
- **Logic**: Scales soft drift based on how often the habit is scheduled
- **Formula**: `softScale = 7 / frequency_per_week`
- **Examples**: 
  - Daily habit (7/week): scale = 1.0
  - 3x/week: scale = 2.33
  - Weekly: scale = 7.0
- **Benefit**: Infrequent habits drift more during long non-scheduled gaps (realistic)

### 5. Bad Habit Improvements
- **Personalized Avoidance**: Same growth personalization as good habits
- **Gentler First Lapse**: After 14+ day avoidance streaks, first lapse uses 0.9x reinstatement rate
- **Frequency Scaling**: Bad habit drift also scales with schedule frequency

### 6. Prediction Realism
- **Personalized Projections**: All future strength predictions use personalized rates
- **Scheduled-Only Growth**: Projections only apply growth on scheduled days
- **Realistic Timelines**: "Days to 95%" accounts for actual schedule, not just calendar days

## Technical Implementation Details

### New Helper Functions Added:
1. `computeFrequencyPerWeek()` - Extracts schedule frequency from repeat patterns
2. `personalizeGrowthRate()` - Learns user's growth rate from history  
3. `personalizeAvoidanceRate()` - Bad habit version of growth personalization
4. `getHumaneDecayRate()` - Applies progressive decay penalties
5. `personalizeReinstatementRate()` - Mitigates first bad habit lapse
6. `computeExperienceFloor()` - Enhanced floor with long-term bonuses

### Modified Core Logic:
- `analyzeFullHabitHistory()`: Added personalization computation at start
- Good habit completion: Uses personalized growth rate
- Good habit miss: Uses humane decay with consecutive miss tracking
- Bad habit avoidance: Uses personalized avoidance rate
- Bad habit lapse: Uses potentially mitigated reinstatement
- Soft drift: Scaled by schedule frequency for both habit types
- All predictions: Use personalized rates instead of base rates

### Numerical Safeguards:
- Growth rates clamped to [0.005, 0.20]
- Decay rates clamped to [0.001, 0.25]  
- All strengths clamped to [0, 1]
- Personalization requires ≥8 completions to activate
- Plateau detection prevents over-fitting at high strengths

## Benefits Achieved

1. **Personalization**: Engine adapts to individual learning patterns
2. **Realism**: Matches human habit formation psychology better
3. **Encouragement**: Reduces discouragement from single lapses
4. **Experience Rewards**: Long-term practitioners get deserved advantages
5. **Schedule Awareness**: Different frequencies handled appropriately
6. **Accurate Predictions**: Timelines based on personal history, not averages

## Backward Compatibility

- No new Core Data fields required
- All existing data structures unchanged
- Graceful fallbacks for insufficient history
- Maintains existing API surface
- Default behavior for edge cases

The engine now provides much more realistic and encouraging feedback while maintaining the scientific foundation of the original habit strength model.