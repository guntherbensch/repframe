> # **Feb 29, 2024: An update of the command and its description will be available in the coming week.**

# REPFRAME v1.4.1

This is a Stata package to calculate, tabulate and visualize Reproducibility and Replicability Indicators. These indicators compare estimates from a multiverse of analysis paths of a robustness analysis - be they reproducibility or replicability analyses - to the original estimate in order to gauge the degree of reproducibility or replicability. The package comes with two commands: `repframe` is the main command, and `repframe_gendata` generates a dataset that is used in the help file of the command to show examples of how the command works.  

The package can be installed in Stata by executing:
```stata
net install repframe, from("https://raw.githubusercontent.com/guntherbensch/repframe/main") replace
```

Once installed, please see 
```stata
help repframe
```
for the syntax and the whole range of options.

As shown in the figure below and described in the following, the `repframe` command can be applied both to derive indicators at the level of individual studies and to pool these indicators across studies. At both levels, the command produces two outputs, a table with the main set of indicators (*Reproducibility and Replicability Indicators table*) as .csv file and a so-called *Sensitivity Dashboard* that visualizes a second set of indicators. At the study level, the command additionally produces as third output *study-level output data* on the indicators as a Stata .dta file that is ready to be re-introduced into the command to calculate the indicators across studies.  
<img width="800" alt="repframe outputs" src="https://github.com/guntherbensch/repframe/assets/128997073/a10f15d7-1012-4dcc-8412-b7afc856a2b6"> &nbsp;


## Defaults applied by the repframe command

The `repframe` command applies a few default assumptions. Use the following options in case your analysis makes different assumptions. 

