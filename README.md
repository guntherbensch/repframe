# REPFRAME v1.1

This is a Stata package that produces Reproducibility and Replicability Indicators and Sensitivity Dashboards. These tools compare estimates from a multiverse of analysis paths of robustness tests - be they reproducibility or replicability analyses - to the original estimate in order to gauge the degree of reproducibility or replicability. The package comes with two commands: `repframe` is the main command, and `repframe_gendata` generates a dataset that is used in the help file of the command to show examples of how the command works. 

The package can be installed by executing in Stata:
```
net install repframe, from("https://raw.githubusercontent.com/guntherbensch/repframe/main") replace
```

Once installed, please see `help repframe` for the syntax and the whole range of options.


## Required input data structure

The data needs to be in a specific format for repframe to be able to calculate the Indicators and Dashboards. Each observation should represent one analysis path, that is the combination of analytical decisions in the multiverse robustness test. 
In the below toy example, two alternative choices are assessed for one analytical decision (*outcome*), and three alternative choices are assessed for two other analytical decision (*covariates* and *sample*). This gives a multiverse of 3^2*2^1 = 18 analysis paths, if all combinations are to be considered. The number of observations is therefore 18 in this example.

For each observation, the minimum requirement is that `beta` and `beta_orig` are defined together with `se` and `se_orig`. As an alternative to the standard error information, information on *p*-values (`pval` and `pval_orig`) or on the *t*/*z*-score (`zscore` and `zscore_orig`) may be proveided.  

It is important to note that, irrespective of whether the original analysis is included as one analysis path in the multiverse robustness test or not, the dataset should only include the information on the original analysis in the variables ending with `_orig`.

<img width="500" alt="toy example of repframe multiverse input data structure" src="https://github.com/guntherbensch/repframe/assets/128997073/a7856668-c22b-4783-a2a4-7b1aea2d3c8b">

## Required input data structure

Details will follow soon.
