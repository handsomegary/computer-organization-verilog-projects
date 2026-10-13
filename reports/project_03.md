# project_03：三個 CPU 版本的規格符合性審核

結論：**三個版本都有可辨識的設計工作，但目前不能認定完整符合對應 A／B／C 等級。** Single-cycle 與 pipeline 的 `addi` 會額外寫 memory；pipeline 缺 `j`；hazard 版有 `slt`、`addi`、mixed-stage forwarding、store-data 與記憶體更新的明確缺口。原 RTL 全部保留，未為了讓測試通過而修 CPU。

本報告依提供的投影片：A 是 single cycle，B 是五級 pipeline，C 是 forwarding 加 load-use stall／bubble；共同要求 `lw,sw,add,addi,sub,and,or,slt,beq,j`。提供資料中示例初值有 400／40 的差異，因此不把兩者混成同一條測資。課程的 `t0=register0, t1=register1, ... s0=register6` 是自訂 alias；以下只用 numeric register ID。Reg0 的 zero／可寫語意沒有另訂明確規則，這次不以任一標準 ABI 假設判錯。probe 的閒置指令採 `or $31,$31,$31`，並明確 seed r31=0，沒有依賴不在必要清單內的 sll-zero NOP。

## 範圍與驗證狀態

| 版本 | 原 authored `.v` | 結構 | 嚴格 Icarus 編譯 | 功能判定 |
|---|---:|---|---|---|
| `single_cycle` | 15（14 RTL + 1 TB） | PC、control、GPR、ALU、instruction/data memory、branch/jump 路徑 | 待 Linux CI 實跑 | 部分 A；`addi` 的 memory side effect 是已確認缺陷 |
| `pipeline` | 19（18 RTL + 1 TB） | IF/ID、ID/EX、EX/MEM、MEM/WB 五級路徑 | 待 Linux CI 實跑 | 部分 B；缺 `j`，且相同 `addi` 缺陷 |
| `hazard` | 8（7 RTL + 1 TB） | forwarding、PC/IF-ID hold、control bubble | 舊式 output range 宣告預期會被 strict 模式拒絕，實際診斷待 CI | 部分 C；即使 Program 2 通過也不代表所有 hazard／ISA 完整 |

已逐一閱讀 42 個原檔。`python checks/check_project_03.py --model-only` 的靜態／Python golden 檢查已通過；它沒有執行 Verilog，不把此結果寫成 HDL PASS。預設指令在 Linux 執行 compile-only、原 TB compile-only 及定向模擬：

```sh
python checks/check_project_03.py --model-only
python checks/check_project_03.py
```

所有模擬執行檔、注入的 TB 及 stdout 都在暫存處理；沒有 waveform、VCD、公開大 log 或展開向量檔。source SHA-256 於 audit 前後核對，防止測試改動原 RTL。CI 綠燈表示審核程序完成、報告觀察可重現，**不表示三個 CPU 全部符合 ISA**。

## Single-cycle：可確認事項與缺陷

