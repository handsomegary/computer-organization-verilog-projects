Computer Organization Final Project — 已修正版本

本 repo 現在包含可通過驗證的五個修正版，以及重新撰寫的 A／B／C 參考實作。
四份來源的初始擷取版保存在 Git commit 21d436e；目前檔案樹已移除需要大幅
重作的舊設計，不再把已知損壞版本當成可用範例。

建議先使用新寫的版本

reference/rtl/mips_single_cycle.v
    Level A：module mips_single_cycle，單週期。
reference/rtl/mips_pipeline.v
    Level B：module mips_pipeline，參數 HAZARD_ENABLE=0。
    Level C：同一個五階段 module，HAZARD_ENABLE=1（預設）。
    B 版需要對 RAW 相依指令插入 NOP；C 版自動 forwarding 與 load-use stall。

新版本介面：clk、reset（active high）、pc；管線版另外提供 stall。
內含 regs[0:31]、imem[0:1023]、dmem[0:1023]，PC 與資料位址皆以 byte 計。
imem[n]／dmem[n] 對應 byte address 4*n。內建 ROM 使用全部十種指令，
完成後 r8=24、r9=7、dmem[100]=24（byte address 400）。

保留原架構並修正的版本

sources/02-final-pj/single-cycle/         Level A
sources/02-final-pj/pipeline/             Level B，RAW 相依間排程 3 個 NOP
sources/02-final-pj/hazard/               Level C，無需相依 NOP
sources/03-final-project-rar/single-cycle/ Level A
sources/03-final-project-rar/pipeline/    Level B，RAW 相依間排程 3 個 NOP

保留原有 module 名稱、top 介面與 stage-register 架構。這些專案具有重複
module 名稱，請分開編譯。各自 tb/ 內現在都有會 assert 結果並正常結束的 TB。
修正內容包括 addi、byte addressing、$zero、jump、branch flush 與 C 版的
store forwarding／load-use。詳細差異與移除理由見 AUDIT.zh-TW.txt。

依指定簡報實作的 ISA

lw sw add addi sub and or slt beq j
signed slt、16-bit sign extension、32-bit wraparound 算術、PC+4、標準 branch／
jump 位址、無 branch delay slot。支援範圍是作業的十種指令，沒有實作完整
MIPS32 的例外／溢位處理。不對齊或超出記憶體的 lw 回傳 0、sw 不產生作用。

重跑全部驗證：Python 3 + Icarus Verilog

python verification/check_package.py
python verification/check_all.py

下載套件包含所有 RTL、testbench 與測資產生器；不需要原始 Downloads
資料夾或本機私有檔案。範例 ROM 在 HDL 內，額外向量由驗證腳本產生。
Ubuntu 可先執行 sudo apt-get install iverilog；Windows 安裝 Icarus 後，
將 iverilog/vvp 所在目錄加入 PATH，或使用下列明確工具路徑參數。
GitHub Actions 會在乾淨 checkout 檢查封包並重跑全部 173 個案例。

工具未在 PATH 時：
python verification/check_all.py --iverilog C:/path/bin/iverilog.exe --vvp C:/path/bin/vvp.exe
可攜套件若需要指定函式庫，另加 --iverilog-base C:/path/lib/ivl。
結果預設放在 .verification-build/，任何編譯或功能失敗都回傳非零。

最終結果：173／173 通過
    38 個保留專案回歸案例。
    97 個新版本驗證（獨立 MIPS 模型、12 個定向程式、20 個固定 seed 隨機程式，
       分別檢查 A、B、C，另含內建 ROM 與 reset）。
    22 個舊 pipeline 的 ISA／隨機／控制清除比對。
    16 個獨立 reset、forwarding、load/store、branch、$zero 與記憶體壓力案例。
隨機與整合比對涵蓋全部 32 個暫存器及完整資料記憶體，不以「預期失敗」算通過。

reports/summary.json                    四組套件的總結果
reports/verification-results.json       保留專案回歸紀錄
reports/reference-results.json          新版本獨立模型與逐案例結果
reports/pipeline-results.json           保留 pipeline 比對結果
reports/stress-results.json             獨立壓力測試
reports/changes.json                    修正、移除及替換對照
source-manifest.json                    目前所有 .v 的 SHA-256 與原始來源對照

未搬動或修改 Downloads 的原檔。舊碼仍可從初始 commit 找回。
本次交付為 RTL、testbench 與驗證說明；未另製作課程要求的個人／小組 PDF，
也未進行 FPGA synthesis、timing closure 或實體板驗證。
