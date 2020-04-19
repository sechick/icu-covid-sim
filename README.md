# Online Supplement for: ICU capacity management during the COVID-19 pandemic using a process simulation (icu-covid-sim)

icu-covid-sim is an ICU decision support tool for ICU capacity planning for COVID crisis is designed to support ICU capacity decisions for COVID-19 and for non-COVID unplanned patients, using tools from operations research (queue and process simulation). Decision support tool for ICU capacity planning for COVID crisis. Queue and simulation tool. This is online supplemental material for a refereed Letter accepted (on 18 april 2020) for publication in Intensive Care Medicine (https://www.springer.com/journal/134/). 

## AUTHORS: 

Andres Alban*; Stephen E Chick*, PhD; Dave A. Dongelmans**, MD, PhD; Alexander F. van der Sluijs**, MD; W. Joost Wiersinga**** MD, PhD, MBA; Alexander P.J. Vlaar**, MD, PhD, MBA; Danielle Sent***, PhD

 *INSEAD Technology and Operations Management
** Amsterdam UMC (location AMC) Intensive Care Medicine
*** Amsterdam UMC (location AMC) Medical Informatics
**** Amsterdam UMC (location AMC) Infectious Disease Medicine

NOTE: Code provided as is for noncommercial, academic usage only.

This repository contains R/Rstudio/Shiny implementation of the decision support tool described in 'ICU capacity management during the COVID-19 pandemic using a process simulation' by the authors above.

The application has been deployed at: https://andres-alban.shinyapps.io/icu-covid-sim/. Source code at https://github.com/sechick/icu-covid-sim/.

## QUICK START INSTRUCTIONS

Summary: Decision support too for ICU capacity expansion planning during COVID outbreak. Calculates maximum throughput of COVID-19 patients through COVID-19 ICU beds, and similar for non-COVID-19 patients through non-COVID-19 beds. Also informs number of patients which must be referred elsewhere and bed utilization, for a range of ICU bed capacities under consideration.

This is Online Supplemental Material for 'ICU capacity management during the COVID-19 pandemic using a process simulation', accepted (on 18 april 2020) to appear for publication in Intensive Care Medicine.

See: 
* Motivation, conceptual model, and application to Amsterdam UMC (location AMC) ICU ([README-AppA.md](README-AppA.md)).
* User Manual at ([README-AppB.md](README-AppB.md)).

* Tool which can be adapted with data for other hospital's ICUs at https://andres-alban.shinyapps.io/icu-covid-sim/. At that web site, first, fill in parameter values for COVID and nonCOVID patients to describe arrival patterns and length of stay (LOS) distributions. Second, click 'Simulate' button. Third, observe the simulation results (may take a minute).

### Parameters for COVID-19 and non-COVID-19 patients:

 - Arrival rate to the ICU
 - Length of stay (LOS) distribution specified with median and interquartile range (IQR) or mean and standard deviation (sd)
 - Number of ICU beds allocated to COVID-19 and non-COVID-19 patients
 
### Outputs include:

- COVID patients per day which can be handled in ICU, given COVID demand, LOS requirements, and potential for bed blocking. One can thereby deduce the rate of patients which must be referred elsewhere by subtracting the demand from the patients which can be handled.

<p align="center">
  <img src="Docs/throughput_example.png" width="450" alt="throughput_example text">
</p>

- Similar statistics for unplanned non-COVID-19 ICU patients, for the block of beds allocated for them: Fraction of referrals and occupancy rate.

<p align="center">
  <img src="Docs/referrals_example.png" width="350" alt="referrals_example text">
  <img src="Docs/occupancy_example.png" width="350" alt="occupancy_example text">
</p>

## For more details: 

Model was adapted from an earlier study of operations management / process flow simulations at: https://ssrn.com/abstract_id=3565826 (invited for 2020 Winter Simulation Conference). See also https://ssrn.com/abstract_id=3570406.

Software provided "as is". Support not provided, feedback to icucovidcap@gmail.com (please also let us know if it helped, or if your LOS distribution is different for COVID-19 patients). 

