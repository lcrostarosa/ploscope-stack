
n# PLO Equity Simulation and Analysis System

This comprehensive simulation system generates thousands of random Pot Limit Omaha (PLO) hands, calculates their equities using your backend server, and provides detailed statistical analysis and visualizations.

## Features

### 🎲 Simulation Capabilities
- Generate up to 100,000+ random PLO hands
- 8-player tables with 4-card hole cards
- Dual board analysis (top and bottom flop)
- **Multithreaded processing** for 5-10x speed improvement
- Configurable thread pools (1-50 concurrent threads)
- Batch processing with thread-safe data handling
- Real-time progress tracking
- Automatic retry and error handling

### 📊 Hand Analysis
- **Hand Strength Categorization**: Automatically categorizes each hand into poker strength categories:
  - Garbage (high card)
  - Bottom/Middle/Top Pair
  - Bottom/Middle/Top Two Pair
  - Low/Middle/Top Three of a Kind
  - Bottom/Middle/Top Full House
  - Four of a Kind
  - Straight Flush

### 📈 Equity Analysis
- **Estimated vs Actual Equity**: Compare theoretical equity with multi-player actual equity
- **Statistical Metrics**: Mean, median, standard deviation, min/max for all equity types
- **Scoop Probability**: Calculate likelihood of winning both boards
- **Bad Beat Analysis**: Identify vulnerable strong hands and their weakness frequencies

### 📊 Visualizations
- Equity distribution histograms
- Estimated vs Actual equity scatter plots
- Hand category frequency analysis
- Scoop probability distributions
- Bad beat vulnerability charts
- Comprehensive statistical summaries

## Installation and Setup

### Prerequisites
1. **Backend Server**: Make sure your equity calculation server is running
   ```bash
   cd backend
   python equity_server.py
   ```

2. **Python Dependencies**: Install required packages
   ```bash
   pip install -r requirements.txt
   ```

### Dependencies
- `pandas` - Data manipulation and analysis
- `numpy` - Numerical computations
- `matplotlib` - Plotting and visualization
- `seaborn` - Statistical data visualization
- `requests` - HTTP requests to backend
- `treys` - Poker hand evaluation

## Usage

### Quick Start
```bash
# Run a quick test with 100 hands
python run_simulation.py --quick-test

# Run 1,000 hands (good for testing)
python run_simulation.py --hands 1000

# Run full simulation with 100,000 hands
python run_simulation.py --hands 100000 --batch-size 100

# High-performance run with 20 threads
python run_simulation.py --hands 50000 --threads 20 --batch-size 200
```

### Command Line Options
```bash
python run_simulation.py [OPTIONS]

Options:
  --hands N           Number of hands to simulate (default: 1000)
  --batch-size N      Batch size for processing (default: 50)
  --threads N         Maximum concurrent threads (default: 10)
  --backend-url URL   Backend server URL (default: http://localhost:5001)
  --no-viz           Skip visualization generation
  --quick-test       Run quick test with 100 hands
  -h, --help         Show help message
```

### Examples
```bash
# Quick test run
python run_simulation.py --quick-test

# Medium simulation
python run_simulation.py --hands 10000 --batch-size 100

# Large simulation without visualizations (faster)
python run_simulation.py --hands 100000 --no-viz

# High-performance run with many threads
python run_simulation.py --hands 50000 --threads 25 --batch-size 250

# Custom backend server
python run_simulation.py --backend-url http://192.168.1.100:5001
```

## Output Files

### Data Files
- `simulation_results/plo_simulation_results_TIMESTAMP.json` - Complete simulation data
- `simulation_results/intermediate_results_N.json` - Periodic backups during long runs

### Visualizations
All visualizations are saved to `simulation_visualizations/`:

1. **equity_distributions.png** - Equity distribution analysis
   - Estimated vs Actual equity scatter plots
   - Equity histograms for both boards

2. **hand_category_analysis.png** - Hand strength analysis
   - Frequency of each hand category
   - Average equity by hand strength

3. **scoop_analysis.png** - Scoop probability analysis
   - Scoop probability distributions
   - Correlation with individual board equities

4. **bad_beat_analysis.png** - Bad beat vulnerability
   - Frequency of bad beats by hand type
   - Vulnerability scores and distributions

