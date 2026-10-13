# project_02：三個 MIPS 版本的原碼查核

本報告只記錄匿名封存 HDL 的介面、架構與可重現問題，**沒有修正其功能，也不把查核腳本成功視為 CPU 正確性通過**。基準是提供的作業投影片；原始碼保留於 `projects/project_02`。

目前本機已完成來源證據檢查與獨立 ISA 模型核對。Icarus 尚未在本機使用，以下 HDL 編譯／模擬觀察均列為**待 Linux CI 實跑確認**，不宣稱已執行成功。CI 的目的包括確認健康元件和再現已知缺陷；它會在封存行為與報告預期不同時失敗，而不是把錯誤 CPU 的功能偷偷修成正確。

## 檢查基準與範圍

要求的十種指令是 `lw, sw, add, addi, sub, and, or, slt, beq, j`。使用 32-bit 數值、PC+4、16-bit 立即數符號延伸；beq 目標為 PC+4 加 sign-extended immediate×4，j 為 `{(PC+4)[31:28],index26,2'b00}`。沒有由原投影片推導出例外／陷阱的額外要求；本檢查的 add/sub 用低 32 位數值。

投影片的 loop 例子在兩頁分別使用 400 與 40，又在旁註保留 +400；不能默認它們相同。投影片的自訂 alias 是 t0→0、t1→1、…、t5→5、s0→6、…、s5→11，不是標準 MIPS ABI 的 t/s register 編號。故檢查用數字暫存器，參考模型不強制 r0 不可寫；定向 HDL 程式避免寫 r0，也不把原碼的 r0 寫入保護當成自訂例子的正確性判定。

原 C 題程式以數字暫存器核對：

```text
sub $2,$1,$3
and $12,$2,$5
or  $13,$6,$2
add $14,$2,$2
sw  $15,100($2)
```

為避免地址範圍遮蔽相依問題，該定向測試令 r1=4、r3=44，得到 r2=−40，因此 store 的 byte address 是 60；另設 r5=3、r6=8、r15=55。期望 r2=FFFFFFD8、r12=00000000、r13=FFFFFFD8、r14=FFFFFFB0，記憶體 byte address 60 的資料為 55。封存陣列直接以 byte address 索引，故觀察標為「raw slot60」，與採 word index 的 array[15] 區分。

本次不使用原作者檔名、身分、報告或評比；沒有新增作業說明文件。所有產物在暫存目錄刪除，不產生波形、VCD、圖片、長 log 或公開展開向量。

## 介面與架構

| 版本 | 頂層 | 必需輸入 | 主要輸出／架構 |
|---|---|---|---|
| single_cycle | CPU_SingleCycle | CLK、RST | 八個 32-bit 資料路徑觀察值（含 PC_NEXT）；單週期 PC／IM／RF／ALU／DM |
| pipeline | CPU_Pipeline | CLK、RST | PC_NEXT、PC+4、ID/EX 資料、ALU、WB 等 32-bit 輸出，Write_Addr_Mem_WB 為 5 bits；IF/ID、ID/EX、EX/MEM、MEM/WB |
| hazard | CPU_NoHazard | CLK、RST | PC_NEXT 與資料路徑 32-bit 值、FORWARDA/B 各 2 bits、三個 write-address 各 5 bits；五級管線、forwarding 與 load-use 控制 |

各版名為 PC_NEXT 的埠實際接 PC 元件的 **PC_OUT**，所以是目前 PC，而不是提前一拍的 next-PC 預測。RST 為高有效非同步 reset。single_cycle 的 RF 在上升緣寫；pipeline、hazard 的 RF 在下降緣寫，管線暫存器在上升緣更新。指令 ROM 以 PC[31:2] 取 word。

single_cycle 使用一般 MemToReg 方向：0 選 ALU、1 選 DM。pipeline/hazard 的數值慣例相反：1 選 ALU、0 選 DM，但其 WB mux 的 IN0/IN1 也相反，兩者彼此一致，**這本身不是缺陷**。

## 已確認來源問題與信心

「高」代表能由可辨識原碼直接確認該結構／控制設定，不表示本機已經完成 HDL 模擬。

