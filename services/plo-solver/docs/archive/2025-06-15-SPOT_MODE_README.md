# 🎯 Spot Mode - PLO Equity Calculator

## Overview

Spot Mode is a new feature in the PLO Simulator that allows you to set up specific poker scenarios and calculate equity against random opponents. This is perfect for analyzing particular hands or spots that you want to study.

## Features

### 🎲 Scenario Setup
- **Hero Cards**: Input your exact 4-card PLO hand
- **Known Opponents**: Optionally add specific opponent hands
- **Community Cards**: Set any combination of flop, turn, and river cards for both boards
- **Flexible Boards**: Can simulate pre-flop, post-flop, turn, or river scenarios

### 🔢 Simulation Settings
- **Random Opponents**: Choose 1-7 random opponents to simulate against
- **Simulation Runs**: Configure from 100 to 100,000 iterations for accuracy
- **Dual Board Support**: Full PLO5 (double board) equity calculations

### 📊 Results
- **Estimated Equity**: Your equity against random opponents
- **Actual Equity**: Multi-player equity considering all known hands
- **Both Boards**: Separate calculations for top and bottom boards

## How to Use

### 1. Enable Spot Mode
- Click the **🎯 Spot Mode** button at the top of the interface
- This toggles between Live Mode (full table simulation) and Spot Mode

### 2. Set Your Cards
- **Hero Cards**: Select your 4 PLO cards using the dropdown menus
- Cards are automatically prevented from being duplicated

### 3. Add Community Cards (Optional)
Configure the boards with any combination of:
- **Top Board**: Flop (3 cards), Turn (1 card), River (1 card)
- **Bottom Board**: Flop (3 cards), Turn (1 card), River (1 card)
- **Leave Empty**: For pre-flop simulations

### 4. Add Known Opponents (Optional)
- Click **+ Add Opponent** to add known opponent hands
- Input their 4 cards using the dropdown menus
- Click **Remove** to delete an opponent

### 5. Configure Simulation
- **Random Opponents**: Set how many random opponents to simulate against (1-7)
- **Simulation Runs**: Higher numbers = more accurate results (1000 recommended)

### 6. Run Simulation
- Click **Run Simulation** to calculate equity
- Results will show estimated and actual equity for both boards

## Example Scenarios

### Pre-Flop Analysis
```
Hero: A♠ A♥ K♦ Q♣
Community Cards: (empty)
Random Opponents: 3
Simulation Runs: 5000
```

### Post-Flop Spot
```
Hero: J♠ T♠ 9♥ 8♥
Top Board: A♠ 7♠ 2♦
Bottom Board: K♥ Q♥ 5♣
Random Opponents: 2
Simulation Runs: 2000
```

### Known Opponent Analysis
```
Hero: A♠ A♥ K♦ Q♣
Opponent 1: 8♠ 8♥ 7♦ 6♣
Top Board: A♦ 8♣ 2♠
Bottom Board: K♠ Q♠ J♠
Random Opponents: 1
```

## Technical Details

### Card Selection
- **Duplicate Prevention**: Cards are automatically marked and prevented from being selected twice
- **Warning Indicators**: ⚠️ appears next to any accidentally duplicated cards
- **Standard Notation**: Uses standard poker notation (2-9, T, J, Q, K, A with suits ♠♥♦♣)

### Simulation Engine
- **Backend Processing**: Uses the same high-performance multiprocessing engine as Live Mode
- **PLO Rules**: Proper PLO hand evaluation (exactly 2 hole cards + 3 board cards)
- **Random Generation**: Cryptographically random opponent hands and board completion

### API Endpoint
The frontend communicates with the backend via:
```
POST /spot-simulation
```

With request format:
```json
{
  "players": [
    {
      "player_number": 1,
      "cards": ["As", "Ah", "Kd", "Qc"]
    }
  ],
  "topBoard": ["Ad", "8c", "2s"],
  "bottomBoard": ["Ks", "Qs", "Js"],
  "numRandomOpponents": 2,
  "simulationRuns": 1000
}
```

## Performance Guidelines

### Recommended Settings
- **Quick Analysis**: 1,000 runs (5-15 seconds)
- **Detailed Analysis**: 5,000 runs (15-60 seconds)
- **High Precision**: 10,000+ runs (1-5 minutes)

### Factors Affecting Speed
- **Number of simulation runs**: Linear impact on time
- **Random opponents**: Minimal impact
- **Board completion**: More missing cards = slightly slower
- **Server hardware**: CPU cores and speed matter most

## Use Cases

### 🎓 Study Tool
- Analyze specific hands from your play sessions
- Compare equity in different board textures
- Understand how opponent ranges affect your equity

### 🧮 Equity Calculator
- Quick equity calculations for coaching
- Hand review and analysis
- Pre-flop equity comparisons

### 🔬 Research Tool
- Generate data for PLO strategy articles
- Test theoretical scenarios
- Validate hand strength assumptions

## Switching Between Modes

### Live Mode (🎲)
- Full 8-player table simulation
- Random deals and betting action
- Complete poker hand simulation

### Spot Mode (🎯)
- Specific scenario analysis
- Custom hand and board setup
- Focused equity calculations

Click the mode buttons at the top to switch between them instantly.

## Tips for Accurate Results

1. **Use Enough Iterations**: 1000+ for reliable results, 5000+ for precision
2. **Complete Scenarios**: Fill in all known information for most accurate equity
3. **Realistic Opponents**: Consider actual opponent ranges when interpreting results
4. **Board Texture**: Different board textures dramatically affect equity
5. **Sample Size**: Run multiple similar scenarios to understand variance

## Troubleshooting

### Common Issues
- **Duplicate Cards**: Check for ⚠️ warnings and fix duplicate selections
- **Slow Results**: Reduce simulation runs or check backend server
- **No Results**: Ensure at least hero cards are filled in completely

### Backend Requirements
- Equity server must be running on port 5001
- Start with: `cd backend && python equity_server.py`

## Future Enhancements

Planned features for Spot Mode:
- **Range vs Range**: Simulate ranges instead of specific hands
- **ICM Integration**: Tournament equity calculations  
- **Hand History Import**: Load hands from tracking software
- **Batch Analysis**: Run multiple scenarios automatically
- **Export Results**: Save results to CSV/JSON files 