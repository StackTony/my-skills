---
name: gdb-core-analyzer
description: 这个skill专门用于使用GDB命令进行程序调试分析进程产生的coredump文件。当需要调试程序崩溃、分析进程coredump文件、诊断coredump文件里的内存问题、分析多线程问题时，使用此skill进行深入分析和故障诊断。
---

# GDB Core 文件分析

系统化的 Core 文件分析方法论，包含根因分析(RCA)框架和标准化报告输出。

## 一、环境区分

**READ THIS BEFORE DOING ANYTHING ELSE**

```
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║                    ⚠️  CRITICAL WARNING ⚠️                              ║
║                                                                          ║
║  你正在分析的是 COREDUMP 文件，不是在线运行的程序                        ║
║                                                                          ║
║  两个不同的环境：                                                         ║
║  1. 故障环境 - 崩溃的系统 (不可访问)                                      ║
║  2. 分析环境 - 你当前的工作站 (你现在所在的位置)                          ║
║                                                                          ║
║  禁止的操作：                                                             ║
║  ❌ free -h                     (分析环境的内存)                          ║
║  ❌ ps aux                      (分析环境的进程)                          ║
║  ❌ cat /proc/xxx               (分析环境的proc)                          ║
║  ❌ 任何在分析环境上执行的系统命令                                        ║
║                                                                          ║
║  要求的操作：                                                             ║
║  ✅ gdb> info registers         (从COREDUMP提取)                         ║
║  ✅ gdb> bt                      (从COREDUMP提取)                        ║
║  ✅ gdb> thread apply all bt    (从COREDUMP提取)                         ║
║  ✅ 所有数据必须来自 COREDUMP 文件                                         ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
```

### 分析环境中的文件

✓ Core 文件（从故障环境复制）
✓ 可执行文件（与core文件匹配）
✓ GDB 调试工具

### 证据来源优先级

1. Core 文件（通过 GDB 命令提取）
2. 可执行文件（用于符号解析）
3. 源代码（如有必要）

---

## 二、分析流程

### Phase 1: 初始评估

```bash
# 加载 core 文件
gdb <executable> <core_file>

# 基本信息
gdb> info signal          # 崩溃信号
gdb> info registers       # 寄存器状态
gdb> bt                   # 调用栈
gdb> info threads         # 线程信息
```

### Phase 2: 上下文发现

```bash
# 所有线程堆栈
gdb> thread apply all bt

# 内存映射
gdb> info proc mappings

# 共享库
gdb> info sharedlibrary
```

### Phase 3: 深度分析

#### 崩溃位置分析
```bash
# 切换到崩溃帧
gdb> frame 0

# 查看源代码
gdb> list

# 查看局部变量
gdb> info locals
gdb> info args

# 反汇编
gdb> disassemble
```

#### 内存问题分析
```bash
# 检查内存内容
gdb> x/10gx <address>

# 查找内存模式
gdb> find 0xstart, +len, value
```

#### 多线程问题分析
```bash
# 查看特定线程
gdb> thread <n>

# 死锁检测
gdb> thread apply all bt | grep pthread_mutex
```

### Phase 4: 根因分析

应用 5 Whys 技术：
1. 为什么崩溃？→ 原因1
2. 为什么原因1存在？→ 原因2
3. 为什么原因2存在？→ 原因3
4. 为什么原因3存在？→ 原因4
5. 为什么原因4存在？→ 根本原因

---

## 三、根因分析框架

### 证据链构建

每个结论必须有以下证据支撑：

```
[观察到的现象] ← [直接证据 FROM COREDUMP]
    ↓
[直接原因] ← [技术证据 FROM COREDUMP]
    ↓
[技术机制] ← [代码/数据证据]
    ↓
[设计缺陷] ← [架构/流程证据]
    ↓
[根本原因] ← [系统性证据]
```

### 根因声明模板

**技术版本：**
```
ROOT CAUSE: [具体技术问题]

MECHANISM: [问题如何发生]

EVIDENCE CHAIN:
1. [观察] → [来自 coredump 的证据]
2. [直接原因] → [来自堆栈/日志的证据]
3. [技术机制] → [来自变量/内存的证据]
4. [设计缺陷] → [来自代码/架构的证据]
5. [系统性问题] → [来自流程/标准的证据]

SCOPE: [影响范围]
```

**通俗版本：**
```
问题是什么？
[用简单语言描述]

为什么会发生？
[用类比解释]

具体是怎么出错的？
[分步骤说明]

真正的根本原因是什么？
[系统性问题的解释]

修复方案：
• 立即修复：[解决当前问题]
• 长期方案：[防止类似问题]
```

---

## 四、标准化分析报告模板

### 报告格式（必须遵循）

