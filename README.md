# ComputingSystemsIII LabX

## 1. 使用方式

使用Vivado2017.4, 在欢迎页点击Quick Start下的Create Project.

可以将本地repo的文件夹作为Vivado工程文件夹(但**不能**将工程名命名为`labx`(以及一切大小写组合)), **并且取消勾选Create project subdirectory**.

或者在本地repo的文件夹外另设Vivado工程文件夹.

选择RTL Project, 并勾选Do not specify sources at this time.

选择开发板xc7a100tcsg324-3.

等待Vivado生成初始工程文件, 随后通过Add sources将Constraint, Design Sources, Simulation Sources分别添加到工程中.

需要更改`RAM_B.v`中以下片段, 确保初始化的内存数据是符合预期的.

```verilog
// in file RAM_B.v

initial	begin
    $readmemh("PATH TO YOUR HEX FILE", data);
end
```

设置用于仿真的顶层模块为`core_sim`, 工程顶层模块为`top`, 通过Run Simulation(例如对流水线各阶段的PC寄存器进行观察)可以验证源文件是否被成功添加到工程中. 或者你也可以尝试使用Open Waveform Configuration打开`/sim_1/imports/sim/core_sim_behav.wcfg`使用现成的仿真配置.

## 2. 文件目录结构
```
lab1.srcs
│  README.md    <- this file
│  
├─constrs_1
│  └─imports
│      └─code
│              constraint.xdc
│              
├─sim_1
│  └─imports
│      └─sim
│              core_sim.v
│              core_sim_behav.wcfg
│              
└─sources_1
    └─imports
        └─code
            │  RAM_B.v
            │  ROM_D.v
            │  top.v
            │  uart_buffer.v
            │  UART_TX_CTRL.vhd
            │  VGATEST.v
            │  
            ├─auxillary
            │      btn_scan.v
            │      clk_diff.v
            │      Code2Inst.v
            │      CPUTEST.v
            │      debug_clk.v
            │      display.v
            │      Font816.v
            │      function.vh
            │      my_clk_gen.v
            │      parallel2serial.v
            │      top.v
            │      vga.v
            │      VGATEST.v
            │      
            ├─common
            │      add_32.v
            │      cmp_32.v
            │      MUX2T1_32.v
            │      MUX4T1_32.v
            │      REG32.v
            │      
            └─core
                    ALU.v
                    BranchPrediction.v
                    CSRRegs.v
                    CtrlUnit.v
                    ExceptionUnit.v
                    HazardDetectionUnit.v
                    ImmGen.v
                    RAM_B.v
                    Regs.v
                    REG_EX_MEM.v
                    REG_ID_EX.v
                    REG_IF_ID.v
                    REG_MEM_WB.v
                    ROM_D.v
                    RV32core.v
```