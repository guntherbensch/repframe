# REPFRAME v1.4.2

This is a Stata package to calculate, tabulate and visualize Reproducibility and Replicability Indicators. These indicators compare estimates from a multiverse of analysis paths of a robustness analysis &mdash; be they reproducibility or replicability analyses &mdash; to the original estimate in order to gauge the degree of reproducibility or replicability. The package comes with two commands: `repframe` is the main command, and `repframe_gendata` generates a dataset that is used in the help file of the command to show examples of how the command works.  

The package can be installed in Stata by executing:
```stata
net install repframe, from("https://raw.githubusercontent.com/guntherbensch/repframe/main") replace
```

Once installed, please see 
```stata
help repframe
```
for the syntax and the whole range of options.

As shown in the figure below and described in the following, the `repframe` command can be applied both to derive indicators at the level of individual studies and to pool these indicators across studies. At both levels, the command produces two outputs, a table with the main set of indicators (*Reproducibility and Replicability Indicators table*) as .csv file and a so-called *Sensitivity Dashboard* that visualizes a second set of indicators. At the study level, the command additionally produces as third output *study-level indicator data* as a Stata .dta file that is ready to be re-introduced into the command to calculate the indicators across studies.  
<img width="800" alt="repframe outputs" src="https://github.com/guntherbensch/repframe/assets/128997073/bd1c5852-355b-427d-9c4e-963aa7d39333"> &nbsp;



## Defaults applied by the repframe command

The `repframe` command applies a few default assumptions. Use the following options in case your analysis makes different assumptions. 

