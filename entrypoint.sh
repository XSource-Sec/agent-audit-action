#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Banner
echo ""
echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}${BOLD}║                                                              ║${NC}"
echo -e "${PURPLE}${BOLD}║   🛡️  AgentAudit - AI Agent Security Testing                 ║${NC}"
echo -e "${PURPLE}${BOLD}║                                                              ║${NC}"
echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Validate inputs
if [ -z "$TARGET" ]; then
    echo -e "${RED}❌ Error: TARGET is required${NC}"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ Error: API_KEY is required${NC}"
    echo -e "${YELLOW}   Get your API key at: https://app.xsourcesec.com${NC}"
    exit 1
fi

# Set defaults
MODE=${MODE:-quick}
FAIL_ON=${FAIL_ON:-high}
TIMEOUT=${TIMEOUT:-300}

echo -e "${CYAN}📋 Scan Configuration:${NC}"
echo -e "   Target:   ${BOLD}$TARGET${NC}"
echo -e "   Mode:     ${BOLD}$MODE${NC}"
echo -e "   Fail on:  ${BOLD}$FAIL_ON${NC}"
echo -e "   Timeout:  ${BOLD}${TIMEOUT}s${NC}"
echo ""

# Make API request
echo -e "${BLUE}🔍 Starting security scan...${NC}"
echo ""

RESPONSE=$(python3 << EOF
import requests
import json
import sys

try:
    response = requests.post(
        "https://agentaudit-api.fly.dev/api/v1/ci/scan",
        headers={
            "X-API-Key": "$API_KEY",
            "Content-Type": "application/json"
        },
        json={
            "target": "$TARGET",
            "mode": "$MODE",
            "timeout": int("$TIMEOUT")
        },
        timeout=int("$TIMEOUT") + 30  # Extra buffer for API
    )

    if response.status_code == 401:
        print(json.dumps({"error": "Invalid API key. Get a valid key at https://app.xsourcesec.com"}))
        sys.exit(1)
    elif response.status_code == 403:
        data = response.json()
        print(json.dumps({"error": data.get("detail", "Access denied - check your plan limits")}))
        sys.exit(1)
    elif response.status_code != 200:
        print(json.dumps({"error": f"API error: {response.status_code} - {response.text}"}))
        sys.exit(1)

    print(json.dumps(response.json()))

except requests.exceptions.Timeout:
    print(json.dumps({"error": "Scan timed out. Try increasing the timeout value."}))
    sys.exit(1)
except Exception as e:
    print(json.dumps({"error": str(e)}))
    sys.exit(1)
EOF
)

# Check for errors
ERROR=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('error', ''))" 2>/dev/null || echo "")
if [ -n "$ERROR" ]; then
    echo -e "${RED}❌ Error: $ERROR${NC}"
    exit 1
fi

# Parse response
SCAN_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['scan_id'])")
STATUS=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['status'])")
TOTAL_FINDINGS=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['total_findings'])")
CRITICAL=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['findings']['critical'])")
HIGH=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['findings']['high'])")
MEDIUM=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['findings']['medium'])")
LOW=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['findings']['low'])")
RISK_SCORE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['risk_score'])")
REPORT_URL=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['report_url'])")
DURATION=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['duration_seconds'])")

# Results header
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                     📊 SCAN RESULTS                          ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Scan info
echo -e "${CYAN}ℹ️  Scan Info:${NC}"
echo -e "   Scan ID:  ${BOLD}$SCAN_ID${NC}"
echo -e "   Status:   ${GREEN}$STATUS${NC}"
echo -e "   Duration: ${BOLD}${DURATION}s${NC}"
echo ""

# Risk score with color coding
echo -e "${CYAN}📈 Risk Score:${NC}"
if (( $(echo "$RISK_SCORE >= 75" | bc -l 2>/dev/null || echo 0) )); then
    echo -e "   ${RED}${BOLD}$RISK_SCORE / 100${NC} ${RED}(Critical Risk)${NC}"
elif (( $(echo "$RISK_SCORE >= 50" | bc -l 2>/dev/null || echo 0) )); then
    echo -e "   ${YELLOW}${BOLD}$RISK_SCORE / 100${NC} ${YELLOW}(High Risk)${NC}"
elif (( $(echo "$RISK_SCORE >= 25" | bc -l 2>/dev/null || echo 0) )); then
    echo -e "   ${BLUE}${BOLD}$RISK_SCORE / 100${NC} ${BLUE}(Medium Risk)${NC}"
else
    echo -e "   ${GREEN}${BOLD}$RISK_SCORE / 100${NC} ${GREEN}(Low Risk)${NC}"
