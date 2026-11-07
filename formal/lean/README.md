# MARD-01 的 Lean 验证

本项目形式化 MARD-01 第十一轮分析笔记第 1 至 4 节的数学命题。前三节研究分组中位数、输入细化与两点反例。第四节研究用同一批标签拟合中位数造成的抽样偏差。[分析原文](../../reports/round11/ANALYTICAL_NOTE.md)

完整验证检查 42 条声明的传递公理依赖，其中 23 条属于抽样偏差证明。编译将警告视为错误，官方检查器在新内核环境中重放 `ProofCheck` 的完整导入链。2026-11-06 的历史记录覆盖原先的 19 条声明。[当前验证记录](verification/sampling/RESULT.json) · [前三节历史记录](verification/RESULT.json) · [GitHub 自动验证](https://github.com/SHIN09-git/obelix-error-floor-audit/actions/workflows/lean.yml)

## 已证明的内容

| 原文命题 | Lean 声明 | 条件与结论 |
|---|---|---|
| 分组中位数达到最小绝对误差 | `Mard.grouped_median_optimal` | 对任意非空有限记录集、任意实数标签、任意分组，在同组只能给出同一预测的条件下，最优 MAE 等于组中位数绝对偏差总和除以**全部评分记录数**。 |
| 丰富输入不会提高最优误差 | `Mard.feature_refinement` | 若粗输入能由丰富输入得到，且记录、标签和分母不变，则丰富输入的最优 MAE 不大于粗输入的最优 MAE。 |
| 0.41 不是丰富输入的普遍下界 | `Mard.Counterexample.population_counterexample` | 明确的两点概率分布中，粗输入最优风险恰为 `41/100`，丰富输入最优风险恰为零，输入差异恰为 `3/250 = 1.2%`，给定预测函数可测且逐点正确。 |

另有总体版本 `Mard.population_feature_refinement`：对同一个测度和目标变量，粗输入的可测预测函数可以复合成丰富输入的可测预测函数，因此最优总体绝对风险不增。用非负扩展实数积分定义风险，允许无穷风险而不引入未定义的实数积分；通常的有限一阶矩概率分布也在其适用范围内。

## 第一条没有把中位数最优性当作假设

`sampleMedian` 先排序，保留重复标签，再逐对移除两端。奇数个标签取中央值，偶数个标签取中央两值的算术平均。证明依次完成：

1. 非空列表的中央值落在标签的共同上下界内。
2. 对 `a ≤ m ≤ b`，两端相对 `m` 的绝对误差之和不大于相对任意 `c` 的误差之和。
3. 对排序列表进行两端归纳，得到中位数的最优性。
4. 排序只是置换，不改变误差和。
5. 将原评分记录按组重新求和，证明组中位数确实达到下确界。

记录集使用独立的记录标识。两个标签或输入相同的记录仍可拥有不同标识，不会被去重。空组没有贡献；主平均误差定理明确要求评分集非空。

## 反例与原文逐项对应

令 `U` 等概率取 `-1` 和 `+1`：

```text
A = 503/500 + (3/500) U       = 1.006 + 0.006 U
Y = -4 + (41/100) U          = -4 + 0.41 U
f(A) = -4 + ((41/100)/(3/500)) (A - 503/500)
```

`A` 的两个值为 `1` 和 `253/250 = 1.012`。粗输入在两个结果中相同，所以任何粗预测器都只能输出一个常数。证明不仅给出误差 `0.41` 的预测器，也证明任何常数的误差都不低于 `0.41`。丰富输入的指定仿射函数在两个结果上都准确，非负性随后给出最优值为零。

`coinMeasure` 用两个各占一半的点质量构造，Lean 同时证明其总质量为一。另将实际积分化为两点平均，证明输入、标签和预测函数的可测性。这里不存在训练过程，也没有把样本拟合成绩当成总体结果。

## 抽样偏差与两次高斯观测

固定一个组的标签分布 $\nu$，假设 $E_\nu|Y|<\infty$。对 $n\ge1$ 个观测记

$$
\widehat R_n=\inf_{c\in\mathbb R}\frac1n\sum_{i=1}^n|Y_i-c|,
\qquad R^*(\nu)=\inf_{c\in\mathbb R}E_\nu|Y-c|.
$$

`fittedRisk` 使用已有的样本中位数。Lean 证明这个统计量等于左式的下确界，也等于把全部记录看作同一组时的 `Mard.optimalRisk`。如果每个观测值至多改变 $\delta$，拟合损失的变化也至多为 $\delta$，因此统计量连续且可测。有限一阶绝对矩保证它可积。[估计量与原定义的对应](Mard/Sampling.lean)

若每个 $Y_i$ 的边缘分布都是 $\nu$，则 $E[\widehat R_n]\le R^*(\nu)$。对任意固定中心 $c$，用样本中位数计算的损失逐样本都不大于用 $c$ 计算的损失。后者的期望等于 $E_\nu|Y-c|$，再对 $c$ 取下确界即得结论。`iid_product_bias` 把它落实到独立同分布样本的乘积概率测度上。单次观测给出 $\widehat R_1=0$。[一般期望不等式与独立抽样版本](Mard/Sampling.lean)

当 $Y_1,Y_2$ 独立且同服从 $N(\mu,\tau^2)$ 时，$\widehat R_2=|Y_1-Y_2|/2$。差值服从 $N(0,2\tau^2)$，正态密度的绝对一阶矩给出经验期望。另由关于 $\mu$ 的反射对称性，Lean 证明 $\mu$ 在所有常数中心中达到总体最优。于是

$$
E[\widehat R_2]=\frac{\tau}{\sqrt\pi},
\qquad R^*(\nu)=\tau\sqrt{\frac{2}{\pi}}.
$$

$\tau=0$ 时两者同为零。$\tau>0$ 时，经验期望为总体最优风险的 $1/\sqrt2$，约低 29.3%。即使在这个模型中，单次样本的拟合损失仍有正概率超过任意给定的有限阈值，包括 $R^*(\nu)$。把该比例用于实测数据，需要另外论证组内的独立高斯抽样假设。[高斯公式、严格不等式与尾部概率](Mard/GaussianSampling.lean)

## 文件

| 文件 | 内容 |
|---|---|
| `Mard/Basic.lean` | 评分风险、最优风险、非负性和下确界基础 |
| `Mard/Median.lean` | 中位数构造、一般最优性和按组求和 |
| `Mard/Refinement.lean` | 有限样本及总体的输入细化定理 |
| `Mard/Counterexample.lean` | 精确有理常数反例及有限平均形式 |
| `Mard/PopulationCounterexample.lean` | 明确概率测度、积分和总体最优值 |
| `Mard/Sampling.lean` | 经验最小值、同边缘分布观测和独立同分布样本的期望不等式 |
| `Mard/GaussianSampling.lean` | 高斯总体最优风险、两次独立观测的精确期望与尾部概率 |
| `Audit.lean` | 42 条声明的公理依赖、主要定理签名及双观测样例 |
| `ProofCheck.lean` | 新环境内核重放的单一入口 |
| `verification/sampling/RESULT.json` | 当前检查结果、版本和证明输入哈希 |
| `verification/RESULT.json` | 2026-11-06 前三节的历史记录 |
| `verification/sampling/axioms.log` | 公理依赖检查的实际输出 |
| `verification/sampling/kernel-replay.log` | 新环境内核重放日志 |
| `reference/ANALYTICAL_NOTE.md` | 两次验证使用的同一份原文。`reference/SOURCE.json` 记录 11 月 6 日核查前三节时的来源和 SHA-256 |

## 复现

固定 Lean `v4.24.0`；mathlib 固定到提交 `f897ebcf72cd16f89ab4577d0c826cd14afaafc7`。间接依赖由 `lake-manifest.json` 固定。

安装 [elan](https://github.com/leanprover/elan) 后，在本目录（`formal/lean`）执行；`lean-toolchain` 会选择固定工具链。首次运行需要联网取得工具链和依赖，保留 `lake-manifest.json` 中的固定版本：

```text
lake exe cache get Mathlib.Data.Real.Archimedean Mathlib.Algebra.Order.BigOperators.Group.Finset Mathlib.Algebra.BigOperators.Group.Finset.Basic Mathlib.Tactic.Linarith Mathlib.Tactic.NormNum Mathlib.Tactic.Ring Mathlib.Data.List.Sort Mathlib.Data.List.Induction Mathlib.Data.Fintype.BigOperators Mathlib.MeasureTheory.Integral.Lebesgue.Countable Mathlib.MeasureTheory.Constructions.BorelSpace.Basic Mathlib.Probability.HasLaw Mathlib.Topology.MetricSpace.Pseudo.Pi Mathlib.MeasureTheory.Constructions.Pi Mathlib.Probability.Distributions.Gaussian.Real Mathlib.MeasureTheory.Integral.Gamma
lake build
lake env lean -DwarningAsError=true Audit.lean
```

完整检查还需要单独构建官方内核重放工具。以下命令在本目录执行：

```text
git clone --branch v4.24.0 https://github.com/leanprover/lean4checker.git .verification-tools/lean4checker
git -C .verification-tools/lean4checker checkout --detach da26eb05e9959402afcb9bd6dfe5dc4f700f70d6
lake -d .verification-tools/lean4checker build lean4checker
pwsh -NoProfile -File ./verify.ps1 -CheckerExe ./.verification-tools/lean4checker/.lake/build/bin/lean4checker
```

Windows 上为最后的程序路径加 `.exe`。`verify.ps1` 需要 PowerShell 7，从 `PATH` 查找 Lean，也支持 `-LeanBin` 指定工具目录。它重新编译、核对 42 条声明的公理依赖，并执行新环境内核重放；任何一步失败都会返回非零状态。新日志写入忽略的 `.verification-runs/`，不会覆盖随仓库保存的历史证据。

GitHub 工作流使用相同固定版本，在 Ubuntu 上自动执行这些检查。首次运行的下载和完整重放可能需要数分钟。

内核重放使用官方 `lean4checker` 的 `v4.24.0`，提交 `da26eb05e9959402afcb9bd6dfe5dc4f700f70d6`。该工具单独编译，在项目的搜索路径下运行：

```text
lake env <lean4checker的路径> --fresh -v ProofCheck
```

`--fresh` 将入口及导入依赖放到一个新的内核环境中重放。它仍使用 Lean 内核，不是另一种独立实现的证明器。

## 结论范围

验证范围为分析笔记第 1 至 4 节的数学命题。OBELiX 的实测记录、分组语义、论文引文与 `0.407752...` 等数据派生值沿用原数值审计。

组中位数最小值使用评分标签，只是规定函数类内的数学最优值，不是训练算法可实现的测试成绩。反例证明原先给出的条件不足以推出普遍风险门槛，不声称真实电解质存在零误差预测器。形式化也不增加这些已有统计原理的新颖性。

本项目没有留置证明占位符，没有新增公理，没有使用 `native_decide`。公理依赖输出应只包含 Lean 标准的 `propext`、`Classical.choice`、`Quot.sound`。编译将警告视为错误。

原文和形式化对应关系由本次助手复核，未进行外部人工同行评审。验证仍依赖 Lean 内核和所用基础逻辑的可靠性。

## English summary

The first three sections establish the grouped-median optimum, monotonicity under richer inputs and a population counterexample. Section 4 proves the expected empirical absolute-loss minimum is at most the population minimum for a nonempty sample with a common marginal and a finite first absolute moment. For two independent Gaussian observations with standard deviation $\tau$, these values are $\tau/\sqrt\pi$ and $\tau\sqrt{2/\pi}$ respectively. The proof also covers zero variance and shows that a single fitted value can exceed the population optimum with positive probability at every positive scale.

The full verification checks 42 named declarations and replays the complete import chain in a fresh Lean kernel environment. The earlier 19-declaration receipt is archived separately. The empirical audit and its manuscript have their own versioned release. [Current receipt](verification/sampling/RESULT.json) · [Original receipt](verification/RESULT.json) · [Licensing](../../LICENSING.md)