<ins>Tests for statistical significance</ins>: The command applies two-sided *t*-tests to define which *p*-values imply statistical significance. These tests may apply different significance levels to the original results (`siglevel_orig(#)`) and to the robustness results (`siglevel(#)`). If the related *p*-values inputted via the options `pval(varname)` and `pval_orig(varname)` are based on one-sided tests, these *p*-values need to be multiplied by two so as to make them correspond to a two-sided test. If no information on *p*-values is available, the command derives the missing *p*-value information applying the *t*-test formula. Depending on which additional information is available, this may done based on *t*/*z*-scores (`zscore(varname)` and `zscore_orig(varname)`), on standard errors (`se(varname)` and `se_orig(varname)`) and degrees of freedom (`df(varname)` and `df_orig(varname)`), or on standard errors assuming a normal distribution. Remember that the latter may not always be appropriate, for example with small samples or when estimations have few degrees of freedom because they account for survey sampling, e.g. via the Stata command `svy:`. Conversely, if input data on *p*-values is based on other distributional assumptions than normality, the formula may not correctly derive standard errors. It is therefore recommended to specify both the information on *p*-values and on standard errors, and to consider the implications if non-normality is assumed in either the original or robustness analysis. 

<ins>Units in which effect sizes are measured</ins>: The command assumes that effect sizes of original results and robustness results are measured in the same unit. If this is not the case, for example because one is measured in log terms and the other is not, use the option `sameunits(varname)`. This option requires a numerical variable **varname** containing the observation-specific binary information on whether the two are measured in the same unit (1=yes) or not (0=no).

<ins>Original analysis to be included as one robustness analysis path</ins>: The command assumes that the original analysis is not to be included as one analysis path in the multiverse robustness analysis. Otherwise specify the option `orig_in_multiverse(1)`. Then, the original result is incorporated in the computation of the two [variation indicators](#the-reproducibility-and-replicability-indicators). Irrespective of whether the original analysis is included as one robustness analysis path or not, the dataset should only include the information on the original analysis in the variables inputted via the options ending with *_orig*, and not as a separate robustness analysis path.


## Required input data structure 

### Data structure for analyses at study level

The input data at study level needs to be in a specific format for `repframe` to be able to calculate the indicators and dashboards. Each observation should represent one analysis path, that is the combination of analytical decisions in the multiverse robustness analysis. 
In the toy example with one main outcome represented in the below figure, two alternative choices are assessed for one analytical decision (**analytical_decision_1**, e.g. a certain adjustment of the outcome variable) and three alternative choices are assessed for two other analytical decision (**analytical_decision_2** and **analytical_decision_3**, e.g. the set of covariates and the sample used). This gives a multiverse of 3^2*2^1 = 18 analysis paths, if all combinations are to be considered. The number of observations is therefore 18 in this example.

For each observation, the minimum requirement is that the variable **mainlist** (this is the outcome at the study level) is defined together with the coefficient information inputted via the options `beta(varname)` and `beta_orig(varname)` and information to determine statistical significance. It is recommended to specify both the information on *p*-values and on standard errors, as outlined above in the sub-section on defaults applied by the `repframe` command. As noted in that same sub-section, the dataset should furthermore not include observations with information on the original analysis as robustness analysis paths but only in the variables inputted via the options ending with *_orig*. Also note that the variable **mainlist** should be numeric with value labels.

<img width="800" alt="toy example of repframe multiverse input data structure" src="https://github.com/guntherbensch/repframe/assets/128997073/81821432-de86-4bea-b0a8-66f8515c2508"> &nbsp;

The Stata help file contains a simple example that uses the command [`repframe_gendata`](https://github.com/guntherbensch/repframe/blob/main/repframe_gendata.ado) to build such a data structure. 

### Data structure for analyses across studies

The `repframe` can also be used to compile Reproducibility and Replicability Indicators across studies. To do so, one only has to append the *study-level indicator data* that include the Reproducibility and Replicability Indicators of individual studies and then feed them back into a variant of the `repframe` command. 
The following steps need to be taken:
1. run `repframe` multiple times with individual studies to create the *study-level indicator data* saved as *repframe_data_[fileidenfier].dta* &mdash; with [fileidenfier] as defined by the option `fileidentifier(string)`
2. `append` the individual *study-level indicator data*, making sure that all individual studies applied the same significance level, which can be checked with the variable **siglevel** contained in the *study-level indicator data*   
3. run the following commands to compile a dataset with Reproducibility and Replicability Indicators across studies

```stata
. encode ref, gen(reflist)
. drop ref
. order reflist
. save "[filename].dta", replace
```
&ensp; where [filename] can be freely chosen for the dataset containing all appended *study-level indicator data*, potentially including the full path of the file.  
4. run `repframe` again, now using the option `studypool(1)` to request the calculation of indicators across studies. 


## The Reproducibility and Replicability Indicators

The *Reproducibility and Replicability Indicators table* and the *Sensitivity Dashboard* present two separate sets of indicators. These indicators are primarily designed as easily and intuitively interpretable metrics for tests of robustness reproducibility, which asks to what extent results in original studies are robust to alternative plausible analytical decisions on the same data ([Dreber and Johannesson 2023](#references)). This makes it plausible to assume that that the tests of robustness reproducibility and the original study measure exactly the same underlying effect size, with no heterogeneity and no difference in statistical power. 

For tests of replicability using new data or alternative research designs, more sophisticated indicators are required to account for potential heterogeneity and difference in statistical power (cf. [Mathur & VanderWeele 2020](#references), [Pawel & Held 2022](#references)).

The indicators are meant to inform about the following three pieces of information on reproducibility and replicability, related to either statistical significance or effect sizes:
- <ins>agreement indicators</ins>: Can original and robustness results be considered to have the same statistical significance (effect size)?
- <ins>relative indicators</ins>: To what extent does the statistical significance (do the effect sizes) of the original results differ from those of the robustness results?
- <ins>variation indicators</ins>: To what extent do the robustness tests vary among each other in terms of statistical significance (effect sizes)? 

The *Sensitivity Dashboard* additionally includes the option `extended(string)`, which allows incorporating a
- <ins>significance switch indicator</ins>: To what extent are robustness coefficients (standard errors) large (small) enough to have turned an originally insignificant result significant, regardless of the associated standard error (coefficient)? And what about the reverse for originally significant results?   

### Reproducibility and Replicability Indicators table

The following describes the main indicators presented in the *Reproducibility and Replicability Indicators table* as they are computed at the level of each assessed outcome within a single study. Aggregation across outcomes at the study level is simply done by averaging the indicators as computed at outcome level, separately for outcomes reported as originally significant and outcomes reported as originally insignificant. Similarly, aggregation across studies is simply done by averaging the indicators as computed at study level.  

1. The **statistical significance indicator** as a significance agreement indicator measures for each outcome $j$ the share of the $n$ robustness analysis paths $i$ that are reported as statistically significant or insignificant in both the original study and the robustness analysis. Accordingly, the indicator is computed differently for outcomes where the original results were reported as statistically significant and those where the original results were found to be statistically insignificant. Statistical significance is defined by a two-sided test with $\alpha^{orig}$ being the significance level applied in the original study and $\alpha$ being the significance level applied in the robustness analysis. For statistically significant original results, the effects of the robustness analysis paths must also be in the same direction as the original result, as captured by coefficients having the same sign or, expressed mathematically, by $\mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)$.

$$ I_{1j} = mean(\mathbb{I}(pval_i \le \alpha) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0))  \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{1j} = mean(\mathbb{I}(pval_i > \alpha))  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$
  
:point_right: This percentage indicator is intended to capture whether statistical significance in a robustness analysis confirms statistical significance in an original study. The indicator reflects a combination of *technical* robustness of results (are estimates robust in terms of achieving a certain level of statistical significance?) and *classification* robustness (is the classification as statically significant robust to a potentially more (or less) demanding level of statistical significance?).  
> *Interpretation*: An indicator $I_{1j}$ of 0.3 for an outcome $j$ reported as statistically significant in the original study, for example, implies that 30\% of robustness analysis paths for this outcome (i) are statistically significant according to the significance level adopted in the robustness analysis, and (ii) that their coefficients share the same sign as the coefficient in the original study. Conversely, 70\% of robustness analysis paths for this outcome are most likely statistically insignificant, while it cannot be excluded that part of these paths are statistically significant but in the opposite direction. Note also that robustness analysis paths for this outcome may be found statistically ingnificant &mdash; and thus non-confirmatory &mdash; only because of a stricter significance level adopted in the robustness analysis compared to the original study. An indicator of 0.3 for outcomes reported as statistically insignificant in the original study implies that 30\% of robustness test analysis paths for this outcome are also statistically insignificant according to the significance level adopted in the robustness analysis. Now, the remaining 70\% of robustness analysis paths are statistically significant (most likely with the same sign), while a less strict significance level applied in the robustness analysis could now affect this indicator.   


2. The **relative effect size indicator**  measures the mean of the coefficients $\beta_i$ of all robustness analysis paths for each outcome $j$ divided by the original coefficient $\beta^{orig}_j$. The indicator requires that the effect sizes of the original and robustness results are measured in the same units. It is furthermore only applied to outcomes reported as statistically significant in the original study, now &mdash; and for the following indicators as well &mdash; irrespective of whether in the same direction or not.

$$ I_{2j} = \frac{mean(\beta_i)} {\beta^{orig}_j} \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{2j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$

:point_right: This ratio indicator is intended to capture how the size of robustness coefficients compares to the size of original coefficients.  
> *Interpretation*: An indicator $I_{2j}$ above 1 implies that the mean of the coefficients of all the robustness analysis paths for a statistically significant orginal result on outcome $j$ is &mdash; in absolute terms &mdash; higher than the original coefficient (while both show in the same direction), with a factor of $I_{2j}$ (e.g. 1.3). An indicator between 0 and 1 means that the mean coefficient in the robustness analysis paths is lower than the original coefficient (while both show in the same direction), again with a factor of $I_{2j}$ (e.g. 0.7). An indicator below 0 implies that the two compared parameters have different signs. Here, the absolute value of the mean coefficient in the robustness analysis paths is higher (lower) than the absolute value of the original coefficient if $I_{2j}$ is above (below) -1.


3. The **relative *t*/*z*-value indicator** as a relative significance indicator measures for each outcome $j$ the mean of the *t*/*z*-values ($zscore_i$) of all the robustness analysis paths divided by the *t*/*z*-value of the original result. The indicator is also only derived for outcomes reported as statistically significant in the original study.

