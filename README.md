# REPFRAME v1.7.1

`repframe` is a Stata package to calculate, tabulate and visualize reproducibility and replicability indicators based on multiverse robustness analyses. These indicators assess how results from a range of plausible analytical choices compare to the original findings, helping to gauge the robustness of empirical conclusions.

The package includes two commands: `repframe`, the main command, and `repframe_gendata`, which generates a dataset used in the command's help file to show examples of how the command works.  

The package can be installed in Stata by executing:
```stata
net install repframe, from("https://raw.githubusercontent.com/guntherbensch/repframe/main") replace
```

Once installed, please see 
```stata
help repframe
```
for the syntax and the full range of options.


## Main outputs produced by *repframe*

The `repframe` command can be applied to derive indicators at both the individual study level and the pooled level across studies. The diagram below maps the basic commands on the left to the corresponding input data in the center and the three types of output on the right: data, tables and figures. 

The key outputs are indicated by the numbers (3) and (4) in the diagram, both of which can be created at the individual study level and the pooled level across studies: 
- *Reproducibility and Replicability Indicators*: a table containing a first set of main indicators in .csv or xlsx format. See [below](#reproducibility-and-replicability-indicators-table) and [Dreber and Johannesson (2025)](#references).
- *Robustness Dashboard*: a visualization of a second main set of indicators in the form of a single, intuitive graph. See [below](#robustness-dashboard) and [Bensch et al. (2025)](#references).

As additional output, the `repframe` command transforms analysis-path input data to a (1) *Harmonized analytical path dataset* and saves study-level indicator information in (2) *Study-level indicator data*, which is ready to be reintroduced into the command to calculate the indicators across studies. Lastly, the `repframe` command can additionally generate plots that compare how much coefficients differ between original and robustness analyses and how much individual choices contribute to robustness patterns across multiple robustness specifications (4+, see also [below](#complementary-coefficient-and-contribution-plots) for details). 

All input and output data is in Stata .dta format. 

<img width="800" alt="repframe outputs" src="https://github.com/user-attachments/assets/28c5d847-770c-4712-89e8-9f4acb135bf0"> &nbsp;


## Defaults applied by *repframe*

The `repframe` command applies a few default assumptions. Use the following options if your analysis makes different assumptions. 

<ins>Tests for statistical significance</ins>: The command applies two-sided *t*-tests to determine which *p*-values imply statistical significance. You may apply different significance levels to the original estimates (`siglevel_orig(#)`) and to the robustness estimates (`siglevel(#)`). If *p*-values are alternatively based on one-sided tests, multiply them by two before introducing them via the option `pval(varname)` to correspond to a two-sided test. If no *p*-values are available, the command derives the missing *p*-value information using the *t*-test formula based on *t*/*z*-scores (`zscore(varname)`), standard errors (`se(varname)`), and optionally degrees of freedom (`df(varname)`). If no degrees of freedom are provided, a normal distribution is assumed. Note that this assumption may be inappropriate, for example in small samples, when *p*-values are derived using randomisation inference, or in designs using complex estimations such as those that account for survey sampling, e.g. via the Stata command `svy:`. Conversely, if your input *p*-values are based on distributional assumptions other than normality, the derived standard errors may be inaccurate. It is therefore recommended to provide both *p*-values and standard errors. 

> [!IMPORTANT]  
> Replicators of the **Robustness Reproducibility in Economics(R<sup>2</sup>E)** project should always apply a 5\% significance level to the robustness analysis, i.e. `siglevel(5)`.

<ins>Units of effect size measurement</ins>: The command assumes that effect sizes in the original and robustness analysis are measured in the same units. If not (e.g. one is in logs and the other is not), specify the option `sameunits(varname)`, where the variable **varname** is 1 if units match and 0 otherwise.

<ins>Inclusion of original specification in multiverse</ins>: By defalut, the original specification is assumed *not* to be part of the robustness analysis paths. If it is, specify via the option `orig_in_multiverse(varname)` for which result the specification from the original analysis should be included in the multiverse robustness analysis. Then, the original specification is incorporated in the computation of three of the [variation indicators](#the-reproducibility-and-replicability-indicators) ($I_{4}$, $I_{5}$, and $I´_{3}$) for the respective result(s). Regardless of whether the original specification is included as one robustness analysis path or not, the original specification for each result must appear as a separate analytical path in the input data. 


## Required input data structure 

### Data structure for analyses at study level

The input data at study level needs to be in a specific format for `repframe` to calculate the indicators and dashboards. Each observation should represent one analytical path, which is the combination of analytical decisions in a multiverse robustness analysis. 

The dataset must contain the following variables. The table also lists the `repframe` option used to include the variable as well as the variable name in the example presented below the table:

| variable type | `repframe` option | variable name in snippet | note
| ---- | ---- | ---- | ---- | 
| result | - | outcome | should be numeric with value labels
| coefficient | `beta()` | b |
| standard error and/or *p*-value | `se()` <br>  `pval()` | se <br> p | It is recommended to specify both the information on *p*-values and on standard errors, as outlined above in the sub-section on [defaults applied by the `repframe` command](#defaults-applied-by-repframe)
binary indicator identifying the original path | `origpath()` | origpath | | 
level of statistical significance in the original analysis | `siglevel_orig()` | - | | 
level of statistical significance in the robustness analysis | `siglevel()` | - | 


<br> 
<img width="1200" alt="toy example of repframe multiverse input data structure" src="https://github.com/user-attachments/assets/2999922e-4943-4da0-b4a9-7173b02ed479"> &nbsp;

The Stata help file contains a simple example that uses the command [`repframe_gendata`](https://github.com/guntherbensch/repframe/blob/main/repframe_gendata.ado) to build such a data structure. 

For this example, the minimum command input looks as follows:
```stata
repframe outcome, beta(b) se(se) pval(p) origpath(origpath) siglevel_orig(10) siglevel(5)
```

The `repframe` command gives error messages if requirements are not met.

The specific dataset example shown above includes two additonal types of variables that are typically important: first, the variable *orig_include* tells us that the original specification is supposed to be included in the mutiverse robustness analysis. Since the `repframe` command by default assumes *not* to include this specification, we should additionally specify the option `orig_in_multiverse()`. 

Second, we see that four analytical decisions are varied for the main result, here referred to as *cov1* to *if_cond*, where *cov1* refers to the inclusion of a certain covariate set, for example. These variables help to define each unqiue analytical path. While these variable are not required for `repframe` to work, if included via the `decisions()` option, `repframe` can produce a set of complementary plots that allow further examination of the robustness of the results (see [below](#complementary-coefficient-and-contribution-plots)). Here, each decision variable should be labelled, numeric with the decision adopted by the original authors always being zero, and with labelled values. 

```stata
repframe outcome, beta(b) se(se) pval(p) origpath(origpath) siglevel_orig(10) siglevel(5) orig_in_multiverse(orig_include) decisions(cov1 cov2 cov3 ifcond)
```


### Data structure for analyses across studies

The `repframe` command can also compile Reproducibility and Replicability Indicators across studies. To do so, one only has to append the *study-level indicator data* that include the Reproducibility and Replicability Indicators of individual studies and then feed them back into a variant of the `repframe` command. 
In Stata, the following steps need to be taken:
1. run `repframe` for each individual study to create the *study-level indicator data* saved as *repframe_data_studies_[fileidenfier].dta* &mdash; with [fileidenfier] as defined by the option `fileidentifier(string)`; always use the same significance level, which is stored in the variable **siglevel**
2. append the individual *study-level indicator data*   
3. ecode and clean the dataset using the following Stata code

```stata
. encode ref, gen(reflist)
. drop ref
. order reflist
. save "[filename].dta", replace
```
&ensp; where [filename] can be freely chosen for the dataset containing all appended *study-level indicator data*, potentially including the full path of the file.  
4. run `repframe` again, now using the option `studypool(1)` to request the calculation of indicators across studies. 


## The Reproducibility and Replicability Indicators

The *Reproducibility and Replicability Indicators table* and the *Robustness Dashboard* present two separate sets of indicators designed to capture different aspects of robustness. These indicators are especially appropriate for robustness reproducibility assessments where the same data is analyzed under varying specifications ([Dreber and Johannesson 2025](#references)). 

This makes it plausible to assume that the tests of robustness reproducibility and the original study measure exactly the same underlying effect size, with no heterogeneity and no difference in statistical power. For tests of replicability using new data or alternative research designs, more sophisticated indicators are required to account for potential heterogeneity and differences in statistical power (cf. [Patil et al. 2016](#references), [Mathur and VanderWeele 2020](#references), [Pawel and Held 2022](#references)).

The indicators cover the following three pieces of information on reproducibility and replicability, related to either statistical significance or effect sizes:
- <ins>agreement indicators</ins>: Do the original and robustness analyses exhibit the same level of statistical significance (effect size)?
- <ins>relative indicators</ins>: To what extent does the statistical significance (do effect sizes) differ between the original and robustness analysis paths?
- <ins>variation indicators</ins>: To what extent does the statistical significance (do effect sizes) vary across robustness analysis paths? 

If different significance thresholds ${\alpha}$ are used in original versus robustness analyses, the *Robustness Dashboard* also includes:
- <ins>significance classification agreement indicator</ins>: Do the original and robustness analyses agree in terms of whether their findings are classified as statistically significant?

If the option `extended(string)` is used, the dashboard furthermore adds:
- <ins>significance switch indicator</ins>: To what extent are robustness coefficients (standard errors) large (small) enough to have turned an originally insignificant result significant, regardless of the associated standard error (coefficient)? And what about the reverse for originally significant results?   

With `ivarweight(1)`, the indicators can be weighted inversely to their variance, analogous to meta-analysis techniques.


### Reproducibility and Replicability Indicators table

The following describes the main indicators presented in the *Reproducibility and Replicability Indicators table* as they are computed at the level of each assessed result within a single study. Aggregation across results at the study level is simply done by averaging the indicators as computed at the result level, separately for results reported as originally significant and results reported as originally insignificant. Similarly, aggregation across studies is simply done by averaging the indicators as computed at the study level. An example of a *Reproducibility and Replicability Indicators table* at the study level is provided at the end of this section.

1. The **statistical significance indicator** as a significance agreement indicator measures for each result $j$ the share of the $n$ robustness analysis paths $i$ that are reported as statistically significant or insignificant in both the original study and the robustness analysis. Accordingly, the indicator is computed differently for results where the original estimates were reported as statistically significant and those where the original estimates were found to be statistically insignificant. Statistical significance is defined by a two-sided test with $\alpha^{orig}$ being the significance level applied in the original study and $\alpha$ being the significance level applied in the robustness analysis. For statistically significant original estimates, the effects of the robustness analysis paths must also be in the same direction as the original estimate, as captured by coefficients having the same sign or, expressed mathematically, by $\mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)$.

$$ I_{1j} = mean(\mathbb{I}(pval_i \le \alpha) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0))  \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{1j} = mean(\mathbb{I}(pval_i > \alpha))  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$
  
:point_right: This share indicator is intended to capture whether statistical significance in a robustness analysis confirms statistical significance in an original study. The indicator reflects a combination of *technical* agreement of results (do estimates agree in terms of achieving a certain level of statistical significance?) and *classification* agreement as introduced above (do estimates agree in terms of whether they are classified as statistically significant, given a potentially more or less demanding level of statistical significance applied by original authors?).  
> *Interpretation*: An indicator $I_{1j}$ of 0.3 for a result $j$ reported as statistically significant in the original study, for example, implies that 30\% of robustness analysis paths for this result (i) are statistically significant according to the significance level adopted in the robustness analysis, and (ii) that their coefficients share the same sign as the coefficient in the original study. Conversely, 70\% of robustness analysis paths for this result are most likely statistically insignificant, while it cannot be excluded that part of these paths are statistically significant but in the opposite direction. Note also that robustness analysis paths for this result may be found statistically insignificant &mdash; and thus non-confirmatory &mdash; only because of a stricter significance level adopted in the robustness analysis compared to the original study. An indicator of 0.3 for results reported as statistically insignificant in the original study implies that 30\% of robustness analysis paths for this result are also statistically insignificant according to the significance level adopted in the robustness analysis. Now, the remaining 70\% of robustness analysis paths are statistically significant (most likely with the same sign), while a less strict significance level applied in the robustness analysis could now affect this indicator.   


2. The **relative effect size indicator**  measures the mean of the coefficients $\beta_i$ of all robustness analysis paths for each result $j$ divided by the original coefficient $\beta^{orig}_j$. The indicator requires that effect sizes in the original and robustness analyses are measured in the same units. It is also only applied to results reported as statistically significant in the original study, now &mdash; and for the following indicators as well &mdash; irrespective of whether they are in the same direction or not.

$$ I_{2j} = \frac{mean(\beta_i)} {\beta^{orig}_j} \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{2j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$

:point_right: This ratio indicator is intended to capture how the size of robustness coefficients compares to the size of original coefficients.  
> *Interpretation*: An indicator $I_{2j}$ above 1 implies that the mean of the coefficients of all the robustness analysis paths for a statistically significant original result $j$ is &mdash; in absolute terms &mdash; higher than the original coefficient (while both show in the same direction), with a factor of $I_{2j}$ (e.g. 1.3). An indicator between 0 and 1 means that the mean coefficient in the robustness analysis paths is lower than the original coefficient (while both show in the same direction), again with a factor of $I_{2j}$ (e.g. 0.7). An indicator below 0 implies that the two compared statistics have different signs. Here, the absolute value of the mean coefficient in the robustness analysis paths is higher (lower) than the absolute value of the original coefficient if $I_{2j}$ is above (below) -1.


3. The **relative *t*/*z*-value indicator** as a relative significance indicator measures for each result $j$ the mean of the *t*/*z*-values ($zscore_i$) of all the robustness analysis paths divided by the *t*/*z*-value from the original analysis. The indicator is also only derived for results reported as statistically significant in the original study.

$$ I_{3j} = \frac{mean(zscore_i)} {zscore^{orig}_j} \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{3j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$ 

:point_right: This ratio indicator is designed to compare the statistical significance in a robustness analysis to that in the original study.
> *Interpretation*: An indicator $I_{3j}$ above (below) 1 means that the average *t*/*z*-value of all robustness analysis paths for result $j$ is &mdash; in absolute terms &mdash; higher (lower) than the original coefficient, suggesting a higher (lower) level of statistical significance in the robustness analysis. An indicator below 0 additionally implies that the two compared statistics have different signs, where the absolute value of the mean *t*/*z*-value in the robustness analysis paths is higher (lower) than the absolute value of the original *t*/*z*-value if $I_{3j}$ is above (below) -1.


4. The **effect size variation indicator** measures for each result $j$ the standard deviation $sd$ of all robustness coefficients divided by the standard error $se$ of the original coefficient. 
Here, the $\beta_i$ may incorporate the original specification as one robustness analysis path. The indicator requires that effect sizes of the original and robustness analyses are measured in the same units.

$$ I_{4j} = \frac{sd(\beta_i)}{se(\beta^{orig}_j)} $$

applied separately to $pval^{orig}_j \le \alpha^{orig}$ and $pval^{orig}_j > \alpha^{orig}$. 

:point_right: This ratio indicator is intended to capture how the variation in coefficients of a robustness analysis compares to the variation estimated for the original coefficient.
> *Interpretation*: An indicator $I_{4j}$ above (below) 1 means that variation across all robustness analysis paths for result $j$ is higher (lower) than the variation estimated in the original analysis, with a factor of $I_{4j}$. 


5. The ***t*/*z*-value variation indicator** as a significance variation indicator measures the standard deviation of *t*/*z*-values of all the robustness analysis paths for each result $j$. Here, the $zscore_i$ may incorporate the original specification as one robustness analysis path.

$$ I_{5j} = sd(zscore_i)  $$

applied separately to $pval^{orig}_j \le \alpha^{orig}$ and $pval^{orig}_j > \alpha^{orig}$. 

:point_right: This absolute indicator is intended to capture the variation in the statistical significance across robustness analysis paths.
> *Interpretation*: $I_{5j}$ simply reports the standard deviation of *t*/*z*-values of all the robustness analysis paths for result $j$ as a measure of variation in statistical significance. Higher values indicate higher levels of variation.

The following shows an example of the *Reproducibility and Replicability Indicators table*, indicating the five indicators as outlined above. The indicators are grouped by whether the respective result was originally reported as statistically significant or not. Each of these two sets of indicators also includes the average across the respective results. 

<img width="600" alt="repframe indicators table example" src="https://github.com/guntherbensch/repframe/assets/128997073/24f31cc0-87b4-42bf-8446-621e22db3fe5"> &nbsp;
&nbsp;

As additional references, the second to fourth columns of the table contain the following three figures on the estimate from the original study:
  - original beta estimate, $\beta^{orig}_j$
  - original beta estimate, expressed as % deviation from original mean of the outcome, i.e. $\beta^{orig}_j$ $/$ $mean^{orig}_j$ $\times$ 100
  - *p*-value of original beta estimate, $pval^{orig}_j$. 
  

### Robustness Dashboard

The Robustness Dashboard is a key feature of `repframe`, offering a visual summary of how robust the results of a study are across different analytical choices. 

To ensure clarity and meaningfulness, indicators are calculated and shown only for subsets of robustness paths for which they are most informative. For example, the *relative effect size indicator* is only computed for robustness paths that are statistically significant and share the same sign as the original estimate. This selective calculation helps avoid meaningless averages (e.g., over opposite-sign or non-significant estimates) and keeps the visual output focused. 

The dashboard contains up to nine indicators:
- A core set of four default indicators, $I´_1$ to $I´_4$
- Two conditional indicators, $I´_5$ and $I´_6$
- Three indicators in an extended version of the dashboard, $I´_7$ to $I´_9$, which are shown if requested using the `customindicators()` option.  

When aggregating across multiple results (within a study or across studies), each indicator is averaged separately for originally significant and originally insignificant results. Unlike the indicators in the *Reproducibility and Replicability Indicator table*, the dashboard always applies the same significance level (α) to both original and robustness analyses. This is meant to clearly separate:

- Technical agreement: whether robustness paths reproduce the result under the same significance threshold;

- Classification disagreement: whether discrepancies are due to different significance thresholds being applied in the original study and in the robustness analysis.

 See the [example dashboard figures](#the-dashboard-output) below for a study-level visualization.


1. The **significance agreement indicator** is the share of robustness paths that agree with the original result in terms of statistical significance and direction. It is derived for each result $j$ in a similar way as the *statistical significance indicator* from the *Reproducibility and Replicability Indicators table*. The only differences are that (i) the indicator is the same for statistically significant and insignificant estimates in robustness analyses and that (ii) the same significance level $\alpha$ is applied to the original analysis and to the robustness analysis (note that (ii) only becomes relevant when aggregating into significant versus insignificant original results, as done in the [bottom Dashboard figure](#the-dashboard-output) below). The indicator is expressed in \% of all robustness analysis paths on either statistically significant or insignificant original results and, hence, additionally multiplied by 100. For statistically significant robustness analysis paths with the same sign, the indicator is calculated as follows: 

$$ I´_{1j} = mean(\mathbb{I}(pval_i \le \alpha) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)) \times 100 $$

applied separately to $pval^{orig}_j \le \alpha$ and $pval^{orig}_j > \alpha$. 
The same indicator is also calculated for statistically significant robustness analysis paths with opposite sign, i.e. differing from the above formula through $\mathbb{I}(\beta_i \times \beta^{orig}_j < 0)$. For statistically insignificant robustness analysis paths, the indicator corresponds to 100 minus these two indicators on statistically significant results with same and opposite sign. 

:point_right: This proportion indicator is intended to capture the *technical* agreement of results (are estimates robust in terms of achieving a certain level of statistical significance?).
> *Interpretation*: An indicator $I´_{1j}$ of 30\% implies that 30\% of robustness analysis paths for result $j$ are statistically significant. Depending on which of the four sub-indicators of the *Robustness Dashboard* one is referring to, this refers to (i) statistically significant *or* insignificant original results and to (ii) original and robustness coefficients that share *or* do not share the same sign. For example, if $I´_{1j}$ is 30\% for results with the same sign and 3\% for results with opposite signs, the remaining 67\% of robustness analysis paths for this result are statistically insignificant. The significance levels applied to the original study and the robustness analysis are identical and correspond to the one defined in the robustness analysis.


2. The **relative effect size indicator** is the median robustness coefficient of same-sign significant paths compared to the original coefficient, in percent of the original coefficient. It differs from $I_{2j}$ from the *Reproducibility and Replicability Indicators table* in that it is only derived for robustness analysis paths that are (i) statistically significant and (ii) in the same direction as the original estimate. This ensures it reflects meaningful variation in magnitude rather than direction, and prevents opposite-sign estimates from disproportionately skewing the indicator. In addition, the indicator takes the median of the robustness coefficients instead of the mean, in order to be less sensitive to outliers and to center the indicator more clearly on shifts in effect size levels, rather than overall variation, which is separately captured the *effect size variation indicator* introduced below. Furthermore, one is subtracted from the ratio, in order to underscore the relative nature of the indicator. A ratio of 2/5 thus turns into -3/5, and multiplied by 100 to -60\%, making it a scaled difference indicator. Just like $I_{2j}$, the indicator requires that effect sizes in the original and robustness analyses are measured in the same units. 

$$ I´_{2j} = (\frac{median(\beta_i)} {\beta^{orig}_j} - 1) \times 100  \quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha \land \beta_i \times \beta^{orig}_j \ge 0 $$

$$ I´_{2j}  \text{ not applicable otherwise} $$

:point_right: This scaled difference indicator is intended to capture how effect sizes of robustness analyses compare to the original effect sizes. The indicator focuses on the case where a comparison of effect sizes is most relevant and interpretable, that is when both the original and robustness analysis yield estimates that are statistically significant and in the same direction.  
> *Interpretation*: An indicator $I´_{2j}$ for result $j$ with an originally significant result (below) 0\% means that the mean of statistically significant robustness coefficients in the same direction as the original estimate is higher (lower) than the original coefficient, by $I´_{2j}$\% &mdash; e.g. +30\% (-30\%).


The *Robustness Dashboard* does not include a **relative significance indicator**.


3. The **effect size variation indicator** measures the mean absolute deviation of robustness coefficients from their median, relative to the original coefficient. Like $I´_{2j}$, it only considers robustness analysis paths for results reported as statistically significant that are (i) statistically significant and (ii) in the same direction as the original estimate. The mean value is divided by the original coefficient and multiplied by 100 so that it is measured in the same unit as $I´_{2j}$. Here, the $\beta_i$ may incorporate the original specification as one robustness analysis path. The indicator requires that effect sizes in the original and robustness analyses are measured in the same units.

$$ I´_{3j} = \frac{mean(\mid \beta_i - median(\beta_i) \mid)}  {\beta^{orig}_j} \times 100  	\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha \land \beta_i \times \beta^{orig}_j \ge 0 $$ 

$$ I´_{3j}  \text{ not applicable otherwise} $$

:point_right: This ratio indicator is intended to capture how the variation in coefficients of robustness analysis paths compares to the size of the original coefficient. The indicator complements $I´_{2j}$ focusing on the case of original and robustness analyses with estimates that are statistically significant and in the same direction. 
> *Interpretation*: An indicator $I´_{3j}$ of, for example, 10\% means that variation across robustness analysis paths for result $j$ is equivalent to 10\% of the original coefficient. 


4. The **significance variation indicator** is the average difference in p*-values between all robustness analysis paths and the original analysis. This indicator is always derived, except for robustness and original analyses with both statistically significant estimates, since the deviation is known to be small in that case.

$$ I´_{4j} = mean(\mid pval_i - pval^{orig}_j \mid) $$ 

applied separately to (i) $pval^{orig}_j \le \alpha \land pval_i > \alpha$, 
                     (ii) $pval^{orig}_j > \alpha \land pval_i > \alpha$, and 
                    (iii) $pval^{orig}_j > \alpha \land pval_i \le \alpha$.

:point_right: This absolute indicator is intended to capture the variation in statistical significance across robustness analysis paths that turned or are statistically insignificant.
> *Interpretation*: An indicator $I´_{4j}$ of 0.2, for example, implies that *p*-values among certain robustness analysis paths for result $j$ on average differ by 0.2 from the original *p*-value. Depending on which of the three sub-indicators of the *Robustness Dashboard* one is referring to, this refers to the case of (i) a significant estimate in the original analysis and insignificant estimates in the robustness analysis, (ii) an insignificant estimate in the original analysis and insignificant estimates in the robustness analysis, or (iii) an insignificant estimate in the original analysis and significant estimates in the robustness analysis. Like *p*-values themselves, this deviation may assume values between 0 (very small deviation) and 1 (maximum deviation). 


5. The **effect size agreement indicator** measures the share of insignificant robustness paths that fall within the  confidence interval of the original estimate, $\beta(cilo)^{orig}_j$ and $\beta(ciup)^{orig}_j$. It only considers statistically insignificant robustness analysis paths for results reported as statistically significant in the original study, and applies the significance level $\alpha$ adopted in the robustness analysis. The indicator requires that effect sizes in the original and robustness analyses are measured in the same units.

$$ I´_{5j} = mean(\mathbb{I}(\beta(cilo)^{orig}_j \le \beta_i \le \beta(ciup)^{orig}_j)) \times 100 		\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i > \alpha $$ 

$$ I´_{5j}  \text{ not applicable otherwise} $$

:point_right: This proportion indicator is intended to complement the *significance agreement indicator* and thereby to capture *technical* agreement of results not only in terms of achieving a certain but arbitrary level of statistical significance, but also in terms of showing similarity of coefficients.
> *Interpretation*: An indicator $I´_{5j}$ of 10\% implies that 10\% of robustness analysis paths for this result $j$ with originally significant results are insignificant according to the significance level adopted by the robustness analysis, but with robustness coefficients that cannot be rejected to lie inside the confidence interval of the estimate. The closer these 10\% are to the share of statistically insignificant robustness analysis paths for this result, the less does this indicator confirm the *statistical significance indicator*. For example, if the share of statistically insignificant robustness analysis paths for this result is 15\%, two-thirds of these analytical paths are non-confirmatory according to *statistical significance indicator* and confirmatory according to the *effect size agreement indicator*.


6. The **indicator on non-agreement due to significance classification** is an indicator that focuses on *classification* robustness of results as defined above. It applies only in situations in which an original study applied a different &mdash; more or less stringent &mdash; classification of what constitutes a statistically significant result than the robustness analysis. The indicator reflects the share of disagreement in statistical significance due to different significance thresholds between original and robustness analysis. Specifically, it identifies those originally significant (insignificant) results that have statistically insignificant (significant) robustness analysis paths only because a more (less) stringent significance level definition is applied in the robustness analysis than in the original study. The indicator is also expressed in \% and therefore includes the multiplication by 100. For the case where a more stringent significance level definition is applied in the robustness analysis, the indicator is calculated as follows.

$$ I´_{6j} = mean(\mathbb{I}(\alpha < pval_i \le \alpha^{orig})) \times 100  \quad  \text{if } \alpha < pval^{orig}_j \le \alpha^{orig} $$

$$ I´_{6j}  \text{ not applicable otherwise} $$

In the opposite case, with a less stringent significance level definition applied in the robustness analysis, the same formula applies with opposite signs.

:point_right: This proportion indicator is intended to capture non-robustness of findings reported as (in)significant in original studies that is due to differences in the classification of statistical significance.
> *Interpretation*: Consider the case where the robustness analysis paths apply a significance level of 5\% and the original analysis applied a less strict significance level of 10\%. In this case, estimates from robustness analyses with $0.05 < pval_i \le 0.10$ are only categorized as insignificant and thus having a non-agreeing significance level because of differing definitions of statistical significance. An indicator $I´_{6j}$ of 10\%, for example, implies that this holds true for 10\% of robustness analysis paths for result $j$.


7. The **significance classification agreement indicator** is the aggregate share of robustness paths that confirm the original classification as significant or insignificant. 

$$ I´_{7j} =    I´_{1j}^{ssign}                    \times 100   \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I´_{7j} = (1-I´_{1j}^{ssign} - I´_{1j}^{nsign}) \times 100   \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$ 

where *ssign* refers to $I´_{1j}$ when derived for estimates from robustness analyses with the same sign, and *nsign* when derived for estimates from robustness analyses with the opposite sign.

The indicator presented in the *Robustness Dashboard* is the average across all results or studies.

$$ I´_{7} =    mean(I´_{7j}) $$     

This is different from the other indicators, as it is not differentiated by whether results are originally significant or insignificant.

In cases where the robustness analysis and original study or studies applied different significance levels, the *Robustness Dashboard* additionally shows this indicator when applying a uniform significance level, that is when the formulae include $\alpha$ instead of $\alpha^{orig}$. Both indicators have their advantages and disadvantages. Consider the example with $pval^{orig}_j$=0.07, $\alpha$=0.05, and $\alpha^{orig}$=0.10. Here, the former indicator would categorize robustness analysis paths with equal *p*-values of $pval_i$=0.07 as non-confirmatory, whereas the latter indicator would categorize robustness analysis paths with lower *p*-values of $pval_i$=0.04 as non-confirmatory, both of which can be seen as contrary to common intuition. It is therefore generally recommended to use the same significance level in a robustness analysis as in the original study or studies (if the latter differ among each other, the less stringent significance level is to be chosen).    

:point_right: This proportion indicator is intended to capture to which degree statistical significance as reported in original studies is confirmed through the robustness analyses &mdash; where the classification of statistical significance may differ from that of the original study or not.  
> *Interpretation*: An indicator $I´_{7}$ of 80\% implies that the classification into significant or insignificant in robustness analysis paths confirms the classification by original authors in 80\% when averaged over individual results (studies).  


#### Extended set of Robustness Dashboard indicators 
The *Robustness Dashboard* additionally includes the option `customindicators(string)` that allows showing the following type of indicators in an extended set of indicators. 

8. & 9. The **significance switch indicators** include two sub-indicators that capture the shares of robustness paths where a change in coefficient or standard error would reverse significance status. Both are derived separately for originally significant and insignificant results. For originally significant results, these indicators measure the share of robustness coefficients (standard errors) that are sufficiently small (large) to have turned the result insignificant when standard errors (coefficients) are held at their values in the original study. Whether absolute values of coefficients (standard errors) are sufficiently small (large) is determined based on the threshold values $\beta(tonsig)_j$ and $se(tonsig)_j$. The indicators require that effect sizes in the original and robustness analyses are measured in the same units.

$$ I´_{8j} = mean(\mathbb{I}(\mid \beta_i \mid  \le \beta(tonsig)_j)) \times 100   		\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i > \alpha $$ 

$$ I´_{9j} = mean(\mathbb{I}(se_i  \ge se(tonsig)_j)) \times 100   		\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i > \alpha $$ 

The indicators for originally insignificant results are a mirror image of those for originally significant results: now the indicators measure the shares of robustness coefficients (standard errors) that are sufficiently large (small) to have turned results significant, applying threshold values $\beta(tosig)_j$ and $se(tosig)_j$, respectively.   

$$ I´_{8j} = mean(\mathbb{I}(\mid \beta_i \mid  > \beta(tosig)_j)) \times 100   		\quad  \text{if } pval^{orig}_j > \alpha \land pval_i \le \alpha $$ 

$$ I´_{9j} = mean(\mathbb{I}(se_i  < se(tosig)_j)) \times 100   		\quad  \text{if } pval^{orig}_j > \alpha \land pval_i \le \alpha $$ 

:point_right: These proportion indicators are intended to capture the drivers behind changes in statistical significance between original study and robustness analysis.
> *Interpretation*: An indicator $I´_{8j}$ of, for example, 30\% for a result $j$ with an originally significant result, implies that 30\% of the robustness analysis paths that are statistically insignificant have coefficients that are sufficiently small for the robustness analysis path to be statistically insignificant even if the standard error would be identical to the one in the original study. The other (sub-)indicators can be interpreted analogously. 


#### Weak-IV-robust inference adjustments in the Robustness Dashboard
The *Robustness Dashboard* can be extended to incorporate adjustments that reflect robust hypothesis testing in the presence of weak instruments. Three approaches are supported, each allowing the dashboard to additionally provide a weak-IV-robust version of the *significance agreement indicator*.

1. ***tF* adjustment**:
Developed by [Lee, Moreira, and co-authors](#references), the *tF* approach adjusts conventional standard errors and *p*-values based on the first-stage *F*-statistic. The user must supply *F*-statistics for each specification via the `tFinput()` option. The adjustment applies a smooth correction factor to standard errors, improving inference under weak instruments relative to the standard 2SLS *t*-test.
2. ***VtF* adjustment**:
The *VtF* approach (also by [Lee et al.](#references)) requires the user to supply *VtF*-adjusted critical values, such as those obtained using the user-written *VtF* command in Stata ([link](https://irs.princeton.edu/davidlee-supplementVTF)). This is also done via the `tFinput()` option. Unlike *tF*, *VtF* does not yield adjusted standard errors or *p*-values. Instead, the dashboard uses the critical values to calculate a *VtF*-adjusted significance indicator at the 5\% or 1\% level.
*VtF* leverages additional information &mdash; specifically, the empirical correlation between residuals from the 2SLS regression &mdash; making it more powerful than *tF*. It yields shorter confidence intervals and improves the likelihood of detecting true effects under weak instruments. When using this option, the dashboard expects that the provided critical values correspond to the 5\% level (if the applied significance level is above 1\%) or to the 1\% level (if the applied level equals 1\%).
Both *tF* and *VtF* ensure correct test size but do not resolve the power asymmetry problem &mdash; the tendency of *t*-based IV inference to favour one direction of effect over the other under weak instruments. As emphasized by [Keane & Neal (2024)](#references), this can lead to misleading conclusions about the sign of the effect. In addition, both methods are only applicable to just-identified models with a single instrument.
3. **Anderson–Rubin (AR) test**:
The AR test provides a weak-IV-robust alternative that avoids power asymmetry and maintains valid inference regardless of instrument strength. The dashboard can incorporate AR *p*-values, which the user supplies via the `pval_ar()` option (e.g., extracted from the `weakiv` command in Stata). This method is particularly attractive in the single-instrument case, where the AR test has a known finite-sample distribution. However, AR-based inference is typically less powerful than that based on the *VtF* adjustment.

In addition to these three inference adjustments, the dashboard can include an alternative indicator that interprets weak instruments as less problematically:

4. **Sign disagreement based on first-stage direction**:
As argued in [Angrist & Kolesár (2024)](#references), IV specifications with a first-stage coefficient in the *unexpected* direction are the ones most likely to generate misleading inference under weak instruments. The `signfirst()` option therefore allows the user to flag the proportion of specifications in which the first-stage coefficient has the wrong sign. Rather than adjusting existing dashboard indicators, this additional sign disagreement indicator offers a less conservative approach to diagnosing weak-IV problems. It helps identify the extent to which robustness analyses include specifications that are not just weak, but problematic from the perspective of directional validity of the instrument.


#### The Dashboard output

The following shows an example of the *Robustness Dashboard*, indicating where the indicators outlined above can be found in the figure. Indicators from the extended set are in lighter blue. The vertical axis of the dashboard shows individual results, grouped into statistically significant and insignificant if aggregated. Note that this grouping may differ from the one in the *Reproducibility and Replicability Indicators table*, because that table applies to original results the significance level defined by original authors, whereas the dashboard applies the same significance level as adopted in the robustness analysis. The horizontal axis distinguishes between analysis paths with statistically significant and insignificant estimates, additionally differentiating between statistically significant estimates in the same and in opposite direction as the estimates from the original study. Circle sizes illustrate $I´_{1j}$, the *significance agreement indicator*. They are coloured in either darker blue for confirmatory results or in lighter blue for non-confirmatory results. As can be seen with Outcome 3 in the figure, this colouring also discriminates $I´_{1j}$ from $I´_{6j}$, the *indicator on non-agreement due to significance classification*.

When aggregating across results or studies, the bottom of the dashboard additionally includes a histogram with the share of confirmatory results and absolute values of effect sizes. 

In the results window of Stata, the `repframe` command provides additional information on the (minimum and maximum) number of specifications that have been used to derive the dashboard indicators.   

<img width="700" alt="repframe Robustness Dashboard example" src="https://github.com/user-attachments/assets/7dafd122-ac5c-4aef-b092-e84484294215"> &nbsp;
&nbsp;

<img width="700" alt="repframe Robustness Dashboard example, aggregated" src="https://github.com/user-attachments/assets/a3466d49-37a5-4485-bf4f-74299960c25e"> &nbsp;


#### Complementary coefficient and contribution plots 
`repframe` allows complementing the *Robustness Dashboard* by other plots that visualize how estimates vary across specifications and which decisions drive that variation:

- Coefficient Plot: Displays point estimates and confidence intervals for the original estimate and the preferred robustness analysis path &mdash; as specified via the option `prefpath()`. This helps assess the consistency of effect size and direction across key analytical paths.

- Contribution Plots: These plots decompose the variation in estimates or indicators by showing how much individual decision contributes to the overall robustness pattern:

  - Single-Choice Deviation Plot: Shows the change in a robustness indicator when one decision is fixed to an alternative choice, while others vary.

  - Stepwise Deviation Plot: Illustrates how an indicator changes as more decisions are gradually shifted away from the original specification.

  - Single-Decision Reversion Plot: Shows the change in a robustness indicator when one decision is fixed back to its original choice, while others vary.

These plots offer intuitive visual diagnostics of the influence of model decisions and help zoom into key sources of result variation.

### Summary

The following table summarizes which indicators are included in the *Reproducibility and Replicability Indicators table* and the *Robustness Dashboard*. 

| Type of indicator  | | Reproducibility and Replicability Indicators table | Robustness Dashboard | Symbol in Dashboard |
| ------------------ | --------------------- | --------- | ---------- | -- |
|significance (sig.) | sig. agreement        |  $I_{1}$  |  $I´_{1}$  | (main figure in dashboard - no symbol) |
|                    | relative sig.         |  $I_{3}$  |  -         | - | 
|                    | sig. variation        |  $I_{5}$  |  $I´_{4}$  | $\overline{\Delta p}$ (mean abs. var. of *p*-value) |
|                    | sig. classification agreement | - |  $I´_{6}$ (if different sig. levels) | *p* $\le$ ${\alpha}^o$ (less stringent sig. level applied in original study) or *p* > ${\alpha}^o$ (more stringent sig. level applied in original study)|
| | overall sig. (and sig. classification) agreement | - |  $I´_{7}$ (if aggregated) | $\overline{\kappa}$ (mean share of confirmatory results)|  
|                    | sig. switch           |  -        |  $I´_{8}$ \& $I´_{9}$ (ext.)  | high/ low ${\|\beta\|}$ (abs. value of ${\beta}$) and ${se}$ |
| effect size (e.s.) | e.s. agreement        |     -     |  $I´_{5}$  | ${\beta}$ in ${CI}(\beta^o)$ (confidence interval of orig. ${\beta}$) |
|                    | relative e.s.         |  $I_{2}$  |  $I´_{2}$  | $\widetilde{\beta}$ (median ${\beta}$) |
|                    | e.s. variation        |  $I_{4}$  |  $I´_{3}$  | $\overline{\Delta\beta}$ (mean abs. var. of ${\beta}$) |


## Update log

2025-06-21, v1.7.1:

- Dashboard update with publication of the working paper *The Robustness Dashboard*, [Bensch et al. (2025)](#references):
  - If `siglevel(5)` is specified, not only show *significance agreement indicator* for p $\le$ 0.05 as the main value in the bubble, but also include the same indicator calculated for p $\le$ 0.10 in a smaller label beneath the bubble. This provides a sensitivity check that allows users to assess whether agreement in statistical significance is robust to adopting a slightly more lenient threshold, as is often used in original studies.

2025-05-16, v1.7:

- Replace option `extended(string)` by `customindicators(string)` in order to additionally allow for a "skeleton" version of the *Robustness Dashboard* that only includes the bubbles with the statistical significance indicator, which can be called via `customindicators(SIGagronly)`.
- Update how *Robustness Dashboard* can account for weak instruments:
  - Replace option `iVF()` by `tFinput(string varname)` to allow for both *tF* and *VtF* adjustment as proposed by [Lee et al. (2022)](#references) and [Lee et al. (2023)](#references).
  - Add option `pval_ar(varname)` to also allow for weak-IV adjustment following [Anderson and Rubin (1949)](#references). 
  - If `aggregation(0)` and `studypooling(0)` and `tFinput(tF ...)` or `pval_ar()` being defined, add to the original estimate the t*F*- or AR-adjusted *p*-value resulting from the analysis path of the original study.
- Remove "0%" from dashboards generated with `aggregation(1)` when the value is not applicable &mdash; that is, when no results in that category exist, such as when no original estimates were significant or insignificant.
- Fix minor bugs occurring with `studypooling(1)`.
  
2024-12-06, v1.6:

- Include option `decisions()` that allows accounting for the analytical decisions taken; if option `decisions()` is defined, `repframe` creates a set of three complementary plots that show the contributions of individual decisions to deviations in indicator values.
  - Because of that inclusion, the input data structure had to be revised in that the specification adopted by the original authors is included as an individual analytical path, and not only via the variables ending with *_orig*; this allows for a straightforward way of specifying the `decisions()` taken by the original authors for each of the results. Another advantage of this data structure is that it correpsonds to th  data strucutre used by related commands such as [`speccurve`](https://github.com/martin-andresen/speccurve).
  - in the process of this revision, the option `origpath()` was introduced to specify the original authors' specifications, one for each result.
  - relatedly, all *_orig* options &mdash; except siglevel_orig &mdash; have been removed from the `repframe` command.
- Include option `prefpath()`. If a preferred new specification can be identified in a robustness test, this option allows identifying such a preferred new specification, and `repframe` creates another complementary plot that compares the original estimate with this preferred estimate of the robustness test.   
- The option `orig_in_multiverse()` now requests a variable instead of a simple 0-1 indicator; this allows for setting this option differently for individual results. 
- Resolve [Issue #1](https://github.com/guntherbensch/repframe/issues/1), that is providing an explanation of **beta_rel_orig** in the github Readme.
- Data at level of analytical path with uniform set of variables and uniform naming stored as *repframe_data_analysispaths_[fileidenfier].dta*.
  - in the process of this revision, the name under which the study-level data is stored has been changed to *repframe_data_studies_[fileidenfier].dta* (from *repframe_data_[fileidenfier].dta*).
- Adjustments affecting the Robustness Dashboard:
  - inclusion of *effect size agreement indicator* into the default set of indicators; accordingly, the option `extended()` can now only be set to "none" or "SIGswitch".
  - split longer results names into two lines.
  - minor adjustment in line spacing of Dashboard for newer Stata versions (version ${\ge}$ 16).
- Text revisions, among others regarding the use of the term "result". 
  
2024-06-03, v1.5.2:

- Minor adjustments in Sensitivity Dashboard:
  -  rename dashboard to *Robustness Dashboard*, including the option `sensdash()`, which is now called `dashboard()`.
  -  correct calculation of the *effect size variation indicator* when `sameunits(variable==0)` and `orig_in_multiverse(1)` applies for any analytical path.
  -  correct calculation of the *indicator on non-agreement due to significance classification* when `aggregation(1)`.
  -  remove slight inconsistency in rounding if sum of shares would exceed or fall below 100\%.
  -  adjust colouring of confirmatory and non-confirmatory results.
  -  extend *indicator on non-agreement due to significance classification* to situations in which an original study applied a less stringent classification of what constitutes a statistically significant result than the robustness analysis.
  -  show histogram with share of confirmatory results (${\kappa}$) and absolute values of effect sizes ($|{\beta}|$) at bottom of dashboard when `aggregation(1)`.
  -  inclusion of the *overall significance (and sig. classification) agreement indicator*.
  
2024-03-17, v1.5.1:

- Improve MacOS compatibility.
- Revise table output, including added `tabfmt()` option.
- Fix a bug that occurred when assessing only one result. 

2024-03-05, v1.5:

- Fix minor bugs occurring with `studypooling(1)`.
- Clarify that `repframe` only works with Stata 14.0 or higher.
- Introduce option `studypooling()` to `repframe_genadd` command and include illustrative example on pooling across studies in Stata help file. 

2024-03-04, v1.4.2:

- Adjust the option `extended()` to allow for multiple choices.
- Extend the application of the *significance variation indicator* in the Sensitivity Dashboard to originally insignificant results with significant robustness analysis paths.
- Add examples to the Stata help file.
- Minor revisions of the code.

2024-02-29, v1.4.1:

- Make options `siglevel()` and `siglevel_orig()` compulsory for analyses at study level.
- Add recommendation to include both the information on *p*-values and standard errors at study level.

2024-02-28, v1.4:

- Add option `siglevel_orig()` to allow testing against significance level adopted by original authors; incorporated as an indicator on significance classification into the Sensitivity Dashboard.
- Additional effect size agreement / confidence interval coverage indicator and additional notes to Sensitivity Dashboard and Reproducibility and Replicability Indicators table.
- Produce Reproducibility and Replicability Indicators table for indicators pooled across studies.
- Remove certain requirements to the input data formatting.
- Use NHANES II data for the example in the help file, among others to have multiple results that effectively differ from each other. 
- Revise entire command structure and adopt uniform naming convention.

2024-02-13, v1.3.1:

- Minor amendments to the code.

2024-01-22, v1.3:

- Add the option `studypooling()` to calculate indicators across studies.

2024-01-19, v1.2:

- Incorporate the package `sensdash()`.

2024-01-18, v1.1:

- First version of `repframe` package.


## References
Anderson, T. W., & Rubin, H. (1949). Estimation of the parameters of a single equation in a complete system of stochastic equations. *The Annals of Mathematical Statistics*, *20*(1), 46-63.

Angrist, J., & Kolesár, M. (2024). One instrument to rule them all: The bias and coverage of just-ID IV. *Journal of Econometrics*, *240*(2), 105398. doi: [10.1016/j.jeconom.2022.12.012](https://doi.org/10.1016/j.jeconom.2022.12.012).

Bensch, G., Rose, J., Brodeur, A., & Ankel-Peters, J. (2025). The Robustness Dashboard. *I4R Discussion Paper No. 234*. Available at
https://hdl.handle.net/10419/319180.

Dreber, A. & Johanneson, M. (2025). A Framework for Evaluating Reproducibility and Replicability in Economics. *Economic Inquiry*, *63*(2), 338-356. doi: [10.1111/ecin.13244](https://onlinelibrary.wiley.com/doi/full/10.1111/ecin.13244).

Keane, M. P. & Neal, T. (2024). A practical guide to weak instruments. *Annual Review of Economics*, *16*, 185-212. doi: [10.1146/annurev-economics-092123-111021](https://doi.org/10.1146/annurev-economics-092123-111021).

Lee, D. S., McCrary, J., Moreira, M. J., & Porter, J. (2022). Valid *t*-ratio Inference for IV. *American Economic Review*, *112*(10), 3260-3290. doi: [10.1257/aer.20211063](https://doi.org/10.1257/aer.20211063).

Lee, D. S., McCrary, J., Moreira, M. J., Porter, J. R., & Yap, L. (2023). What to do when you can't use '1.96' Confidence Intervals for IV. *National Bureau of Economic Research Working Paper No. w31893*.

Mathur, M. B., & VanderWeele, T. J. (2020). New statistical metrics for multisite replication projects. *Journal of the Royal Statistical Society Series A: Statistics in Society*, *183*(3), 1145-1166. doi: [10.1111/rssa.12572](https://doi.org/10.1111/rssa.12572). 

Patil, P., Peng, R. D., & Leek, J. T. (2016). What should researchers expect when they replicate studies? A statistical view of replicability in psychological science. *Perspectives on Psychological Science*, *11*(4), 539-544. doi: [10.1177/1745691616646366](https://doi.org/10.1177/1745691616646366).

Pawel, S., & Held, L. (2022). The sceptical Bayes factor for the assessment of replication success. *Journal of the Royal Statistical Society Series B: Statistical Methodology*, *84*(3), 879-911. doi: [10.1111/rssb.12491](https://doi.org/10.1111/rssb.12491).