5. **statistical_summary.png** - Complete statistical overview
   - Mean, median, standard deviation tables
   - Min/max values for all metrics

### Statistical Data
- `simulation_visualizations/statistical_summary.json` - Raw statistical data in JSON format

## Data Format

### Input Format (to Backend)
```json
{
  "players": [
    {
      "player_number": 1,
      "cards": ["Js", "7d", "As", "8d"]
    },
    ...
  ],
  "topBoard": ["7h", "4d", "Jd"],
  "bottomBoard": ["9s", "4c", "2s"]
}
```

### Output Format (from Backend)
```json
[
  {
    "player_number": 1,
    "cards": ["Js", "7d", "As", "8d"],
    "top_estimated_equity": 0.125,
    "top_actual_equity": 0.15,
    "bottom_estimated_equity": 0.125,
    "bottom_actual_equity": 0.12
  },
  ...
]
```

## Analysis Features

### Hand Categorization
The system categorizes each player's hand on each board using the Treys poker evaluation library:

- **Straight Flush** (score ≤ 10)
- **Four of a Kind** (score ≤ 166)
- **Full House** (score ≤ 1599)
  - Top Full House (score ≤ 322)
  - Middle Full House (322 < score ≤ 900)
  - Bottom Full House (900 < score ≤ 1599)
- **Three of a Kind** (1619 < score ≤ 2467)
  - Top/Middle/Low categorization
- **Two Pair** (2467 < score ≤ 3325)
  - Top and Bottom, Middle, Bottom categorization
- **One Pair** (3325 < score ≤ 6185)
  - Top/Middle/Bottom categorization
- **High Card** (score > 6185)

### Bad Beat Analysis
Identifies situations where strong hands are vulnerable:
- Tracks hands with >80% equity that still lose
- Calculates vulnerability scores
- Identifies most common bad beat scenarios
- Analyzes by hand strength category

### Scoop Probability
Calculates the likelihood of winning both boards:
- Simple independence assumption: P(scoop) = P(top) × P(bottom)
- Identifies hands with high scoop potential
- Correlates with hand strength categories

## Performance

### Recommended Settings
- **Testing**: 100-1,000 hands, 5-10 threads, batch size 25-50
- **Analysis**: 10,000-50,000 hands, 10-20 threads, batch size 100-200
- **Research**: 100,000+ hands, 15-25 threads, batch size 200-500

### Timing Estimates (Multithreaded)
- 100 hands: ~5-15 seconds (10 threads)
- 1,000 hands: ~30-90 seconds (10 threads)
- 10,000 hands: ~5-15 minutes (20 threads)
- 100,000 hands: ~1-3 hours (25 threads)

*Times depend on backend server performance, thread count, and network latency*

### Thread Performance Guidelines
- **Conservative**: 5-10 threads for stable performance
- **Balanced**: 10-20 threads for good speed/stability ratio
- **Aggressive**: 20-30 threads for maximum speed (monitor backend load)
- **Warning**: >30 threads may overwhelm the backend server

## Troubleshooting

### Common Issues
1. **Backend Connection Errors**
   - Ensure equity server is running: `cd backend && python equity_server.py`
   - Check URL and port: default is `http://localhost:5001`

2. **Memory Issues with Large Simulations**
   - Reduce batch size: `--batch-size 25`
   - Skip visualizations: `--no-viz`
   - Run in smaller chunks

3. **Slow Performance**
   - Increase batch size for better throughput
   - Check backend server performance
   - Consider running on faster hardware

### Error Recovery
- Simulation automatically saves progress every 10 batches
- Interrupted simulations save partial results
- Failed requests are tracked and reported

## Advanced Usage

### Customizing the Simulation
Edit `simulation/plo_simulation.py` to:
- Change number of players (default: 8)
- Modify hand categorization logic
- Add custom analysis metrics
- Adjust bad beat vulnerability thresholds

### Integration with Other Tools
The JSON output format is compatible with:
- R statistical analysis
- Excel/Google Sheets
- Custom data analysis pipelines
- Machine learning frameworks

## Contributing

To extend the simulation system:
1. Fork the repository
2. Add new analysis functions to `PLOSimulation` class
3. Update visualization methods
4. Add tests for new functionality
5. Submit pull request

## License

This simulation system is part of the PLOSolver project and follows the same license terms. 