| 編號 | 問題與影響 | 來源定位 | 信心 |
|---|---|---|---|
| P02-01 | 三版 addi 都把 MEMWRITE 設為 1。addi 本應只寫暫存器，卻可能把舊 rt 寫入以算術結果作位址的資料記憶體；算術答案看似對也不代表沒有記憶體副作用。 | [single Controller:50](../projects/project_02/single_cycle/rtl/Controller.v#L50)、[pipeline CONTROLLER:47](../projects/project_02/pipeline/rtl/CONTROLLER.v#L47)、[hazard Controller:49](../projects/project_02/hazard/rtl/Controller.v#L49) | 高 |
| P02-02 | 三版 DM 直接用完整 ADDR 當 0..63 陣列索引。可視為「byte address 的稀疏 word 槽」抽象；在有效 aligned 地址下，sw/lw 都用相同索引，並不表示每次 load 都錯。限制是只有 aligned byte address 0,4,…,60 的 16 個 word 位置可用，不等於通常 64-word 陣列用 ADDR>>2 可涵蓋 0..252。地址 100、252、400 都越界。byte16 寫 raw word16 而非一般模型 word4 是布局差異，與超出範圍分開看。 | [single DM:12–14](../projects/project_02/single_cycle/rtl/DataMemory.v#L12)、[pipeline DM:12–14](../projects/project_02/pipeline/rtl/DATAMEMORY.v#L12)、[hazard DM:12–14](../projects/project_02/hazard/rtl/DataMemory.v#L12)，寫入在各檔 29 行 | 索引／範圍高；單次值是否不符須看抽象慣例 |
| P02-03 | DM reset 迴圈是 i<63，只清 0..62；宣告的 word63 未清。這是 reset 邊界遺漏，不由 ISA 自動要求全部記憶體都需 reset。 | 三個 DM 的 22–24 行 | 高 |
| P02-04 | pipeline／hazard Controller 無 jump opcode/control，頂層也沒有 jump target concat 或 jump mux。必要的 j 沒有實作；不能因 SingleCycle 另有 jump，就把該功能算到另兩版。 | [pipeline Controller:52–70](../projects/project_02/pipeline/rtl/CONTROLLER.v#L52)、[pipeline top:90–92](../projects/project_02/pipeline/rtl/CPU_PIPELINE.v#L90)、[hazard Controller:54–72](../projects/project_02/hazard/rtl/Controller.v#L54)、[hazard top:101–106](../projects/project_02/hazard/rtl/CPU_NoHazard.v#L101) | 高 |
| P02-05 | hazard 的 ALU 第二暫存器輸入有 forwarding，但 EX/MEM 的 store-data 接的是未轉傳 READ_DATA_2_ID_EX。`add r2,r1,r3; sw r2,0(r4)` 可把舊 r2 寫入，與 ALU operand-B forwarding 正常並不矛盾。 | [hazard top:75–89](../projects/project_02/hazard/rtl/CPU_NoHazard.v#L75)，尤其 89 行；DM 接線在 94–95 行 | 高 |
| P02-06 | pipeline／hazard 的 taken beq 直到 EX/MEM 才選 PC，沒有沖刷更年輕的指令。在本檢查的「不採分支延遲槽」模型下，後續錯誤路徑 addi 仍會提交。此約定需明列；不能暗把三個 delay slots 當成原題已允許。 | [pipeline top:76–92](../projects/project_02/pipeline/rtl/CPU_PIPELINE.v#L76)、[hazard top:86–106](../projects/project_02/hazard/rtl/CPU_NoHazard.v#L86) | 結構高；行為待 CI |
| P02-07 | hazard ROM 只指定 0..8，清零迴圈從 12 起，9..11 留 X。它的內建程式也不是投影片 C 的五條原指令，不能用該 ROM 的波形宣稱原 C 範例已測。 | [hazard IM:27–39](../projects/project_02/hazard/rtl/InstructionMemory.v#L27) | 高 |
| P02-08 | load-use 判斷把 IF/ID.rt 一律視作來源，缺 opcode/source-use 判斷。`lw r2,...; addi r2,r3,5` 中第二個 r2 是目的而非讀取，仍會多停一拍。這是性能／精確 stall 判定問題，不是已證明會算錯。 | [Hazard_detection_unit:12–22](../projects/project_02/hazard/rtl/Hazard_detection_unit.v#L12) | 高 |

400-byte loop 與 40-byte loop 的地址範圍不同；64-word DM 在通常 word-array[ADDR>>2] 模型下也不能完整容納以 400 為起點的整段範例。該模型是明示的比較慣例，不是指投影片明定了實際陣列布局。原碼的稀疏索引可以容納 40-byte 版本的 aligned 地址，卻無法直接存取 100 或 400；容量差異不能擴大成「所有 lw/sw 數值都錯」。單週期內建 sw/lw 的 base 19 加 4 會產生未對齊地址 23，原碼稀疏槽仍可自洽讀寫，但不是一般 word-aligned MIPS 範例；查核改用獨立、對齊的輸入，不修其 ROM。

## 能由來源確認的已實作部分

- ALU 有 add、sub、and、or、signed slt，額外 nor 不在必要集合中；slt 的 IN0/IN1 宣告為 signed，不能誤判成 unsigned。
- Sign_Extend 保留立即數 bit15；兩個 shift helpers 用 concat 補兩個低位零。single_cycle 的 branch 使用本指令 PC+4 加位移，jump 使用 PC+4 高四位拼 index26<<2。
- pipeline/hazard 有四組 stage registers，branch 位址沿 ID/EX、EX/MEM 傳遞；WB 選擇與其反向 MemToReg 慣例一致。
- ForwardingUnit 的 EX/MEM=10 優先於 MEM/WB=01，雙邊來源可分別選擇；load-use unit 能關 PCWrite、IF/ID write，並讓 Controller 產生零控制 bubble。單元存在不等於 store-data、branch/jump 或所有 dependency 都正確。
- pipeline B 沒有 forwarding 是架構層級差異，不能直接用 C 的未排程相依程式對它作完整正確性扣分。仍須用適當排程測其必要 ISA；此查核只對明確的 jump 缺漏與無延遲槽 branch probe 記錄不符。

## 可重跑查核

從儲存庫根目錄執行：

```sh
python checks/check_project_02.py
python checks/check_project_02.py --variant single_cycle
python checks/check_project_02.py --variant pipeline
python checks/check_project_02.py --variant hazard
python checks/check_project_02.py --static-only
```

預設需要 Icarus 的 iverilog/vvp，可用環境變數 IVERILOG、VVP 指定工具。缺工具時不宣稱模擬通過；`--static-only` 明確只核來源模式與獨立 Python ISA oracle。沒有改 HDL、插入修復 wire 或取代原模組。

腳本將三個 variant 分開編譯，避免同名模組互相混用。每版先 compile 原 TB+RTL（不跑無 assertion 或無 finish 的原 TB），再把少量新 probe 寫到暫存目錄。探測程式覆寫**模擬中的 IM/RF 初值**以隔離測資，但不寫回原檔；這是刺激，不是修原電路。

未使用的 IM 槽填入十指令集合內的 `or $31,$31,$31`，只把 r31 原值寫回自身；獨立模型使用同一填充指令，避免依賴未支援的零指令或 r0 寫入保護。

| Probe | 對照的正確模型／預期封存觀察 | CI 的成功含義 |
|---|---|---|
| ALU、decoder、符號延伸、負 branch 位移 | 五種必要 R-type、addi/lw/sw/beq、FFF8→FFFFFFF8、PC4+位移→FFFFFFE4 | 健康的局部操作仍可重現 |
| addi MEMWRITE、DM word63、byte index／100／252／400 | 控制錯誤、reset 遺漏、索引布局與越界觀察旗標均為 1 | P02-01..03 的具體限制重現，**不是需求通過**，亦不把布局差異當成所有 load 數值錯 |
| j 跳過錯誤路徑 addi | 正確 r4=0；single 預期 0，pipeline/hazard 預期 99；目標 r5=7 | 缺失 jump 可重現 |
| taken beq 跳過錯誤路徑 addi | 無 delay-slot 模型 r4=0；single 0，兩管線 99；目標 r5=7 | 不沖刷的限制可重現 |
| hazard forwarding/stall 單元 | EX/MEM 優先，MEM/WB 後選；load-use 控制三個 0，正常三個 1；rt-only 也停 | 健康 forwarding 與額外 stall 分開核對 |
| `add→sw` 的相鄰 store 資料 | 正確 r2=12、memory[0]=12；封存預期 r2=12、memory[0]=0 | 缺 store-data forwarding 可重現 |
| `lw→add` load-use | memory byte0=21，add r3=r2+r2=42，至少停一拍 | 這組特定 load-use 行為可重現 |
| 投影片 C 五指令 | 上述 r2/r12/r13/r14，並觀察 archive raw slot60=55 | 檢查這組 forwarding 程式的結果；有限位址範圍另列 |

probe 內建有 `$fatal` 及有界停止；CI 只印短摘要，不保存完整模擬紀錄。任何預期封存行為不同、編譯失敗、模擬超時或沒有觀察值都會讓腳本失敗。成功摘要刻意寫 `ARCHIVE FINDINGS REPRODUCED`，不寫 CPU PASS。

## 實際證據狀態與限制

本機已執行三版 `--static-only` 與獨立 ISA oracle，來源證據一致。HDL compile、局部 simulation 和 integration probe 均待有工具的 Linux CI；沒有用 Python 代替 RTL 測試結果。

這是定向查核，不是完整 MIPS 符合性驗證：未窮舉所有 instruction/data combinations，未驗證 exception、所有記憶體邊界、所有控制相依或完整效能。未用原 TB 的顯示波形作為正確性證據；原 TB 只有時脈／reset 驅動，hazard 原 TB 沒有結束條件。若未來原始碼改變，應重新核對觀察基線，不要把新行為硬改成此報告的錯誤結果。