$$ I_{3j} = \frac{mean(zscore_i)} {zscore^{orig}_j} \quad  \text{if } pval^{orig}_j \le \alpha^{orig} $$ 

$$ I_{3j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > \alpha^{orig} $$ 

:point_right: This ratio indicator is intended to capture how the statistical significance of robustness results compares to the statistical significance of original results.
> *Interpretation*: An indicator $I_{3j}$ above (below) 1 means that the average *t*/*z*-value of all robustness analysis paths for outcome $j$ is &mdash; in absolute terms &mdash; higher (lower) than the original coefficient, suggesting a higher (lower) level of statistical significance in the robustness analysis. An indicator below 0 additionally implies that the two compared parameters have different signs, where the absolute value of the mean *t*/*z*-value in the robustness analysis paths is higher (lower) than the absolute value of the original *t*/*z*-value if $I_{3j}$ is above (below) -1.


4. The **effect size variation indicator** measures for each outcome $j$ the standard deviation $sd$ of all robustness coefficients divided by the standard error $se$ of the original coefficient. 
Here, the $\beta_i$ may incorporate the original result as one robustness analysis path. The indicator requires that the effect sizes of the original and robustness results are measured in the same units.

$$ I_{4j} = \frac{sd(\beta_i)}{se(\beta^{orig}_j)} $$

applied separately to $pval^{orig}_j \le \alpha^{orig}$ and $pval^{orig}_j > \alpha^{orig}$. 

:point_right: This ratio indicator is intended to capture how the variation in coefficients of robustness results compares to the variation estimated for the original coefficient.
> *Interpretation*: An indicator $I_{4j}$ above (below) 1 means that variation across all robustness analysis paths for outcome $j$ is higher (lower) than the variation estimated for the original result, with a factor of $I_{4j}$. 


5. The ***t*/*z*-value variation indicator** as a significance variation indicator measures the standard deviation of *t*/*z*-values of all the robustness analysis paths for each outcom $j$. Here, the $zscore_i$ may incorporate the original result as one robustness analysis path.

$$ I_{5j} = sd(zscore_i)  $$

applied separately to $pval^{orig}_j \le \alpha^{orig}$ and $pval^{orig}_j > \alpha^{orig}$. 

:point_right: This absolute indicator is intended to capture the variation in the statistical significance across robustness results.
> *Interpretation*: $I_{5j}$ simply reports the standard deviation of *t*/*z*-values of all the robustness analysis paths for outcome $j$ as a measure of variation in statistical significance. Higher values indicate higher levels of variation.

The following shows an example of the *Reproducibility and Replicability Indicators table*, indicating the five indicators as outlined above.
<img width="600" alt="repframe indicators table example" src="https://github.com/guntherbensch/repframe/assets/128997073/24f31cc0-87b4-42bf-8446-621e22db3fe5"> &nbsp;
&nbsp;


### Sensitivity Dashboard

A general difference to the indicators included in the *Reproducibility and Replicability Indicators table* is that the same level of statistical significance is applied to original and robustness results. The motivation is to separate *technical* and *classification* reproducibility or replicability of results as defined above and outlined in the description of the first two indicators. 

In the same vein as for indicators presented in the *Reproducibility and Replicability Indicators table*, aggregation across outcomes at the study level (across studies) is simply done by averaging the indicators as computed at outcome (study) level, separately for outcomes reported as originally significant and outcomes reported as originally insignificant.

1. The **significance agreement indicator** is derived for each outcome $j$ in a similar way as the *statistical significance indicator* from the *Reproducibility and Replicability Indicators table*. The only differences are that (i) the indicator is the same for statistically significant and insignificant robustness results and that (ii) the same significance level $\alpha$ is applied to the original results and to the robustness results. The indicator is expressed in \% of all robustness results on either statistically significant or insignificant original results and, hence, additionally multiplied by 100.

$$ I´_{1j} = mean(\mathbb{I}(pval_i \le \alpha) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)) \times 100 $$

