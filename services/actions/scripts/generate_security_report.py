#!/usr/bin/env python3
"""
Security Report Generator
Parses security scan results and generates comprehensive reports
"""

import json
import os
import sys
from datetime import datetime
from typing import Dict, List, Any


class SecurityReportGenerator:
    def __init__(self):
        self.results = {}
        self.summary = {
            'total_vulnerabilities': 0,
            'critical_vulnerabilities': 0,
            'high_vulnerabilities': 0,
            'medium_vulnerabilities': 0,
            'low_vulnerabilities': 0,
            'outdated_packages': 0,
            'static_analysis_issues': 0,
            'scan_timestamp': datetime.now().isoformat()
        }

    def load_npm_audit_results(self) -> None:
        """Load and parse npm audit results"""
        try:
            with open('npm-audit-results.json', 'r') as f:
                data = json.load(f)
            
            if 'metadata' in data and 'vulnerabilities' in data['metadata']:
                vulns = data['metadata']['vulnerabilities']
                self.results['npm_audit'] = {
                    'critical': vulns.get('critical', 0),
                    'high': vulns.get('high', 0),
                    'moderate': vulns.get('moderate', 0),
                    'low': vulns.get('low', 0),
                    'total': sum(vulns.values())
                }
                
                self.summary['critical_vulnerabilities'] += vulns.get('critical', 0)
                self.summary['high_vulnerabilities'] += vulns.get('high', 0)
                self.summary['medium_vulnerabilities'] += vulns.get('moderate', 0)
                self.summary['low_vulnerabilities'] += vulns.get('low', 0)
                self.summary['total_vulnerabilities'] += sum(vulns.values())
                
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
            print(f"Warning: Could not load npm audit results: {e}")
            self.results['npm_audit'] = {'error': str(e)}

    def load_npm_outdated_results(self) -> None:
        """Load and parse npm outdated results"""
        try:
            with open('npm-outdated-results.json', 'r') as f:
                data = json.load(f)
            
            outdated_count = len(data)
            self.results['npm_outdated'] = {
                'count': outdated_count,
                'packages': list(data.keys())[:10]  # First 10 packages
            }
            self.summary['outdated_packages'] += outdated_count
            
        except (FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Warning: Could not load npm outdated results: {e}")
            self.results['npm_outdated'] = {'error': str(e)}

    def load_safety_results(self) -> None:
        """Load and parse Python safety results"""
        try:
            with open('safety-results.json', 'r') as f:
                data = json.load(f)
            
            if isinstance(data, list):
                vuln_count = len(data)
                self.results['safety'] = {
                    'count': vuln_count,
                    'vulnerabilities': data[:5]  # First 5 vulnerabilities
                }
                self.summary['total_vulnerabilities'] += vuln_count
                self.summary['high_vulnerabilities'] += vuln_count  # Safety reports are typically high severity
                
        except (FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Warning: Could not load safety results: {e}")
            self.results['safety'] = {'error': str(e)}

    def load_pip_audit_results(self) -> None:
        """Load and parse pip-audit results"""
        try:
            with open('pip-audit-results.json', 'r') as f:
                data = json.load(f)
            
            if 'vulnerabilities' in data:
                vulns = data['vulnerabilities']
                self.results['pip_audit'] = {
                    'count': len(vulns),
                    'vulnerabilities': vulns[:5]  # First 5 vulnerabilities
                }
                self.summary['total_vulnerabilities'] += len(vulns)
                
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
            print(f"Warning: Could not load pip-audit results: {e}")
            self.results['pip_audit'] = {'error': str(e)}

    def load_pip_outdated_results(self) -> None:
        """Load and parse pip outdated results"""
        try:
            with open('pip-outdated-results.json', 'r') as f:
                data = json.load(f)
            
            if isinstance(data, list):
                outdated_count = len(data)
                self.results['pip_outdated'] = {
                    'count': outdated_count,
                    'packages': [pkg['name'] for pkg in data[:10]]  # First 10 packages
                }
                self.summary['outdated_packages'] += outdated_count
                
        except (FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Warning: Could not load pip outdated results: {e}")
            self.results['pip_outdated'] = {'error': str(e)}

    def load_bandit_results(self) -> None:
        """Load and parse Bandit static analysis results"""
        try:
            with open('bandit-results.json', 'r') as f:
                data = json.load(f)
            
            if 'results' in data:
                results = data['results']
                high_severity = [r for r in results if r.get('issue_severity') == 'HIGH']
                medium_severity = [r for r in results if r.get('issue_severity') == 'MEDIUM']
                low_severity = [r for r in results if r.get('issue_severity') == 'LOW']
                
                self.results['bandit'] = {
                    'total_issues': len(results),
                    'high_severity': len(high_severity),
                    'medium_severity': len(medium_severity),
                    'low_severity': len(low_severity),
                    'sample_issues': high_severity[:3] + medium_severity[:2]  # Top issues
                }
                
                self.summary['static_analysis_issues'] += len(results)
                self.summary['high_vulnerabilities'] += len(high_severity)
                self.summary['medium_vulnerabilities'] += len(medium_severity)
                self.summary['low_vulnerabilities'] += len(low_severity)
                
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
            print(f"Warning: Could not load bandit results: {e}")
            self.results['bandit'] = {'error': str(e)}

    def load_semgrep_results(self) -> None:
        """Load and parse Semgrep results"""
        try:
            with open('semgrep-results.json', 'r') as f:
                data = json.load(f)
            
            if 'results' in data:
                results = data['results']
                error_results = [r for r in results if r.get('extra', {}).get('severity') == 'ERROR']
                warning_results = [r for r in results if r.get('extra', {}).get('severity') == 'WARNING']
                
                self.results['semgrep'] = {
                    'total_findings': len(results),
                    'errors': len(error_results),
                    'warnings': len(warning_results),
                    'sample_findings': error_results[:3] + warning_results[:2]
                }
                
                self.summary['static_analysis_issues'] += len(results)
                self.summary['high_vulnerabilities'] += len(error_results)
                self.summary['medium_vulnerabilities'] += len(warning_results)
                
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
            print(f"Warning: Could not load semgrep results: {e}")
            self.results['semgrep'] = {'error': str(e)}

    def load_trivy_results(self) -> None:
        """Load and parse Trivy config scan results"""
        try:
            with open('trivy-config-results.json', 'r') as f:
                data = json.load(f)
            
            if 'Results' in data:
                total_misconfigs = 0
                for result in data['Results']:
                    if 'Misconfigurations' in result:
                        total_misconfigs += len(result['Misconfigurations'])
                
                self.results['trivy_config'] = {
                    'total_misconfigurations': total_misconfigs,
                    'scanned_files': len(data['Results'])
                }
                
                self.summary['static_analysis_issues'] += total_misconfigs
                
        except (FileNotFoundError, json.JSONDecodeError, KeyError) as e:
            print(f"Warning: Could not load trivy config results: {e}")
            self.results['trivy_config'] = {'error': str(e)}

    def generate_report(self) -> Dict[str, Any]:
        """Generate comprehensive security report"""
        print("🔍 Generating security report...")
        
        # Load all results
        self.load_npm_audit_results()
        self.load_npm_outdated_results()
        self.load_safety_results()
        self.load_pip_audit_results()
        self.load_pip_outdated_results()
        self.load_bandit_results()
        self.load_semgrep_results()
        self.load_trivy_results()
        
        # Generate final report
        report = {
            'summary': self.summary,
            'detailed_results': self.results,
            'recommendations': self.generate_recommendations()
        }
        
        return report

    def generate_recommendations(self) -> List[str]:
        """Generate actionable recommendations based on findings"""
        recommendations = []
        
        if self.summary['critical_vulnerabilities'] > 0:
            recommendations.append("🚨 CRITICAL: Address critical vulnerabilities immediately")
        
        if self.summary['high_vulnerabilities'] > 0:
            recommendations.append("⚠️ HIGH: Review and fix high-severity vulnerabilities")
        
        if self.summary['outdated_packages'] > 10:
            recommendations.append("📦 Update outdated dependencies to latest stable versions")
        
        if self.summary['static_analysis_issues'] > 5:
            recommendations.append("🔍 Review static analysis findings and improve code quality")
        
        if not recommendations:
            recommendations.append("✅ No major security issues found - mastertain current security practices")
        
        # Always add general recommendations
        recommendations.extend([
            "🔄 Run security scans regularly (weekly/monthly)",
            "📚 Keep security tools and databases updated",
            "🛡️ Implement security-first development practices"
        ])
        
        return recommendations

    def save_report(self, report: Dict[str, Any]) -> None:
        """Save report to files"""
        # Save JSON report
        with open('security-report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        # Save human-readable report
        with open('security-report.md', 'w') as f:
            f.write(self.format_markdown_report(report))
        
        print("📄 Security reports saved:")
        print("  - security-report.json (machine-readable)")
        print("  - security-report.md (human-readable)")

    def format_markdown_report(self, report: Dict[str, Any]) -> str:
        """Format report as Markdown"""
        md = f"""# Security Analysis Report

**Generated:** {report['summary']['scan_timestamp']}

## 📊 Summary

- **Total Vulnerabilities:** {report['summary']['total_vulnerabilities']}
  - Critical: {report['summary']['critical_vulnerabilities']}
  - High: {report['summary']['high_vulnerabilities']}
  - Medium: {report['summary']['medium_vulnerabilities']}
  - Low: {report['summary']['low_vulnerabilities']}
- **Outdated Packages:** {report['summary']['outdated_packages']}
- **Static Analysis Issues:** {report['summary']['static_analysis_issues']}

## 🔍 Detailed Findings

"""
        
        # Add detailed findings for each tool
        for tool, results in report['detailed_results'].items():
            if 'error' not in results:
                md += f"### {tool.replace('_', ' ').title()}\n\n"
                md += f"```json\n{json.dumps(results, indent=2)}\n```\n\n"
        
        # Add recommendations
        md += "## 💡 Recommendations\n\n"
        for rec in report['recommendations']:
            md += f"- {rec}\n"
        
        md += "\n---\n*Report generated by PLOSolver Security Analysis*\n"
        
        return md


def master():
    """master function"""
    generator = SecurityReportGenerator()
    
    try:
        report = generator.generate_report()
        generator.save_report(report)
        
        # Print summary to console
        print("\n🔒 Security Analysis Summary:")
        print(f"  Total Vulnerabilities: {report['summary']['total_vulnerabilities']}")
        print(f"  Outdated Packages: {report['summary']['outdated_packages']}")
        print(f"  Static Analysis Issues: {report['summary']['static_analysis_issues']}")
        
        # Exit with appropriate code
        if report['summary']['critical_vulnerabilities'] > 0:
            print("\n❌ Critical vulnerabilities found!")
            sys.exit(1)
        elif report['summary']['high_vulnerabilities'] > 0:
            print("\n⚠️ High-severity vulnerabilities found!")
            sys.exit(1)
        else:
            print("\n✅ No critical or high-severity vulnerabilities found!")
            sys.exit(0)
            
    except Exception as e:
        print(f"❌ Error generating security report: {e}")
        sys.exit(1)


if __name__ == "__master__":
    master() 