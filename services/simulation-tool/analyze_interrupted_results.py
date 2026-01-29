#!/usr/bin/env python3
"""
Analyze Interrupted Results

This script loads interrupted simulation results and generates 
visualizations to show what data was collected.
"""

import json
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import os
import sys

# Add simulation directory to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'simulation'))

def load_interrupted_results(filename='simulation_results/interrupted_results.json'):
    """Load interrupted simulation results"""
    try:
        with open(filename, 'r') as f:
            data = json.load(f)
        return data
    except Exception as e:
        print(f"Error loading results: {e}")
        return None

def create_partial_visualizations(results_data):
    """Create visualizations from partial results"""
    
    if not results_data or 'simulation_results' not in results_data:
        print("No simulation results found in data")
        return
    
    simulation_results = results_data['simulation_results']
    total_hands = len(simulation_results)
    
    if total_hands == 0:
        print("No hands found in simulation results")
        return
    
    print(f"Found {total_hands} hands in interrupted results")
    
    # Flatten data for analysis
    df_data = []
    for hand in simulation_results:
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
    print(f"Created dataframe with {len(df)} player-hand combinations")
    
    # Create output directory
    os.makedirs("interrupted_analysis", exist_ok=True)
    
    # Create comprehensive visualization
    create_interrupted_summary(df, total_hands)
    create_equity_analysis(df)
    create_hand_category_analysis(df)
    create_statistical_summary(df)
    
    print("Visualizations saved to 'interrupted_analysis' directory")

def create_interrupted_summary(df, total_hands):
    """Create a summary overview of the interrupted results"""
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    
    # Basic statistics
    total_players = len(df)
    unique_hands = df['hand_number'].nunique()
    avg_players_per_hand = total_players / unique_hands if unique_hands > 0 else 0
    
    # Summary text
    summary_text = f"""
    INTERRUPTED SIMULATION SUMMARY
    ────────────────────────────────
    Total Hands Processed: {total_hands:,}
    Total Player-Hand Combinations: {total_players:,}
    Average Players per Hand: {avg_players_per_hand:.1f}
    
    EQUITY STATISTICS
    ────────────────────
    Top Board Estimated Equity:
      Mean: {df['top_estimated'].mean():.3f}
      Median: {df['top_estimated'].median():.3f}
      Std: {df['top_estimated'].std():.3f}
    
    Top Board Actual Equity:
      Mean: {df['top_actual'].mean():.3f}
      Median: {df['top_actual'].median():.3f}
      Std: {df['top_actual'].std():.3f}
    
    Bottom Board Estimated Equity:
      Mean: {df['bottom_estimated'].mean():.3f}
      Median: {df['bottom_estimated'].median():.3f}
      Std: {df['bottom_estimated'].std():.3f}
    
    Bottom Board Actual Equity:
      Mean: {df['bottom_actual'].mean():.3f}
      Median: {df['bottom_actual'].median():.3f}
      Std: {df['bottom_actual'].std():.3f}
    """
    
    axes[0, 0].text(0.05, 0.95, summary_text, transform=axes[0, 0].transAxes,
                    fontsize=10, verticalalignment='top', fontfamily='monospace')
    axes[0, 0].set_xlim(0, 1)
    axes[0, 0].set_ylim(0, 1)
    axes[0, 0].axis('off')
    axes[0, 0].set_title('Simulation Summary', fontsize=14, fontweight='bold')
    
    # Hand distribution over time
    hand_timeline = df.groupby('hand_number').size()
    axes[0, 1].plot(hand_timeline.index, hand_timeline.values, 'b-', alpha=0.7)
    axes[0, 1].set_xlabel('Hand Number')
    axes[0, 1].set_ylabel('Players per Hand')
    axes[0, 1].set_title('Players per Hand Over Time')
    axes[0, 1].grid(True, alpha=0.3)
    
    # Top vs Bottom equity correlation
    axes[1, 0].scatter(df['top_actual'], df['bottom_actual'], alpha=0.6, s=20)
    axes[1, 0].set_xlabel('Top Board Actual Equity')
    axes[1, 0].set_ylabel('Bottom Board Actual Equity')
    axes[1, 0].set_title('Top vs Bottom Board Equity Correlation')
    axes[1, 0].grid(True, alpha=0.3)
    
    # Scoop probability distribution
    if df['scoop_probability'].sum() > 0:
        axes[1, 1].hist(df['scoop_probability'], bins=30, alpha=0.7, color='green')
        axes[1, 1].set_xlabel('Scoop Probability')
        axes[1, 1].set_ylabel('Frequency')
        axes[1, 1].set_title('Scoop Probability Distribution')
    else:
        axes[1, 1].text(0.5, 0.5, 'No Scoop Probabilities\n> 0 Found', 
                       ha='center', va='center', transform=axes[1, 1].transAxes)
        axes[1, 1].set_title('Scoop Probability Distribution')
    
    plt.tight_layout()
    plt.savefig('interrupted_analysis/summary_overview.png', dpi=300, bbox_inches='tight')
    plt.close()

