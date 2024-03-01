> # **Feb 29, 2024: An update of the command and its description will be available in the coming week.**

# REPFRAME v1.4.1

This is a Stata package to calculate, tabulate and visualize Reproducibility and Replicability Indicators. These indicators compare estimates from a multiverse of analysis paths of robustness tests - be they reproducibility or replicability analyses - to the original estimate in order to gauge the degree of reproducibility or replicability. The package comes with two commands: `repframe` is the main command, and `repframe_gendata` generates a dataset that is used in the help file of the command to show examples of how the command works.  

The package can be installed by executing in Stata:
```stata
net install repframe, from("https://raw.githubusercontent.com/guntherbensch/repframe/main") replace
```

Once installed, please see 
```stata
help repframe
```
for the syntax and the whole range of options.

As shown in the figure and described in the following, the `repframe` command can be applied both to derive indicators at the level of individual studies and to pool these indicators across studies. At both levels, the command produces two outputs, a table with the main set of indicators (*Reproducibility and Replicability Indicators table*) and a so-called *Sensitivity Dashboard* that visualizes a second set of indicators. At the study level, the command additionally produces as third output *study-level output data* on the indicators that is ready to be re-introduced into the command to calculate the indicators across studies.  
<img width="800" alt="repframe outputs" src="https://github.com/guntherbensch/repframe/assets/128997073/a10f15d7-1012-4dcc-8412-b7afc856a2b6"> &nbsp;


## Required input data structure 

### Data structure for analyses at study level

The input data at study level needs to be in a specific format for `repframe` to be able to calculate the Indicators and Dashboards. Each observation should represent one analysis path, that is the combination of analytical decisions in the multiverse robustness test. 
In the toy example with one main outcome represented in the below figure, two alternative choices are assessed for one analytical decision (**analytical_decision_1**, e.g. a certain adjustment of the outcome variable) and three alternative choices are assessed for two other analytical decision (**analytical_decision_2** and **analytical_decision_3**, e.g. the set of covariates and the sample used). This gives a multiverse of 3^2*2^1 = 18 analysis paths, if all combinations are to be considered. The number of observations is therefore 18 in this example.