applied separately to $pval^{orig}_j \le \alpha$ and $pval^{orig}_j > \alpha$. 
The same indicator is also calculated for statistically significant robustness results with opposite sign, i.e. differing from the above formula through $\mathbb{I}(\beta_i \times \beta^{orig}_j < 0)$.

:point_right: This percentage indicator is intended to capture the *technical* robustness of results (are estimates robust in terms of achieving a certain level of statistical significance?).
> *Interpretation*: An indicator $I´_{1j}$ of 30\% implies that 30\% of robustness analysis paths for outcomes $j$ are statistically significant. Depending on which of the four sub-indicators of the *Sensitivity Dashboard* one is referring to, this refers to (i) statistically significant *or* insignficant original results and to (ii) original and robustness coefficients that share *or* do not share the same sign. For example, if $I´_{1j}$ is 30\% for results with the same sign and 3\% for results with opposite signs, the remaining 67\% of robustness analysis paths for this outcome are statistically insignificant. The significance levels applied to the original study and the robustness analysis are identical and correspond to the one defined in the robustness analysis.


2. The **indicator on non-agreement due to significance definition** is an auxiliary significance agreement indicator that focuses on *classification* reproducibility or replicability of results as defined above. It identifies those originally significant results that have statistically insignificant robustness analysis paths only because a more stringent significance level definition is applied in the robustness analysis than in the original study. The indicator is also expressed in \% and therefore includes the muliplication by 100. It requires that the effect sizes of the original and robustness results are measured in the same units.

