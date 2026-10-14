# 計算機組織 Final Project：原碼與可執行修正版

下載本 repo 後，可直接使用 [repaired/](repaired/README.md) 中的五個修正版及重新撰寫的 A／B／C 參考實作。完整 RTL、testbench、測資產生器與驗證入口均已收錄；從 repo 根目錄執行 `python repaired/verification/check_all.py` 即可重跑 **173／173** 項驗證。需要 Python 3 與 Icarus Verilog（`iverilog`、`vvp`），沒有額外 Python 套件。

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

歷史原版四組都發現至少一項必要功能缺陷：第一組缺 `slt`、memory bus 及 PC 目標有誤；第二組有 `addi` 記憶體副作用，管線版缺 `j`；第三組另有 hazard 的比較、轉傳與 memory 更新問題；第四組原頂層無法 elaboration。這些原版仍完整保留在 `projects/`。可用修正版已另外補在 `repaired/`：第二組 A／B／C、第三組 A／B 保留原架構修正；第一組、第四組及第三組原 hazard 需大幅重作，請採用 `repaired/reference/rtl/` 的新參考實作。

[Linux CI 實跑](https://github.com/handsomegary/computer-organization-verilog-projects/actions/runs/38482714485)使用 Icarus Verilog 12.0／Python 3.12.15，五個查核工作全部完成。CI 綠燈代表原始碼完整性及已記錄的正反案例可重現；各 CPU 的缺陷仍保留在原檔中。第三組 hazard 的嚴格編譯失敗，另使用明示的 `-gno-io-range-error` 相容選項執行功能探測，詳見其報告。

## 執行修正版

從 repo 根目錄執行：

```sh
python checks/check_repaired_package.py
python repaired/verification/check_all.py
```

第一個命令核對完整套件、來源 SHA-256 及所有案例依賴；第二個實際編譯並模擬，任一功能失敗都回傳非零。測資及預期 memory 檔案由已收錄的 Python runner 即時產生。編譯產物預設放在 `repaired/.verification-build/`，不需要從其他 repo 取得檔案。快速示範、Windows 可攜工具參數與各版本介面請看 [修正版入口](repaired/README.md)。

本套件來自 [computer-organization-final-verilog-review](https://github.com/handsomegary/computer-organization-final-verilog-review/tree/012b371e2ad6fd768170ad6aa9bc32254aadad04) 的已驗證提交。146 個 tracked files 全部納入，RTL、testbench 與產生器逐位元組保留；六份歷史 JSON 報告僅將絕對主機路徑換為通用標記。[來源與檔案雜湊](repaired/package-source.json) 同時記錄上游及套件版本，原 repo 的 `projects/` 與 `reports/` 不變。此次整合實跑 38 個回歸、97 個新參考、22 個 pipeline 與 16 個壓力案例，全部通過。CI 另設修正版工作，與歷史原版查核分開。

## 重現歷史原版查核

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

`projects/` 只從原資料取 HDL；其他 FPGA 專案設定、執行檔、PDF/PPTX、報告附件與波形不收錄。`repaired/` 另含完整可執行模擬套件與已清理主機路徑的歷史驗證報告，不含 `.git`、build、波形、執行檔或大量產生的測資。FPGA 綜合、timing closure、實體板驗證及課程繳交報告不在此模擬套件範圍。
