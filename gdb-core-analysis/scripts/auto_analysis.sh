#!/bin/bash
# auto_analysis.sh - Generate standardized GDB core analysis report

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="core_analysis_report_${TIMESTAMP}.txt"

show_usage() {
    echo "Usage: $0 <executable> <core_file> [output_file]"
    echo ""
    echo "Parameters:"
    echo "  executable   - Path to the executable file"
    echo "  core_file    - Path to the core dump file"
    echo "  output_file  - Optional output file (default: core_analysis_report_TIMESTAMP.txt)"
    exit 1
}

if [ -z "$1" ] || [ -z "$2" ]; then
    show_usage
fi

EXECUTABLE="$1"
CORE_FILE="$2"

if [ -n "$3" ]; then
    REPORT_FILE="$3"
fi

if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Executable not found: $EXECUTABLE"
    exit 1
fi

if [ ! -f "$CORE_FILE" ]; then
    echo "Error: Core file not found: $CORE_FILE"
    exit 1
fi

EXE_VERSION=$(file "$EXECUTABLE" | head -1)
CORE_TIMESTAMP=$(stat -c %y "$CORE_FILE" 2>/dev/null | cut -d'.' -f1 || stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$CORE_FILE" 2>/dev/null || date -r "$CORE_FILE" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)

echo "Starting core analysis..."
echo "Executable: $EXECUTABLE"
echo "Core file: $CORE_FILE"
echo "Output: $REPORT_FILE"

GDB_TEMP=$(mktemp)
cat > "$GDB_TEMP" << 'EOF'
set pagination off
set print pretty on
set print array on

# Get signal info
printf "\n--- SIGNAL ---\n"
info signal

# Get registers
printf "\n--- REGISTERS ---\n"
info registers

# Get backtrace
printf "\n--- BACKTRACE ---\n"
bt full

# Get threads
printf "\n--- THREADS ---\n"
info threads
thread apply all bt

# Get memory mappings
printf "\n--- MEMORY MAPPINGS ---\n"
info proc mappings

# Get shared libraries
printf "\n--- SHARED LIBRARIES ---\n"
info sharedlibrary

# Get crash location details if available
printf "\n--- CRASH LOCATION ---\n"
frame 0
list
info locals
info args

quit
EOF

GDB_OUTPUT=$(gdb -batch -x "$GDB_TEMP" "$EXECUTABLE" "$CORE_FILE" 2>&1)
rm -f "$GDB_TEMP"

SIGNAL_INFO=$(echo "$GDB_OUTPUT" | grep -A5 "--- SIGNAL ---" | tail -n +2)
REGISTERS=$(echo "$GDB_OUTPUT" | grep -A20 "--- REGISTERS ---" | head -n 20)
BACKTRACE=$(echo "$GDB_OUTPUT" | grep -A100 "--- BACKTRACE ---" | head -n 100)
THREADS=$(echo "$GDB_OUTPUT" | grep -A50 "--- THREADS ---" | head -n 50)
MEMORY_MAPPINGS=$(echo "$GDB_OUTPUT" | grep -A30 "--- MEMORY MAPPINGS ---" | head -n 30)
CRASH_LOCATION=$(echo "$GDB_OUTPUT" | grep -A30 "--- CRASH LOCATION ---" | head -n 30)

SIGNAL_NAME=$(echo "$GDB_OUTPUT" | grep -i "signal" | head -1 | grep -oP "SIG\w+" || echo "Unknown")
CRASH_FUNC=$(echo "$GDB_OUTPUT" | grep -E "^\#0" | head -1 | awk '{print $NF}' | tr -d '()' || echo "Unknown")

cat > "$REPORT_FILE" << EOF
================================================================================
Core 文件崩溃分析报告
================================================================================

一、基本信息
--------------------------------------------------------------------------------
Core 文件路径：$CORE_FILE
可执行文件：$EXECUTABLE
程序版本：$EXE_VERSION
崩溃时间：$CORE_TIMESTAMP
分析时间：$(date)

二、崩溃信号
--------------------------------------------------------------------------------
$SIGNAL_INFO

三、崩溃位置
--------------------------------------------------------------------------------
$CRASH_LOCATION

四、完整调用栈
--------------------------------------------------------------------------------
$BACKTRACE

五、线程信息
--------------------------------------------------------------------------------
$THREADS

六、内存映射
--------------------------------------------------------------------------------
$MEMORY_MAPPINGS

七、寄存器状态
--------------------------------------------------------------------------------
$REGISTERS

八、初步分析
--------------------------------------------------------------------------------
崩溃信号：$SIGNAL_NAME
崩溃函数：$CRASH_FUNC

（此处需要分析员根据调用栈和变量信息进行深入分析，填写具体原因）

九、建议分析步骤
--------------------------------------------------------------------------------
1. 查看崩溃位置的源代码，理解崩溃原因
2. 分析调用栈，定位触发路径
3. 检查相关变量值，理解数据状态
4. 如果是多线程问题，分析线程间交互
5. 应用 5 Whys 方法进行根因分析
6. 制定解决方案和预防措施

================================================================================
十、GDB 调试原始输出
================================================================================

$GDB_OUTPUT

================================================================================
报告生成时间：$(date)
分析工具：gdb $EXECUTABLE
================================================================================
EOF

echo ""
echo "=== Analysis Complete ==="
echo "Report: $REPORT_FILE"
echo ""
echo "Quick Summary:"
echo "  Signal: $SIGNAL_NAME"
echo "  Function: $CRASH_FUNC"