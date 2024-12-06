{smcl}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "repframe##syntax"}{...}
{viewerjumpto "Description" "repframe##description"}{...}
{viewerjumpto "Options" "repframe##options"}{...}
{viewerjumpto "Remarks" "repframe##remarks"}{...}
{viewerjumpto "Examples" "repframe##examples"}{...}
{hi:help repframe}{...}
{right:}
{hline}

{title:Title}

{phang}
{bf:repframe} {hline 2} Calculate, tabulate and visualize Reproducibility and Replicability Indicators

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:repframe}
{it:mainvar}
{ifin}
{cmd:,} [{it:parameters required in study-level analyses}] [{it:semi-optional parameters}] [{it:optional parameters}]

{pstd}
where {cmd:mainvar} is the name of the labelled variable that specifies either{p_end}
{p 8 17 2}- the result(s) studied in a single reproducibility or replicability analysis study, or{p_end}
{p 8 17 2}- the study references of reproducibility or replicability analyses studies, if to be pooled across studies ({cmd:studypooling(1)}).{p_end}


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:parameters required for study-level analyses {help repframe##options:[+]}}
{synopt:{opt beta(varname)}}beta coefficients in analysis paths of robustness tests, incl. original beta coefficient{p_end}
{synopt:{opt siglevel(#)}}significance level{p_end}
{synopt:{opt siglevel_orig(#)}}maximum significance level labelled as statically significant by original authors{p_end}
{synopt:{opt origpath(varname)}}specifier of analysis paths from original study{p_end}
{synopt:{opt shortref(string)}}short study reference{p_end}

{syntab:parameters being semi-optional for study-level analyses {help repframe##dsemioptional_para:[+]}}
{synopt:{opt pval(varname)}}{it:p}-values on statistical significance of estimates in analysis paths of robustness tests and original study{p_end}
{synopt:{opt se(varname)}}standard errors of beta coefficients in analysis paths of robustness tests and original study{p_end}
{synopt:{opt zscore(varname)}}{it:t}/{it:z}-scores of estimates in analysis paths of robustness tests and original study{p_end}

{syntab:optional parameters {help repframe##optional_para:[+]}}
{synopt:{opt studypool:ing(0/1)}}pool Reproducibility and Replicability Indicators across studies{p_end}
{synopt:{opt decisions(varlist)}}analytical decision variables{p_end}
{synopt:{opt df(varname)}}degrees of freedom in analysis paths of robustness tests and original study{p_end}
{synopt:{opt mean(varname)}}mean of the outcome variables in the analysis paths of robustness tests and original study{p_end}
{synopt:{opt sameunits(varname)}}indicator on whether original study and analysis paths of robustness tests use same effect size units{p_end}
{synopt:{opt filepath(string)}}file storage location{p_end}
{synopt:{opt fileid:entifier(string)}}file version identifier{p_end}
{synopt:{opt orig_in_multiverse(varname)}}inclusion of original specification in set of analysis paths of robustness test{p_end}
{synopt:{opt prefpath(varname)}}specifier of preferred analysis path of robustness test{p_end}
{synopt:{opt ivarw:eight(0/1)}}show Reproducibility and Replicability Indicators across all results weighted by the inverse variance{p_end}

{syntab:optional parameters related to table of Reproducibility and Replicability Indicators {help repframe##optional_para_RRI:[+]}}
{synopt:{opt tabfmt(string)}}file format of Reproducibility and Replicability Indicators table{p_end}
{synopt:{opt shelvedind(0/1)}}show shelved Reproducibility and Replicability Indicators{p_end}
{synopt:{opt beta2(varname)}}second beta coefficients in analysis paths of robustness tests and original study{p_end}
{synopt:{opt pval2(varname)}}{it:p}-values on second estimates in analysis paths of robustness tests and original study{p_end}
{synopt:{opt se2(varname)}}standard errors of second beta coefficients in analysis paths of robustness tests and original study{p_end}
{synopt:{opt zscore2(varname)}}{it:t}/{it:z}-scores of second beta coefficients in analysis paths of robustness tests and original study{p_end}

{syntab:optional parameters related to Robustness Dashboard {help repframe##optional_para_RobDash:[+]}}
{synopt:{opt dash:board(0/1)}}create Robustness Dashboard{p_end}
{synopt:{opt vshortref_orig(string)}}very short reference to original study{p_end}
{synopt:{opt extended(string)}}show indicators from extended set of Reproducibility and Replicability Indicators in the dashboard{p_end}
{synopt:{opt aggregation(0/1)}}show results in the dashboard aggregated across results instead of individually{p_end}
{synopt:{opt graphfmt(string)}}file format of Robustness Dashboard graph{p_end}
{synopt:{opt ivF(varname)}}first-stage {it:F}-Statistics, if IV/2SLS estimations{p_end}
{synopt:{opt signfirst(varname)}}share of first stages with wrong sign{p_end}
{synoptline}
{p2colreset}{...}

			
{marker description}{...}
{title:Description}

{pstd}
{cmd:repframe} calculates Reproducibility and Replicability Indicators to compare estimates from a multiverse of analysis paths 
of robustness tests - be they reproducibility or replicability analyses - to the original estimates.
The command can be applied to calculate indicators across results of a single study or alternatively across studies, the latter requiring that {cmd:studypooling(1)} is set.  
The command produces four outputs: 
First, a table with the main set of indicators ({it:Reproducibility and Replicability Indicators table}). 
Second, a figure that visualizes a second set of indicators, the so-called {it:Robustness Dashboard}, which may be complemented by additional plots to further scrutinize the robustness of results,
the latter requiring that {cmd:decisions()} and/ or {cmd:prefpath()} is defined.    
Third - if the analysis is at the study level -, a dataset with {it:harmonized analysis path data}.
Fourth - again if the analysis is at the study level -, a dataset with {it:study-level indicator data} that is ready to be re-introduced into the command when {cmd:studypooling(1)} is set.  
The required data structure and the output data with the different indicators is described in the {help repframe##see_also:online Readme on GitHub}.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:parameters required for study-level analyses}

{phang}
{opt beta(varname)} specifies the variable {it:varname} that includes the beta coefficients in analysis paths of robustness tests at study level
and also the original beta coefficient for the respective result at study level.

{phang}
{opt siglevel(#)} gives the significance level for two-sided tests at study level applied to robustness analyses;
{cmd:siglevel(5)}, for example, stands for a 5% level;
{cmd:siglevel(#)} is also the significance level applied to original results with indicators presented in the {it:Robustness Dashboard}.

{phang}
{opt siglevel_orig(#)} gives the maximum level of statistical significance labelled as statically significant by original authors, assuming two-sided tests; 
{cmd:siglevel_orig(5)}, for example, stands for a 5% level applied by original authors;
the {it:Reproducibility and Replicability Indicators table} classifies original results as statistically significant against this benchmark and
the {it:Robustness Dashboard} shows the related {it:Indicator on non-agreement due to significance definition}.  

{phang}
{opt origpath(varname)} specifies the variable {it:varname} that contains for each and every observation a binary indicator on whether the analysis path
(i.e. specification) is the one from the original study.

{phang}
{opt shortref(string)} provides a short reference in string format for the study, such as "[first author] et al. (year)".
This reference can either be a reference to the original study or to the reproducability or replicability analysis study.


{marker semioptional_para}{...}
{dlgtab:parameters being semi-optional for study-level analyses}

{phang}
To derive the degree of statistical significance of individual estimates, the command {it:repframe} uses information from {cmd:pval()},
{cmd:se()} and {cmd:zscore()}. and {cmd:zscore_orig()}. The command {it:repframe} determines the non-specified variables based on
the {it:t}-test formula and making assumptions on normality of the data, which may not be appropriate in all cases.
It is therefore recommended to specify both the information on {it:p}-values and standard errors
(see also the discussion on defaults applied by the command {it:repframe} in the {help repframe##see_also:online Readme on GitHub}).

{phang}
{opt pval(varname)} specifies the variable {it:varname} that includes the {it:p}-values on statistical significance of estimates in analysis paths
of robustness tests and the original study; {it:p}-values are assumed to be derived from two-sided {it:t}-tests; if {cmd:pval()} is not specified,
it is calculated based on {cmd:beta()} and {cmd:se()} or {cmd:beta()} and {cmd:zscore()}.

{phang}
{opt se(varname)} specifies the variable {it:varname} that includes the standard errors of beta coefficients in analysis paths of robustness tests and
the original study; if {cmd:se()} is not specified, it is calculated based on {cmd:beta()} and {cmd:pval()} or {cmd:beta()} and {cmd:zscore()}. 

{phang}
{opt zscore(varname)} specifies the variable {it:varname} that includes the {it:t}/{it:z}-scores of estimates in analysis paths of robustness tests and
the original study; if {cmd:zscore()} is not specified, it is calculated based on {cmd:beta()} and {cmd:se()} or {cmd:beta()} and {cmd:pval()}.


{marker optional_para}{...}
{dlgtab:optional parameters}

{phang}
Some optional parameters that can only be applied to study-level analyses (SLA) are marked by "[SLA only]".

{phang}
{opt studypool:ing(0/1)} is a binary indicator on whether input data are Reproducibility and Replicability Indicators on individual studies, 
for which Indicators pooled across studies are to be calculated; default is {cmd:studypooling(0)}.

{phang}
{opt decisions(varlist)} specifies the list of variables {it:varlist} that cover the analytical decisions adopted in the robustness tests. 
Each of the variables is either a binary or a categorical numerical variable indicating the choice of the analytical decision taken in the
respective analytical path. The decision choices taken in the original study, indicated by ({cmd:origpath==1}), also have to be included in
the input data, and they all have to be set to zero. For example, one of the variables may be the set of covariates used, where -0- is the 
choice of the original authors (irrespective of whether that choice is included in any analysis path of the multiverse analysis), and -1- may
represents a set of covariates introduced as part of the robustness test.
If {cmd:decisions()} is defined, three complementary plots are generated that show the contributions of individual decisions to deviations in indicator values.
When generated, these plots are briefly described in Stata's results window. [SLA only]

{phang}			
{opt df(varname)} specifies the variable {it:varname} that includes the degrees of freedom in analysis paths of robustness tests and the original study;
if {cmd:df()} is not specified, an approximately normal distribution is assumed. [SLA only]

{phang}
{opt mean(varname)} specifies the variable {it:varname} that includes the mean of the outcome variables in the analysis paths of robustness tests and
the original study, ideally being the baseline mean in the control group; if {cmd:mean()} is not specified for analysis paths of robustness tests,
it is assumed to be equal to {cmd:mean()} in the original study. [SLA only]

{phang}
{opt sameunits(varname)} specifies the variable {it:varname} that contains for each and every observation a binary indicator
on whether the original study and analysis paths of robustness tests use same effect size units ({it:varname}==1)
or not ({it:varname}==0); default is that {it:varname} is assumed to be always equal to one. [SLA only]

{phang}
{opt filepath(string)} provides the full file path under which the output files (table, graph, and data) of the {it:repframe} command are stored. 
If {cmd:filepath(string)} is not defined, outputs are stores in the operating system's standard /Downloads folder.

{phang}
{opt fileid:entifier(string)} allows to specifiy an identifier by which to differentiate versions of the output files (table, graph, and data)
of the {it:repframe} command. This identifier serves as a suffix to these files. If {cmd:fileidentifier(string)} is not defined,
the current date is used as default.

{phang}
{opt orig_in_multiverse(varname)} specifies the variable {it:varname} that contains for each and every observation a binary indicator on
whether the original specification should be included for the respective result as one analysis path in the multiverse robustness test
({it:varname}==1 or {it:varname}==0); default is that {it:varname} is zero for all results.
It is therefore important to note that it is not sufficient to include the original specification as one analysis path into the dataset 
that is used with the command {it:repframe}, but that {it:varname}==1 has to be set for the respective result in order to account for the
analysis path of the original study in the indicator calculation. Specifically, this choice affects the variation indicators among the
Reproducibility and Replicability Indicators. [SLA only]

{phang}
{opt prefpath(varname)} specifies the variable {it:varname} that contains for each and every observation a binary indicator on
whether the analysis path is considered the preferred specification of the robustness test; default is to consider none of the
analysis paths as preferred ({it:varname}==0). If {cmd:prefpath()} is defined, one complementary coefficient plot is generated
that compares the original estimate with this preferred estimate of the robustness test. [SLA only]

{phang}
{opt ivarweight(0/1)} is a binary indicator on whether to show Reproducibility and Replicability Indicators across all results
weighted by the inverse variance (yes=1, no=0); default is {cmd:ivarweight(0)}. This parameter requires that the {cmd:mean(varname)}
and {cmd:mean_orig(varname)} are also defined. [SLA only]


{marker optional_para_RRI}{...}		
{dlgtab:optional parameters related to table of Reproducibility and Replicability Indicators}

{phang}
Some optional parameters that can only be applied to study-level analyses (SLA) are marked by "[SLA only]".

{phang}
{opt tabfmt(string)} provides the file format under which the table of Reproducibility and Replicability Indicators is stored; default is {cmd:tabfmt(csv)}, 
but a slightly more formatted version is available for {cmd:tabfmt(xlsx)}.

{phang}
{opt shelvedind(0/1)} is a binary indicator on whether to also show shelved indicators from among the indicators 
proposed in a previous version of {help repframe##references:Dreber and Johannesson (2024)} (yes=1, no=0); default is {cmd:shelvedind(0)}. 

{phang}
{opt beta2(varname)} specifies the variable {it:varname} that includes the second beta coefficients in analysis paths of robustness tests and the original study,
if such second coefficients exist. This may, for example, be the case if the robustness test involves the coefficient of a variable
and the coefficient of the squared variable in order to test non-linear relationships. [SLA only]

{phang}
{opt pval2(varname)} specifies the variable {it:varname} that includes the {it:p}-values on statistical significance of second estimates
in analysis paths of robustness tests and the original study, if such second estimates exist;
if {cmd:pval2()} is not specified, it is calculated based on {cmd:beta2()} and {cmd:se2()} or {cmd:beta2()} and {cmd:zscore2()}. [SLA only]

{phang}
{opt se2(varname)} specifies the variable {it:varname} that includes the standard errors of second beta coefficients in analysis paths of robustness tests
and the original study, if such second beta coefficients exist; if {cmd:se2()} is not specified, it is calculated based on {cmd:beta2()} and {cmd:pval2()}
or {cmd:beta2()} and {cmd:zscore2()}. [SLA only]

{phang}
{opt zscore2(varname)} specifies the variable {it:varname} that includes the {it:t}/{it:z}-scores of second estimates in analysis paths of robustness tests
and the original study if such second estimates exist; if {cmd:zscore2()} is not specified, it is calculated based on {cmd:beta2()} and
{cmd:se2()} or {cmd:beta2()} and {cmd:pval2()}. [SLA only]


{marker optional_para_RobDash}{...}
{dlgtab:optional parameters related to Robustness Dashboard}

{phang}
Some optional parameters that can only be applied to study-level analyses (SLA) are marked by "[SLA only]".

{phang}
{opt dash:board(0/1)} is a binary indicator on whether to create the Robustness Dashboard (yes=1, no=0);
default is {cmd:dashboard(1)}.

{phang}
{opt vshortref_orig(string)} provides a very short reference to the original study, for example "[first letters of original authors] (year)";
default is {cmd vshortref_orig("original estimate")}. This reference is included in the Robustness Dashboard. [SLA only]

{phang}
{opt extended(string)} provides the type of indicator from the extended set of Reproducibility and Replicability Indicators that is to be shown in the dashboard;
{cmd extended()} can be set to "none" (no indicator from the extended set) or "SIGswitch" (Significance switch indicator); default is {cmd:extended("none")}.

{phang}
{opt aggregation(0/1)} is a binary indicator on whether to show results in the dashboard individually (=0) or aggregated across results (=1);
default at study level is {cmd:aggregation(0)}; if pooled across studies, {cmd:aggregation()} is always set to 1. [SLA only]

{phang}
{opt graphfmt(string)} provides the file format under which the Robustness Dashboard is stored; default is {cmd:graphfmt(emf)} for Windows
and {cmd:graphfmt(tif)} otherwise; {help graph export:other possible formats} include {it:ps},  {it:eps},  {it:pdf}, and  {it:png}.

{phang}
{opt ivF(varname)} specifies the variable {it:varname} that includes the first-stage {it:F}-Statistics,
if estimates are based on IV/2SLS estimations.

{phang}
{opt signfirst(varname)} specifies the (uniform) variable {it:varname} that includes the share of first stages with wrong sign in a range between 0 and 1,
if IV/2SLS estimations (cf. {help repframe##references:Angrist and Kolesár (2024)}). This parameter should only be used if the share is identical for all results.	


{marker examples}{...}
{title:Examples}

{phang}	
{bf:Data preparation for analyses at study level}

{p 8 12}. {stata "use http://www.stata-press.com/data/mus2/mus206nhanes.dta"}{p_end}
{p 8 12}(Data from the second US National health and Nutrition Examination Survey (NHANES II), 1976-1980){p_end}

{p 8 12}({stata "repframe_gendata, studypooling(0)":{it:click to generate multiverse dataset at study level}}){p_end}

{phang}	
{bf:#1.1: Reproducibility and Replicability Indicators table and Robustness Dashboard with minimum parameter settings}

{p 8 12}. {stata "repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex)"}{p_end}

{p 8 12}
[{it:note that this example requires that the output table can be stored in the operating system's standard /Downloads folder. If this does not work, specify the file location with the parameter} {cmd:filepath(string)}.]{p_end}

{phang}	
{bf:#1.2: Same output as #1.1, now based on information on the degrees of freedom instead of {it:p}-values}

{p 8 12}. {stata "repframe outcome, beta(b) df(df) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex)"}{p_end}

{phang}	
{bf:#1.3a: Variation of #1.1 in that Dashboard now includes information on the deviations of the original results from their mean}

{p 8 12}. {stata "repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex)  mean(out_mn)"}{p_end}

{phang}	
{bf:#1.3b: Variation of #1.1 in that Dashboard now includes the extended set of indicators}

{p 8 12}. {stata "repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex)  extended(SIGswitch)"}{p_end}

{phang}	
{bf:#1.3c: Variation of #1.1 in that Dashboard now shows aggregate study-level indicators across results}

{p 8 12}. {stata "repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex)  aggregation(1)"}{p_end}

{phang}	
{bf:#1.4: Variation of #1.1 in that the multiverse of robustness analysis paths now includes the original estimate as defined by the parameter {it:orig_in_multiverse()}}

{p 8 12}. {stata "repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex) orig_in_multiverse(orig_include)"}{p_end}

{phang}	
{bf:#1.5: Same output as #1.1, now additionally generating plots on the contribution of individual decisions given that the parameter {it:decisions()} is defined}

{p 8 12}. {stata "repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex) decisions(cov1 cov2 cov3 cov4 ifcond)"}{p_end}

{p 8 12} The above line of code produces plots on individual contributions, where all decision choices of the original authors are included and varied.{p_end}
{p 8 12} #1.5b: The following code generates the same plots when one original choice (here: {it:cov3==0} and {it:ifcond==0}, repsectively) is not included in any robustness test of the multiverse analysis for one of the outcomes (here: {it:outcome==3}).{p_end}

{com}{...}
        preserve
            drop if outcome==3 & (cov3==0 & origpath!=1)        
            // cov3 as a variable with only one alternative decision choice
            repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex) decisions(cov1 cov2 cov3 cov4 ifcond) 
            // same line of repframe code as above
        restore

        preserve
            drop if outcome==3 & (ifcond==0 & origpath!=1)      
            // ifcond as a variable with multiple alternative decision choice
            repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex) decisions(cov1 cov2 cov3 cov4 ifcond) 
            // same line of repframe code as above
        restore
{txt}{...}

{p 8 12}
[{it:note that the command {it:repframe} produces notes in Stata's results window to explain the first complementary plot, the so-called {it:Single-Choice Deviation Plot}.}]{p_end}

{phang}	
{bf:#1.6: Same output as #1, now additionally generating a graph that compares the original specification and the preferred specification of the robustness test given that the parameter {it:prefpath()} is defined}}

{p 8 12}. {stata "repframe outcome, beta(b) pval(p) se(se) siglevel(5) siglevel_orig(10) origpath(origpath) shortref(repframe_ex) prefpath(prefpath)"}{p_end}



{phang}	
{bf:Data preparation for analyses across studies}

{p 8 12}({stata "repframe_gendata, studypooling(1)":{it:click to generate illustrative study-level indicator data}}){p_end}

{phang}	
{bf:#2.1: Reproducibility and Replicability Indicators table and Robustness Dashboard (across studies) with minimum parameter settings}

{p 8 12}. {stata "repframe reflist, studypooling(1)"}

{phang}	
{bf:#2.2: Same table output as #2.1, Dashboard now with the extended set of indicators}

{p 8 12}. {stata "repframe reflist, studypooling(1) extended(SIGswitch)"}


{marker references}{...}
{title:References}

{p 4 8 2}
Angrist, J., & Kolesár, M. (2024). One instrument to rule them all: The bias and coverage of just-ID IV. {it:Journal of Econometrics}, 240(2), 105398.{p_end}
{p 4 8 2}
Dreber, A. & Johanneson, M. (2024). A Framework for Evaluating Reproducibility and Replicability in Economics. {it:Economic Inquiry}.{p_end}


{marker see_also}{...}
{title:Also see}

{p 4 8 2} Online Readme on GitHub, among others with an explanation of the required input data structure: {browse "https://github.com/guntherbensch/repframe"}{p_end}


{title:Authors}

      Gunther Bensch, bensch@rwi-essen.de
      RWI
	  
