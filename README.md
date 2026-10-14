# 計算機組織 Final Project：Verilog 歸檔與規格檢查

依提供的四個目錄擷取 **115 個作者撰寫的 Verilog／testbench 檔案**，以指定 FinalProject 簡報作為共同檢查基準。原 RTL 功能保留；移除註解中的身分資料，並替含人名的 module／檔名使用通用別名。檢查報告記錄各版本的功能與缺陷。

| 來源順序 | 原目錄簡稱 | 檔案數 | 匿名 Verilog | 檢查報告 |
|---|---|---:|---|---|
| 1 | COMPUTER program FINAL | 10 | [project_01](projects/project_01) | [報告](reports/project_01.md) |
| 2 | final_pj | 56 | [project_02](projects/project_02) | [報告](reports/project_02.md) |
| 3 | 計組final project | 42 | [project_03](projects/project_03) | [報告](reports/project_03.md) |
| 4 | FInal project | 7 | [project_04](projects/project_04) | [報告](reports/project_04.md) |

第三組原始碼在 RAR 內，已僅取出 HDL；第一組 ZIP 與目錄中的十個 HDL 完全相同，因此只存一份。另略過四個工具自動產生的 `glbl.v`。第二、三組各自包含 single_cycle、pipeline、hazard 三種版本，分別檢查，不將各版本同名模組混在一起編譯。第一組的重名 EX、MEM 原檔也保留，報告會說明可用組合與衝突。

## 檢查範圍

核心基準是簡報要求的 `lw`、`sw`、`add`、`addi`、`sub`、`and`、`or`、`slt`、`beq`、`j`，及 A 單週期、B pipeline、C hazard detection 三個實作等級。各版本按其架構分開判斷；單週期版本不因沒有 C 等級單元而被當作單週期錯誤。

檢查包含編譯／elaboration、控制訊號、signed 立即數與比較、PC／branch／jump、memory addressing、pipeline 暫存控制及 forwarding／load-use。簡報範例有 400 與 40 的不一致，並使用自訂 t/s 暫存器別名；報告將這些差異與真正 RTL 缺陷分開，不直接混用標準 MIPS ABI。

完整結論請看四份報告，其中列出原檔位置、定向反例、可確認的功能與未驗證範圍。編譯成功、模組名稱含 Hazard，或原 testbench 能動，都不能單獨證明所有指令符合。CI 驗證這些檢查的可重現性；CPU 的合格與否由各份報告判定。

四組都發現至少一項必要功能缺陷，目前沒有可認定完整符合要求的版本：第一組缺 `slt`、memory bus 及 PC 目標有誤；第二組有 `addi` 記憶體副作用，管線版缺 `j`；第三組另有 hazard 的比較、轉傳與 memory 更新問題；第四組原頂層無法 elaboration。

[Linux CI 實跑](https://github.com/handsomegary/computer-organization-verilog-projects/actions/runs/38482714485)使用 Icarus Verilog 12.0／Python 3.12.15，五個查核工作全部完成。CI 綠燈代表原始碼完整性及已記錄的正反案例可重現；各 CPU 的缺陷仍保留在原檔中。第三組 hazard 的嚴格編譯失敗，另使用明示的 `-gno-io-range-error` 相容選項執行功能探測，詳見其報告。

## 重現檢查

需要 Python 3.12 和 Icarus Verilog（`iverilog`、`vvp`），Python 僅使用標準函式庫。

```sh
python checks/check_inventory.py
python checks/check_project_01.py
python checks/check_project_02.py
python checks/check_project_03.py
python checks/check_project_04.py
```

檢查程式在臨時目錄產生短 testbench、執行模擬並檢查已記錄結果；結束後自動清除。原 testbench 預設只做編譯檢查，避免無限時脈或沒有 `$finish` 的程式持續跑。GitHub Actions 在 Linux 安裝 Icarus 並執行全部檢查。

## 歸檔與容量

[inventory.json](inventory.json) 記錄所有公開檔案、來源順序、模組名稱及匿名版的 `archived_sha256`。原版對照已在上傳前完成：除註解及匿名識別字外，115 個 HDL 的 Verilog token 序列一致。

只從原資料取 HDL；其他專案設定、執行檔、PDF/PPTX、報告附件與波形都不收錄。新增加的小型檢查程式、檢查報告與 CI 用來記錄此任務的結果。沒有個人姓名、學號、原始私有路徑、VCD／波形圖片或大量模擬資料。