$$ I´_{2j} = mean(\mathbb{I}(\alpha < pval_i \le \alpha^{orig}_j)) \times 100  \quad  \text{if } \alpha < pval^{orig}_j \le \alpha^{orig}_j $$

$$ I´_{2j}  \text{ not applicable otherwise} $$

:point_right: This percentage indicator is intended to capture non-robustnuss of results reported as significant in original studies that is due to differences in the classification of statistical significance.
> *Interpretation*: Consider the case where the robustness analysis paths apply a significance level of 5\% and the original analysis applied a less strict significance level of 10\%. In this case, robustness results with $0.05 < pval_i \le 0.10$ are only categorized as insignificant and thus having a non-agreeing significance level because of differing definitions of statistical significance. An indicator $I´_{2j}$ of 10\%, for example, implies that this holds true for 10\% of robustness analysis paths for outcome $j$.


3. The **relative effect size indicator** differs from $I_{2j}$ from the *Reproducibility and Replicability Indicators table* in that it is only derived for robustness analysis paths that are (i) statistically significant and (ii) in the same direction as the original result. In addition, the indicator takes the median of the robustness estimates instead of the mean, in order to be less sensitive to outliers. Furthermore, one is subtracted from the ratio, in order to underscore the relative nature of the indicator. A ratio of 2/5 thus turns into -3/5, and multiplied by 100 to -60\%.

$$ I´_{3j} = (\frac{median(\beta_i)} {\beta^{orig}_j} - 1) \times 100  \quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha \land \beta_i \times \beta^{orig}_j \ge 0 $$

$$ I´_{3j}  \text{ not applicable otherwise} $$