fi
echo ""

# Findings summary
echo -e "${CYAN}🔍 Findings Summary:${NC}"
echo -e "   Total: ${BOLD}$TOTAL_FINDINGS${NC}"
echo ""

if [ "$CRITICAL" -gt 0 ]; then
    echo -e "   ${RED}🔴 Critical: $CRITICAL${NC}"
else
    echo -e "   ⚪ Critical: 0"
fi

if [ "$HIGH" -gt 0 ]; then
    echo -e "   ${YELLOW}🟠 High:     $HIGH${NC}"
else
    echo -e "   ⚪ High:     0"
fi

if [ "$MEDIUM" -gt 0 ]; then
    echo -e "   ${BLUE}🟡 Medium:   $MEDIUM${NC}"
else
    echo -e "   ⚪ Medium:   0"
fi

if [ "$LOW" -gt 0 ]; then
    echo -e "   ${CYAN}🟢 Low:      $LOW${NC}"
else
    echo -e "   ⚪ Low:      0"
fi
echo ""

# Report link
echo -e "${PURPLE}📄 Full Report:${NC}"
echo -e "   ${BOLD}$REPORT_URL${NC}"
echo ""

# Set GitHub outputs
echo "scan_id=$SCAN_ID" >> $GITHUB_OUTPUT
echo "total_findings=$TOTAL_FINDINGS" >> $GITHUB_OUTPUT
echo "critical_count=$CRITICAL" >> $GITHUB_OUTPUT
echo "high_count=$HIGH" >> $GITHUB_OUTPUT
echo "medium_count=$MEDIUM" >> $GITHUB_OUTPUT
echo "low_count=$LOW" >> $GITHUB_OUTPUT
echo "risk_score=$RISK_SCORE" >> $GITHUB_OUTPUT
echo "report_url=$REPORT_URL" >> $GITHUB_OUTPUT
echo "status=$STATUS" >> $GITHUB_OUTPUT

# Add job summary
cat >> $GITHUB_STEP_SUMMARY << SUMMARY
## 🛡️ AgentAudit Security Scan Results

| Metric | Value |
|--------|-------|
| **Target** | \`$TARGET\` |
| **Scan Mode** | $MODE |
| **Risk Score** | **$RISK_SCORE / 100** |
| **Duration** | ${DURATION}s |

### 🔍 Findings

| Severity | Count |
|----------|-------|
| 🔴 Critical | $CRITICAL |
| 🟠 High | $HIGH |
| 🟡 Medium | $MEDIUM |
| 🟢 Low | $LOW |
| **Total** | **$TOTAL_FINDINGS** |

📄 [View Full Report]($REPORT_URL)
SUMMARY

# Check fail_on threshold
SHOULD_FAIL=0

case "$FAIL_ON" in
    "critical")
        if [ "$CRITICAL" -gt 0 ]; then
            SHOULD_FAIL=1
            FAIL_REASON="critical"
        fi
        ;;
    "high")
        if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            SHOULD_FAIL=1
            if [ "$CRITICAL" -gt 0 ]; then
                FAIL_REASON="critical"
            else
                FAIL_REASON="high"
            fi
        fi
        ;;
    "medium")
        if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ] || [ "$MEDIUM" -gt 0 ]; then
            SHOULD_FAIL=1
            if [ "$CRITICAL" -gt 0 ]; then
                FAIL_REASON="critical"
            elif [ "$HIGH" -gt 0 ]; then
                FAIL_REASON="high"
            else
                FAIL_REASON="medium"
            fi
        fi
        ;;
    "low")
        if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ] || [ "$MEDIUM" -gt 0 ] || [ "$LOW" -gt 0 ]; then
            SHOULD_FAIL=1
            if [ "$CRITICAL" -gt 0 ]; then
                FAIL_REASON="critical"
            elif [ "$HIGH" -gt 0 ]; then
                FAIL_REASON="high"
            elif [ "$MEDIUM" -gt 0 ]; then
                FAIL_REASON="medium"
            else
                FAIL_REASON="low"
            fi
        fi
        ;;
    "none")
        # Never fail based on findings
        ;;
esac

if [ "$SHOULD_FAIL" -eq 1 ]; then
    echo ""
    echo -e "${RED}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}${BOLD}  ❌ BUILD FAILED: Found $FAIL_REASON severity vulnerabilities${NC}"
    echo -e "${RED}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}💡 To change failure threshold, set fail_on: 'critical' or 'none'${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  ✅ SECURITY SCAN PASSED${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
fi
