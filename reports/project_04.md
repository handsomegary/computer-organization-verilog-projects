# project_04 檢查報告

證據狀態：[Linux CI 實跑完成](https://github.com/handsomegary/computer-organization-verilog-projects/actions/runs/38482198455)，使用 Icarus Verilog 12.0／Python 3.12.15，頂層與原 TB 的編譯失敗，以及 EX／IF／ID／MEM 正常案例和反例均已再現。

## 結論

**目前不符合完整專案要求。** 有 IF、ID、EX、MEM、WB 五個時脈模組，但原頂層具名埠接錯，無法完成 elaboration；獨立模組也存在固定 branch/jump 目標及錯誤 forwarding 判斷。原 RTL 已保留，沒有將修正版替換進歸檔。

## 編譯與架構

- [Main.v:138](../projects/project_04/rtl/Main.v#L138) 使用 EX 的 `.Alu_result(...)`，而 [Execution.v:2](../projects/project_04/rtl/Execution.v#L2) 宣告的是 `result`。
- [Main.v:152](../projects/project_04/rtl/Main.v#L152) 使用 MEM 的 `.result(...)`，而 [Memory_Access.v:2](../projects/project_04/rtl/Memory_Access.v#L2) 宣告的是 `Alu_result`。
- Main 的 `Alu_result` 又沒有對應的 32-bit wire 宣告，容易形成單位元 implicit net；修改埠名時仍需核對資料線寬度。這份檢查沒有直接代改。
- 原 `ha` 頂層與 `ha_tb` testbench 在 Icarus 12.0 都無法 elaboration。單獨 EX、IF、ID、MEM 已完成定向模擬；單元結果不代表整合 CPU 可執行完整程式。

## 指令與功能

| 項目 | 已驗證或可由原碼確認的行為 | 判定 |
|---|---|---|
| add/sub/and/or | EX 在非特殊輸入 7、5 時分別得到 12、2、5、7 | 基本單元案例正確，仍有值 2 的缺陷 |
| slt | signed `-1 < 1` 得 1 | 這個 signed 邊界案例正確 |
| addi | 7 加 sign-extended −4 得 3；ID 輸出 FFFFFFFC | 一般案例正確，base 值 2 仍受錯誤 forwarding 影響 |
| lw/sw | 只列舉位址 0、4、…、40，地址 0 寫 17 後可讀回 | 容量／地址限制；位址 100 寫 99 後讀取仍保留舊 17 |
| beq | EX 的相等資料會拉高 branch | IF 未按指令 offset 算目標，固定設 PC=16 |
| jump | EX 會拉高 jump | IF 未組合指令 target 與 PC 高位，固定設 PC=104 |
| 寄存器 decode | rs=1 讀到指定 reg1=11；接著 rs=0 仍讀到 11 | rs=0 沒有合法 case，保留舊值 |
| hazard | 用運算元**數值**是否為 2 判斷 forwarding | 不等同目的／來源寄存器編號比較，沒有完整 forwarding/stall |

### 值 2 不是寄存器編號 2

[Execution.v:51](../projects/project_04/rtl/Execution.v#L51) 等處比較 `Read_data1==5'b00010` 或 `Read_data2==5'b00010`。這兩個輸入是 32-bit 資料，值剛好等於 2 也會誤走 forwarding 分支。`RESULT` 的保存只由 `ins_reg` 的事件與 rd=2 決定，且沒有 reset，不能代表一般 EX/MEM 或 MEM/WB 的有效目的暫存器。

定向案例用普通 `add`、rs=1、rt=3、rd=4，資料為 2、5，應得到 7；原碼取得未正確保存的 RESULT，模擬結果不等於 7。這個缺陷也影響 sub、and、or 和以 2 為 base 的立即數／存取計算。

### 控制流與記憶體

[Instruction_Fetching.v:22](../projects/project_04/rtl/Instruction_Fetching.v#L22) 和 [Instruction_Fetching.v:24](../projects/project_04/rtl/Instruction_Fetching.v#L24) 將 jump、branch 目標直接設為 104、16。從 PC=80 reset 後普通下一拍是 84，但 branch 直接變 16，jump 直接變 104。沒有使用 `PC+4+signext(imm)<<2` 或指令 jump target，無法作一般指令的控制流。

[Memory_Access.v:49](../projects/project_04/rtl/Memory_Access.v#L49) 及讀取 case 只支援十一個位址。指定的 hazard 範例有 `sw $15,100($2)`，這份有限地址列舉不足以支援其一般結果；沒有 default 地址处理，無效 load 会保留前次讀值。

### 自訂別名與未覆蓋寄存器

PPTX 使用自訂 t/s 別名，應與標準 MIPS ABI 分開看。本實作 [Main.v:75](../projects/project_04/rtl/Main.v#L75) 把 s5..s0 依序接 reg6..reg11，與簡報所列 s0..s5→6..11 的順序相反；ID/WB 又將 reg0 指到欄位編號 12，而沒有 rs/rt=0 分支。這是資料對應差異，不用「標準 $zero 必須不變」作額外扣分。

ID/WB 只列部分欄位編號，沒有涵蓋簡報 hazard 範例所用的全部 register indices。應先統一 numeric register fields 與輸出別名，再驗證整個程式。

## 重現方式與範圍

```sh
python checks/check_project_04.py
```

此命令在暫存目錄編譯原頂層／testbench，確認已發現的 elaboration 問題，再獨立跑 EX、IF、ID、MEM 的正常案例與反例。全部 compile／模擬產物自動刪除，沒有 VCD、波形圖或大量輸出檔。

CI 驗證這份檢查可重現；整合 CPU 的狀態仍是本頁所列不符合。未驗證項目包括修正接線後的完整退休指令序列、全 ISA 邊界及完整 load-use／branch flush，沒有把單元案例推廣成全功能保證。
