#!/bin/bash
# evidence_chain.sh - Build evidence chain for GDB core analysis RCA

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EVIDENCE_DIR="${HOME}/core_analysis_evidence"
EVIDENCE_FILE="${EVIDENCE_DIR}/evidence_${TIMESTAMP}.txt"

mkdir -p "$EVIDENCE_DIR"

clear
cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║              EVIDENCE CHAIN BUILDER                           ║
║        Building unbreakable chain from symptom to root cause  ║
║                                                                ║
║  ⚠️  CRITICAL: All evidence must come from COREDUMP          ║
║      NOT from your analysis environment!                      ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF

echo -e "${CYAN}Output will be saved to: ${EVIDENCE_FILE}${NC}"
echo ""

# Initialize evidence file
cat > "$EVIDENCE_FILE" << 'HEADER'
================================================================================
                       EVIDENCE CHAIN REPORT
                       (GDB Core Analysis)
================================================================================

PRINCIPLE: Every claim must be backed by concrete evidence from core dump,
           code, or system state. No assumptions allowed.

================================================================================
HEADER

echo "Report Date: $(date)" >> "$EVIDENCE_FILE"
echo "Analyst: $(whoami)" >> "$EVIDENCE_FILE"
echo "" >> "$EVIDENCE_FILE"

prompt_evidence() {
    local level="$1"
    local question="$2"
    local evidence_question="$3"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${level}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "${YELLOW}${question}${NC}"
    read -p "> " answer
    
    echo -e "${YELLOW}${evidence_question}${NC}"
    echo -e "${CYAN}(Provide specific gdb commands, outputs, addresses)${NC}"
    read -p "> " evidence
    
    echo "" >> "$EVIDENCE_FILE"
    echo "${level}" >> "$EVIDENCE_FILE"
    echo "$(printf '=%.0s' {1..80})" >> "$EVIDENCE_FILE"
    echo "" >> "$EVIDENCE_FILE"
    echo "发现: $answer" >> "$EVIDENCE_FILE"
    echo "" >> "$EVIDENCE_FILE"
    echo "证据: $evidence" >> "$EVIDENCE_FILE"
    echo "" >> "$EVIDENCE_FILE"
    
    echo "$answer|$evidence"
}

echo -e "${MAGENTA}开始构建证据链...${NC}"
echo ""

# Level 0: Symptom
RESULT=$(prompt_evidence \
    "Level 0: 观察到的现象 (Symptom)" \
    "程序表现出什么问题？(用户可见的症状)" \
    "这个观察的证据是什么？")
SYMPTOM=$(echo "$RESULT" | cut -d'|' -f1)

# Level 1: Direct Cause  
RESULT=$(prompt_evidence \
    "Level 1: 直接原因 (Proximate Cause)" \
    "core dump显示的直接技术原因是什么？" \
    "从core dump哪里看到的？(bt/info signal输出)")
PROXIMATE=$(echo "$RESULT" | cut -d'|' -f1)

# Level 2: Mechanism
RESULT=$(prompt_evidence \
    "Level 2: 技术机制 (Mechanism)" \
    "这个直接原因是如何产生的？(技术细节)" \
    "哪些数据结构/代码证明了这个机制？(print/x/struct输出)")
MECHANISM=$(echo "$RESULT" | cut -d'|' -f1)

# Level 3: Design Flaw
RESULT=$(prompt_evidence \
    "Level 3: 设计缺陷 (Underlying Cause)" \
    "为什么这个技术问题会存在？(代码/设计层面)" \
    "从代码、配置、架构哪里看到的？")
DESIGN_FLAW=$(echo "$RESULT" | cut -d'|' -f1)

# Level 4: Root Cause
RESULT=$(prompt_evidence \
    "Level 4: 根本原因 (Root Cause)" \
    "为什么这个设计缺陷能够存在？(系统/流程层面)" \
    "什么系统性证据支持这个结论？")
ROOT_CAUSE=$(echo "$RESULT" | cut -d'|' -f1)

# Call Chain
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}调用链路 (Call Chain)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}请输入从触发到崩溃的完整调用链${NC}"
echo -e "${CYAN}格式: 函数名 → 证据 (每行一个，输入空行结束)${NC}"
echo ""

echo "" >> "$EVIDENCE_FILE"
echo "调用链路 (Call Chain)" >> "$EVIDENCE_FILE"
echo "$(printf '=%.0s' {1..80})" >> "$EVIDENCE_FILE"
echo "" >> "$EVIDENCE_FILE"

while true; do
    read -p "调用链路 > " call_line
    if [ -z "$call_line" ]; then
        break
    fi
    echo "$call_line" >> "$EVIDENCE_FILE"
done

# Generate Visualization
echo "" >> "$EVIDENCE_FILE"
echo "" >> "$EVIDENCE_FILE"
echo "$(printf '=%.0s' {1..80})" >> "$EVIDENCE_FILE"
echo "                    证据链可视化 (Evidence Chain)" >> "$EVIDENCE_FILE"
echo "$(printf '=%.0s' {1..80})" >> "$EVIDENCE_FILE"
echo "" >> "$EVIDENCE_FILE"

cat >> "$EVIDENCE_FILE" << CHAIN

[观察现象] $SYMPTOM
    ↓
    证据链接 ✓
    ↓
[直接原因] $PROXIMATE
    ↓
    证据链接 ✓
    ↓
[技术机制] $MECHANISM
    ↓
    证据链接 ✓
    ↓
[设计缺陷] $DESIGN_FLAW
    ↓
    证据链接 ✓
    ↓
[根本原因] $ROOT_CAUSE

CHAIN

# Plain language explanation
echo ""
echo -e "${YELLOW}用生活化的比喻解释这个问题:${NC}"
read -p "> " analogy

echo -e "${YELLOW}一句话总结这个问题:${NC}"
read -p "> " executive_summary

echo "" >> "$EVIDENCE_FILE"
echo "$(printf '=%.0s' {1..80})" >> "$EVIDENCE_FILE"
echo "                    通俗解释 (Plain Language)" >> "$EVIDENCE_FILE"
echo "$(printf '=%.0s' {1..80})" >> "$EVIDENCE_FILE"
echo "" >> "$EVIDENCE_FILE"
echo "一句话总结: $executive_summary" >> "$EVIDENCE_FILE"
echo "" >> "$EVIDENCE_FILE"
echo "生活化类比: $analogy" >> "$EVIDENCE_FILE"
echo "" >> "$EVIDENCE_FILE"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 证据链构建完成${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "完整证据链报告: ${CYAN}${EVIDENCE_FILE}${NC}"