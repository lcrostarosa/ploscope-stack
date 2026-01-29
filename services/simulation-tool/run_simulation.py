#!/usr/bin/env python3
"""
PLO Equity Simulation Runner

This script runs the comprehensive PLO equity simulation and analysis.
Make sure the equity server is running before executing this script.

Usage:
    python run_simulation.py [--hands N] [--batch-size N] [--backend-url URL]

Examples:
    python run_simulation.py --hands 1000 --batch-size 50
    python run_simulation.py --hands 100000 --batch-size 100
    python run_simulation.py --backend-url http://localhost:5001
"""

import argparse
import sys
import os
import requests
import time

# Add simulation directory to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'simulation'))

from plo_simulation import PLOSimulation


def check_backend_health(backend_url):
    """Check if the backend server is running and accessible"""
    try:
        response = requests.get(f"{backend_url}/health", timeout=5)
        if response.status_code == 200:
            print(f"✓ Backend server is running at {backend_url}")
            return True
        else:
            print(f"✗ Backend server responded with status {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"✗ Cannot connect to backend server at {backend_url}")
        print(f"  Error: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Run PLO equity simulation and analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --hands 1000 --batch-size 50        # Quick test run
  %(prog)s --hands 100000 --batch-size 100     # Full simulation  
  %(prog)s --threads 20 --hands 10000          # High-performance run
  %(prog)s --backend-url http://localhost:5001  # Custom backend URL
        """
    )
    
    parser.add_argument(
        '--hands', 
        type=int, 
        default=1000,
        help='Number of hands to simulate (default: 1000)'
    )
    
    parser.add_argument(
        '--batch-size', 
        type=int, 
        default=50,
        help='Batch size for processing (default: 50)'
    )
    
    parser.add_argument(
        '--backend-url', 
        type=str, 
        default='http://localhost:5001',
        help='Backend server URL (default: http://localhost:5001)'
    )
    
    parser.add_argument(
        '--threads', 
        type=int, 
        default=10,
        help='Maximum number of concurrent threads (default: 10)'
    )
    
    parser.add_argument(
        '--no-viz', 
        action='store_true',
        help='Skip visualization generation (faster completion)'
    )
    
    parser.add_argument(
        '--quick-test', 
        action='store_true',
        help='Run a quick test with 100 hands'
    )
    
    args = parser.parse_args()
    
    # Override settings for quick test
    if args.quick_test:
        args.hands = 100
        args.batch_size = 25
        print("🚀 Running quick test mode (100 hands)")
    
    print("PLO Equity Simulation Runner")
    print("=" * 50)
    print(f"Configuration:")
    print(f"  Hands to simulate: {args.hands:,}")
    print(f"  Batch size: {args.batch_size}")
    print(f"  Max threads: {args.threads}")
    print(f"  Backend URL: {args.backend_url}")
    print(f"  Generate visualizations: {not args.no_viz}")
    print()
    
    # Check backend connectivity
    print("Checking backend server...")
    if not check_backend_health(args.backend_url):
        print()
        print("❌ Backend server is not accessible!")
        print("   Make sure to start the equity server first:")
        print("   cd backend && python equity_server.py")
        sys.exit(1)
    
    print()
    
    # Initialize and run simulation
    try:
        simulator = PLOSimulation(backend_url=args.backend_url, max_threads=args.threads)
        
        print("🎲 Starting simulation...")
        start_time = time.time()
        
        successful, failed = simulator.run_simulation(
            num_hands=args.hands, 
            batch_size=args.batch_size
        )
        
        simulation_time = time.time() - start_time
        
        if successful > 0:
            print(f"\n✅ Simulation completed successfully!")
            print(f"   Time taken: {simulation_time:.1f} seconds")
            print(f"   Successful hands: {successful:,}")
            print(f"   Failed requests: {failed:,}")
            print(f"   Success rate: {(successful/(successful+failed)*100):.1f}%")
            
            # Save results
            print("\n💾 Saving results...")
            results_file = simulator.save_results()
            print(f"   Results saved to: {results_file}")
            
            # Generate visualizations
            if not args.no_viz:
                print("\n📊 Generating visualizations...")
                viz_start = time.time()
                simulator.create_visualizations()
                viz_time = time.time() - viz_start
                print(f"   Visualizations completed in {viz_time:.1f} seconds")
                print("   Visualizations saved to: simulation_visualizations/")
            else:
                print("\n⏭️  Skipping visualizations (--no-viz flag)")
            
            print(f"\n🎉 All done! Total time: {time.time() - start_time:.1f} seconds")
            
        else:
            print("\n❌ No successful equity calculations!")
            print("   Check if the backend server is working correctly.")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n\n⚠️  Simulation interrupted by user")
        if hasattr(simulator, 'simulation_results') and simulator.simulation_results:
            print("💾 Saving partial results...")
            simulator.save_results("interrupted_results.json")
            print("   Partial results saved")
        sys.exit(1)
        
    except Exception as e:
        print(f"\n❌ Error during simulation: {e}")
        if hasattr(simulator, 'simulation_results') and simulator.simulation_results:
            print("💾 Saving partial results...")
            simulator.save_results("error_results.json")
            print("   Partial results saved")
        sys.exit(1)


if __name__ == "__main__":
    main() 