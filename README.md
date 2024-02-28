> # **Feb 28, 2024: An update of the command and its description will be available in the coming week.**

# REPFRAME v1.4

This is a Stata package that produces Reproducibility and Replicability Indicators and Sensitivity Dashboards. These tools compare estimates from a multiverse of analysis paths of robustness tests - be they reproducibility or replicability analyses - to the original estimate in order to gauge the degree of reproducibility or replicability. The package comes with two commands: `repframe` is the main command, and `repframe_gendata` generates a dataset that is used in the help file of the command to show examples of how the command works. 

The package can be installed by executing in Stata:
```stata
net install repframe, from("https://raw.githubusercontent.com/guntherbensch/repframe/main") replace
```

Once installed, please see 
```stata
help repframe
```
for the syntax and the whole range of options.


## Required input data structure

The data needs to be in a specific format for repframe to be able to calculate the Indicators and Dashboards. Each observation should represent one analysis path, that is the combination of analytical decisions in the multiverse robustness test. 
In the below toy example with only one main outcome, two alternative choices are assessed for one analytical decision (**analytical decision_1**, e.g. a certain adjustment of the outcome variable) and three alternative choices are assessed for two other analytical decision (**analytical decision_2** and **analytical decision_3**, e.g. the set of covariates and the sample used). This gives a multiverse of 3^2*2^1 = 18 analysis paths, if all combinations are to be considered. The number of observations is therefore 18 in this example.

For each observation, the minimum requirement is that the variables **outcome**, **beta** and **beta_orig** are defined together with **se** and **se_orig**. As an alternative to the standard error information, information on *p*-values (**pval** and **pval_orig**) or on the *t*/*z*-score (**zscore** and **zscore_orig**) may be provided.  

It is important to note that, irrespective of whether the original analysis is included as one analysis path in the multiverse robustness test or not, the dataset should only include the information on the original analysis in the variables ending with **_orig**. Also note that the variable **outcome** should be numeric with value labels.

<img width="800" alt="toy example of repframe multiverse input data structure" src="https://github.com/guntherbensch/repframe/assets/128997073/dcace409-a602-47d5-a240-67961eda3256"> &nbsp;

The Stata help file contains a simple example that uses the command [`repframe_gendata`](https://github.com/guntherbensch/repframe/blob/main/repframe_gendata.ado) to build such a data structure. 


## Defaults applied by the repframe command

The `repframe` command applies a few default assumptions. Use the following options in case your analysis applies different assumptions. 

<ins>Tests for statistical significance</ins>: The command applies two-sided *t*-tests for statistical significance with a 5% significance level. The significance level can be adjusted using the option `siglevel(#)`, for example by changing it to `siglevel(10)`. Degrees of freedom can be defined for smaller samples with the options `df(varname)` and `df_orig(varname)`, each requiring a numerical variable containing the observation-specific information on the degrees of freedom. Avoid inputting **pval** and **pval_orig** if you used one-sided tests; otherwise multiply these *p*-values by two so as to make them correspond to a two-sided test. Finally, consider well if this input data on *p*-values is based on other distributional assumptions.

<ins>Units in which effect sizes are measured</ins>: The command assumes that effect sizes of original results and results of robustness test are measured in the same unit. If this is not the case, for example because one is measured in log terms and the other is not, use the option `sameunits(varname)`, which requires a numerical variable containing the observation-specific binary information on whether the two are measured in the same unit (1=yes) or not (0=no).

<ins>Original analysis to be included as one analysis path in the multiverse robustness test</ins>: The command assumes that the original analysis is not to be included as one analysis path in the multiverse robustness test, otherwise specify the option `orig_in_multiverse(1)`. Then, the original result is incorporated in the computation of the variation indicators. Irrespective of whether the original analysis is included as one analysis path in the multiverse robustness test or not, the dataset should only include the information on the original analysis in the variables ending with **_orig**, and not in the variables on the analysis paths of robustness tests.


## Output data

The `repframe` command produces output in the form of a Sensitivity Dashboard graph, a Reproducibility and Replicability Indicators table and a dataset including the Reproducibility and Replicability Indicators of an individual study.

See the Reproducibility Assessment Protocol (available upon request) for a more detailed description of the individual indicators.

The dataset including the Reproducibility and Replicability Indicators can be used to compile Reproducibility and Replicability Indicators across studies.


## Reproducibility and Replicability Indicators across studies

The `repframe` can also be used to compile Reproducibility and Replicability Indicators across studies. To do so, only only hgas to append the Stata datasets that include the Reproducibility and Replicability Indicators of individual studies and then feed them back into a variant of the `repframe` command. 
The following steps need to be taken:
1. run `repframe` multiple times with multiple studies
2. `append` the individual data outputs saved as *reproframe_data_[fileidenfier].dta* - with [fileidenfier] as defined by the option `fileidentifier(string)`, making sure that all individual studies applied the same significance level, which can be checked by the variable called **siglevel** contained in the individual data outputs   
3. run the following commands to compile a dataset with Reproducibility and Replicability Indicators across studies

```stata
. encode ref, gen(reflist)
. drop ref
. foreach var in beta beta_orig {
	  gen `var' = .  // empty variables generated since these are required to run the command repframe
  }
  order reflist
. save "[filename].dta", replace
```
&ensp; where [filename] can be freely chosen for the dataset containing all appended individual data outputs, potentially including the full path of the file.  
4. run `repframe` again, now using the options `studypool(1)` to request the Indicators to be calculated across studies and `siglevel(#)` to specify the significance level applied to the indivdual studies in two-sided tests, for example `siglevel(5)` or `siglevel(10)`. 


## The Reproducibility and Replicability Indicators

The indicators are primarily designed as easily and intuitively interpretable metrics for tests of robustness reproducibility, which asks to what extent results in original studies are robust to alternative plausible analytical decisions on the same data ([Dreber and Johannesson 2023](#references)). This makes it plausible to assume that that the tests of robustness reproducibility and the original study measure exactly the same underlying effect size, with no heterogeneity and no difference in statistical power. 

For replications using new data or alternative research designs, more sophisticated indicators are required to account for potential heterogeneity and difference in statistical power (cf. [Mathur & VanderWeele 2020](#references), [Pawel & Held 2022](#references)).

The indicators are meant to inform about the following three pieces of information on reproducibility and replicability:
- <ins>significance agreement</ins>: To what extent does the statistical significance in the original and robustness results differ?
- <ins>relative effect size</ins>: To what extent do the effect sizes of the original results differ from those of the robustness results?
- <ins>variation</ins>: To what extent do the robustness tests vary among each other? 

The following describes the indicators as they are computed at the level of each assessed outcome within a single study. 

The **significance agreement indicator** measures for each outcome $j$ the share of the $n$ robustness test analysis paths $i$ whose level of statistical significance agrees with that of the original result. Accordingly, the indicator is computed differently for outcomes where the original results $orig$ were found to be statistically significant and those where the original results were found to be statistically insignificant. Statistical significance is defined by a two-sided tests with a significance level of $\alpha$, the default being $\alpha=0.05$. For original results found to be statistically significant, the effects of the robustness test analysis paths additionally have to be in the same direction as the original result.

$$ I_{1j} = \frac{1}{n} \times \sum_{i=1}^n \mathbb{I}(pval_i \le &alpha;) \times \mathbb{I}(\beta_i \times \beta^{orig}_j \ge 0)  \quad  \text{if } pval^{orig}_j \le &alpha; $$ 

$$ I_{1j} = \frac{1}{n} \times \sum_{i=1}^n \mathbb{I}(pval_i > &alpha;)  \quad  \text{if } pval^{orig}_j > &alpha; $$ 


The **relative effect size indicator**  measures for each outcome $j$ the mean of the effect sizes $\beta$ of all the $n$ robustness test analysis paths divided by the original effect size. Again, different formula are applied to outcomes where the original results were found to be statistically significant and those where the original results were found to be statistically insignificant. This indicator requires that the effect sizes of the original and robustness test results are measured in the same units.

$$ I_{2j} = \frac{ \frac{1}{n} \times \sum \beta_i} {\beta^{orig}_j} \quad  \text{if } pval^{orig}_j \le &alpha; $$ 

$$ I_{2j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > &alpha; $$ 


The **relative *t*/*z*-value indicator** measures for each outcome $j$ the mean of the *t*/*z*-values ($zscore$) of all the robustness test analysis paths divided by the *t*/*z*-value of the original result.

