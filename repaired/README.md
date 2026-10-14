# 可執行的計算機組織修正版

本目錄已包含完整 RTL、testbench、測資產生器及獨立驗證模型，可在下載此 repo 後直接執行。來源是 [computer-organization-final-verilog-review](https://github.com/handsomegary/computer-organization-final-verilog-review/tree/012b371e2ad6fd768170ad6aa9bc32254aadad04) 的提交 `012b371e2ad6fd768170ad6aa9bc32254aadad04`，共 146 個 tracked files。[package-source.json](package-source.json) 記錄逐檔來源與套件 SHA-256，以該提交的 Git blob 位元組為基準；所有 RTL、testbench、Python runner、案例定義及 source manifest 均原樣複製，六份歷史 JSON 報告僅替換絕對主機路徑。

從 **repo 根目錄** 執行：

```sh
python checks/check_repaired_package.py
python repaired/verification/check_all.py
```

需要 Python 3（建議 3.12）及 Icarus Verilog，`iverilog`、`vvp` 放在 PATH。Python 僅用標準函式庫。完整執行應回報 `ALL: 173/173`：回歸 38、新參考 97、pipeline 22、壓力測試 16。任一編譯、模擬、逾時或功能錯誤都回傳非零。測資與預期記憶體檔案由 runner 產生，結果預設放在 `.verification-build/`（位於本目錄內）。

Windows 可攜工具可明確指定路徑：

```sh
python repaired/verification/check_all.py --iverilog C:/path/bin/iverilog.exe --vvp C:/path/bin/vvp.exe --iverilog-base C:/path/lib/ivl
```

快速執行三個新參考模式的內建程式：

```sh
iverilog -g2012 -s reference_demo_tb -o demo.vvp repaired/verification/reference_demo_tb.v repaired/reference/rtl/mips_single_cycle.v repaired/reference/rtl/mips_pipeline.v
vvp demo.vvp
```

應得到 `REFERENCE DEFAULT ROM PASS`，並正常結束。該 testbench 同時核對單週期 A、基本管線 B 與 hazard 管線 C；包含內建程式、全部暫存器、完整資料記憶體與 reset。

| 可用版本 | 位置 | 使用方式 |
|---|---|---|
| 新參考 A | [mips_single_cycle.v](reference/rtl/mips_single_cycle.v) | `mips_single_cycle`，單週期 |
| 新參考 B | [mips_pipeline.v](reference/rtl/mips_pipeline.v) | `mips_pipeline`，`HAZARD_ENABLE=0`，相依指令需排程 NOP |
| 新參考 C | [mips_pipeline.v](reference/rtl/mips_pipeline.v) | `HAZARD_ENABLE=1`，自動 forwarding 與 load-use stall |
| 第二組修正版 A／B／C | [sources/02-final-pj](sources/02-final-pj) | 各版本分開編譯，使用各自 `tb/` |
| 第三組修正版 A／B | [sources/03-final-project-rar](sources/03-final-project-rar) | 各版本分開編譯，使用各自 `tb/` |

第一組、第四組及第三組原 hazard 需要大幅重作，此套件提供新參考 A／B／C 作為替代。原版均仍保留於本 repo 的 `projects/`，沒有覆蓋或刪除。五個保留架構修正版的修正對照與界線見 [changes.json](reports/changes.json)、[修正報告](AUDIT.zh-TW.txt)。

支援作業指定的 `lw sw add addi sub and or slt beq j`、byte addressing、signed `slt` 與無 branch delay slot。詳細介面、記憶體容量及 reset 行為見 [上游 README](README.txt)。該 README 與歷史報告的相對路徑以本目錄為根；其中舊 commit 指的是上游 repo 的歷史，不是本 repo。完整模擬不需 FPGA 工程檔；綜合、timing closure、實體板驗證及課程繳交 PDF 未包含在此交付。