<ins>Tests for statistical significance</ins>: The command applies two-sided *t*-tests to define which *p*-values imply statistical significance. These tests may apply different significance levels to the original results (`siglevel_orig(#)`) and to the robustness results (`siglevel(#)`). If the *p*-values inputted via the options `pval(varname)` and `pval_orig(varname)` are based on one-sided tests, these *p*-values need to be multiplied by two so as to make them correspond to a two-sided test. If no information on *p*-values is available, the command derives the missing *p*-value information applying the *t*-test formula. Depending on which additional information is available, this may done based on *t*/*z*-scores (`zscore(varname)` and `zscore_orig(varname)`), on standard errors (`se(varname)` and `se_orig(varname)`) and degrees of freedom (`df(varname)` and `df_orig(varname)`), or on standard errors (`se(varname)` and `se_orig(varname)`) assuming a normal distribution. Remember that the latter may not always be appropriate, for example with small samples or when estimations account for survey sampling, e.g. via the Stata command `svy:`. Conversely, if input data on *p*-values is based on other distributional assumptions than normality, the formula may not correctly derive standard errors. It is therefore recommended to specify both the information on *p*-values and on standard errors, and to consider the implications if non-normality is assumed in either the original or robustness analysis. 

<ins>Units in which effect sizes are measured</ins>: The command assumes that effect sizes of original results and robustness results are measured in the same unit. If this is not the case, for example because one is measured in log terms and the other is not, use the option `sameunits(varname)`, which requires a numerical variable containing the observation-specific binary information on whether the two are measured in the same unit (1=yes) or not (0=no).

<ins>Original analysis to be included as one robustness analysis path</ins>: The command assumes that the original analysis is not to be included as one analysis path in the multiverse robustness analysis. Otherwise specify the option `orig_in_multiverse(1)`. Then, the original result is incorporated in the computation of the two [variation indicators](#the-reproducibility-and-replicability-indicators). Irrespective of whether the original analysis is included as one robustness analysis path or not, the dataset should only include the information on the original analysis in the variables inputted via the options ending with *_orig*, and not as separate robustness analysis paths.


## Required input data structure 

### Data structure for analyses at study level

The input data at study level needs to be in a specific format for `repframe` to be able to calculate the indicators and dashboards. Each observation should represent one analysis path, that is the combination of analytical decisions in the multiverse robustness analysis. 
In the toy example with one main outcome represented in the below figure, two alternative choices are assessed for one analytical decision (**analytical_decision_1**, e.g. a certain adjustment of the outcome variable) and three alternative choices are assessed for two other analytical decision (**analytical_decision_2** and **analytical_decision_3**, e.g. the set of covariates and the sample used). This gives a multiverse of 3^2*2^1 = 18 analysis paths, if all combinations are to be considered. The number of observations is therefore 18 in this example.

For each observation, the minimum requirement is that the variable **mainlist** (this is the outcome at the study level) is defined together with the coefficient information inputted via the options `beta(varname)` and `beta_orig(varname)` and information to determine statistical significance. It is recommended to specify both the information on *p*-values and on standard errors, as outlined above in the sub-section on defaults applied by the `repframe` command. As noted in that sub-section above, the dataset should furthermore not include observations with information on the original analysis as robustness analysis paths but only in the variables inputted via the options ending with *_orig*. Also note that the variable **mainlist** should be numeric with value labels.

<img width="800" alt="toy example of repframe multiverse input data structure" src="https://github.com/guntherbensch/repframe/assets/128997073/81821432-de86-4bea-b0a8-66f8515c2508"> &nbsp;

The Stata help file contains a simple example that uses the command [`repframe_gendata`](https://github.com/guntherbensch/repframe/blob/main/repframe_gendata.ado) to build such a data structure. 

### Data structure for analyses across studies

The `repframe` can also be used to compile Reproducibility and Replicability Indicators across studies. To do so, one only has to append the *study-level output data* that include the Reproducibility and Replicability Indicators of individual studies and then feed them back into a variant of the `repframe` command. 
The following steps need to be taken:
1. run `repframe` multiple times with individual studies to create the *study-level output data* saved as *repframe_data_[fileidenfier].dta* - with [fileidenfier] as defined by the option `fileidentifier(string)`
2. `append` the individual *study-level output data*, making sure that all individual studies applied the same significance level, which can be checked with the variable **siglevel** contained in the *study-level output data*   
3. run the following commands to compile a dataset with Reproducibility and Replicability Indicators across studies

```stata
. encode ref, gen(reflist)
. drop ref
. order reflist
. save "[filename].dta", replace
```
&ensp; where [filename] can be freely chosen for the dataset containing all appended *study-level output data*, potentially including the full path of the file.  
4. run `repframe` again, now using the option `studypool(1)` to request the calculation of indicators across studies. 


## The Reproducibility and Replicability Indicators

The *Reproducibility and Replicability Indicators table* and the *Sensitivity Dashboard* present two separate sets of indicators. These indicators are primarily designed as easily and intuitively interpretable metrics for tests of robustness reproducibility, which asks to what extent results in original studies are robust to alternative plausible analytical decisions on the same data ([Dreber and Johannesson 2023](#references)). This makes it plausible to assume that that the tests of robustness reproducibility and the original study measure exactly the same underlying effect size, with no heterogeneity and no difference in statistical power. 

For tests of replicability using new data or alternative research designs, more sophisticated indicators are required to account for potential heterogeneity and difference in statistical power (cf. [Mathur & VanderWeele 2020](#references), [Pawel & Held 2022](#references)).

The indicators are meant to inform about the following three pieces of information on reproducibility and replicability, related to either statistical significance or effect sizes:
- <ins>agreement indicators</ins>: Can original and robustness results be considered to have the same statistical significance (effect size)?
- <ins>relative indicators</ins>: To what extent does the statistical significance (do the effect sizes) of the original results differ from those of the robustness results?
- <ins>variation indicators</ins>: To what extent do the robustness tests vary among each other in terms of statistical significance (effect sizes)? 

The *Sensitivity Dashboard* additionally includes the option `extended(1)`, which incorporates a
- <ins>significance switch indicator</ins>: To what extent are robustness coefficients - or standard errors - large enough to turn an originally insignificant (significant) result significant (insignificant)?   

### Reproducibility and Replicability Indicators table

The following describes the main indicators presented in the *Reproducibility and Replicability Indicators table* as they are computed at the level of each assessed outcome within a single study. Aggregation across outcomes at the study level is simply done by averaging the indicators as computed at outcome level, separately for outcomes reported as originally significant and outcomes reported as originally insignificant. Similarly, aggregation across studies is simply done by averaging the indicators as computed at study level.  

1. The **statistical significance indicator** as a significance agreement indicator measures for each outcome $j$ the share of the $n$ robustness analysis paths $i$ that are reported as statistically significant or insignificant in both the original study and the robustness analysis. Accordingly, the indicator is computed differently for outcomes where the original results were reported as statistically significant and those where the original results were found to be statistically insignificant. Statistical significance is defined by a two-sided test with $\alpha^{orig}$ being the significance level applied in the original study and $\alpha$ being the significance level applied in the robustness analysis. For statistically significant original results, the effects of the robustness analysis paths must also be in the same direction as the original result, as captured by coefficients having the same sign or, expressed mathematically, by $\mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)$.

$$ I_{1j} = mean(\mathbb{I}(pval_i \le \alpha) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0))  \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{1j} = mean(\mathbb{I}(pval_i > \alpha))  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$
  
:point_right: This percentage indicator is intended to capture the *technical* robustness of results (are estimates robust in terms of achieving a certain level of statistical significance?) and the *classification* robustness (is the classification as statically significant robust to a potentially more (or less) demanding level of statistical significance?).  
> *Interpretation*: An indicator $I_{1j}$ of 0.3 for an outcome $j$ reported as statistically significant in the original study, for example, implies that 30\% of robustness analysis paths for this outcome (i) are statistically significant according to the significance level adopted in the robustness analysis, and (ii) that their coefficients share the same sign as the coefficient in the original study. Conversely, 70\% of robustness analysis paths for this outcome are most likely statistically insignificant, while it cannot be excluded that part of these paths are statistically significant but in the opposite direction. Note also that robustness analysis paths for this outcome may be found statistically ingnificant only because of a stricter significance level adopted in the robustness analysis compared to the original study. An indicator of 0.3 for outcomes reported as statistically insignificant in the original study implies that 30\% of robustness test analysis paths for this outcome are statistically insignificant according to the significance level adopted in the robustness analysis. Now, the remaining 70\% of robustness analysis paths are statistically significant (most likely with the same sign), while different significance levels in the robustness analysis and original study may also have to be considered.   


2. The **relative effect size indicator**  measures for each outcome $j$ the mean of the coefficients $\beta_i$ of all the $n$ robustness analysis paths divided by the original coefficient $\beta^{orig}_j$. The indicator requires that the effect sizes of the original and robustness test results are measured in the same units. It is furthermore only applied to outcomes reported as statistically significant in the original study, now - and for the following indicators as well - irrespective of whether in the same direction or not.

$$ I_{2j} = \frac{mean(\beta_i)} {\beta^{orig}_j} \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{2j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$

:point_right: This ratio indicator is intended to capture how the size of robustness coefficients compares to the size of original coefficients.  
> *Interpretation*: An indicator $I_{2j}$ above 1 implies that the mean of the coefficients of all the robustness analysis paths for a statistically significant orginal result on outcome $j$ is - in absolute terms - higher than the original coefficient (while both show in the same direction), with a factor of $I_{2j}$ (e.g. 1.3). An indicator between 0 and 1 means that the mean coefficient in the robustness analysis paths is lower than the original coefficient (while both show in the same direction), again with a factor of $I_{2j}$ (e.g. 0.7). An indicator below 0 implies that the two compared parameters have different signs, where the absolute value of the mean coefficient in the robustness analysis paths is higher (lower) than the original coefficient if $I_{2j}$ is above (below) -1.


3. The **relative *t*/*z*-value indicator** as a relative significance indicator measures for each outcome $j$ the mean of the *t*/*z*-values ($zscore$) of all the robustness test analysis paths divided by the *t*/*z*-value of the original result. The indicator is also only derived for outcomes reported as statistically significant in the original study.