:point_right: This percentage indicator is intended to capture how the size of robustness coefficients compares to the size of original coefficients. The indicator focuses on the case where a comparison of coefficient sizes is most relevant and interpretable, that is when both the original and robustness results are statistically significant and in the same direction.  
> *Interpretation*: An indicator $I´_{3j}$ for outcome $j$ with an originally significant result (below) 0\% means that the mean of statistically significant robustness coefficients in the same direction as the original result is higher (lower) than the original coefficient, by $I´_{3j}$\% &mdash; e.g. +30\% (-30\%).


The Sensitivity Dashboard does not include a **relative significance indicator**.


4. The **effect size variation indicator** measures the mean absolute deviation of coefficients in robustness analysis paths from their median. Like $I´_{3j}$, it only considers robustness analysis paths for outcomes reported as statistically significant that are (i) statistically significant and (ii) in the same direction as the original result. The mean value is divided by the original coefficient and multiplied by 100 so that it is measured in the same unit as $I´_{3j}$. Here, the $\beta_i$ may incorporate the original result as one robustness analysis path. The indicator requires that the effect sizes of the original and robustness results are measured in the same units.

$$ I´_{4j} = \frac{mean(\mid \beta_i - median(\beta_i) \mid)}  {\beta^{orig}_j} \times 100  	\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha \land \beta_i \times \beta^{orig}_j \ge 0 $$ 

$$ I´_{4j}  \text{ not applicable otherwise} $$

:point_right: This percentage indicator is intended to capture how the variation in coefficients of robustness results compares to the variation in coefficients among original results. The indicator complements $I´_{3j}$ focusing on the the case of original and robustness results that are statstically significant and in the same direction. 
> *Interpretation*: An indicator $I´_{4j}$ of, for example, 10\% means that variation across robustness results for outcome $j$ is equivalent to 10\% of the original coefficient. 


5. The **significance variation indicator** measures the mean of the deviations between *p*-values from the robustness analysis paths and the original *p*-value. This indicator is always derived, except for robustness and original results that are both statistically significant, since the deviation is known to be small in that case.

$$ I´_{5j} = mean(\mid pval_i - pval^{orig}_j \mid) $$ 

applied separately to (i) $pval^{orig}_j \le \alpha \land pval_i > \alpha$, 
                     (ii) $pval^{orig}_j > \alpha \land pval_i > \alpha$, and 
                    (iii) $pval^{orig}_j > \alpha \land pval_i \le \alpha$.

:point_right: This absolute indicator is intended to capture the variation in statistical significance across robustness results that are or turned statistically insignificant.
> *Interpretation*: An indicator $I´_{5j}$ of 0.2, for example, implies that *p*-values among certain robustness analysis paths for outcome $j$ on average differ by 0.2 from the original *p*-value. Depending on which of the three sub-indicators of the *Sensitivity Dashboard* one is referring to, this refers to the case of (i) a significant original result and insignficant robustness results, (ii) an insignificant original result and insignficant robustness results, or (iii) an insignificant original result and signficant robustness results. Like *p*-values themselves, this deviation may assume values between 0 (very small deviation) and 1 (maximum deviation). 

#### Extension of the Sensitivity Dashboard
The *Sensitivity Dashboard* additionally includes the option `extended(string)` to show two types of indicators in an extended set of indicators. 


6. The **effect size agreement indicator** measures the share of robustness coefficients that lie inside the bounds of the confidence interval of the original coefficient, $\beta(cilo)^{orig}_j$ and $\beta(ciup)^{orig}_j$. It only considers statistically insignificant robustness analysis paths for outcomes reported as statistically significant in the original study. The indicator requires that the effect sizes of the original and robustness results are measured in the same units.

$$ I´_{6j} = mean(\mathbb{I}(\beta(cilo)^{orig}_j \le \beta_i \le beta(ciup)^{orig}_j)) \times 100 		\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i > \alpha $$ 