For each observation, the minimum requirement is that the variables **mainlist** (this is the outcome at the study level), **beta** and **beta_orig** are defined together with information to determine statistical significance. In principle, this can be either information on standard errors (**se** and **se_orig**), on *p*-values (**pval** and **pval_orig**) or on the *t*/*z*-score (**zscore** and **zscore_orig**). `repframe` then determines the non-specified variables based on the conventional *t*-test formula. However, it is recommended to specify both the information on *p*-values and on standard errors, because the application of this formula may not be appropriate in all cases. For example, when the original estimations accounted for sampling weights (pweights) using the command `svy:` in Stata, *p*-values will not be correctly derived using that formula. Conversely, if input data on *p*-values is based on other distributional assumptions than normality, the formula may not correctly derive standard errors.  

It is also important to note that, irrespective of whether the original analysis is included as one analysis path in the multiverse robustness test or not, the dataset should only include the information on the original analysis in the variables ending with **_orig**. Also note that the variable **mainlist** should be numeric with value labels.

<img width="800" alt="toy example of repframe multiverse input data structure" src="https://github.com/guntherbensch/repframe/assets/128997073/81821432-de86-4bea-b0a8-66f8515c2508"> &nbsp;

The Stata help file contains a simple example that uses the command [`repframe_gendata`](https://github.com/guntherbensch/repframe/blob/main/repframe_gendata.ado) to build such a data structure. 

### Data structure for analyses across studies

The `repframe` can also be used to compile Reproducibility and Replicability Indicators across studies. To do so, one only has to append the Stata datasets that include the Reproducibility and Replicability Indicators of individual studies and then feed them back into a variant of the `repframe` command. 
The following steps need to be taken:
1. run `repframe` multiple times with multiple studies
2. `append` the individual data outputs saved as *repframe_data_[fileidenfier].dta* - with [fileidenfier] as defined by the option `fileidentifier(string)`, making sure that all individual studies applied the same significance level, which can be checked by the variable called **siglevel** contained in the individual data outputs   
3. run the following commands to compile a dataset with Reproducibility and Replicability Indicators across studies

```stata
. encode ref, gen(reflist)
. drop ref
. order reflist
. save "[filename].dta", replace
```
&ensp; where [filename] can be freely chosen for the dataset containing all appended individual data outputs, potentially including the full path of the file.  
4. run `repframe` again, now using the option `studypool(1)` to request the indicators to be calculated across studies. 


## Defaults applied by the repframe command

The `repframe` command applies a few default assumptions. Use the following options in case your analysis applies different assumptions. 

<ins>Tests for statistical significance</ins>: The command applies two-sided *t*-tests for statistical significance of estimates derived in the reproducibility or replicability analyses. The significance level is specified with the option `siglevel(#)`, for example `siglevel(5)`, and with `siglevel_orig(#)` applied to the original estimate. If you derived **pval** and **pval_orig** based on one-sided tests, multiply these *p*-values by two so as to make them correspond to a two-sided test. If you do not input information on  standard errors and *p*-values, the command applies the conventional *t*-test formula. Here, degrees of freedom can be defined for smaller samples with the options `df(varname)` and `df_orig(varname)`, each requiring a numerical variable containing the observation-specific information on the degrees of freedom. The caveats with the conventional *t*-test formula apply as mentioned above.

<ins>Units in which effect sizes are measured</ins>: The command assumes that effect sizes of original results and results of robustness test are measured in the same unit. If this is not the case, for example because one is measured in log terms and the other is not, use the option `sameunits(varname)`, which requires a numerical variable containing the observation-specific binary information on whether the two are measured in the same unit (1=yes) or not (0=no).

<ins>Original analysis to be included as one analysis path in the multiverse robustness test</ins>: The command assumes that the original analysis is not to be included as one analysis path in the multiverse robustness test, otherwise specify the option `orig_in_multiverse(1)`. Then, the original result is incorporated in the computation of the two [variation indicators](#the-reproducibility-and-replicability-indicators). Irrespective of whether the original analysis is included as one analysis path in the multiverse robustness test or not, the dataset should only include the information on the original analysis in the variables ending with **_orig**, and not in the variables on the analysis paths of robustness tests.


## The Reproducibility and Replicability Indicators

The *Reproducibility and Replicability Indicators table* and the *Sensitivity Dashboard* present two separate sets of indicators. These indicators are primarily designed as easily and intuitively interpretable metrics for tests of robustness reproducibility, which asks to what extent results in original studies are robust to alternative plausible analytical decisions on the same data ([Dreber and Johannesson 2023](#references)). This makes it plausible to assume that that the tests of robustness reproducibility and the original study measure exactly the same underlying effect size, with no heterogeneity and no difference in statistical power. 

For replications using new data or alternative research designs, more sophisticated indicators are required to account for potential heterogeneity and difference in statistical power (cf. [Mathur & VanderWeele 2020](#references), [Pawel & Held 2022](#references)).

The indicators are meant to inform about the following three pieces of information on reproducibility and replicability, related to either statistical significance or effect sizes:
- <ins>agreement indicators</ins>: Can original and robustness results be considered to have the same statistical significance (effect size)?
- <ins>relative indicators</ins>: To what extent does the statistical significance (do the effect sizes) of the original results differ from those of the robustness results?
- <ins>variation</ins>: To what extent do the robustness tests vary among each other in terms of statistical significance (effect sizes)? 

### Reproducibility and Replicability Indicators table

The following describes the main indicators presented in the *Reproducibility and Replicability Indicators table* as they are computed at the level of each assessed outcome within a single study. By analogy, the indicators across studies are derived in the same way, only that *outcome* needs to be replaced by *study* in the following.  

1. The **statistical significance indicator** as a significance agreement indicator measures for each outcome $j$ the share of the $n$ robustness test analysis paths $i$ that are reported as statistically significant in both the original study and the robustness analysis. Accordingly, the indicator is computed differently for outcomes where the original results were reported as statistically significant and those where the original results were found to be statistically insignificant. Statistical significance is defined by a two-sided tests with a significance level of $\alpha$, with the significance level applied in the original study being $\alpha^{orig}$, and the significance level applied as default by the `repframe` command being $\alpha=0.05$. For original results found to be statistically significant, the effects of the robustness test analysis paths additionally have to be in the same direction as the original result, as captured by $\mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)$.

$$ I_{1j} = mean(\mathbb{I}(pval_i \le \alpha) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0))  \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{1j} = mean(\mathbb{I}(pval_i > \alpha))  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$
  
:point_right: This indicator captures the *technical* robustness of results (are estimates robust?) and the *classification* robustness (is the classification as statically significant robust to a potentially more (or less) demanding level of statistical significance?).  
> *Interpretation*: An indicator $I_{1j}$ of 0.3 for outcomes reported as statistically significant in the original study, for example, implies that 30\% of robustness test analysis paths for these outcomes (i) are statistically significant according to the significance level adopted in the robustness analysis, and (ii) that their coefficients also share the same sign as the coefficient in the original study. Conversely, 70\% of robustness test analysis paths for these outcomes are statistically insignificant, while it cannot be excluded that part of these paths are statistically significant but in the opposite direction. Note also that statistical insignificance may be due to a stricter significance level adopted in the robustness analysis compared to the original study. An indicator of 0.3 for outcomes reported as statistically insignificant in the original study implies that 30\% of robustness test analysis paths for these outcomes are statistically insignificant according to the significance level adopted in the robustness analysis. Now, the remaining 70\% of robustness test analysis paths are statistically significant (most likely with the same sign), while different significance levels in the robustness analysis and original study may also have to be considered.   


2. The **relative effect size indicator**  measures for each outcome $j$ the mean of the effect sizes $\beta$ of all the $n$ robustness test analysis paths divided by the original effect size. Again, different formula are applied to outcomes where the original results were found to be statistically significant and those where the original results were found to be statistically insignificant. This indicator requires that the effect sizes of the original and robustness test results are measured in the same units.

$$ I_{2j} = \frac{mean(\beta_i)} {\beta^{orig}_j} \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{2j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$

:point_right: This indicator captures the ratio between robustness coefficients and original coefficients.  
> *Interpretation*: An indicator $I_{2j}$ above 1 means that the mean coefficient in the robustness analysis paths is higher than the original coefficient - with a factor of $I_{2j}$ (e.g. 1.6) -. An indicator between 0 and 1 means that the mean coefficient in the robustness analysis paths is lower than the original coefficient (while both show in the same direction) - again with a factor of $I_{2j}$ (e.g. 0.4) -. An indicator below 0 implies that the two compared parameters have different signs, where the absolute value of the mean coefficient in the robustness analysis paths is higher (lower) than the original coefficient if $I_{2j}$ is above (below) -1. $I_{2j}$ is only derived for outcomes reported as statistically significant in the original study, now irrespective of whether in the same direction or not.


3. The **relative *t*/*z*-value indicator** as a relative significance indicator measures for each outcome $j$ the mean of the *t*/*z*-values ($zscore$) of all the robustness test analysis paths divided by the *t*/*z*-value of the original result.

