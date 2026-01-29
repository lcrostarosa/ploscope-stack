import random
import json
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from itertools import combinations
import requests
from typing import List, Dict, Tuple
import time
from datetime import datetime
import os
from collections import defaultdict
from treys import Card
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
import queue

# Import centralized evaluator utility
import sys
import os
from pathlib import Path

# Get the absolute path to the backend directory
current_dir = Path(__file__).parent
backend_dir = current_dir.parent / 'backend'
sys.path.insert(0, str(backend_dir))

from utils.evaluator_utils import get_evaluator

# Set up plotting style
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")

class PLOSimulation:
    def __init__(self, backend_url="http://localhost:5001", max_threads=10):
        self.backend_url = backend_url
        self.evaluator = get_evaluator()
        self.max_threads = max_threads
        
        # Card deck setup
        self.ranks = ['2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A']
        self.suits = ['h', 'd', 'c', 's']
        self.deck = [rank + suit for rank in self.ranks for suit in self.suits]
        
        # Results storage with thread safety
        self.simulation_results = []
        self.hand_categories = {}
        self.bad_beat_analysis = defaultdict(list)
        self.results_lock = threading.Lock()
        
        # Progress tracking
        self.processed_hands = 0
        self.failed_hands = 0
        self.progress_lock = threading.Lock()
        
    def generate_random_hand(self, num_players=8):
        """Generate a random PLO hand with specified number of players"""
        shuffled_deck = random.sample(self.deck, len(self.deck))
        
        # Deal 4 cards to each player
        players = []
        card_index = 0
        
        for i in range(num_players):
            player_cards = shuffled_deck[card_index:card_index + 4]
            players.append({
                'player_number': i + 1,
                'cards': player_cards
            })
            card_index += 4
        
        # Generate top and bottom boards (3 cards each)
        top_board = shuffled_deck[card_index:card_index + 3]
        card_index += 3
        bottom_board = shuffled_deck[card_index:card_index + 3]
        
        return {
            'players': players,
            'topBoard': top_board,
            'bottomBoard': bottom_board
        }
    
    def evaluate_hand_strength(self, hole_cards: List[str], board: List[str]) -> Tuple[str, int]:
        """Evaluate the strength of a PLO hand and categorize it"""
        try:
            # Convert string cards to Treys format
            treys_hole = [Card.new(card) for card in hole_cards]
            treys_board = [Card.new(card) for card in board]
            
            # Find best hand using exactly 2 hole cards and 3 board cards
            best_score = float('inf')
            best_hand_type = "Garbage"
            
            for hole_combo in combinations(treys_hole, 2):
                for board_combo in combinations(treys_board, 3):
                    hand = list(hole_combo) + list(board_combo)
                    score = self.evaluator.evaluate(hand, [])
                    
                    if score < best_score:
                        best_score = score
                        best_hand_type = self.categorize_hand_strength(score)
            
            return best_hand_type, best_score
            
        except Exception as e:
            print(f"Error evaluating hand {hole_cards} with board {board}: {e}")
            return "Garbage", 7462
    
    def categorize_hand_strength(self, treys_score: int) -> str:
        """Convert Treys score to hand category"""
        if treys_score <= 10:  # Straight Flush
            return "Straight Flush"
        elif treys_score <= 166:  # Four of a Kind
            return "Four of a Kind"
        elif treys_score <= 322:  # Full House (Top)
            return "Top Full House"
        elif treys_score <= 1599:  # Full House (Middle/Bottom)
            return "Middle Full House" if treys_score <= 900 else "Bottom Full House"
        elif treys_score <= 1609:  # Flush
            return "Flush"
        elif treys_score <= 1619:  # Straight
            return "Straight"
        elif treys_score <= 2467:  # Three of a Kind
            if treys_score <= 1900:
                return "Top Three of Kind"
            elif treys_score <= 2100:
                return "Middle Three of Kind"
            else:
                return "Low Three of Kind"
        elif treys_score <= 3325:  # Two Pair
            if treys_score <= 2700:
                return "Top and Bottom 2 Pair"
            elif treys_score <= 3000:
                return "Middle 2 pair"
            else:
                return "Bottom 2 pair"
        elif treys_score <= 6185:  # One Pair
            if treys_score <= 4500:
                return "Top Pair"
            elif treys_score <= 5300:
                return "Middle Pair"
            else:
                return "Bottom Pair"
        else:  # High Card
            return "Garbage"
    
    def send_equity_request(self, hand_data: Dict) -> Dict:
        """Send equity calculation request to backend"""
        try:
            response = requests.post(
                f"{self.backend_url}/simulated-equity",
                json=hand_data,
                headers={'Content-Type': 'application/json'}
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                print(f"Error response: {response.status_code} - {response.text}")
                return None
                
        except Exception as e:
            print(f"Request failed: {e}")
            return None
    
    def process_single_hand(self, hand_number: int) -> Tuple[bool, Dict]:
        """Process a single hand - designed for multithreading"""
        try:
            # Generate random hand
            hand_data = self.generate_random_hand()
            
            # Send to backend for equity calculation
            equity_results = self.send_equity_request(hand_data)
            
            if equity_results:
                # Process results
                hand_analysis = {
                    'hand_number': hand_number,
                    'timestamp': datetime.now().isoformat(),
                    'top_board': hand_data['topBoard'],
                    'bottom_board': hand_data['bottomBoard'],
                    'players': []
                }
                
                # Store hand categories for this thread
                local_hand_categories = {}
                
                # Analyze each player
                for player_result in equity_results:
                    player_num = player_result['player_number']
                    cards = player_result['cards']
                    
                    # Categorize hands on both boards
                    top_category, _ = self.evaluate_hand_strength(cards, hand_data['topBoard'])
                    bottom_category, _ = self.evaluate_hand_strength(cards, hand_data['bottomBoard'])
                    
                    # Store categories locally (will be merged later)
                    local_hand_categories[f"player_{player_num}_top"] = top_category
                    local_hand_categories[f"player_{player_num}_bottom"] = bottom_category
                    
                    # Calculate scoop probability
                    scoop_prob = self.calculate_scoop_probability(player_result)
                    
                    player_analysis = {
                        'player_number': player_num,
                        'cards': cards,
                        'top_estimated_equity': player_result['top_estimated_equity'],
                        'top_actual_equity': player_result['top_actual_equity'],
                        'bottom_estimated_equity': player_result['bottom_estimated_equity'],
                        'bottom_actual_equity': player_result['bottom_actual_equity'],
                        'top_hand_category': top_category,
                        'bottom_hand_category': bottom_category,
                        'scoop_probability': scoop_prob
                    }
                    
                    hand_analysis['players'].append(player_analysis)
                
                # Store bad beat analysis data locally
                local_bad_beats = defaultdict(list)
                self.analyze_bad_beats_local(equity_results, local_hand_categories, local_bad_beats)
                
                return True, {
                    'hand_analysis': hand_analysis,
                    'hand_categories': local_hand_categories,
                    'bad_beats': local_bad_beats
                }
            else:
                return False, None
                
        except Exception as e:
            print(f"Error processing hand {hand_number}: {e}")
            return False, None
    
    def analyze_bad_beats_local(self, hand_results: List[Dict], local_categories: Dict, local_bad_beats: Dict):
        """Analyze bad beats for a single hand (thread-safe)"""
        for result in hand_results:
            player_num = result['player_number']
            cards = result['cards']
            
            # Categorize this player's hand on both boards
            top_category = local_categories.get(f"player_{player_num}_top", "Unknown")
            bottom_category = local_categories.get(f"player_{player_num}_bottom", "Unknown")
            
            # Check if this is a strong hand that could be vulnerable
            strong_hands = ["Top Full House", "Middle Full House", "Four of a Kind", 
                          "Top Three of Kind", "Middle Three of Kind"]
            
            if top_category in strong_hands:
                vulnerability_score = self.calculate_vulnerability(result, 'top')
                if vulnerability_score > 0.1:  # 10% or higher chance of being beaten
                    local_bad_beats[top_category].append({
                        'player': player_num,
                        'cards': cards,
                        'vulnerability': vulnerability_score,
                        'board': 'top'
                    })
    
    def update_progress(self, success: bool):
        """Thread-safe progress updating"""
        with self.progress_lock:
            if success:
                self.processed_hands += 1
            else:
                self.failed_hands += 1
    
    def calculate_scoop_probability(self, player_equities: Dict) -> float:
        """Calculate probability of scooping both boards"""
        top_equity = player_equities.get('top_actual', 0)
        bottom_equity = player_equities.get('bottom_actual', 0)
        
        # Simple approximation: multiply equities (assumes independence)
        scoop_prob = top_equity * bottom_equity
        return scoop_prob
    
    def analyze_bad_beats(self, hand_results: List[Dict]):
        """Analyze potential bad beat scenarios"""
        for result in hand_results:
            player_num = result['player_number']
            cards = result['cards']
            
            # Categorize this player's hand on both boards
            top_category = self.hand_categories.get(f"player_{player_num}_top", "Unknown")
            bottom_category = self.hand_categories.get(f"player_{player_num}_bottom", "Unknown")
            
            # Check if this is a strong hand that could be vulnerable
            strong_hands = ["Top Full House", "Middle Full House", "Four of a Kind", 
                          "Top Three of Kind", "Middle Three of Kind"]
            
            if top_category in strong_hands:
                vulnerability_score = self.calculate_vulnerability(result, 'top')
                if vulnerability_score > 0.1:  # 10% or higher chance of being beaten
                    self.bad_beat_analysis[top_category].append({
                        'player': player_num,
                        'cards': cards,
                        'vulnerability': vulnerability_score,
                        'board': 'top'
                    })
    
    def calculate_vulnerability(self, player_result: Dict, board: str) -> float:
        """Calculate how vulnerable a strong hand is to being beaten"""
        equity_key = f"{board}_actual"
        equity = player_result.get(equity_key, 0)
        
        # If equity is less than 0.8 (80%), the hand is vulnerable
        vulnerability = max(0, 0.8 - equity)
        return vulnerability
    
    def run_simulation(self, num_hands: int = 100000, batch_size: int = 100):
        """Run the full simulation with multithreading"""
        print(f"Starting multithreaded simulation of {num_hands} hands...")
        print(f"Backend URL: {self.backend_url}")
        print(f"Max threads: {self.max_threads}")
        print(f"Batch size: {batch_size}")
        
        # Reset counters
        self.processed_hands = 0
        self.failed_hands = 0
        
        total_batches = (num_hands + batch_size - 1) // batch_size
        
        for batch_num in range(total_batches):
            batch_start = batch_num * batch_size
            batch_end = min(batch_start + batch_size, num_hands)
            actual_batch_size = batch_end - batch_start
            
            print(f"Processing batch {batch_num + 1}/{total_batches}: hands {batch_start + 1} to {batch_end}...")
            
            # Process this batch with multithreading
            batch_results = self.process_batch_multithreaded(
                hand_numbers=list(range(batch_start + 1, batch_end + 1)),
                batch_num=batch_num + 1
            )
            
            # Add successful results to main storage
            with self.results_lock:
                self.simulation_results.extend(batch_results)
            
            # Progress update
            current_success = self.processed_hands
            current_failed = self.failed_hands
            total_processed = current_success + current_failed
            
            if total_processed > 0:
                success_rate = (current_success / total_processed) * 100
                print(f"Batch {batch_num + 1} complete. Total: {total_processed} hands, "
                      f"Success: {current_success}, Failed: {current_failed}, "
                      f"Success rate: {success_rate:.1f}%")
            
            # Save intermediate results every 5 batches
            if (batch_num + 1) % 5 == 0:
                self.save_results(f"intermediate_results_batch_{batch_num + 1}.json")
        
        final_success = self.processed_hands
        final_failed = self.failed_hands
        print(f"Simulation complete! Successfully processed {final_success} hands, {final_failed} failed.")
        return final_success, final_failed
    
    def process_batch_multithreaded(self, hand_numbers: List[int], batch_num: int) -> List[Dict]:
        """Process a batch of hands using multithreading"""
        batch_results = []
        
        with ThreadPoolExecutor(max_workers=self.max_threads) as executor:
            # Submit all hands in this batch
            future_to_hand = {
                executor.submit(self.process_single_hand, hand_num): hand_num 
                for hand_num in hand_numbers
            }
            
            # Collect results as they complete
            for future in as_completed(future_to_hand):
                hand_num = future_to_hand[future]
                try:
                    success, result_data = future.result()
                    self.update_progress(success)
                    
                    if success and result_data:
                        hand_analysis = result_data['hand_analysis']
                        hand_categories = result_data['hand_categories']
                        bad_beats = result_data['bad_beats']
                        
                        # Thread-safe storage of results
                        with self.results_lock:
                            # Store hand categories
                            self.hand_categories.update(hand_categories)
                            
                            # Store bad beat analysis
                            for category, beats in bad_beats.items():
                                self.bad_beat_analysis[category].extend(beats)
                        
                        batch_results.append(hand_analysis)
                        
                except Exception as e:
                    print(f"Error processing hand {hand_num}: {e}")
                    self.update_progress(False)
        
        return batch_results
    
    def save_results(self, filename: str = None):
        """Save simulation results to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"plo_simulation_results_{timestamp}.json"
        
        # Create results directory if it doesn't exist
        os.makedirs("simulation_results", exist_ok=True)
        filepath = os.path.join("simulation_results", filename)
        
        with open(filepath, 'w') as f:
            json.dump({
                'simulation_results': self.simulation_results,
                'hand_categories': dict(self.hand_categories),
                'bad_beat_analysis': dict(self.bad_beat_analysis),
                'total_hands': len(self.simulation_results)
            }, f, indent=2)
        
        print(f"Results saved to {filepath}")
        return filepath
    
    def create_visualizations(self):
        """Create comprehensive visualizations of the simulation results"""
        if not self.simulation_results:
            print("No simulation results to visualize!")
            return
        
        # Flatten data for analysis
        df_data = []
        for hand in self.simulation_results:
            for player in hand['players']:
                df_data.append({
                    'hand_number': hand['hand_number'],
                    'player_number': player['player_number'],
                    'cards': ' '.join(player['cards']),
                    'top_estimated': player['top_estimated_equity'],
                    'top_actual': player['top_actual_equity'],
                    'bottom_estimated': player['bottom_estimated_equity'],
                    'bottom_actual': player['bottom_actual_equity'],
                    'top_category': player['top_hand_category'],
                    'bottom_category': player['bottom_hand_category'],
                    'scoop_probability': player['scoop_probability']
                })
        
        df = pd.DataFrame(df_data)
        
        # Create output directory
        os.makedirs("simulation_visualizations", exist_ok=True)
        
        # 1. Equity Distribution Analysis
        self._create_equity_distributions(df)
        
        # 2. Hand Category Analysis
        self._create_hand_category_analysis(df)
        
        # 3. Scoop Probability Analysis
        self._create_scoop_analysis(df)
        
        # 4. Bad Beat Analysis
        self._create_bad_beat_analysis()
        
        # 5. Statistical Summary
        self._create_statistical_summary(df)
        
        print("All visualizations saved to 'simulation_visualizations' directory")
    
    def _create_equity_distributions(self, df: pd.DataFrame):
        """Create equity distribution visualizations"""
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        
        # Top Estimated vs Actual
        axes[0, 0].scatter(df['top_estimated'], df['top_actual'], alpha=0.5)
        axes[0, 0].plot([0, 1], [0, 1], 'r--', label='Perfect Correlation')
        axes[0, 0].set_xlabel('Top Estimated Equity')
        axes[0, 0].set_ylabel('Top Actual Equity')
        axes[0, 0].set_title('Top Board: Estimated vs Actual Equity')
        axes[0, 0].legend()
        
        # Bottom Estimated vs Actual
        axes[0, 1].scatter(df['bottom_estimated'], df['bottom_actual'], alpha=0.5)
        axes[0, 1].plot([0, 1], [0, 1], 'r--', label='Perfect Correlation')
        axes[0, 1].set_xlabel('Bottom Estimated Equity')
        axes[0, 1].set_ylabel('Bottom Actual Equity')
        axes[0, 1].set_title('Bottom Board: Estimated vs Actual Equity')
        axes[0, 1].legend()
        
        # Equity distributions
        axes[1, 0].hist(df['top_actual'], bins=50, alpha=0.7, label='Top Actual')
        axes[1, 0].hist(df['top_estimated'], bins=50, alpha=0.7, label='Top Estimated')
        axes[1, 0].set_xlabel('Equity')
        axes[1, 0].set_ylabel('Frequency')
        axes[1, 0].set_title('Top Board Equity Distributions')
        axes[1, 0].legend()
        
        axes[1, 1].hist(df['bottom_actual'], bins=50, alpha=0.7, label='Bottom Actual')
        axes[1, 1].hist(df['bottom_estimated'], bins=50, alpha=0.7, label='Bottom Estimated')
        axes[1, 1].set_xlabel('Equity')
        axes[1, 1].set_ylabel('Frequency')
        axes[1, 1].set_title('Bottom Board Equity Distributions')
        axes[1, 1].legend()
        
        plt.tight_layout()
        plt.savefig('simulation_visualizations/equity_distributions.png', dpi=300, bbox_inches='tight')
        plt.close()
    
    def _create_hand_category_analysis(self, df: pd.DataFrame):
        """Create hand category analysis visualizations"""
        fig, axes = plt.subplots(2, 2, figsize=(20, 15))
        
        # Top board hand categories
        top_categories = df['top_category'].value_counts()
        axes[0, 0].bar(range(len(top_categories)), top_categories.values)
        axes[0, 0].set_xticks(range(len(top_categories)))
        axes[0, 0].set_xticklabels(top_categories.index, rotation=45, ha='right')
        axes[0, 0].set_title('Top Board Hand Categories Frequency')
        axes[0, 0].set_ylabel('Count')
        
        # Bottom board hand categories
        bottom_categories = df['bottom_category'].value_counts()
        axes[0, 1].bar(range(len(bottom_categories)), bottom_categories.values)
        axes[0, 1].set_xticks(range(len(bottom_categories)))
        axes[0, 1].set_xticklabels(bottom_categories.index, rotation=45, ha='right')
        axes[0, 1].set_title('Bottom Board Hand Categories Frequency')
        axes[0, 1].set_ylabel('Count')
        
        # Average equity by hand category - Top board
        top_equity_by_category = df.groupby('top_category')['top_actual'].agg(['mean', 'std']).reset_index()
        axes[1, 0].bar(range(len(top_equity_by_category)), top_equity_by_category['mean'], 
                      yerr=top_equity_by_category['std'], capsize=5)
        axes[1, 0].set_xticks(range(len(top_equity_by_category)))
        axes[1, 0].set_xticklabels(top_equity_by_category['top_category'], rotation=45, ha='right')
        axes[1, 0].set_title('Average Actual Equity by Top Board Hand Category')
        axes[1, 0].set_ylabel('Average Equity')
        
        # Average equity by hand category - Bottom board
        bottom_equity_by_category = df.groupby('bottom_category')['bottom_actual'].agg(['mean', 'std']).reset_index()
        axes[1, 1].bar(range(len(bottom_equity_by_category)), bottom_equity_by_category['mean'], 
                      yerr=bottom_equity_by_category['std'], capsize=5)
        axes[1, 1].set_xticks(range(len(bottom_equity_by_category)))
        axes[1, 1].set_xticklabels(bottom_equity_by_category['bottom_category'], rotation=45, ha='right')
        axes[1, 1].set_title('Average Actual Equity by Bottom Board Hand Category')
        axes[1, 1].set_ylabel('Average Equity')
        
        plt.tight_layout()
        plt.savefig('simulation_visualizations/hand_category_analysis.png', dpi=300, bbox_inches='tight')
        plt.close()
    
    def _create_scoop_analysis(self, df: pd.DataFrame):
        """Create scoop probability analysis"""
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        
        # Scoop probability distribution
        axes[0, 0].hist(df['scoop_probability'], bins=50, alpha=0.7)
        axes[0, 0].set_xlabel('Scoop Probability')
        axes[0, 0].set_ylabel('Frequency')
        axes[0, 0].set_title('Distribution of Scoop Probabilities')
        
        # Scoop probability vs top equity
        axes[0, 1].scatter(df['top_actual'], df['scoop_probability'], alpha=0.5)
        axes[0, 1].set_xlabel('Top Board Actual Equity')
        axes[0, 1].set_ylabel('Scoop Probability')
        axes[0, 1].set_title('Scoop Probability vs Top Board Equity')
        
        # Top players by scoop probability
        high_scoop = df.nlargest(100, 'scoop_probability')
        scoop_by_category = high_scoop.groupby('top_category')['scoop_probability'].mean().sort_values(ascending=False)
        axes[1, 0].bar(range(len(scoop_by_category)), scoop_by_category.values)
        axes[1, 0].set_xticks(range(len(scoop_by_category)))
        axes[1, 0].set_xticklabels(scoop_by_category.index, rotation=45, ha='right')
        axes[1, 0].set_title('Average Scoop Probability by Hand Category (Top 100)')
        axes[1, 0].set_ylabel('Average Scoop Probability')
        
        # Combined equity analysis
        df['combined_equity'] = df['top_actual'] + df['bottom_actual']
        axes[1, 1].scatter(df['combined_equity'], df['scoop_probability'], alpha=0.5)
        axes[1, 1].set_xlabel('Combined Equity (Top + Bottom)')
        axes[1, 1].set_ylabel('Scoop Probability')
        axes[1, 1].set_title('Scoop Probability vs Combined Equity')
        
        plt.tight_layout()
        plt.savefig('simulation_visualizations/scoop_analysis.png', dpi=300, bbox_inches='tight')
        plt.close()
    
    def _create_bad_beat_analysis(self):
        """Create bad beat analysis visualization"""
        if not self.bad_beat_analysis:
            print("No bad beat data to analyze")
            return
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        
        # Bad beat frequency by hand type
        bad_beat_counts = {category: len(beats) for category, beats in self.bad_beat_analysis.items()}
        axes[0, 0].bar(bad_beat_counts.keys(), bad_beat_counts.values())
        axes[0, 0].set_title('Bad Beat Frequency by Hand Category')
        axes[0, 0].set_ylabel('Number of Bad Beats')
        axes[0, 0].tick_params(axis='x', rotation=45)
        
        # Average vulnerability by hand type
        avg_vulnerability = {}
        for category, beats in self.bad_beat_analysis.items():
            vulnerabilities = [beat['vulnerability'] for beat in beats]
            avg_vulnerability[category] = np.mean(vulnerabilities) if vulnerabilities else 0
        
        axes[0, 1].bar(avg_vulnerability.keys(), avg_vulnerability.values())
        axes[0, 1].set_title('Average Vulnerability by Hand Category')
        axes[0, 1].set_ylabel('Average Vulnerability Score')
        axes[0, 1].tick_params(axis='x', rotation=45)
        
        # Vulnerability distribution
        all_vulnerabilities = []
        for beats in self.bad_beat_analysis.values():
            all_vulnerabilities.extend([beat['vulnerability'] for beat in beats])
        
        if all_vulnerabilities:
            axes[1, 0].hist(all_vulnerabilities, bins=30, alpha=0.7)
            axes[1, 0].set_xlabel('Vulnerability Score')
            axes[1, 0].set_ylabel('Frequency')
            axes[1, 0].set_title('Distribution of Vulnerability Scores')
        
        # Summary text
        total_bad_beats = sum(len(beats) for beats in self.bad_beat_analysis.values())
        axes[1, 1].text(0.1, 0.8, f"Total Bad Beat Scenarios: {total_bad_beats}", 
                       transform=axes[1, 1].transAxes, fontsize=12)
        axes[1, 1].text(0.1, 0.7, f"Most Vulnerable: {max(avg_vulnerability.keys(), key=avg_vulnerability.get) if avg_vulnerability else 'N/A'}", 
                       transform=axes[1, 1].transAxes, fontsize=12)
        axes[1, 1].text(0.1, 0.6, f"Average Vulnerability: {np.mean(all_vulnerabilities):.3f}" if all_vulnerabilities else "N/A", 
                       transform=axes[1, 1].transAxes, fontsize=12)
        axes[1, 1].set_xlim(0, 1)
        axes[1, 1].set_ylim(0, 1)
        axes[1, 1].axis('off')
        axes[1, 1].set_title('Bad Beat Summary Statistics')
        
        plt.tight_layout()
        plt.savefig('simulation_visualizations/bad_beat_analysis.png', dpi=300, bbox_inches='tight')
        plt.close()
    
    def _create_statistical_summary(self, df: pd.DataFrame):
        """Create statistical summary report"""
        summary_stats = {
            'Top Board': {
                'Estimated Equity': {
                    'Mean': df['top_estimated'].mean(),
                    'Median': df['top_estimated'].median(),
                    'Std': df['top_estimated'].std(),
                    'Max': df['top_estimated'].max(),
                    'Min': df['top_estimated'].min()
                },
                'Actual Equity': {
                    'Mean': df['top_actual'].mean(),
                    'Median': df['top_actual'].median(),
                    'Std': df['top_actual'].std(),
                    'Max': df['top_actual'].max(),
                    'Min': df['top_actual'].min()
                }
            },
            'Bottom Board': {
                'Estimated Equity': {
                    'Mean': df['bottom_estimated'].mean(),
                    'Median': df['bottom_estimated'].median(),
                    'Std': df['bottom_estimated'].std(),
                    'Max': df['bottom_estimated'].max(),
                    'Min': df['bottom_estimated'].min()
                },
                'Actual Equity': {
                    'Mean': df['bottom_actual'].mean(),
                    'Median': df['bottom_actual'].median(),
                    'Std': df['bottom_actual'].std(),
                    'Max': df['bottom_actual'].max(),
                    'Min': df['bottom_actual'].min()
                }
            }
        }
        
        # Save statistical summary
        with open('simulation_visualizations/statistical_summary.json', 'w') as f:
            json.dump(summary_stats, f, indent=2)
        
        # Create summary table visualization
        fig, ax = plt.subplots(figsize=(12, 8))
        ax.axis('tight')
        ax.axis('off')
        
        # Create table data
        table_data = []
        for board in ['Top Board', 'Bottom Board']:
            for equity_type in ['Estimated Equity', 'Actual Equity']:
                stats = summary_stats[board][equity_type]
                table_data.append([
                    f"{board} {equity_type}",
                    f"{stats['Mean']:.4f}",
                    f"{stats['Median']:.4f}",
                    f"{stats['Std']:.4f}",
                    f"{stats['Max']:.4f}",
                    f"{stats['Min']:.4f}"
                ])
        
        table = ax.table(cellText=table_data,
                        colLabels=['Metric', 'Mean', 'Median', 'Std Dev', 'Max', 'Min'],
                        cellLoc='center',
                        loc='center')
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1.2, 1.5)
        
        ax.set_title('Statistical Summary of Equity Calculations', fontsize=16, fontweight='bold', pad=20)
        
        plt.savefig('simulation_visualizations/statistical_summary.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        print("Statistical summary saved to statistical_summary.json and statistical_summary.png")


def main():
    """Main execution function"""
    print("PLO Equity Simulation and Analysis")
    print("=" * 40)
    
    # Initialize simulation
    simulator = PLOSimulation()
    
    # Run simulation
    try:
        successful, failed = simulator.run_simulation(num_hands=1000, batch_size=50)  # Start with smaller number for testing
        
        if successful > 0:
            # Save results
            results_file = simulator.save_results()
            
            # Create visualizations
            simulator.create_visualizations()
            
            print(f"\nSimulation complete!")
            print(f"Successful hands: {successful}")
            print(f"Failed requests: {failed}")
            print(f"Results saved to: {results_file}")
            print("Visualizations saved to: simulation_visualizations/")
        else:
            print("No successful equity calculations - check if backend is running!")
            
    except KeyboardInterrupt:
        print("\nSimulation interrupted by user")
        if simulator.simulation_results:
            simulator.save_results("interrupted_results.json")
            print("Partial results saved")
    except Exception as e:
        print(f"Error during simulation: {e}")
        if simulator.simulation_results:
            simulator.save_results("error_results.json")
            print("Partial results saved")


if __name__ == "__main__":
    main() 