```
================================================================================
<程序名> 崩溃分析报告
================================================================================

一、基本信息
--------------------------------------------------------------------------------
Core 文件路径：<core文件路径>
可执行文件：<可执行文件路径>
程序版本：<版本信息>
崩溃时间：<根据core文件时间戳>
<其他相关信息>

二、崩溃信号
--------------------------------------------------------------------------------
信号类型：<信号名> (信号编号)
信号说明：<信号含义>

三、崩溃位置
--------------------------------------------------------------------------------
崩溃函数：<函数名>
崩溃文件：<源文件路径>
崩溃行号：<行号>
崩溃语句：<具体语句>

变量状态：
  - <变量1> = <值>
  - <变量2> = <值>

四、<问题类型>分析
--------------------------------------------------------------------------------
<根据崩溃类型进行的具体分析>

五、完整调用栈
--------------------------------------------------------------------------------
<调用栈信息>

六、线程信息
--------------------------------------------------------------------------------
<线程信息>

七、关键数据结构详情
--------------------------------------------------------------------------------
<数据结构内容>

八、根本原因分析
--------------------------------------------------------------------------------
1. 直接原因：
   <直接技术原因>

2. 可能原因：
   a) <可能原因1>
   b) <可能原因2>

3. 触发路径：
   <调用链路>

九、建议解决方案
--------------------------------------------------------------------------------
1. 临时方案：
   <临时解决方案>

2. 长期方案：
   a) <长期解决方案1>
   b) <长期解决方案2>

3. 预防措施：
   <预防措施>

================================================================================
十、分析流程详解
================================================================================

10.1 GDB 调试命令使用记录
--------------------------------------------------------------------------------
<每一步的分析命令、目的和输出>

10.2 源码分析
--------------------------------------------------------------------------------
<相关源代码分析>

10.3 调用链路分析
--------------------------------------------------------------------------------
<完整的调用链路分析>

10.4 关键数据结构分析
--------------------------------------------------------------------------------
<关键数据结构的详细分析>

十一、结论
--------------------------------------------------------------------------------
<最终结论>

================================================================================
报告生成时间：<时间>
分析工具：gdb <可执行文件>
分析人员：<分析人员>
================================================================================
```

---

## 五、快速分析脚本

### 自动分析脚本

```bash
#!/bin/bash
# auto_core_analysis.sh

EXECUTABLE=$1
CORE_FILE=$2

if [ -z "$CORE_FILE" ] || [ -z "$EXECUTABLE" ]; then
    echo "Usage: $0 <executable> <core_file>"
    exit 1
fi

OUTPUT_FILE="core_analysis_report_$(date +%Y%m%d_%H%M%S).txt"

cat > /tmp/analysis.gdb << 'EOF'
set pagination off
set logging file /tmp/gdb_output.txt
set logging on

printf "\n=== Core Analysis Output ===\n"

printf "\n--- Basic Info ---\n"
info signal
info registers

printf "\n--- Backtrace ---\n"
bt full

printf "\n--- Threads ---\n"
info threads
thread apply all bt

printf "\n--- Memory Mapping ---\n"
info proc mappings

printf "\n--- Shared Libraries ---\n"
info sharedlibrary

set logging off
quit
EOF

gdb -batch -x /tmp/analysis.gdb $EXECUTABLE $CORE_FILE 2>/dev/null

cat > $OUTPUT_FILE << 'HEADER'
================================================================================
Core 文件崩溃分析报告
================================================================================

HEADER

echo "Core 文件路径：$CORE_FILE" >> $OUTPUT_FILE
echo "可执行文件：$EXECUTABLE" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

cat /tmp/gdb_output.txt >> $OUTPUT_FILE

echo "=== Analysis Report: $OUTPUT_FILE ==="
rm -f /tmp/analysis.gdb /tmp/gdb_output.txt
```

### 快速分析命令

```bash
# 基础分析
gdb -batch -ex "bt" -ex "info signal" -ex "info registers" $EXECUTABLE $CORE_FILE

# 完整分析
gdb -batch -ex "bt full" -ex "info threads" -ex "info registers" -ex "info proc mappings" $EXECUTABLE $CORE_FILE

# 多线程分析
gdb -batch -ex "thread apply all bt" -ex "info threads" $EXECUTABLE $CORE_FILE
```

---

## 六、常见崩溃类型分析

### SIGSEGV (段错误)

```bash
# 检查崩溃原因
gdb> print $_siginfo.si_signo
gdb> print $_siginfo.si_code
gdb> print/x $_siginfo.si_addr

# 检查内存映射
gdb> info proc mappings | grep <address>
```

### SIGABRT (程序中止)

```bash
# 查看调用栈
gdb> bt

# 检查是否 assert 失败
gdb> bt | grep assert
```

### 死锁分析

```bash
# 查看所有线程
gdb> thread apply all bt

# 查找锁等待
gdb> thread apply all bt | grep pthread_mutex
```

---

## 七、GDB 命令参考

### 基础命令

| 命令 | 说明 |
|------|------|
| `bt` | 调用栈 |
| `bt full` | 完整调用栈 |
| `info registers` | 寄存器 |
| `info threads` | 线程 |
| `frame N` | 切换帧 |
| `list` | 查看源码 |
| `print var` | 打印变量 |
| `x/addr` | 检查内存 |

### 高级命令

| 命令 | 说明 |
|------|------|
| `disassemble` | 反汇编 |
| `info locals` | 局部变量 |
| `info args` | 函数参数 |
| `thread apply all bt` | 所有线程堆栈 |
| `info proc mappings` | 内存映射 |

---

## 八、编译优化配置

### 调试编译选项

```bash
# 启用调试信息
gcc -g my_program.c -o my_program

# 最大调试信息
gcc -g3 my_program.c -o my_program

# 无优化调试
gcc -g -O0 my_program.c -o my_program

# 保留帧指针（更好的堆栈）
gcc -g -fno-omit-frame-pointer my_program.c -o my_program
```

### Core Dump 配置

```bash
# 启用 core dump
ulimit -c unlimited

# 设置 core 文件模式
echo "/tmp/core-%e-%p-%t" > /proc/sys/kernel/core_pattern
```

---

## 九、最佳实践

1. **环境区分**：所有数据来自 core 文件，不是分析环境的系统命令

2. **证据链**：每个结论必须有 coredump 中的数据支撑

3. **5 Whys**：持续追问"为什么"直到找到根本原因

4. **标准化报告**：使用第四节的报告模板输出

5. **源码分析**：必要时查看源代码理解逻辑

6. **调用链路**：梳理完整的调用路径

---

## 版本信息

- **Skill版本**: 2.0
- **GDB版本**: 7.0+
- **创建日期**: 2026-04-07
- **更新日期**: 2026-04-08