$$ I´_{6j}  \text{ not applicable otherwise} $$

:point_right: This percentage indicator is intended to complement the *significance agreement indicator* and thereby to capture *technical* robustness of results not only in terms of achieving a certain but arbitrary level of statistical significance, but also in terms of showing similarity of coefficients.
> *Interpretation*: An indicator $I´_{6j}$ of 10\% implies that 10\% of robustness analysis paths for this outcome $j$ with originally significant results are insignificant according to the significance level adopted by the robustness analysis, but with robustness coefficients that cannot be rejected to lie inside the confidence interval of the original result. The closer these 10\% are to the share of statistically insignificant robustness analysis paths for this outcome, the less does this indicator confirm the *statistical significance indicator*. For example, if the share of statistically insignificant robustness analysis paths for this outcome is 15\%, two-thirds of these analysis paths are non-confirmatory according to *statistical significance indicator* and confirmatory according to the *effect size agreement indicator*.


7. & 8. The **significance switch indicators** include two sub-indicators for originally significant and insignificant results, respectively. For originally significant results, these indicators measure the share of robustness coefficients (standard errors) that are sufficiently small (large) to have turned the result insignificant when standard errors (coefficients) are held at their values in the original study. Whether absolute values of coefficients (standard errors) are sufficiently small (large) is determined based on the threshold values $\beta(tonsig)_j$ and $se(tonsig)_j$. The indicators require that the effect sizes of the original and robustness results are measured in the same units.

$$ I´_{7j} = mean(\mathbb{I}(\mid \beta_i \mid  \le \beta(tonsig)_j) \times 100   		\quad  \text{if } pval^{orig}_j > \alpha \land pval_i > \alpha $$ 

$$ I´_{8j} = mean(\mathbb{I}(se_i  \ge se(tonsig)_j) \times 100   		\quad  \text{if } pval^{orig}_j > \alpha \land pval_i > \alpha $$ 

The indicators for originally insignificant results are a mirror image of those for originally significant results: now the indicators measure the shares of robustness coefficients (standard errors) that are sufficiently large (small) to have turned results significant, applying threshold values $\beta(tosig)_j$ and $se(tosig)_j$, respectively.   

$$ I´_{7j} = mean(\mathbb{I}(\mid \beta_i \mid  > \beta(tosig)_j) \times 100   		\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha $$ 

$$ I´_{8j} = mean(\mathbb{I}(se_i  < se(tosig)_j) \times 100   		\quad  \text{if } pval^{orig}_j \le \alpha \land pval_i \le \alpha $$ 

:point_right: These percentage indicators are intended to capture the drivers behind changes in statistical significance between original study and robustness analysis.
> *Interpretation*: An indicator $I´_{7j}$ of, for example, 30\% for an outcome $j$ with an originally significant result, implies that 30\% of the robustness analysis paths that are statistically insignificant have coefficients that are sufficiently small for the robustness analysis path to be statistically insignificant even if the standard error would be identical to the one in the original study. The other (sub-)indicators can be interpreted analogously. 


The following shows an example of the *Sensitivity Dashboard*, indicating where the indicators outlined above can be found in the figure. Indicators from the extended set are in lighter blue. 

<img width="600" alt="repframe Sensitivity Dashboard example" src="https://github.com/guntherbensch/repframe/assets/128997073/ac29ab67-727c-44a6-a0c6-855e99821f60"> &nbsp;
&nbsp;

<img width="600" alt="repframe Sensitivity Dashboard example, aggregated" src="https://github.com/guntherbensch/repframe/assets/128997073/b8616f2e-a187-4e38-8144-480998388b40"> &nbsp;
&nbsp;


## Update log

2024-03-04, v1.4.2:

- Adjust the option `extended` to allow for multiple choices.
- Extend the application of the significance variation indicator in the Sensitivity Dashboard to originally insignificant results with significant robustness results.
- Minor revisions of the code.

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

