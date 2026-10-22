# 本地发布前检查记录

日期：2026-10-22。实际运行环境：**Windows，Python 3.12.14**。本页记录首次推送到 GitHub 前完成的本地检查；后续线上执行状态与对应提交见 [GitHub 自动复现记录](https://github.com/SHIN09-git/obelix-error-floor-audit/actions/workflows/reproduce.yml)。

| 检查 | 已观察结果 |
|---|---|
| 便携数值核算 | 41 项核心检查通过 |
| 与冻结结果比较 | 3,292 个参考值一致；浮点数绝对容差为 `1e-12` |
| 与固定 OBELiX 提交比较 | 10 份上游快照及 1 份原许可文件逐字节一致 |
| 与原便携包比较 | 21 份未修改文件的 SHA-256 一致，包括两套数值脚本、数据快照和逐组结果 |
| 科学正文与参考文献 | 与原研究稿文本一致 |
| 引用元数据 | `CITATION.cff` 通过官方 CFF 1.2.0 schema 检查 |
| 输入改动检测 | 对独立副本的输入追加内容后，完整性检查按预期拒绝继续 |
| 已存在的输出目录 | 入口拒绝覆盖；目录中的原文件保留 |
| PDF | 最终 5 页已逐页渲染，由 Codex 检查排版；作者元数据为 JIN HANZHE |
| 本地路径与常见密钥格式 | 对清单内文本做模式检查，未发现匹配项；这不等于完整安全审计 |
| GitHub 自动检查 | 已配置 Windows / Ubuntu 与 Python 3.11 / 3.12 / 3.13；本页快照截止于首次推送之前，线上结果见上方链接 |

机器可读记录：[provenance/validation_summary.json](provenance/validation_summary.json)。上游逐文件比较见 [provenance/upstream_release_check.json](provenance/upstream_release_check.json)。

入口成功时得到的核心结果为：

```json
{
  "core_checks_passed": 41,
  "reference_values_compared": 3292,
  "repeated_subset_MAD_dex": 0.4077528700375033,
  "official_test_group_constant_oracle_MAE_dex": 0.030450070025404456,
  "uses_evaluation_labels": true
}
```

末尾浮点位数与高精度 Decimal 文本的显示可能不同；比较容差已明确固定。这些值使用评价标签，不是新模型的测试表现。

本页报告文件、计算和排版检查。它不宣称人工科学核查、独立实验、全量来源语义核查或同行评审完成。历史完整工作区的 52 项检查没有被重新包装为本公开包的通过数量。