$$ I_{3j} = \frac{mean(zscore_i)} {zscore^{orig}_j} \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{3j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$ 

:point_right: This indicator captures the ratio between the statistical significance of robustness and original results expressed in terms of t*/*z*-values.
> *Interpretation*: An indicator $I_{3j}$ above (below) 1 means that *t*/*z*-values in the robustness analysis paths are, on average, higher (lower) than the original coefficient, suggesting a higher (lower) level of statistical significance in the robustness analyses. An indicator below 0 implies that the two compared parameters have different signs, where the absolute value of the mean *t*/*z*-value in the robustness analysis paths is higher (lower) than the original *t*/*z*-value if $I_{3j}$ is above (below) -1. $I_{3j}$ is also only derived for outcomes reported as statistically significant in the original study, irrespective of whether in the same direction or not.


4. The **effect size variation indicator** measures the standard deviation of effect sizes of all the robustness test analysis paths divided by the standard error of the original effect size. 
Here, the $\beta_i$ may incorporate the original result as one robustness test analysis path. Expressed through the standard deviation $sd$ and the standard error $se$, the formula simplifies to

$$ I_{4j} = \frac{sd(\beta_i)}{se(\beta^{orig}_j)} $$

applied separately to $pval^{orig}_j \le \alpha^{orig}$ and $pval^{orig}_j > \alpha^{orig}$. 

:point_right: This indicator captures the ratio between the variation across robustness results and original results, expressed in terms of standard deviations and standard errors.
> *Interpretation*: An indicator $I_{4j}$ above (below) 1 means that variation across robustness results of either statistically signifiicant or insignifcant original results is higher (lower) than the variation across original results, with a factor of $I_{4j}$. 


5. The ***t*/*z*-value variation indicator** as a significance variation indicator measures the standard deviation of *t*/*z*-values of all the robustness test analysis paths.

$$ I_{5j} = sd(zscore_i)  $$

applied separately to $pval^{orig}_j \le \alpha^{orig}$ and $pval^{orig}_j > \alpha^{orig}$. 

:point_right: This indicator captures the variation in the statistical significance across robustness results.
> *Interpretation*: $I_{5j}$ simply reports the standard deviation of *t*/*z*-values of all the robustness test of either statistically significant or insignifcant original results as a measure of variation in statistical significance. Higher values indicate higher levels of variation.


For all indicators, aggregation at the study level is simply done by averaging the indicators as computed at outcome level. 

Similarly, aggregation across studies is simply done by averaging the indicators as computed at study level. 


### Sensitivity Dashboard

A general difference to the indicators included in the *Reproducibility and Replicability Indicators table* is that the same level of statistical significance is applied to original and robustness results. The motivation is to separate *technical* and *classification* reproducibility or replicability of results as defined above and outlined in the description of the first two indicators.

The **significance agreement indicator** is derived in a similar way as the *statistical significance indicator* from the *Reproducibility and Replicability Indicators table*. The only differences are that (i) the indicator is the same for statitically significant and insignificant robustness estimates and that (ii) the same significance level $\alpha$ is applied to the original results and to the robustness results. The indicator is expressed in \% of all robustness results on either statitically significant or insignificant original results and, hence, additionally multiplied by 100.

$$ I'_{1j} = mean(\mathbb{I}(pval_i \le \alpha) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)) \times 100 $$

applied separately to $pval^{orig}_j \le \alpha$ and $pval^{orig}_j > \alpha$. 
The same indicator is also calculated for statistically significant robustness results with opposite sign, i.e. differing from the above formula through $\mathbb{I}(\beta_i \times \beta^{orig}_j < 0)$.

Hence, this indicator captures the percentage of *technically* robust results.


The **indicator on non-agreement due to significance definition** is an auxiliary significance agreement indicator that focuses on *classification* reproducibility or replicability of results as defined above. It identifies the robustness results found to turn statistically insignificant only because a more stringent significance level definition is applied in the robustness analyses than in the original analysis. For example, when the robustness analyses apply a significance level of 5\% and the original analysis applied a significance level of 10\%, original estimates with $0.05 < pval^{orig}_j \le 0.10$ are only categorized as having a non-agreeing significance level because of differing defintions of statistical significance. The indicator is also expressed in \% and therefore includes the muliplication by 100.

$$ I'_{2j} = mean(\mathbb{I}(pval_i > \alpha) \times pval_i \le \alpha^{orig}_j) \times 100  \quad  \text{if } \alpha^{orig}_j > pval^{orig}_j > \alpha $$

$$ I'_{2j}  \text{ not applicable otherwise} $$

Hence, this indicator captures the percentage of non-robust, originally significant results due to differences in the classification of statistical significance.


The **relative effect size indicator** differs from the *Reproducibility and Replicability Indicators table* in that it is only derived for statistically significant robustness results in the same direction as the original result. In addition, the indicator takes the median of the robustness estimates instead of the mean, in order to be less sensitive to outliers. Furthermore, one is subtracted from the ratio, in order to underscore the relative nature of the indicator. A ratio of 2/5 thus turns into -3/5, and multiplied by 100 to -60\%.

$$ I'_{3j} = (\frac{median(\beta)} {\beta^{orig}_j} - 1) \times 100  \quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha \land \beta_i \times \beta^{orig}_j \ge 0 $$

$$ I'_{3j}  \text{ not applicable otherwise} $$


The Sensitivity Dashboard does not include a **relative significance indicator**.


The **effect size variation indicator** measures the mean absolute deviation of coefficients in robustness test analysis paths from their median. Again, it is only derived for statistically significant robustness results in the same direction as the original result and multiplied by 100. 

$$ I'_{4j} = \frac{mean(\mid \beta - median(\beta) \mid)}  {\beta^{orig}_j} \times 100  	\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha \land \beta_i \times \beta^{orig}_j \ge 0 $$ 

$$ I'_{4j}  \text{ not applicable otherwise} $$


The **significance variation indicator** 

$$ I'_{5j} = mean(\mid pval_i - pval^{orig}_j \mid)		\quad  \text{if } pval^{orig}_j > \alpha \land pval_i > \alpha $$ 

$$ I'_{5j}  \text{ not applicable otherwise} $$

More information following soon.

## Update log

2024-02-29, v1.4.1:

- Make options `siglevel` and `siglevel_orig` compulsory for analyses at study level.
- Add recommendation to include both the information on *p*-values and standard errors at study level.

2024-02-28, v1.4:

- Add option `siglevel_orig` to allow testing against significance level adopted by original authors; incorporated as an indicator on significance definition into the Sensitivity Dashboard.
- Additional effect size agreement / confidence interval coverage indicator and additional notes to Sensitivity Dashboard and Reproducibility and Replicability Indicators table.
- Produce Reproducibility and Replicability Indicators table for indicators pooled across studies.
- Remove certain requirements to the input data formatting.
- Us NHANES II data for the example in the help file, among others to have multiple outcomes that effectively differ from each other. 
- Revise entire command structure and uniform naming convention.

2024-02-13, v1.3.1:

- Minor amendments to the code.

2024-01-22, v1.3:

- Add the option `studypooling` to calculate indicators across studies.

2024-01-19, v1.2:

- Incorporate the package `sensdash`.

2024-01-18, v1.1:

- First version of `repframe` package.


## References
Dreber, A. & Johanneson, M. (2023). *A Framework for Evaluating Reproducibility and Replicability in Economics.* Available at [SSRN](http://dx.doi.org/10.2139/ssrn.4458153).

Mathur, M. B., & VanderWeele, T. J. (2020). New statistical metrics for multisite replication projects. *Journal of the Royal Statistical Society Series A: Statistics in Society*, *183*(3), 1145-1166.

Pawel, S., & Held, L. (2022). The sceptical Bayes factor for the assessment of replication success. *Journal of the Royal Statistical Society Series B: Statistical Methodology*, *84*(3), 879-911.
 
 


 

