# 🛡️ AgentAudit GitHub Action

**Scan your AI agent endpoints for security vulnerabilities in your CI/CD pipeline.**

AgentAudit automatically tests your AI endpoints for prompt injection, jailbreaking, data exfiltration, and other AI-specific security risks.

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-AgentAudit-blue?style=flat-square&logo=github)](https://github.com/marketplace/actions/agentaudit-security-scan)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

---

## 🚀 Quick Start

```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: XSource-Sec/agent-audit-action@v1
        with:
          target: ${{ secrets.AI_ENDPOINT_URL }}
          api_key: ${{ secrets.AGENTAUDIT_API_KEY }}
```

**That's it!** Your AI endpoint will be scanned on every push and pull request.

---

## 📋 Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `target` | ✅ Yes | - | Target URL to scan (your AI endpoint) |
| `api_key` | ✅ Yes | - | AgentAudit API key ([Get one here](https://app.xsourcesec.com)) |
| `mode` | No | `quick` | Scan mode: `quick`, `standard`, or `full` |
| `fail_on` | No | `high` | Fail build on findings at this severity or higher |
| `timeout` | No | `300` | Scan timeout in seconds (30-1800) |

### Scan Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `quick` | Essential security tests, fast execution (~1-2 min) | PRs, frequent commits |
| `standard` | Balanced coverage and speed (~3-5 min) | Pre-merge checks |
| `full` | Comprehensive testing of all vectors (~5-10 min) | Release gates, scheduled scans |

### Fail On Options

| Value | Behavior |
|-------|----------|
| `critical` | Fail only on critical vulnerabilities |
| `high` | Fail on critical or high severity (default) |
| `medium` | Fail on medium or higher |
| `low` | Fail on any finding |
| `none` | Never fail based on findings |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `scan_id` | Unique identifier of the scan |
| `total_findings` | Total number of findings |
| `critical_count` | Number of critical severity findings |
| `high_count` | Number of high severity findings |
| `medium_count` | Number of medium severity findings |
| `low_count` | Number of low severity findings |
| `risk_score` | Overall risk score (0-100) |
| `report_url` | URL to the full scan report |
| `status` | Scan status (completed/failed) |

---

## 📖 Examples

### Block PRs with Security Issues

```yaml
name: PR Security Gate

on: pull_request

jobs:
  security-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: XSource-Sec/agent-audit-action@v1
        with:
          target: ${{ secrets.STAGING_ENDPOINT }}
          api_key: ${{ secrets.AGENTAUDIT_API_KEY }}
          mode: standard
          fail_on: high
```

### Add PR Comment with Results

```yaml
name: Security Scan with Comment

on: pull_request

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: XSource-Sec/agent-audit-action@v1
        id: scan
        with:
          target: ${{ secrets.AI_ENDPOINT_URL }}
          api_key: ${{ secrets.AGENTAUDIT_API_KEY }}
        continue-on-error: true

      - name: Comment PR
        uses: actions/github-script@v7
        with:
          script: |
            const output = `## 🛡️ AgentAudit Security Scan

            | Metric | Value |
            |--------|-------|
            | Risk Score | **${{ steps.scan.outputs.risk_score }}/100** |
            | Critical | ${{ steps.scan.outputs.critical_count }} |
            | High | ${{ steps.scan.outputs.high_count }} |
            | Medium | ${{ steps.scan.outputs.medium_count }} |
            | Low | ${{ steps.scan.outputs.low_count }} |

            📄 [View Full Report](${{ steps.scan.outputs.report_url }})`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            });
```

### Scheduled Full Scans

```yaml
name: Weekly Security Audit

on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM

jobs:
  full-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: XSource-Sec/agent-audit-action@v1
        with:
          target: ${{ secrets.PRODUCTION_ENDPOINT }}
          api_key: ${{ secrets.AGENTAUDIT_API_KEY }}
          mode: full
          timeout: 600
```

### Multi-Environment Scan

```yaml
name: Multi-Environment Security Scan

on: push

jobs:
  scan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [staging, production]
    steps:
      - uses: XSource-Sec/agent-audit-action@v1
        with:
          target: ${{ secrets[format('{0}_ENDPOINT', matrix.environment)] }}
          api_key: ${{ secrets.AGENTAUDIT_API_KEY }}
          mode: ${{ matrix.environment == 'production' && 'full' || 'quick' }}
```

### Conditional Deployment

```yaml
name: Secure Deployment

on:
  push:
    branches: [main]

jobs:
  security-check:
    runs-on: ubuntu-latest
    outputs:
      passed: ${{ steps.scan.outputs.status == 'completed' && steps.scan.outputs.critical_count == '0' }}
    steps:
      - uses: XSource-Sec/agent-audit-action@v1
        id: scan
        with:
          target: ${{ secrets.STAGING_ENDPOINT }}
          api_key: ${{ secrets.AGENTAUDIT_API_KEY }}
          fail_on: critical

  deploy:
    needs: security-check
    if: needs.security-check.outputs.passed == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Production
        run: echo "Deploying..."
```

---

## 🔑 Get Your API Key

1. Sign up at [app.xsourcesec.com](https://app.xsourcesec.com)
2. Navigate to **Settings** → **API Keys**
3. Click **Create API Key**
4. Copy the key and add it to your GitHub Secrets as `AGENTAUDIT_API_KEY`

### Pricing

| Plan | Scans/Month | Targets | Attack Vectors | Price |
|------|-------------|---------|----------------|-------|
| **Free** | 5 | 1 | 100+ | $0/forever |
| **Pro** | 100 | 5 | 600+ | $149/mo |
| **Team** | Unlimited | Unlimited | 650+ | $299/mo |
| **Enterprise** | Unlimited | Unlimited | 650+ | Custom |

[View Pricing →](https://app.xsourcesec.com/pricing)

---

## 🔒 Security

- API keys are only transmitted over HTTPS
- Scan results are encrypted at rest
- We never store your endpoint credentials
- SOC 2 Type II compliant

---

## 📞 Support

- 📧 Email: support@xsourcesec.com
- 💬 Discord: [Join our community](https://discord.gg/xsourcesec)
- 📖 Docs: [docs.xsourcesec.com](https://docs.xsourcesec.com)
- 🐛 Issues: [GitHub Issues](https://github.com/XSource-Sec/agent-audit-action/issues)

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>Built with ❤️ by <a href="https://xsourcesec.com">XSource Security</a></b>
</p>
