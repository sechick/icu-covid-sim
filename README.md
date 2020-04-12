# ICU capacity management during the COVID-19 pandemic using a process simulation (icu-covid-sim)

## AUTHORS: 

Andres Alban*; Stephen E Chick*, PhD; Dave A. Dongelmans**, MD, PhD; Alexander F. van der Sluijs**, MD; W. Joost Wiersinga**** MD, PhD, MBA; Alexander P.J. Vlaar**, MD, PhD, MBA; Danielle Sent***, PhD

 *INSEAD Technology and Operations Management
** Amsterdam UMC (location AMC) Intensive Care Medicine
*** Amsterdam UMC (location AMC) Medical Informatics
**** Amsterdam UMC (location AMC) Infectious Disease Medicine

NOTE: Code provided as is for noncommercial, academic usage only.

This repository contains R/Rstudio/Shiny implementation of the decision support tool described in 'ICU capacity management during the COVID-19 pandemic using a process simulation' by the authors above.

The application has been deployed at: https://andres-alban.shinyapps.io/icu-covid-sim/.

Main readme for this repo is ([README.md](README.md).

## icu-covid-sim

This ICU decision support tool for ICU capacity planning for COVID crisis is designed to support ICU capacity decisions for COVID-19 and for non-COVID unplanned patients, using tools from operations research (queue and process simulation).

## QUICK START INSTRUCTIONS

Summary in words: At https://andres-alban.shinyapps.io/icu-covid-sim/, follow three steps. First, fill in parameter values for COVID and nonCOVID patients to describe arrival patterns and length of stay (LOS) distributions. Second, click 'Simulate' button. Third, observe the simulation results (may take a minute).

### Parameters for COVID-19 and non-COVID-19 patients:

 - Arrival rate to the ICU
 - Length of stay (LOS) distribution specified with median and interquartile range (IQR) or mean and standard deviation (sd)
 - Number of ICU beds allocated to COVID-19 and non-COVID-19 patients
 
### Outputs include:

- COVID patients per day which can be handled in ICU, given COVID demand, LOS requirements, and potential for bed blocking. Can thereby decude the number of patients which must be referred elsewhere.
- Simular statistics for unplanned non-COVID-19 ICU patients, for the block of beds allocated for them.

### For more details: 

Short letter in submission for publication, built on conceptual model at https://ssrn.com/abstract_id=3565826 (invited for 2020 Winter Simulation Conference).

More on the conceptual model is at ([README-AppA.md](README-AppA.md)) or https://ssrn.com/abstract_id=3570406.

More examples of USAGE of the tool is at ([README-AppB.md](README-AppB.md))

Software provided "as is". Support not provided, feedback to icucovidcap@gmail.com (please also let us know if it helped).