$$ I_{3j} = \frac{mean(zscore_i)} {zscore^{orig}_j} \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{3j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$ 

:point_right: This ratio indicator is intended to capture how the statistical significance of robustness results compares to the statistical significance of original results.
> *Interpretation*: An indicator $I_{3j}$ above (below) 1 in absolute terms means that the average *t*/*z*-value of all robustness analysis paths for outcome $j$ is - again in absolute terms - higher (lower) than the original coefficient, suggesting a higher (lower) level of statistical significance in the robustness analysis. An indicator below 0 additionally implies that the two compared parameters have different signs, where the absolute value of the mean *t*/*z*-value in the robustness analysis paths is higher (lower) than the original *t*/*z*-value if $I_{3j}$ is above (below) -1.


4. The **effect size variation indicator** measures the standard deviation $sd$ of all robustness coefficients divided by the standard error $se$ of the original coefficient. 
Here, the $\beta_i$ may incorporate the original result as one robustness test analysis path.

$$ I_{4j} = \frac{sd(\beta_i)}{se(\beta^{orig}_j)} $$

applied separately to $pval^{orig}_j \le \alpha^{orig}$ and $pval^{orig}_j > \alpha^{orig}$. 

:point_right: This ratio indicator is intended to capture how the variation in coefficients of robustness results compares to the variation estimated for the original coefficient.
> *Interpretation*: An indicator $I_{4j}$ above (below) 1 means that variation across all robustness analysis paths for outcome $j$ is higher (lower) than the variation estimated for the original result, with a factor of $I_{4j}$. 


5. The ***t*/*z*-value variation indicator** as a significance variation indicator measures the standard deviation of *t*/*z*-values of all the robustness test analysis paths. Here, the $zscore_i$ may incorporate the original result as one robustness analysis path.

$$ I_{5j} = sd(zscore_i)  $$

applied separately to $pval^{orig}_j \le \alpha^{orig}$ and $pval^{orig}_j > \alpha^{orig}$. 

:point_right: This absolute indicator is intended to capture the variation in the statistical significance across robustness results.
> *Interpretation*: $I_{5j}$ simply reports the standard deviation of *t*/*z*-values of all the robustness analysis paths for outcome $j$ as a measure of variation in statistical significance. Higher values indicate higher levels of variation.


### Sensitivity Dashboard

A general difference to the indicators included in the *Reproducibility and Replicability Indicators table* is that the same level of statistical significance is applied to original and robustness results. The motivation is to separate *technical* and *classification* reproducibility or replicability of results as defined above and outlined in the description of the first two indicators. 

In the same vein as for indicators presented in the *Reproducibility and Replicability Indicators table*, aggregation across outcomes at the study level (studies) is simply done by averaging the indicators as computed at outcome (study) level, separately for outcomes reported as originally significant and outcomes reported as originally insignificant.

1. The **significance agreement indicator** is derived in a similar way as the *statistical significance indicator* from the *Reproducibility and Replicability Indicators table*. The only differences are that (i) the indicator is the same for statistically significant and insignificant robustness results and that (ii) the same significance level $\alpha$ is applied to the original results and to the robustness results. The indicator is expressed in \% of all robustness results on either statitically significant or insignificant original results and, hence, additionally multiplied by 100.

$$ I´_{1j} = mean(\mathbb{I}(pval_i \le \alpha) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)) \times 100 $$

