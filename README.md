# REPFRAME v1.3

This is a Stata package that produces Reproducibility and Replicability Indicators and Sensitivity Dashboards. These tools compare estimates from a multiverse of analysis paths of robustness tests - be they reproducibility or replicability analyses - to the original estimate in order to gauge the degree of reproducibility or replicability. The package comes with two commands: `repframe` is the main command, and `repframe_gendata` generates a dataset that is used in the help file of the command to show examples of how the command works. 

The package can be installed by executing in Stata:
```stata
net install repframe, from("https://raw.githubusercontent.com/guntherbensch/repframe/main") replace
```

Once installed, please see `help repframe` for the syntax and the whole range of options.


## Required input data structure

The data needs to be in a specific format for repframe to be able to calculate the Indicators and Dashboards. Each observation should represent one analysis path, that is the combination of analytical decisions in the multiverse robustness test. 
In the below toy example, two alternative choices are assessed for one analytical decision (*outcome*), and three alternative choices are assessed for two other analytical decision (*covariates* and *sample*). This gives a multiverse of 3^2*2^1 = 18 analysis paths, if all combinations are to be considered. The number of observations is therefore 18 in this example.

For each observation, the minimum requirement is that the variables `beta` and `beta_orig` are defined together with `se` and `se_orig`. As an alternative to the standard error information, information on *p*-values (`pval` and `pval_orig`) or on the *t*/*z*-score (`zscore` and `zscore_orig`) may be proveided.  

It is important to note that, irrespective of whether the original analysis is included as one analysis path in the multiverse robustness test or not, the dataset should only include the information on the original analysis in the variables ending with `_orig`.

<img width="500" alt="toy example of repframe multiverse input data structure" src="https://github.com/guntherbensch/repframe/assets/128997073/a7856668-c22b-4783-a2a4-7b1aea2d3c8b">


## Output data

The package produces output in the form of a Sensitivity Dashboard graph, a Reproducibility and Replicability Indicators table and a dataset including the Reproducibility and Replicability Indicators of an individual study.

See the Reproducibility Assessment Protocol (available upon request) for a more detailed description of the individual indicators.

The dataset including the Reproducibility and Replicability Indicators can be used to compile Reproducibility and Replicability Indicators across studies.


## Reproducibility and Replicability Indicators across studies

The Stata datasets including the Reproducibility and Replicability Indicators of individual studies can be appended and then be fed back into the `repframe` package in order to compile Reproducibility and Replicability Indicators across studies. The following steps need to be taken:
1. run `repframe` multiple times with multiple studies
2. `append` the individual data outputs saved as `reproframe_data_fileidenfier'.dta`, making sure that all apply the same significance level stored under the variable name `siglevel` 
3. run the following commands to compile a dataset with Reproducibility and Replicability Indicators across studies

```stata
. encode ref, gen(reflist)
. drop ref siglevel
. foreach var in beta beta_orig se se_orig {
	  gen `var' = .
  }
. save "[filename].dta", replace
```
4. run `repframe` again, now using the options `studypool(1)` to request the Indicators to be calculated across studies and `siglevel(#)` to specify the significance level applied to the indivdual studies in two-sided tests, for example 5 or 10. 


## Update log

2024-01-22, v1.3:

- Add the option `studypooling' to calculate indicators across studies.

2024-01-19, v1.2:

- Incorporate the package `sensdash'.

2024-01-18, v1.1:

- First version of `repframe' package.
 
 


 

