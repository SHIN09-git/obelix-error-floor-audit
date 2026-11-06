# 许可范围 / Licensing scope

本仓库使用按文件类别区分的许可。根目录的 MIT 文本不覆盖第三方快照，也不将论文改为软件许可。

| 路径或内容 | 适用许可与署名 |
|---|---|
| `reproduce.py`、`scripts/*.py`、`formal/lean/*.lean`、`formal/lean/Mard/*.lean`、`formal/lean/verify.ps1`、`.github/workflows/`、构建和仓库配置 | MIT；Copyright (c) 2026 JIN HANZHE |
| 原创 Markdown 文档、`output/pdf/obelix_error_floor_audit.pdf`、`CITATION.cff` | CC BY 4.0；JIN HANZHE，2026 |
| 原创验证证据及来源记录 `formal/lean/verification/`、`formal/lean/reference/`；原创审计整理与派生结果：`reports/`、`reference_results/`、`provenance/`、`RELEASE_MANIFEST.json`、`evidence/round5/original_facts.json`、`evidence/round11/*_queue.json` | 原创贡献采用 CC BY 4.0；JIN HANZHE，2026；保留其中记载的上游及文献署名 |
| `evidence/round3/upstream_*`、`evidence/round11/upstream_*` | OBELiX 上游 CC BY 4.0；按 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 署名 |
| `sources/obelix_LICENSE.txt` | 随上游快照保留的原许可文本 |

完整文本：[MIT](LICENSE)、[CC BY 4.0](LICENSE-CC-BY-4.0.txt)。本项目只对其有权许可的原创贡献适用上述许可；第三方原始内容的权利不因本仓库署名而改变。原始论文 PDF、字体和第三方 Python 库均未随仓库再分发。

引用文献与遵守许可是两件事。复用 OBELiX 数据时，应保留 OBELiX 的署名、来源链接和 CC BY 4.0 链接；复用本审计的正文或改编分析时，应署名 JIN HANZHE，说明改动，并链接本审计及其 CC BY 4.0 许可。本研究的固定版本入口为 [v1.0.0 发布页](https://github.com/SHIN09-git/obelix-error-floor-audit/releases/tag/v1.0.0)，尚无 DOI。

## English

Original software and configuration are licensed under MIT. Original manuscript text, documentation and audit contributions are licensed under CC BY 4.0. Upstream OBELiX files remain under their upstream CC BY 4.0 license and attribution, including when their data appear in derived audit tables. These licenses apply only to rights held in the respective contributions. Original-paper PDFs, fonts and third-party Python libraries are not redistributed.

The path table above controls scope; the root MIT text does not relicense the upstream snapshots or the manuscript. See the [third-party notices](THIRD_PARTY_NOTICES.md) for source attribution and unchanged-file details.


Lean、mathlib 和 lean4checker 等下载依赖保留各自许可；本仓库不分发它们的源代码或编译缓存。Lean, mathlib and lean4checker dependencies retain their own licenses and are not bundled.