applied separately to $pval^{orig}_j \le \alpha$ and $pval^{orig}_j > \alpha$. 
The same indicator is also calculated for statistically significant robustness results with opposite sign, i.e. differing from the above formula through $\mathbb{I}(\beta_i \times \beta^{orig}_j < 0)$.

:point_right: This percentage indicator is intended to capture the *technical* robustness of results (are estimates robust in terms of achieving a certain level of statistical significance?)?
> *Interpretation*: An indicator $I´_{1j}$ of 3o\% implies that 30\% of robustness test analysis paths for outcomes $j$ are statistically significant. Depending on which of the four sub-indicators of the *Sensitivity Dashboard* one is referring to, this refers to (i) statistically significant *or* insignficant original results and to (ii) original and robustness coefficients that share *or* do not share the same sign. The significance level applied to both the original study and the robustness analysis is the one defined in the robustness analysis. For example, if $I´_{1j}$ is 30\% for results with the same sign and 3\% for results with opposite signs, the remaining 67\% of robustness analysis paths for this outcome are statistically insignificant. 


2. The **indicator on non-agreement due to significance definition** is an auxiliary significance agreement indicator that focuses on *classification* reproducibility or replicability of results as defined above. It identifies those originally significant results that have statistically insignificant robustness analysis paths only because a more stringent significance level definition is applied in the robustness analysis than in the original analysis. The indicator is also expressed in \% and therefore includes the muliplication by 100. 