def create_equity_analysis(df):
    """Create detailed equity analysis"""
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    
    # Top Board: Estimated vs Actual
    axes[0, 0].scatter(df['top_estimated'], df['top_actual'], alpha=0.6)
    axes[0, 0].plot([0, 1], [0, 1], 'r--', label='Perfect Correlation')
    axes[0, 0].set_xlabel('Top Estimated Equity')
    axes[0, 0].set_ylabel('Top Actual Equity')
    axes[0, 0].set_title('Top Board: Estimated vs Actual Equity')
    axes[0, 0].legend()
    axes[0, 0].grid(True, alpha=0.3)
    
    # Bottom Board: Estimated vs Actual  
    axes[0, 1].scatter(df['bottom_estimated'], df['bottom_actual'], alpha=0.6)
    axes[0, 1].plot([0, 1], [0, 1], 'r--', label='Perfect Correlation')
    axes[0, 1].set_xlabel('Bottom Estimated Equity')
    axes[0, 1].set_ylabel('Bottom Actual Equity')
    axes[0, 1].set_title('Bottom Board: Estimated vs Actual Equity')
    axes[0, 1].legend()
    axes[0, 1].grid(True, alpha=0.3)
    
    # Equity distributions - Top Board
    axes[1, 0].hist(df['top_actual'], bins=30, alpha=0.7, label='Top Actual', color='blue')
    axes[1, 0].hist(df['top_estimated'], bins=30, alpha=0.7, label='Top Estimated', color='red')
    axes[1, 0].set_xlabel('Equity')
    axes[1, 0].set_ylabel('Frequency')
    axes[1, 0].set_title('Top Board Equity Distributions')
    axes[1, 0].legend()
    
    # Equity distributions - Bottom Board
    axes[1, 1].hist(df['bottom_actual'], bins=30, alpha=0.7, label='Bottom Actual', color='blue')
    axes[1, 1].hist(df['bottom_estimated'], bins=30, alpha=0.7, label='Bottom Estimated', color='red')
    axes[1, 1].set_xlabel('Equity')
    axes[1, 1].set_ylabel('Frequency')
    axes[1, 1].set_title('Bottom Board Equity Distributions')
    axes[1, 1].legend()
    
    plt.tight_layout()
    plt.savefig('interrupted_analysis/equity_analysis.png', dpi=300, bbox_inches='tight')
    plt.close()

def create_hand_category_analysis(df):
    """Create hand category frequency analysis"""
    fig, axes = plt.subplots(2, 2, figsize=(20, 15))
    
    # Top board categories
    top_categories = df['top_category'].value_counts()
    if len(top_categories) > 0:
        axes[0, 0].bar(range(len(top_categories)), top_categories.values)
        axes[0, 0].set_xticks(range(len(top_categories)))
        axes[0, 0].set_xticklabels(top_categories.index, rotation=45, ha='right')
        axes[0, 0].set_title('Top Board Hand Categories')
        axes[0, 0].set_ylabel('Count')
    
    # Bottom board categories
    bottom_categories = df['bottom_category'].value_counts()
    if len(bottom_categories) > 0:
        axes[0, 1].bar(range(len(bottom_categories)), bottom_categories.values)
        axes[0, 1].set_xticks(range(len(bottom_categories)))
        axes[0, 1].set_xticklabels(bottom_categories.index, rotation=45, ha='right')
        axes[0, 1].set_title('Bottom Board Hand Categories')
        axes[0, 1].set_ylabel('Count')
    
    # Average equity by top category
    if len(top_categories) > 0:
        top_equity_by_cat = df.groupby('top_category')['top_actual'].agg(['mean', 'std']).reset_index()
        axes[1, 0].bar(range(len(top_equity_by_cat)), top_equity_by_cat['mean'], 
                      yerr=top_equity_by_cat['std'], capsize=5)
        axes[1, 0].set_xticks(range(len(top_equity_by_cat)))
        axes[1, 0].set_xticklabels(top_equity_by_cat['top_category'], rotation=45, ha='right')
        axes[1, 0].set_title('Average Actual Equity by Top Hand Category')
        axes[1, 0].set_ylabel('Average Equity')
    
    # Average equity by bottom category
    if len(bottom_categories) > 0:
        bottom_equity_by_cat = df.groupby('bottom_category')['bottom_actual'].agg(['mean', 'std']).reset_index()
        axes[1, 1].bar(range(len(bottom_equity_by_cat)), bottom_equity_by_cat['mean'], 
                      yerr=bottom_equity_by_cat['std'], capsize=5)
        axes[1, 1].set_xticks(range(len(bottom_equity_by_cat)))
        axes[1, 1].set_xticklabels(bottom_equity_by_cat['bottom_category'], rotation=45, ha='right')
        axes[1, 1].set_title('Average Actual Equity by Bottom Hand Category')
        axes[1, 1].set_ylabel('Average Equity')
    
    plt.tight_layout()
    plt.savefig('interrupted_analysis/hand_categories.png', dpi=300, bbox_inches='tight')
    plt.close()

