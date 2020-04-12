# ICU capacity management during the COVID-19 pandemic using a process simulation (icu-covid-sim)

## AUTHORS: 

Andres Alban*; Stephen E Chick*, PhD; Dave A. Dongelmans**, MD, PhD; Alexander F. van der Sluijs**, MD; W. Joost Wiersinga**** MD, PhD, MBA; Alexander P.J. Vlaar**, MD, PhD, MBA; Danielle Sent***, PhD

* INSEAD Technology and Operations Management
** Amsterdam UMC (location AMC) Intensive Care Medicine
*** Amsterdam UMC (location AMC) Medical Informatics
**** Amsterdam UMC (location AMC) Infectious Disease Medicine

NOTE: Code provided as is for noncommercial, academic usage only.

This repository contains R/Rstudio/Shiny implementation of the decision support tool described in 'ICU capacity management during the COVID-19 pandemic using a process simulation' by the authors above.

The application has been deployed at: https://andres-alban.shinyapps.io/icu-covid-sim/.

The main readme for this repo is ([README.md](README.md).

# Appendix B: Example Usage of icu-covid-sim

This ICU decision support tool for ICU capacity planning for COVID crisis is designed to support ICU capacity decisions for COVID-19 and for non-COVID unplanned patients, using tools from operations research (queue and process simulation).

The model provides statistics assuming that one set of ICU beds is reserved for COVID-19 patients, and another set of beds is reserved for non-COVID-19 patients (also called ‘Other patients’). The model is implemented in the R programming language (R Core Team 2020) using RStudio (RStudio Team 2019) and RShiny (Chang et al 2020) and is provided as is without warranty. The model was made available at https://andres-alban.shinyapps.io/icu-covid-sim/.

## Inputs to describe the model:

### Capacity: 

The number of ICU beds for COVID-19 patients is specified separately from the number of ICU beds for Other patients. The assumption is that patients are routed based on COVID-19 status, so that Other patients do not use beds dedicated for COVID-19 patients and vice versa. 

### Demand: 

Demand for resources are described separately for Other patients and for COVID-19 patients

#### Demand from Other patients. 

The average daily arrival rate is input as a daily arrival rate. Arrivals are assumed to be spaced out with exponentially distributed inter-arrival times, which means that a Poisson random variable number of patients arrive each day. This assumption is consistent with random arrivals in a large population of independent demands for unplanned urgent (Law and Kelton 2007). 

The length of stay (LOS) distribution is specified with user input for the median and interquartile range (IQR) or the mean and standard deviation (sd). The length of stay (LOS) distribution for non-COVID patients is assumed to be log-logistic if median (IQR) is specified, or lognormal if mean (sd) is specified. LOS for individual patients is truncated at 200 days for purposes of the analysis. In the analysis reported in the paper for Amsterdam UMC, site AMC, all ICU demand for planned care was presumed to be 0 due to cancellations of procedures. Only historical urgent ICU demand patterns were modelled with a lognormal distribution with mean 4.36 and sd 8.95 (this corresponds to a log-mean 0.52 and log-sd 1.46). The model allows several patient flows for different specialisms, each with a different arrival rate, and different LOS distribution.

A base case would be to aggregate all unplanned non-COVID patients into one group of patients. (Optional advanced: To describe two or more streams of unplanned non-COVID patients, the arrival rates and length of stay distributions for those streams should be separated by commas.)

Demand from COVID-19 patients. Arrival rates for COVID-19 patients are specified separately, so that the performance of the ICUs can be assessed as a function of the arrival rates and ICU bed capacity.

The LOS distributions for COVID-19 patients are assumed to be log-logistic (if median and IQR are entered) or lognormal (if mean and sd are entered) with parameters which may differ from the non-COVID patients. LOS for individual patients is truncated at 28 days for purposes of the analysis.  For the analysis reported in the paper for Amsterdam UMC, site AMC, we used data from recent literature for COVID-19 positive patients (Zhou et al 2020): LOS with median of 8 days, IQR=8 days, with log-logistic distribution capped at 28 days.

## Outputs from the model:

We compute outputs using theoretical results for queuing analysis (M/G/c/c queues) where possible, and otherwise compute results using Monte Carlo/stochastic simulations to estimate or to provide a sense of variation above and below theoretical mean values (Law and Kelton 2007). The outputs from the simulation model for the analysis reported in the paper are computed from steady-state simulations of 20 periods of 2 months each. The defaults model uses 20 periods of 14 days each that can be adjusted in the additional settings of the model.

Performance metrics computed include:

•	Referral rates, for each of COVID-19 and Non-COVID-19 beds, defined to be the fraction of patients who need to be referred to another hospital due to capacity issues.
•	Throughput rate, for each of COVID-19 and Non-COVID-19 beds, defined as the number of patients per day that can go through the system.
•	Occupancy rates, for each of COVID-19 and Non-Covid-19 beds, defined to be the fraction of beds occupied on average through time. 

Reducing the referral rate can be achieved, on average, by increasing the capacity or by decreasing the lengths of stay, for example. Statistical fluctuation can increase or decrease bed counts through time. The throughput rate increases with the arrival rate provided that enough beds are in place to maintain a low referral rate. Occupancy rates can inform decisions for initial capacity expansion plans, or for planning for potential ability to respond to additional spikes in demand.

Theoretical means are plotted together with bars that represent one standard deviation of values computed over a sequence of 2 months in the reported analysis and the user input in the online application. They are not standard errors for estimates of the means (which are computed exactly from theoretical steady-state queueing analysis). Instead, they represent variations in the patient throughput rates, fraction of occupied beds, and fraction of referrals (due to bed blocking). 

## Other results

We present additional results done during initial assessments prior to ramp-up of the COVID-19 pandemic. 

Figure S1 displays the referral rate for COVID-19 and for other patient assuming a 24 bed ICU capacity were available. The bars for ‘specialized’ assume that COVID-19 ICU patients have a dedicated space of 15 beds and 9 beds are combined in a resource pool for all other ICU patients. Performance characteristics assume an average ICU arrival rate of 1 COVID-19 patient per day and 2 non-COVID-19 per day, to provide insights for conditions as of 26 March 2020. The bars for ‘general’ assume that all patients use a single pool of resources (for load balancing), under the unreasonable assumption that patients can be mixed. The results are nonetheless interesting operationally, as it assesses that ICU demand for both COVID-19 and other care needs, on average, an increase in need for referral from 3.8% to 8.2%, on average, due to the need to isolate COVID-19 patients (left panel). The right panel shows an average capacity utilization level of approximately 75% on average, with slightly higher average utilization for COVID-19 patients, at the stated resource levels. Actual bed occupancy varies with variation in arrival rates and individual LOS, thus causing some needs for referrals to other facilities at times when the ICU is full. 

## References:

Alban A, Chick SE, Lvova O, Sent D, 2020, A simulation model to evaluate the patient flow in an intensive care unit under different levels of specialization, invited submission to Proc. 2020 Winter Simulation Conference, KH Bae, B Feng, S Kim, S Lazarova-Molnar, Z Zheng, T Roeder, R Thiesing, eds. Piscataway, NJ, IEEE. https://ssrn.com/abstract_id=3565826

Chang W, Joe Cheng, JJ Allaire, Yihui Xie and Jonathan McPherson (2020). shiny: Web Application Framework for R. R package version 1.4.0.2. https://CRAN.R-project.org/package=shiny

Law AM, WD Kelton, 2007, Simulation Modeling and Analysis, 4th edition, McGraw Hill. 

R Core Team (2020). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. URL https://www.R-project.org/.

RStudio Team (2019). RStudio: Integrated Development for R. RStudio, Inc., Boston, MA URL http://www.rstudio.com/


