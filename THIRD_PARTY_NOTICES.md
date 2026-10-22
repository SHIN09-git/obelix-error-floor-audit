# 第三方来源、署名与再分发范围

## OBELiX

本审计使用 **OBELiX project contributors（NRC-Mila）** 提供的数据与代码快照。

- 论文：F. Therrien et al. *OBELiX: a curated dataset of crystal structures and experimentally measured ionic conductivities for lithium solid-state electrolytes*. Digital Discovery 5 (2026), 910–918. [DOI: 10.1039/D5DD00441A](https://doi.org/10.1039/D5DD00441A)。
- 来源：[NRC-Mila/OBELiX](https://github.com/NRC-Mila/OBELiX)。
- 固定版本：[4eaac889809dd489e3bae468c45d5c0e02b9147a](https://github.com/NRC-Mila/OBELiX/tree/4eaac889809dd489e3bae468c45d5c0e02b9147a)。
- 许可：[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)，随包保留的原文本为 [sources/obelix_LICENSE.txt](sources/obelix_LICENSE.txt)。

| 本仓库文件 | 上游相对路径 |
|---|---|
| `evidence/round3/upstream_all.csv` | `data/downloads/all.csv` |
| `evidence/round3/upstream_processed.csv` | `data/processed.csv` |
| `evidence/round3/upstream_preprocessing.py.txt` | `data/scripts/preprocessing.py` |
| `evidence/round11/upstream_analysis.py.txt` | `data/scripts/analysis.py` |
| `evidence/round11/upstream_train.csv` | `data/downloads/train.csv` |
| `evidence/round11/upstream_test.csv` | `data/downloads/test.csv` |
| `evidence/round11/upstream_test_idx.csv` | `data/test_idx.csv` |
| `evidence/round11/upstream_RF.py.txt` | `benchmark/RF.py` |
| `evidence/round11/upstream_MLP.py.txt` | `benchmark/MLP.py` |
| `evidence/round11/upstream_parse.py.txt` | `benchmark/parse.py` |

快照文件内容保留原字节；本仓库仅调整保存路径，并为研究代码加上 `.txt` 扩展名以表明其作为阅读证据。数值复现运行本审计的原创实现，不执行这些上游脚本。

派生组表、数值统计、解释与说明是本审计的新增贡献，不是 OBELiX 原作者提供的更正，也不表示他们认可本审计结论。复用派生表时，请同时保留 OBELiX 的来源署名与本审计署名。

## 参考论文与历史来源记录

本仓库只分发本审计自己的论文 PDF。以下参考文献 PDF 未被再分发：

- OBELiX 正式论文：[10.1039/D5DD00441A](https://doi.org/10.1039/D5DD00441A)。
- Gneiting, *Making and Evaluating Point Forecasts*：[10.1198/jasa.2011.r10138](https://doi.org/10.1198/jasa.2011.r10138)，[作者预印本](https://arxiv.org/abs/0912.0902)。
- Aono et al. (1990)：[10.1149/1.2086597](https://doi.org/10.1149/1.2086597)，Table IV，第 1026 页。
- Cretin and Fabry (1999)：[10.1016/S0955-2219(99)00055-2](https://doi.org/10.1016/S0955-2219(99)00055-2)，Table 6，第 2937 页。

`evidence/round5/original_facts.json` 是原研究的结构化事实转录和语义说明，保留文献作者、DOI、页码及 `human_verified: false`。`evidence/round11/*_queue.json` 是历史获取清单，不是本包文件存在性清单。其中涉及文献 PDF、网页、历史 issue 检索和授权记录的路径可能不在本包内；它们不会被复现命令自动下载。

这些文献的版权不由 JIN HANZHE 持有。本审计的 CC BY 4.0 许可只覆盖其有权许可的新增内容，不扩张为对第三方整篇论文的授权。

## 原始包与公开整理

[provenance/original_package_manifest.json](provenance/original_package_manifest.json) 保留 2026-10-11 原便携包的文件清单；其中旧 README、旧 PDF 和旧复现说明的指纹不代表本公开版。当前发布文件以根目录的 `RELEASE_MANIFEST.json` 为准。

[provenance/release_origin.json](provenance/release_origin.json) 记录原包指纹和科学正文不变的比较结果。公开整理只更新署名、许可、使用说明、复现包装和排版。冻结数据、两套数值程序和逐组计算结果不变。

## Optional PDF tooling

The optional PDF builder uses ReportLab, Matplotlib and Pillow. They are installed separately under their respective licenses and are not vendored here. Standard PDF fonts are used; no operating-system font files are redistributed.