$$ I´_{2j} = mean(\mathbb{I}(\alpha < pval_i \le \alpha^{orig}_j) \times 100  \quad  \text{if } \alpha < pval^{orig}_j \le \alpha^{orig}_j $$

$$ I´_{2j}  \text{ not applicable otherwise} $$

:point_right: This percentage indicator is intended to capture non-robustnuss of results reported as significant in original studies that is due to differences in the classification of statistical significance.
> *Interpretation*: Consider the case where the robustness analysis paths apply a significance level of 5\% and the original analysis applied a significance level of 10\%. In this case, robustness results with $0.05 < pval_i \le 0.10$ are only categorized as insignificant and thus having a non-agreeing significance level because of differing definitions of statistical significance. An indicator $I´_{2j}$ of 10\%, for example, implies that this holds true for 10\% of robustness test analysis paths for outcome $j$.


3. The **relative effect size indicator** differs from I_{2j} from the *Reproducibility and Replicability Indicators table* in that it is only derived for robustness analysis paths that are (i) statistically significant and (ii) in the same direction as the original result. In addition, the indicator takes the median of the robustness estimates instead of the mean, in order to be less sensitive to outliers. Furthermore, one is subtracted from the ratio, in order to underscore the relative nature of the indicator. A ratio of 2/5 thus turns into -3/5, and multiplied by 100 to -60\%.

$$ I´_{3j} = (\frac{median(\beta_i)} {\beta^{orig}_j} - 1) \times 100  \quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha \land \beta_i \times \beta^{orig}_j \ge 0 $$

$$ I´_{3j}  \text{ not applicable otherwise} $$

:point_right: This percentage indicator is intended to capture how the size of robustness coefficients compares to the size of original coefficients, if the two sets of results are comparable in terms of being both statistically significant and in the same direction.  
> *Interpretation*: An indicator $I´_{3j}$ above (below) 0\% means that the mean of the coefficients of robustness analysis paths that are (i) statistically significant and (ii) in the same direction as the original result for an originally significant outcome $j$ is higher (lower) than the original coefficient, by $I´_{3j}$\% - e.g. +30\% (-30\%).


The Sensitivity Dashboard does not include a **relative significance indicator**.


4. The **effect size variation indicator** measures the mean absolute deviation of coefficients in robustness test analysis paths from their median as determined by $I'_{3j}$. Again, it is only derived for statistically significant robustness results in the same direction as the original result and multiplied by 100.
Here, the $\beta_i$ may incorporate the original result as one robustness test analysis path.

$$ I´_{4j} = \frac{mean(\mid \beta_i - median(\beta_i) \mid)}  {\beta^{orig}_j} \times 100  	\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha \land \beta_i \times \beta^{orig}_j \ge 0 $$ 

$$ I´_{4j}  \text{ not applicable otherwise} $$

:point_right: This percentage indicator is intended to capture how the variation in coefficients of robustness results compares to the variation in coefficients among original results, if the two sets of results are comparable in terms of being both statstically significant and in the same direction.. 
> *Interpretation*: An indicator $I´_{4j}$ above (below) 1 means that variation across robustness results of either statistically significant or insignifcant original results for outcome $j$ is higher (lower) than the variation across original results, with a factor of $I´_{4j}$. 


5. The **significance variation indicator** measures the mean of the deviations between *p*-values from the robustness test analysis paths and the original *p*-value. This indicator is only derived for statistically insignificant robustness results.

$$ I´_{5j} = mean(\mid pval_i - pval^{orig}_j \mid)		\quad  \text{if } pval_i > \alpha $$ 

applied separately to $pval^{orig}_j \le \alpha$ and $pval^{orig}_j > \alpha$.

:point_right: This indicator is intended to capture the variation in the statistical significance across robustness results for statistically insignificant robustness results. The indicator is restricted to statistically insignificant robustness results given that the variation for statstically significant robustness results is either known to be very small (originally signifcant results) or less relevant (originally insignificant results).
> *Interpretation*: An indicator $I´_{5j}$ of 0.2, for example, implies that *p*-values in statistically insignificant robustness test analysis paths for outcome $j$ on average differ by 0.2 from the original *p*-value. Like *p*-values themselves, this deviation may assume values between 0 and 1. If the share of statistically insignificant robustness test analysis paths for this outcome is much (only little) higher than the 10\%, this indicates that few (most) robustness test analysis paths classified as non-confirmatory according to the *statistical significance indicator* are classified as confirmatory according to the 


6. The *Sensitivity Dashboard* additionally includes an **effect size agreement indicator** that measures the ...

$$ I´_{6j} = mean(\mathbb{I}(beta_i \ge beta^{lowero}_j \land beta_i \le beta^{uppero}_j)) 		\quad  \text{if } pval_i > \alpha $$ 

applied ...

:point_right: This indicator is intended to capture ...
> *Interpretation*: An indicator $I´_{6j}$ of ...


7. Lastly, the *Sensitivity Dashboard* allows calcluating **significance switch indicators** that measure ...

$$ I´_{7j} =  $$

:point_right: This indicator is intended to capture ...
> *Interpretation*: An indicator $I´_{7j}$ of ...



For all indicators, aggregation at the study level is simply done by averaging the indicators as computed at outcome level, separately for originally significant and originally insignificant outcomes according to the significance level adpoted in the robustness analysis. 

Similarly, aggregation across studies is simply done by averaging the indicators as computed at study level. 

> More information following soon.


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
 
 


 