$$ I_{3j} = \frac{ \frac{1}{n} \times \sum zscore_i} {zscore^{orig}_j} \quad  \text{if } pval^{orig}_j \le &alpha; $$ 

$$ I_{3j}  \text{ not applicable}  \quad  \text{if } pval^{orig}_j > &alpha; $$ 


The **effect size variation indicator** measures the standard deviation of effect sizes of all the robustness test analysis paths divided by the standard error of the original effect size. 
Here, the $\beta_i$ may incorporate the original result as one robustness test analysis path.

$$ I_{4j} = \sqrt{ \frac\{ (\sum \beta_i - \bar{\beta_i})^2}{N}}  / \sqrt{ \frac{ \sum (\beta^{orig}_j - \bar{\beta^{orig}_j})^2}{N}} \times \frac{ 1}{\sqrt{ N}}  $$

Alternatively expressed through the standard deviation $sd$ and the standard error $se$, the formula simplifies to

$$ I_{4j} = \frac{ sd(\beta_i)}{se(\beta^{orig}_j)} $$


The ***t*/*z*-value variation indicator** measures the standard deviation of *t*/*z*-values of all the robustness test analysis paths.

$$ I_{5j} = \sqrt{ \frac\{ (\sum zscore_i - \bar{zscore_i})^2}{N}} = sd(zscore_i)  $$


For all indicators, aggregation at the study level is simply done by averaging the indicators as computed at outcome level. 

Similarly, aggregation across studies is simply done by averaging the indicators as computed at study level. 


## Update log

2024-02-XX, v1.4:

- Add option `siglevel_orig' to allow testing against significance level adopted by original authors.
- Additional effect size agreement / confidence interval coverage indicator.

2024-02-13, v1.3.1:

- Minor amendments to the code.

2024-01-22, v1.3:

- Add the option `studypooling' to calculate indicators across studies.

2024-01-19, v1.2:

- Incorporate the package `sensdash'.

2024-01-18, v1.1:

- First version of `repframe' package.


## References
Dreber, A. & Johanneson, M. (2023). *A Framework for Evaluating Reproducibility and Replicability in Economics.* Available at [SSRN](http://dx.doi.org/10.2139/ssrn.4458153).

Mathur, M. B., & VanderWeele, T. J. (2020). New statistical metrics for multisite replication projects. *Journal of the Royal Statistical Society Series A: Statistics in Society*, *183*(3), 1145-1166.

Pawel, S., & Held, L. (2022). The sceptical Bayes factor for the assessment of replication success. *Journal of the Royal Statistical Society Series B: Statistical Methodology*, *84*(3), 879-911.
 
 


 

