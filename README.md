# 計算機組織 Final Project：原碼與可執行修正版

下載本 repo 後，可直接使用 [repaired/](repaired/README.md) 中的五個修正版及重新撰寫的 A／B／C 參考實作。完整 RTL、testbench、測資產生器與驗證入口均已收錄；從 repo 根目錄執行 `python repaired/verification/check_all.py` 即可重跑 **173／173** 項驗證。需要 Python 3 與 Icarus Verilog（`iverilog`、`vvp`），沒有額外 Python 套件。

依提供的四個目錄擷取 **115 個作者撰寫的 Verilog／testbench 檔案**，以指定 FinalProject 簡報作為共同檢查基準。原 RTL 功能保留；移除註解中的身分資料，並替含人名的 module／檔名使用通用別名。檢查報告記錄各版本的功能與缺陷。

| 來源順序 | 原目錄簡稱 | 檔案數 | 匿名 Verilog | 檢查報告 |
|---|---|---:|---|---|
| 1 | COMPUTER program FINAL | 10 | [project_01](projects/project_01) | [報告](reports/project_01.md) |
| 2 | final_pj | 56 | [project_02](projects/project_02) | [報告](reports/project_02.md) |
| 3 | 計組final project | 42 | [project_03](projects/project_03) | [報告](reports/project_03.md) |
| 4 | FInal project | 7 | [project_04](projects/project_04) | [報告](reports/project_04.md) |

表內第三組是 RAR 變體；另已收錄不同的 [ZIP 變體](projects/project_03_zip_variant)，完整保留 34 個 single_cycle／pipeline HDL 原始位元組。它的 32 個檔案與第二組原始來源相同，兩個 ROM 不同；與本 repo 先前去除註解的匿名版逐位元組比較則有 18 個相同，不能混稱。第一組 ZIP 與目錄中的十個 HDL 完全相同，因此只存一份。略過工具自動產生的 `glbl.v`。第二、三組 RAR 各自包含 single_cycle、pipeline、hazard 三種版本，分別檢查，不將各版本同名模組混在一起編譯。第一組的重名 EX、MEM 原檔也保留，報告會說明可用組合與衝突。

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

`projects/` 保留原有 115 個匿名 HDL、另外 34 個 ZIP 原始 HDL，以及六份可攜式原 Vivado XPR 和一份被 XPR 引用的 waveform 設定。XPR 只調整私人主機路徑及指向已收錄檔案的相對路徑，保留 filesets、top、generics、FPGA part、Vivado version 與其他設定；它們是經路徑處理的副本，並非原 XPR 位元組。[vivado-materials.json](vivado-materials.json) 記錄原來源／公開檔 SHA-256、允許的路徑變更及所有 98 個檔案引用。第三組本機 XPR 缺少的 `.srcs` 由其 ZIP 對應來源補齊，沒有使用 ROM 不同的 RAR 變體替代。

`repaired/` 的 146 個來源套件檔案與 provenance 保持不變。Vivado 的 cache、runs、生成的 simulation、工具執行檔與學生繳交報告未複製；FPGA 綜合、timing closure 及實體板驗證尚未執行。

## 官方題面與完整附件

[原版 FinalProject 簡報](originals/計算機組織FinalProject.pptx) 完整保留原始位元組，含 9 張投影片與 5 個嵌入圖片；沒有外部圖片／資料檔連結。投影片內已提供 ISA、A／B／C 規格與程式例子，繳交用 RTL、top testbench、報告是學生須製作的成果。[specifications.json](originals/specifications.json) 記錄 SHA-256 及引用分類。

```sh
python checks/check_course_specification.py
python checks/check_inventory.py
python checks/check_vivado_materials.py
python scripts/check_vivado_sim.py
```

可直接開啟的歷史 XPR 在各組 `original_project/`；[清單](vivado-materials.json) 指向六份檔案。這些 XPR 對應有缺陷的歷史原碼，適合查閱原始設定。需要得到通過驗證的結果，請使用下述修正版流程。

## Vivado 模擬入口

從 repo 根目錄執行，預設 `reference` 會一起編譯 `repaired/reference/rtl/mips_single_cycle.v`、`mips_pipeline.v` 和 `repaired/verification/reference_demo_tb.v`，同一 testbench 核對 A／B／C 的內建程式、暫存器、記憶體與 reset。

```sh
vivado -mode batch -source scripts/create_vivado_sim.tcl -tclargs -variant reference -out-dir vivado-sim -run
```

成功的自我檢查應輸出 `REFERENCE DEFAULT ROM PASS`，腳本再確認 simulation log 的 PASS 標記及錯誤。若只建立工程而暫不執行模擬，省略 `-run`。既有輸出路徑會被拒絕，不會覆寫；第二次執行請改用新 `-out-dir`。預設 part 是 `xc7a35tcsg324-1`，可用 `-part` 指定已安裝的器件。

| `-variant` | 修正版設計／testbench |
|---|---|
| `reference` | 新參考 A／B／C，同一 testbench |
| `s02-single-cycle` | 第二組 A |
| `s02-pipeline` | 第二組 B |
| `s02-hazard` | 第二組 C |
| `s03-single-cycle` | 第三組 RAR 修正版 A |
| `s03-pipeline` | 第三組 RAR 修正版 B |

Python 含標準 `tkinter`／Tcl 時，`python scripts/check_vivado_sim.py` 可無 GUI 檢查六個分支、來源選擇、工程／模擬命令流程、錯誤傳遞與不覆寫既有檔案。該檢查採 Tcl interpreter 與 mock Vivado commands；本機未安裝 Vivado／XSim，未宣稱在 Vivado 實跑或以 mock 證明 RTL 功能。RTL 的功能結果由 Icarus 的獨立實際模擬驗證。

腳本 API 已核對官方 [UG835 2018.3](https://docs.amd.com/v/u/2018.3-English/ug835-vivado-tcl-commands)：`create_project`、`add_files`、`get_files`、`set_property`、`update_compile_order`、`launch_simulation`、`run -all`、`close_sim`、`close_project`。Testbench 明確設為 SystemVerilog，以支援 `$fatal` 自我檢查；模擬流程及 `xsim.simulate.runtime` 亦依 [UG900 2019.2](https://docs.amd.com/v/u/2019.2-English/ug900-vivado-logic-simulation) 第 73、174 頁。
