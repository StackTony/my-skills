# GDB Core 分析模式

## 1. 段错误 (SIGSEGV) 分析模式

### 识别特征
- 信号: SIGSEGV
- 常见原因: 空指针、越界访问、use-after-free

### 分析步骤
```bash
# 1. 查看崩溃信号
(gdb) info signal

# 2. 查看崩溃地址
(gdb) print $_siginfo.si_addr
(gdb) print/x $_siginfo.si_code

# 3. 查看调用栈
(gdb) bt

# 4. 检查内存映射
(gdb) info proc mappings | grep <address>
```

### 常见原因模式

#### 空指针解引用
```
变量值 = 0x0
访问时触发 SIGSEGV
```

#### 访问已释放内存
```
内存已被 free
但指针仍被使用
```

#### 栈溢出
```
递归调用过深
局部变量过大
```


## 2. 程序中止 (SIGABRT) 分析模式

### 识别特征
- 信号: SIGABRT
- 通常由 assert() 或 abort() 触发

### 分析步骤
```bash
# 1. 查看调用栈
(gdb) bt

# 2. 查找 assert
(gdb) bt | grep assert

# 3. 查看崩溃帧
(gdb) frame 0
(gdb) list

# 4. 查看局部变量
(gdb) info locals
```

### 常见原因模式

#### assert 失败
```
assert(condition);
condition 为 false 时触发
通常表示程序状态异常
```

#### abort() 调用
```
主动调用 abort()
通常在严重错误时
```


## 3. 死锁分析模式

### 识别特征
- 多个线程处于等待状态
- 持有锁的线程被阻塞

### 分析步骤
```bash
# 1. 查看所有线程
(gdb) info threads

# 2. 所有线程堆栈
(gdb) thread apply all bt

# 3. 查找锁操作
(gdb) thread apply all bt | grep pthread_mutex

# 4. 查看锁状态
(gdb) print mutex_var
(gdb) print mutex_var.__data.__owner
```

### 死锁模式

#### 互斥锁死锁
```
线程A持有锁1，等待锁2
线程B持有锁2，等待锁1
```

#### 条件变量死锁
```
pthread_cond_wait 未被正确唤醒
pthread_cond_signal 调用时机错误
```


## 4. 多线程竞态条件模式

### 识别特征
- 数据不一致
- 随机崩溃
- 与线程调度相关

### 分析步骤
```bash
# 1. 线程状态
(gdb) info threads

# 2. 所有线程堆栈
(gdb) thread apply all bt

# 3. 检查共享变量
(gdb) print shared_var
(gdb) x/10gx &shared_var
```


## 5. 内存问题模式

### 内存泄漏
- 使用 valgrind 检测运行时
- Core 文件无法直接检测泄漏

### 内存损坏
```bash
(gdb) x/10gx <suspect_address>
(gdb) print *(struct_type*)address
```

### 栈溢出
```bash
(gdb) info frame
(gdb) print array[large_index]
```


## 6. 崩溃类型快速识别

| 信号 | 崩溃类型 | 首要检查 |
|------|----------|----------|
| SIGSEGV | 段错误 | si_addr, 内存映射 |
| SIGABRT | 中止 | bt, assert |
| SIGFPE | 浮点异常 | 寄存器, 计算 |
| SIGBUS | 总线错误 | 内存对齐 |


## 7. 分析检查清单

- [ ] 信号类型是什么？
- [ ] 崩溃地址在哪里？
- [ ] 调用栈完整吗？
- [ ] 涉及哪些线程？
- [ ] 有哪些变量可以检查？
- [ ] 需要查看源代码吗？
- [ ] 触发条件是什么？


## 8. 报告必需信息

1. **基本信息**
   - Core 文件路径
   - 可执行文件
   - 崩溃时间

2. **崩溃信息**
   - 信号类型
   - 崩溃位置
   - 变量状态

3. **调用栈**
   - 完整堆栈
   - 局部变量

4. **根因分析**
   - 直接原因
   - 技术机制
   - 根本原因

5. **解决方案**
   - 临时方案
   - 长期方案