| 項目 | 證據與影響 |
|---|---|
| Required R-type control／signed ALU 已實作 | [ALU_Controller.v](../projects/project_03/single_cycle/rtl/ALU_Controller.v#L15) 解碼 add/sub/and/or/slt；[ALU.v](../projects/project_03/single_cycle/rtl/ALU.v#L7) 的 operands 宣告 signed，slt 在 line17 寫 0／1。bench 同時測 `-1<1`、`1<-1`，避免只測非負值。 |
| `addi` 額外寫 memory | [Controller.v:50](../projects/project_03/single_cycle/rtl/Controller.v#L50)：opcode001000 的 `MEMWRITE=1`、`MEMREAD=0`。由 [CPU_SingleCycle.v:30](../projects/project_03/single_cycle/rtl/CPU_SingleCycle.v#L30) 接到 DataMemory，實際 store 資料是舊的 rt 值。`addi $4,$1,-4`，`$1=7` 應只寫 `$4=3`；若 memory slot3 原為77，原程式會把它改成舊 `$4`，不是合法 addi side effect。 |
| PC4、signed branch target、jump 組線存在 | [CPU_SingleCycle.v:38](../projects/project_03/single_cycle/rtl/CPU_SingleCycle.v#L38) 計算 PC+4；line39–43 是 signext offset<<2 與 branch mux；line46–47 是 `{PC4[31:28], target<<2}`。probe 包含 negative branch 與 PC+4 跨高位 nibble 的 jump case。 |
| 記憶體範圍／reset 限制 | [DataMemory.v:12](../projects/project_03/single_cycle/rtl/DataMemory.v#L12) 只有 array0..63；line14／29 用完整 ADDR 作 index。可以把這看作 byte-address 的稀疏 word slot：aligned 可用 address0..60。未做 `ADDR>>2` 不等於每次 lw/sw 都算錯；讀寫同一合法 address 是自洽的。常見 dense word-array 模型則可容納 byte addresses0..252，兩者容量不同。address100在這份實作越界，probe 只記容量限制；不因額外要求無限 memory 判錯。line22 的 reset 迴圈只清0..62，slot63保留舊值，是 reset 實作瑕疵，並非 MIPS ISA 本身規定必須清 RAM。 |
| 原測試證据不足 | [SINGLE_CYCLE_TB.v](../projects/project_03/single_cycle/tb/SINGLE_CYCLE_TB.v) 只有 clock/reset、等待與 finish，沒有比對期望或 assertion。跑完該 TB 不代表數值正確。 |

## Pipeline：完整指令集與 control hazard 的缺口

| 項目 | 證據與影響 |
|---|---|
| 五級資料／control 暫存器存在 | [CPU_PIPELINE.v:44](../projects/project_03/pipeline/rtl/CPU_PIPELINE.v#L44)、line56、76、87 分別接 IF/ID、ID/EX、EX/MEM、MEM/WB。single-instruction probes 預留 drain cycles，不把尚未 WB 的資料誤判錯。 |
| `j` 未完成 | [CONTROLLER.v](../projects/project_03/pipeline/rtl/CONTROLLER.v#L3) 沒有 Jump output／opcode000010 case；[CPU_PIPELINE.v:92](../projects/project_03/pipeline/rtl/CPU_PIPELINE.v#L92) 的 PC_IN mux 只有 PC4 與 branch target。雖另有26-bit shift模組檔案，top 沒把它接入 jump path。bench 的 j 應跳過 `$5` 的寫入；原路徑會繼續順序取指。 |
| `addi` 相同 memory side effect | [CONTROLLER.v:47](../projects/project_03/pipeline/rtl/CONTROLLER.v#L47) 仍令 `MEMWRITE=1`，經 ID/EX、EX/MEM 傳到 data memory。其 addi 數值 WB 可能正確，memory 仍遭破壞。 |
| 不應誤判反向 MemToReg 編碼 | [CONTROLLER.v:14](../projects/project_03/pipeline/rtl/CONTROLLER.v#L14) 的 R-type 是1、lw是0；[CPU_PIPELINE.v:90](../projects/project_03/pipeline/rtl/CPU_PIPELINE.v#L90) 也以 IN0=memory、IN1=ALU 的反向 mux 相配。它和 single-cycle 的 bit 編碼不同，但 R/lw 彼此一致，不列成反接缺陷。 |
| Taken branch 沒有 flush | [CPU_PIPELINE.v:82](../projects/project_03/pipeline/rtl/CPU_PIPELINE.v#L82) 在 EX/MEM 後才形成 branch_select；[IF_ID.v](../projects/project_03/pipeline/rtl/IF_ID.v)、[ID_EX.v](../projects/project_03/pipeline/rtl/ID_EX.v)、[EX_MEM.v](../projects/project_03/pipeline/rtl/EX_MEM.v) 只有 reset／一般 update，沒有 branch kill。按教材 single-cycle、無延遲槽的 ISA golden，跳過路徑上的 add/or/and 不應改 `$5,$6,$7`；probe 會觀察這三個副作用。若課程另訂 delay-slot／插入 NOP protocol，必須另說明；本報告不把未說明的三條錯路徑當作合法延遲槽。 |
| RAW 未處理的範圍 | ALU直接使用 [CPU_PIPELINE.v:65](../projects/project_03/pipeline/rtl/CPU_PIPELINE.v#L65) 的 ID/EX operands，沒有 bypass 或 hold。B 是基本 pipeline，而 C 才另列 hazard detection，因此不單憑此點說「沒有做 B」；它確實不具 C 的一般 unscheduled RAW 能力。 |
| Memory／原 TB 限制 | [DATAMEMORY.v](../projects/project_03/pipeline/rtl/DATAMEMORY.v) 與 single-cycle 同樣是0..63稀疏 slots、reset少清最後一槽。[CPU_Pipeline_tb.v](../projects/project_03/pipeline/tb/CPU_Pipeline_tb.v) 沒有 golden 比對。 |

`MEM_WB.v` 的 `end` 層級經逐行核對是正確的，不列為語法缺陷；能否成功 elaboration 以真正 Icarus compile 為準。

## Hazard：Program 2 與一般邊界不能混為一談

講義五條 Program 2 是 `sub $2,$1,$3; and $12,$2,$5; or $13,$6,$2; add $14,$2,$2; sw $15,100($2)`。最後一條依賴 `$2` 作 base，store data 是 `$15`。audit 注入 numeric registers `$1=20,$3=8,$5=15,$6=160,$15=CAFEBABE`，逐條 ISA golden 為：

| 觀察 | 期望 |
|---|---|
| `$2` | 12 |
| `$12` | 12 |
| `$13` | 172 |
| `$14` | 24 |
| store address／data | 112／CAFEBABE |

這組刻意保留為正向對照，原 forwarding 可能足以通過它；全部結果仍待 CI 確認。它不涵蓋 mixed-stage 雙操作數或立即相依的 store data。原 [PC.v:27](../projects/project_03/hazard/rtl/PC.v#L27) ROM 是其他四條短指令，不是講義 Program 2；bench 只替換測試時的內部 instruction 值，原 PC、pipeline、stall、ALU、WB 仍執行，沒有改原 ROM 檔案。

| 缺口 | source 行號與定向觸發 |
|---|---|
| signed `slt` 與回傳值錯誤 | [ALU.v:93](../projects/project_03/hazard/rtl/ALU.v#L93) 用 unsigned X/Y 比較、true 回全1。`1<2` 應是00000001，`FFFFFFFF(-1)<0` 也應為1；`0<FFFFFFFF(-1)` 應是0。 |
| `addi` WB 選到舊 memory 資料 | [Reg.v:286](../projects/project_03/hazard/rtl/Reg.v#L286) 的 addi MemtoReg_store=0；[CPU.v:70](../projects/project_03/hazard/rtl/CPU.v#L70) 內部0=memory、1=ALU。R-type／lw本身採此編碼是匹配的，只有addi應選ALU卻沒有。`addi $2,$1,-4`、`$1=20` 應寫16。 |
| Mixed-stage forwarding 不獨立 | [CPU.v:98](../projects/project_03/hazard/rtl/CPU.v#L98) 的整組 EX/MEM if 優先於 line116整組 MEM/WB else-if。rs需EX/MEM且rt需MEM/WB時應是10／01，反向應01／10；原邏輯只能選其中一組。 |
| Immediate 被 rt forwarding 覆蓋 | [ALU.v:28](../projects/project_03/hazard/rtl/ALU.v#L28) 先選 ALUSrc，line51–64又覆寫Y。store base20、offset4、rt bypass value12，地址應24；不能把 store datum12改當offset算32。 |
| Store data 缺 bypass | [CPU.v:65](../projects/project_03/hazard/rtl/CPU.v#L65) 把 raw Read_Data2 接入 EX/MEM；[EXandMEM.v:28](../projects/project_03/hazard/rtl/EXandMEM.v#L28) 原樣鎖存。用 sub產生12後接 `sw $2,12($6)`、`$6=160`，期望地址172且資料12。offset故意也取12，隔離與前一項地址錯誤，不能靠碰巧地址正確說 data path 正確。 |
| 連續同控制 memory 操作失效 | [Dmemory.v:32](../projects/project_03/hazard/rtl/Dmemory.v#L32) 的 sensitivity 只有 memwrite/memread，漏掉實際使用的 addr/write_data。控制維持1、只換address或data，第二筆讀／寫不重新計算。 |
| Memory address0 被當成空 slot | [Dmemory.v:16](../projects/project_03/hazard/rtl/Dmemory.v#L16) tags初值全0；line34把0當有效address，line45又當空slot。先存address0=AA再存address4=BB，第一筆會被覆蓋。這和 numeric register0 的語意無關。 |
| Register30 的第二讀埠讀錯 | [Reg.v:339](../projects/project_03/hazard/rtl/Reg.v#L339) rt=30讀sp，第一讀埠line146卻讀fp。以numeric r30=AA55、r29=55AA測試，r30第二讀應AA55。 |
| `j` 無 decode／target path | [Reg.v:235](../projects/project_03/hazard/rtl/Reg.v#L235) 的五種opcode case沒有j/default；[PC.v:40](../projects/project_03/hazard/rtl/PC.v#L40) 只有branch/PC4，CPU沒有jump target concatenation。先addi再給j還會保留前次RegWrite控制，不只是target沒切換。 |

其基本 load-use detector **有實作**：[CPU.v:77](../projects/project_03/hazard/rtl/CPU.v#L77) 接到 PC_Write、IF_ID_Write 和 Control_Slt。audit 保留 `lw $2,...` 後 `add $12,$2,$5` 的一個 stall 正向案例，以及兩個來源都取同一 EX/MEM／MEM/WB 的正向對照。`lw` 後緊接覆寫同rt的addi會不必要stall，這是性能觀察，不能單獨等同數值ISA錯誤。

hazard memory 只有六個帶 address tag 的 word slots，並非一般 array；容量及 miss沒有完整處理列為範圍限制。CPU沒有reset輸入，fixture先送5個NOP，再明確seed相關狀態；不宣稱替原CPU新增reset。Reg0可寫而forwarding排除dest0，是與其他variant不同的行為，未據此判FAIL。branch沒有flush的完整恢復功能也尚未由hazard CPU probe驗證。

## Strict／compatibility 編譯及重現邊界

[Reg.v:12](../projects/project_03/hazard/rtl/Reg.v#L12) 的 output directions 沒宣告向量range，後面的同名reg卻有32／5／2-bit range。Icarus預設要求相符；`-gno-io-range-error` 對這一類舊式scalar-port/vector-reg宣告降為warning，**不修source，也不等同strict通過**。此行為依 [Icarus 官方手冊的 io-range-error 選項](https://github.com/steveicarus/iverilog/blob/master/driver/iverilog.man.in)；實際strict診斷及兼容結果由CI記錄。

check script 首先對三個 original tops 及 original TBs 嚴格 compile-only。single／pipeline各有unit與whole-CPU probe；hazard另以明示 `-gno-io-range-error` compile及執行45個定向觀察。只有成功elaboration且probe正常完成才比較輸出；CPU的FAIL被列為診斷，missingtool、壞adapter、timeout或缺觀察則是audit失敗。

目前覆蓋：required五種R-type含負數slt、負addi/signextend、PC4、lw/sw合法slot、taken/not-taken beq、negative branch、j及single-cycle高nibble拼接；hazard為Program2、load-use stall/bubble、mixed-stage雙來源、immediate/store bypass、memory敏感度/address0、r30與缺j。沒有做形式驗證、完整MIPS exception／overflow trap／endianness／unaligned access、cache、任意長程式、完整hazard branch recovery或post-synthesis時序分析；不把有限probes寫成完整CPU認證。