def create_statistical_summary(df):
    """Create statistical summary table"""
    summary_stats = {
        'Top Board Estimated': {
            'Mean': f"{df['top_estimated'].mean():.4f}",
            'Median': f"{df['top_estimated'].median():.4f}", 
            'Std': f"{df['top_estimated'].std():.4f}",
            'Min': f"{df['top_estimated'].min():.4f}",
            'Max': f"{df['top_estimated'].max():.4f}"
        },
        'Top Board Actual': {
            'Mean': f"{df['top_actual'].mean():.4f}",
            'Median': f"{df['top_actual'].median():.4f}",
            'Std': f"{df['top_actual'].std():.4f}",
            'Min': f"{df['top_actual'].min():.4f}",
            'Max': f"{df['top_actual'].max():.4f}"
        },
        'Bottom Board Estimated': {
            'Mean': f"{df['bottom_estimated'].mean():.4f}",
            'Median': f"{df['bottom_estimated'].median():.4f}",
            'Std': f"{df['bottom_estimated'].std():.4f}",
            'Min': f"{df['bottom_estimated'].min():.4f}",
            'Max': f"{df['bottom_estimated'].max():.4f}"
        },
        'Bottom Board Actual': {
            'Mean': f"{df['bottom_actual'].mean():.4f}",
            'Median': f"{df['bottom_actual'].median():.4f}",
            'Std': f"{df['bottom_actual'].std():.4f}",
            'Min': f"{df['bottom_actual'].min():.4f}",
            'Max': f"{df['bottom_actual'].max():.4f}"
        }
    }
    
    # Save as JSON
    with open('interrupted_analysis/statistical_summary.json', 'w') as f:
        json.dump(summary_stats, f, indent=2)
    
    # Create visual table
    fig, ax = plt.subplots(figsize=(12, 8))
    ax.axis('tight')
    ax.axis('off')
    
    # Create table data
    table_data = []
    for metric, stats in summary_stats.items():
        table_data.append([
            metric,
            stats['Mean'],
            stats['Median'], 
            stats['Std'],
            stats['Min'],
            stats['Max']
        ])
    
    table = ax.table(cellText=table_data,
                    colLabels=['Metric', 'Mean', 'Median', 'Std Dev', 'Min', 'Max'],
                    cellLoc='center',
                    loc='center')
    table.auto_set_font_size(False)
    table.set_fontsize(10)
    table.scale(1.2, 1.5)
    
    ax.set_title('Statistical Summary - Interrupted Results', fontsize=16, fontweight='bold', pad=20)
    
    plt.savefig('interrupted_analysis/statistical_table.png', dpi=300, bbox_inches='tight')
    plt.close()

def main():
    print("Analyzing Interrupted Simulation Results")
    print("=" * 45)
    
    # Load interrupted results
    results = load_interrupted_results()
    
    if results:
        create_partial_visualizations(results)
        print(f"\n✅ Analysis complete!")
        print(f"📊 Visualizations saved to: interrupted_analysis/")
        print(f"📈 Files created:")
        print(f"   - summary_overview.png")
        print(f"   - equity_analysis.png") 
        print(f"   - hand_categories.png")
        print(f"   - statistical_table.png")
        print(f"   - statistical_summary.json")
    else:
        print("❌ Could not load interrupted results")

if __name__ == "__main__":
    main() 