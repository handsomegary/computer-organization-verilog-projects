# project_01 檢查報告

證據狀態：[Linux CI 實跑完成](https://github.com/handsomegary/computer-organization-verilog-projects/actions/runs/38482198455)，使用 Icarus Verilog 12.0／Python 3.12.15，26 個觀察與 15 拍時脈均與本頁基線一致。

**結論：未符合題目要求。** 套件包含可辨識的 IF／ID／EX／MEM／WB 連接，但不是已完成的單週期 CPU，也不能認定為正確的 pipeline 或 hazard detection 實作。缺少 `slt`，memory address 接線形成多重驅動，branch／jump 目標不符指令語意，原附 testbench 亦無法提供確定的初始寄存器值。

保留全部 10 份 Verilog；除隱私匿名化外沒有修補 CPU 功能。檢查腳本的 `AUDIT PASS` 表示能重現以下觀察與缺陷，**不是 CPU 通過 ISA 或作業驗收**。

## 建置範圍與兩個空白替代檔

主設計須明確選擇以下六檔：`CPU_Top.v`、`IF.v`、`ID.v`、`EX.v`、`MEM.v`、`WB.v`。

| 額外檔案 | 實際內容 | 建置／檢查處理 |
|---|---|---|
| [ALUcontrol.v:21](../projects/project_01/rtl/ALUcontrol.v#L21) | 無 port、無邏輯的 `module EX()` | 單獨可編譯；與 EX.v 一起編譯會 module 重名 |
| [DataMem.v:21](../projects/project_01/rtl/DataMem.v#L21) | 無 port、無邏輯的 `module MEM()` | 單獨可編譯；與 MEM.v 一起編譯會 module 重名 |
| [CPU_Alternate.v:25](../projects/project_01/rtl/CPU_Alternate.v#L25) | 包含 clock／reset、例化 CPU_Top 的 testbench | 不是另一套 CPU；分開做 compile-only 檢查 |
| [finaltb.v:25](../projects/project_01/tb/finaltb.v#L25) | 另一份只施加 clock／reset 的 testbench | 分開做 compile-only 檢查 |

兩份原 testbench 都持續產生 clock，沒有停止條件或正確性斷言，因此編譯成功或有數字顯示都不能證明功能正確。不可將所有 `.v` 盲目一起編譯，也不能刪掉重名空檔後假稱原套件沒有衝突。

## 實際時脈與 PC 結構

[CPU_Top.v:51](../projects/project_01/rtl/CPU_Top.v#L51) 的 CLKcounter 循環為 0→1→2→3→4→0；[71–81](../projects/project_01/rtl/CPU_Top.v#L71) 的 `always @(clk)` 只在 clk 改變時取舊 counter。因使用 NBA 更新 counter，PC_CLK 每五個主時脈產生一次有效上升緣；audit 逐拍核對前 15 拍。

[IF.v:33](../projects/project_01/rtl/IF.v#L33) 使用 PC_CLK，而 ID／EX／MEM／WB 都使用每拍的 clk。結果是取指一次、後面階段仍連續處理數拍同一條指令；沒有 instruction-valid 或隨指令動態控制的 stall。這是混合時脈、部分 pipeline 型的組合，不是 A 級單週期，也不能以「有五個階段名稱」當作 B 級正確 pipeline。

`pc` input 在 [IF.v:35–49](../projects/project_01/rtl/IF.v#L35) **只用於 reset 設定起始 PC**；其後內部 newpc 自增。原 testbench 不回授 NEWPC 並不是本設計的 PC 停止原因。真正的 PC 問題是以下 branch／jump 目標。

## 主要缺陷及可重現證據

| 缺陷 | 原始程式位置 | audit 觀察／正確語意 |
|---|---|---|
| MEM 的地址方向錯誤，ALU net 多重驅動 | [MEM.v:39](../projects/project_01/rtl/MEM.v#L39)、[CPU_Top.v:146–173](../projects/project_01/rtl/CPU_Top.v#L146) | MEM 把 Alu_result 宣告為 output reg，且從未賦值；同一 net 也接 EX output。MEM 端地址與 top ALU bus 為 X，無法正常選 memory word |
| `slt` 未實作 | [EX.v:54–98](../projects/project_01/rtl/EX.v#L54) | 先做 or 得 7，再送 `slt`、operands -1 與 1，結果仍 7；signed slt 應為 1 |
| jump 未 reset、未在其他指令清除 | [EX.v:41–44](../projects/project_01/rtl/EX.v#L41)、[96–98](../projects/project_01/rtl/EX.v#L96) | reset 後 jump 是 X；j 之後為 1，接續 add 仍為 1。beq 成立後再 j 時 branch 也留下 1 |
| sw／beq 的第二個來源沿用舊值 | [ID.v:91–118](../projects/project_01/rtl/ID.v#L91) | R-type 先讀 r2=22；後續 sw 的 rt=r7（應為 72）仍讀到 22；beq r7,r7 變成 72 與 22，破壞相等判斷 |
| lw 目的控制訊號來源錯誤 | [ID.v:98](../projects/project_01/rtl/ID.v#L98) | Write_Reg_lw 從 Read_data_mem 的低 5 bits 取 26，沒有從 instruction.rt 取 7。此線在目前 top 中未使用，所以不能誤稱它直接決定目前 WB 的目的寄存器 |
| branch 以指令字當 PC | [IF.v:45–46](../projects/project_01/rtl/IF.v#L45) | 回到 `8c200000`，該值是 lw 指令字；以 PC=24、offset=-5 為例，正確目標是 24+4-20=8 |
| jump 以指令字當 PC | [IF.v:42–44](../projects/project_01/rtl/IF.v#L42) | 回到 `08000019`，非 word-aligned target。該 j 的 index=25，這個 PC 區間的正確目標是 100 |
| j 解碼遺漏且末段條件不可達 | [ID.v:120–121](../projects/project_01/rtl/ID.v#L120) | 末段又測 lw opcode 35，早已被前面分支處理；opcode 2 不進入任何地址解碼，sign_extend 保留前一條 -4 |
| 寄存器啟始條件未提供 | [WB.v:27–66](../projects/project_01/rtl/WB.v#L27)、兩份原 testbench | 沒有 register 初始化或 reset，原 testbench 只施加 CPU reset；r1 等仍從 X 開始，例題需要的 s0／累加器起始值也未建立 |
| debug s 系列別名反向 | [CPU_Top.v:92–97](../projects/project_01/rtl/CPU_Top.v#L92) | 依 PPT 自訂別名，s0 應為 r6、s5 應為 r11；測試設 bankN=100+N，實際 s0=111、s5=106，正好相反 |

MEM 的 case 另以 0..10 直接選 word，沒有 byte-address 到 word-index 的轉換（[MEM.v:65–92](../projects/project_01/rtl/MEM.v#L65)）。這與程式的 PC+4、lw/sw 位移 -4 配合不完整；目前地址本身未驅動，先以介面錯誤為主要失敗，不把尚未正常供給的地址強制修成 input 後假稱 CPU 已正常跑 memory。

R-type WB 還直接讀目前 EX 的 Alu_result，而 instruction_Mem 經過 MEM 的註冊延遲（[CPU_Top.v:169–185](../projects/project_01/rtl/CPU_Top.v#L169)、[WB.v:49–63](../projects/project_01/rtl/WB.v#L49)）。缺少與 tag 同步傳到 WB 的 R-type 結果暫存器，不能將控制字與結果視為已正確沿 pipeline 對齊。

## 十個指定指令的狀態

| 指令 | 隔離單元／整體判斷 |
|---|---|
| add、sub、and、or | EX 的隔離 arithmetic probes 正確；整體 ALU bus、WB tag 與初始化問題仍阻止 CPU 驗收 |
| addi | ID 的負數 sign extension 與 EX 的 12+(-4)=8 可重現；整體 memory passthrough 與寄存器狀態仍有問題 |
| slt | EX 沒有對應 funct 0x2a 分支，明確失敗 |
| lw | MEM 地址方向錯誤、讀取地址未知；目的 control 線亦錯誤 |
| sw | MEM 地址錯誤，加上 ID 的 rt operand 為舊值 |
| beq | rt operand 舊值、PC 目標固定指令字，明確失敗 |
| j | 地址固定指令字、jump 黏住且不 reset，明確失敗 |

WB 把所有 opcode=0 都視為寫回，在 instruction=0 的 probe 中仍將 r0 寫成外部提供的 ALU 值 123（[WB.v:49–52](../projects/project_01/rtl/WB.v#L49)）。這是沒有 bubble／RegWrite 控制的觀察。PPT 把 t0 別名設在 r0，不能在沒有澄清前只拿標準 ABI 的 t0=8 來判斷；此報告也不以「全部 registers 必須 reset 為零」當作普遍 ISA 規則。

## ROM 與 PPT 程式的具體差異

PPT 一頁寫 immediate 400，另一頁寫 40，且同頁註解再次寫 400；這是說明本身的矛盾，不能僅憑 40 與 400 不同就判 CPU 錯。程式應具備正確 immediate 語意，而不是把其中一個數字寫死成答案。

PPT 自訂別名是 t0..t5=r0..r5、s0..s5=r6..r11；以下直接解碼目前 ROM 字，不套用一般 ABI：

| 位址 | 指令字 | 解碼 | 與程式需求的差異 |
|---:|---|---|---|
| 4 | 21610028 | addi r1,r11,40 | PPT s0 是 r6，top 卻把 s0 接 r11 |
| 8 | 8c200000 | lw r0,0(r1) | 範例 lw s1 應使用 PPT 的 r7 |
| 12 | 012a4820 | add r9,r9,r10 | 範例 s2/s1 為 r8/r7，非這組 register index |
| 16 | 203ffffc | addi r31,r1,-4 | 不是 addi r1,r1,-4；WB 根本沒有 r31 case |
| 20 | 002b082a | slt r1,r1,r11 | 不是 PPT 的 r2,r1,r6，且 EX 未實作 slt |
| 24 | 105ffffb | beq r2,r31,-5 | r31 來源沒有完整支援，且 branch PC 更新錯誤 |
| 28 | 08000019 | j index25，target100 | IF 直接把整個指令字當 PC |
| 104 | 950b4025 | opcode 0x25 | 不是指定的 R-type or；EX 沒有實作該 opcode |
| 108 | 00832022 | sub r4,r4,r3 | 這條個別編碼與指定 sub 相符 |
| 112 | 00e43824 | and r7,r7,r4 | 不是範例 t5=r5 與 s4=r10 的 and |
| 116 | acc00000 | sw r0,0(r6) | 不是範例 sw r5,0(r11) |

這些是機器字本身的字段解碼，不以學生註解推定功能。所有 ROM entries 原樣保留在 [IF.v:57–69](../projects/project_01/rtl/IF.v#L57)。

## Program 2 與 C 級 hazard 要求

指定 Program 2 使用數字 register，而非 t/s 別名：

```text
sub r2,r1,r3
and r12,r2,r5
or  r13,r6,r2
add r14,r2,r2
sw  r15,100(r2)
```

後四條對 sub 新產生的 r2 有 RAW dependency：and 的第一來源、or 的第二來源、add 的兩個來源、sw 的 base address。此套件沒有比較 pipeline destination 與 source 的 hazard unit、動態 stall、flush 或 forwarding 選擇器；固定每五拍取指不能當作這些機制。

更直接的限制是 [WB.v:34–63](../projects/project_01/rtl/WB.v#L34) 只保存／選擇 r0..r11，Program 2 必須寫的 r12、r13、r14 沒有 case 或儲存位置。ID 也只列出 r0..r11；probe 請求 rs=r12 時沿用先前 r6=62，而非讀取新的寄存器。即使暫時忽略 RAW，仍不能完整執行指定 Program 2。不能因初始化一些低索引寄存器後有幾筆 arithmetic 值，就認定 C 級通過。

## 可重現檢查

從 repo 根目錄執行：

```sh
python checks/check_project_01.py
```

需要 iverilog／vvp，或設定 IVERILOG／VVP 工具路徑。腳本會實際：

1. 分別編譯兩個空白 EX／MEM，並確認與真正模組一起編譯時的重名錯誤。
2. 用明確六檔清單，分別確認兩份原 testbench 的 elaboration。
3. 在原 RTL 上執行 26 個狀態／單元觀察與 15 拍 core clock 觀察，重現上述缺陷；以獨立 signed slt、branch、jump、rt register 值計算預期偏差。

只有別名觀察暫時由 testbench 設 bankN=100+N，目的是判斷線路映射；不把此測試刺激當作原 CPU 自帶的初始化。所有 probe、編譯產物與 simulator capture 位於暫存目錄，測完清除。沒有波形、VCD、大 log 或 CPU 功能修補。
