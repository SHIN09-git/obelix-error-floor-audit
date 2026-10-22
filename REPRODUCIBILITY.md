# 复现说明

## 环境与入口

数字审计需要 Python 3.11 或更新版本，只使用标准库。把仓库完整下载或解压到任意可写路径，在根目录运行：

```console
python reproduce.py
```

默认在新的 `reproductions/<UTC 时间与随机标识>/` 内生成输入副本、日志与结果。运行过程不联网、不执行上游研究代码、不训练模型，也不覆盖随包输入或参考结果。

```console
python reproduce.py --verify-only
python reproduce.py --output "../mard01-results"
```

第一条只读检查发布文件。第二条将结果写到自选的新目录；目录已经存在时会报错，避免覆盖。自选路径可以位于仓库外，也可以位于仓库的 `reproductions/` 下。

## 入口具体检查什么

1. 根据 `RELEASE_MANIFEST.json` 检查随包文件的大小与 SHA-256。
2. 将冻结输入和原始两套审计脚本复制到结果目录。
3. 运行 `scripts/audit_obelix_error_bound.py`，重算 21 个“子集 × 分组方式”场景和全部 48 个重复组。
4. 运行 `scripts/verify_obelix_error_bound.py --core-only`。它采用 45 位十进制对数与排序两端配对求和，完成 41 项便携核心检查。
5. 将重新生成的 JSON 和 CSV 与冻结参考结果比较。结构、分类、计数和 ID 必须一致，浮点数允许的绝对差为 `1e-12`。
6. 再次检查原发布目录的文件指纹，写出 `REPRODUCTION_RESULT.json`。

清单是文件完整性记录，不是数字签名，也不代替对代码和论证的审查。41 项是原核算脚本中的检查数量；入口的文件指纹和结果比较在这 41 项之外。

## 输出位置

成功时末尾会显示 `"status": "PASS"` 及结果目录：

| 文件 | 内容 |
|---|---|
| `REPRODUCTION_RESULT.json` | 结果摘要、运行 Python 版本、检查数量与适用范围 |
| `reports/round11/error_bound_audit.json` | 21 个场景、来源指纹及限制说明 |
| `reports/round11/repeated_group_audit.json` | 全部重复组的逐条数据 |
| `reports/round11/repeated_groups.csv` | 重复组汇总表 |
| `reports/round11/VALIDATION.json` | 41 项检查及高精度结果 |
| `*.stdout.log`、`*.stderr.log` | 两个计算程序的输出和错误日志 |

主要预期结果：599 条记录，48 个重复组，122 条重复记录，重复子集 MAD 为 `0.4077528700375033`；官方测试集 121 条，其中 3 组、6 条重复记录；该测试集上的组内常数最小 MAE 为 `0.03045007002540445`。后一个数值使用测试标签，不能作为预测成绩或实验噪声估计。

## 公开包与历史工作区的区别

历史完整工作区检查了 52 项；公开包运行 41 项核心检查。差额涉及未分发的原始论文 PDF、早期冻结观测及项目状态。不要在这个包中直接运行不带 `--core-only` 的历史核算命令并期待其完整通过。

`evidence/round5/original_facts.json` 中的原文 PDF、人工核查状态及授权记录路径属于历史来源记录；相关文件没有随包提供。`reference_results/error_bound_audit.json` 也保留了未分发阅读材料的指纹。复现入口只比较实际随包提供的来源项，其余科学字段完整比较。详情见 [来源与再分发范围](THIRD_PARTY_NOTICES.md)。

数字复现不能重新证明 LATP 文献语义检查的正确性。读者需自行取得两篇原文，按 DOI、页码和表格位置核对。来源状态仍为 AI 检查，尚未标记人工科学核查或同行评审完成。

## 可选：重新排版 PDF

数值复现不需要这一步。排版依赖另列在 `requirements-pdf.txt`：

```console
python -m pip install -r requirements-pdf.txt
python scripts/build_pdf.py
```

默认生成 `tmp/pdf-build/obelix_error_floor_audit.pdf`，不覆盖发布 PDF。排版采用标准 PDF 字体和 Matplotlib 数学排版；不依赖本机 Windows 字体。不同平台的字体渲染或 PDF 元数据可能不同，因此只要求正文内容一致，不要求重新排版后的 PDF 字节完全一致。

## GitHub 自动检查

`.github/workflows/reproduce.yml` 配置了 Windows 与 Ubuntu 上的 Python 3.11、3.12、3.13 检查。每个环境运行同一个 `python reproduce.py` 入口。线上执行状态与对应提交见 [GitHub 自动复现记录](https://github.com/SHIN09-git/obelix-error-floor-audit/actions/workflows/reproduce.yml)；本地发布前检查见 [VALIDATION.md](VALIDATION.md)。

The core numerical reproduction is offline and standard-library only. PDF rebuilding is optional and has separate dependencies. A successful run checks integrity, arithmetic and reference agreement; it is not peer review, a new experiment or proof of attainable predictive performance.

