# OBELiX 误差下限审计（MARD-01）

[English](README.en.md) · [英文论文 PDF](output/pdf/obelix_error_floor_audit.pdf) · [论文源文](reports/round11/MANUSCRIPT.md) · [中文证明](reports/round11/ANALYTICAL_NOTE.md)

**JIN HANZHE** · Independent Researcher, Chongqing, China  
公开版 **1.0.0** · 发布日期：2026-10-22 · 科学分析截止：2026-10-11

[GitHub 仓库](https://github.com/SHIN09-git/obelix-error-floor-audit) · [v1.0.0 发布与下载](https://github.com/SHIN09-git/obelix-error-floor-audit/releases/tag/v1.0.0) · [自动复现检查](https://github.com/SHIN09-git/obelix-error-floor-audit/actions/workflows/reproduce.yml)

这项研究复现了 OBELiX 论文中的组内离散统计量，并检查它能否支持“预测误差不可能低于 0.41”的解释。**原统计量的算术结果可以复现；把它直接解释为适用于所有模型的误差下限，仍缺少必要条件。**

本仓库提供研究短文、固定版本的数据快照、两套计算实现和离线复现入口。这是一项针对已发表解释的方法审计，尚未经过同行评审。来源检查、计算和写作中的 AI 使用见 [署名与研究披露](AUTHORSHIP.md)。

## 主要结果

这里的 MAD 指**相对于组内中位数的平均绝对偏差**；不是“绝对偏差的中位数”。目标值为以 S/cm 表示的电导率的 log10，误差单位为 dex。

| 计算对象 | 结果 | 应怎样理解 |
|---|---:|---|
| 全部编码记录 | 599 条；训练 478 条，测试 121 条 | 沿用官方数据划分 |
| 相同记录组分与空间群的重复子集 | 48 组、122 条 | 37 条删失记录均不在此子集中 |
| 重复子集的 MAD | 0.4077528700 | 复现论文四舍五入后的 0.41 |
| 全部 599 条上的组内常数最小 MAE | 0.083048 | 用当前集合的标签选择每组常数 |
| 官方测试集上的组内常数最小 MAE | 0.0304500700 | 同样使用测试标签，不是预测分数 |
| 元素含量、空间群与 6 个晶格参数组成的记录键 | 599 个均不同 | 仅指记录数值的相等关系 |

上述“最小 MAE”是受特定分组约束的有限样本计算，不是新模型成绩，也不是新的实验噪声下限。48 个重复组均完整落在同一个官方划分内，本审计没有指控这些组跨越训练与测试边界。

论文用一个数学反例说明：输入差异很小，本身不能证明这些差异没有预测信息。LATP 案例说明，来源中的一个数值范围不能自动视为可识别的独立试样重复测量。该案例只深入检查了两篇原文，不代表对整个数据库错误率的估计。

## Lean 形式化验证

Lean 4.24.0 已形式化中文分析第 1 至 4 节。前三节证明分组中位数达到最小绝对误差、输入细化时最优风险不增，并构造了粗输入最优风险为 0.41、丰富输入最优风险为零的例子。

第四节证明，来自同一分布且一阶绝对矩有限的观测，用同一批标签拟合中位数时，组内平均绝对偏差的期望不超过总体最优绝对误差。若两次观测独立且服从 $N(\mu,\tau^2)$，两者分别为 $\tau/\sqrt\pi$ 和 $\tau\sqrt{2/\pi}$。用这一比例解释真实重复测量，需要另有证据支持该抽样模型。[证明及复现说明](formal/lean/README.md) · [验证记录](formal/lean/verification/sampling/RESULT.json) · [自动验证](https://github.com/SHIN09-git/obelix-error-floor-audit/actions/workflows/lean.yml)

## 一条命令复现

需要 **Python 3.11 或更新版本**。数值复现只使用标准库，不需要安装依赖、下载数据或训练模型。在下载并解压的仓库目录中运行：

```console
python reproduce.py
```

Windows 上若系统使用 Python 启动器，可运行 `py -3 reproduce.py`。结果写入新的 `reproductions/<时间与标识>/` 目录。入口会先检查发布文件的 SHA-256，再运行两套计算，核对 **41 项便携核心检查**，并将重新生成的结果与随包参考结果比较。

成功时显示 `"status": "PASS"`，并生成 `REPRODUCTION_RESULT.json`。这表示文件与计算检查通过，不等于独立实验、原始文献人工核查或同行评审通过。

只检查包内文件完整性：

```console
python reproduce.py --verify-only
```

指定一个尚不存在的结果目录：

```console
python reproduce.py --output "../mard01-results"
```

详见 [复现范围与输出](REPRODUCIBILITY.md) 和 [本次发布检查](VALIDATION.md)。

## 阅读与文件入口

| 入口 | 内容 |
|---|---|
| [论文 PDF](output/pdf/obelix_error_floor_audit.pdf) | 完整英文研究短文，含署名及数据与准备说明 |
| [中文分析](reports/round11/ANALYTICAL_NOTE.md) | 分母、模型输入与最小绝对误差的推导 |
| [重复组清单](reports/round11/repeated_groups.csv) | 全部 48 个重复组 |
| [逐组证据](reports/round11/repeated_group_audit.json) | 122 条记录、数值、来源及官方划分 |
| [参考计算](reference_results/error_bound_audit.json) | 原分析完整计算记录 |
| [来源与许可](THIRD_PARTY_NOTICES.md) | 固定版本、上游路径、文献及再分发范围 |
| [变更记录](CHANGELOG.md) | 公开整理版的变更 |

上游数据固定为 [OBELiX commit 4eaac889](https://github.com/NRC-Mila/OBELiX/tree/4eaac889809dd489e3bae468c45d5c0e02b9147a)。本包不包含原始论文 PDF；相关 DOI、表格位置和历史文件指纹保留在来源记录中。数值结果可以离线复现，LATP 原文语义需要读者另行取得文献后核对。

## 署名、引用与许可

作者与项目联系人：**JIN HANZHE**（[jinhanzhe09@gmail.com](mailto:jinhanzhe09@gmail.com)）。项目执行中使用了 Codex；AI 不列为作者。具体范围及尚未完成的人工核查见 [AUTHORSHIP.md](AUTHORSHIP.md)。

引用本研究：

> JIN, HANZHE. 2026. *Repeated-composition dispersion does not identify a universal prediction-error floor: A reproducible audit of OBELiX, with a LATP source case*. Version 1.0.0. Research manuscript.

机器可读引用见 [CITATION.cff](CITATION.cff)。本版本尚无 DOI；可引用上述固定版本发布页，但不要将本研究写成已发表期刊论文。

原创代码采用 [MIT](LICENSE)；原创正文、文档和分析记录采用 [CC BY 4.0](LICENSE-CC-BY-4.0.txt)。OBELiX 快照保留上游 CC BY 4.0 许可和署名。适用范围见 [LICENSING.md](LICENSING.md)。本研究不代表 OBELiX 原作者的背书。

