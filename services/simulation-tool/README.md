# PLO Simulation Tool

A comprehensive Pot Limit Omaha (PLO) equity simulation and analysis system that generates thousands of random hands, calculates their equities using the PLOSolver backend, and provides detailed statistical analysis and visualizations.

## 🎯 Overview

This simulation tool is designed for poker researchers, players, and developers who want to analyze PLO hand equities at scale. It can generate up to 100,000+ random PLO hands, calculate their equities using your backend server, and provide comprehensive statistical analysis with visualizations.

## ✨ Features

### 🎲 Simulation Capabilities
- **Massive Scale**: Generate up to 100,000+ random PLO hands
- **8-Player Tables**: Full ring game simulations with 4-card hole cards
- **Dual Board Analysis**: Top and bottom flop analysis
- **Multithreaded Processing**: 5-10x speed improvement with configurable thread pools
- **Real-time Progress Tracking**: Monitor simulation progress
- **Automatic Error Handling**: Retry failed requests and continue processing

### 📊 Hand Analysis
- **Hand Strength Categorization**: Automatically categorizes hands into poker strength categories:
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

## 🚀 Quick Start

### Prerequisites

1. **Backend Server**: Ensure your PLOSolver backend is running
   ```bash
   cd backend
   python src/app.py
   ```

2. **Python Dependencies**: Install required packages
   ```bash
   pip install pandas numpy matplotlib seaborn requests treys
   ```

### Basic Usage

```bash
# Quick test with 100 hands
python run_simulation.py --quick-test

# Run 1,000 hands (good for testing)
python run_simulation.py --hands 1000

# Run full simulation with 100,000 hands
python run_simulation.py --hands 100000 --batch-size 100

# High-performance run with 20 threads
python run_simulation.py --hands 50000 --threads 20 --batch-size 200
```

## 📋 Command Line Options

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

## 📁 Output Files

### Data Files
- `simulation_results/plo_simulation_results_TIMESTAMP.json` - Complete simulation data
- `simulation_results/intermediate_results_N.json` - Periodic backups during long runs

### Visualizations
All visualizations are saved to `simulation_visualizations/`:

1. **equity_distributions.png** - Equity distribution analysis
2. **hand_category_analysis.png** - Hand strength analysis
3. **scoop_analysis.png** - Scoop probability analysis
4. **bad_beat_analysis.png** - Bad beat vulnerability
5. **statistical_summary.png** - Complete statistical overview

### Statistical Data
- `simulation_visualizations/statistical_summary.json` - Raw statistical data in JSON format

## 🔧 Advanced Usage

### Performance Optimization

**Recommended Settings by Use Case:**

| Use Case | Hands | Threads | Batch Size | Est. Time |
|----------|-------|---------|------------|-----------|
| Testing | 100-1,000 | 5-10 | 25-50 | 5-90 seconds |
| Analysis | 10,000-50,000 | 10-20 | 100-200 | 5-15 minutes |
| Research | 100,000+ | 15-25 | 200-500 | 1-3 hours |

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

## 📊 Data Format

### Input Format (to Backend)
```json
{
  "players": [
    {
      "player_number": 1,
      "cards": ["Js", "7d", "As", "8d"]
    }
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
  }
]
```

## 🔍 Analysis Features

### Hand Categorization
The system categorizes each player's hand on each board using the Treys poker evaluation library:

- **Straight Flush** (score ≤ 10)
- **Four of a Kind** (score ≤ 166)
- **Full House** (score ≤ 1599)
- **Three of a Kind** (1619 < score ≤ 2467)
- **Two Pair** (2467 < score ≤ 3325)
- **One Pair** (3325 < score ≤ 6185)
- **High Card** (score > 6185)

### Bad Beat Analysis
Identifies situations where strong hands are vulnerable:
- Tracks hands with >80% equity that still lose
- Calculates vulnerability scores
- Identifies most common bad beat scenarios

### Scoop Probability
Calculates the likelihood of winning both boards:
- Simple independence assumption: P(scoop) = P(top) × P(bottom)
- Identifies hands with high scoop potential

## 🛠️ Troubleshooting

### Common Issues

1. **Backend Connection Errors**
   ```bash
   # Ensure equity server is running
   cd backend
   python src/app.py
   ```

2. **Memory Issues with Large Simulations**
   ```bash
   # Reduce batch size
   python run_simulation.py --batch-size 25
   
   # Skip visualizations
   python run_simulation.py --no-viz
   ```

3. **Slow Performance**
   - Increase batch size for better throughput
   - Check backend server performance
   - Consider running on faster hardware

### Error Recovery
- Simulation automatically saves progress every 10 batches
- Interrupted simulations save partial results
- Failed requests are tracked and reported

## 🔧 Customization

### Modifying Simulation Parameters
Edit `plo_simulation.py` to:
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

## 📚 Additional Documentation

For more detailed information, see:
- `SIMULATION_README.md` - Comprehensive technical documentation
- `analyze_interrupted_results.py` - Tool for analyzing partial simulation results

## 🤝 Contributing

To extend the simulation system:
1. Fork the repository
2. Add new analysis functions to `PLOSimulation` class
3. Update visualization methods
4. Add tests for new functionality
5. Submit pull request

## 📄 License

This simulation system is part of the PLOSolver project and follows the same license terms. See `LICENSE.txt` for details.





