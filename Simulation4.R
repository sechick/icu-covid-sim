
library(actuar) # Necessary to sample loglogistic distribution

## This function samples the arrival times for the specified type in units of days for N days.
# It calls the appropriate function for sampling specified by the type. 
# It returns a list with the first element containing the arrival times in units of days and the second element the day of the week
# It assmes that day 1 is a Monday and day 7 is Sunday.
# To change the distributions I only need to change this function
sample_arrival = function(type,parameters,N){
  # type is one of Poisson or daily
  if (type == "Poisson"){
    sample_Poisson(parameters,N)
  }else if (type == "daily"){
    sample_nday_hour10(parameters,N)
  } else {
    stop('Specify a proper arrival model: "Poisson" or "daily"')
  }
}

## This function samples Poisson arivals with differnt rates for weekdays and weekends 
sample_Poisson = function(parameters,N){
  Nweekday = floor(N/7)*5 + min(N%%7,5) # Number of weekdays in N days (assuming day 1 is a Monday)
  Nweekend = floor(N/7)*2 + max(N%%7 - 5,0) # Number of weekend days in N days (assuming day 1 is a Monday)
  
  rate_wd = 1/parameters[1]
  rate_we = 1/parameters[2]
  adm_time_wd = c()
  adm_time_we = c()
  new_arr = 0
  while(new_arr < Nweekday){
    adm_time_wd = c(adm_time_wd,new_arr)
    new_arr = adm_time_wd[length(adm_time_wd)] + rexp(1,rate = rate_wd)
  }
  adm_time_wd = adm_time_wd[-1]
  new_arr = 0
  while(new_arr < Nweekend){
    adm_time_we = c(adm_time_we,new_arr)
    new_arr = adm_time_we[length(adm_time_we)] + rexp(1,rate = rate_we)
  }
  adm_time_we = adm_time_we[-1]
  
  # Combine weekend and weekends
  adm_time_wd = (adm_time_wd %/% 5)*7 + adm_time_wd %% 5
  adm_time_we = 5 + (adm_time_we %/% 2)*7 + adm_time_we %% 2
  adm_time = sort(c(adm_time_wd,adm_time_we))
  
  adm_weekday = ceiling(adm_time) %% 7
  adm_weekday[adm_weekday==0] = 7
  list(adm_time,adm_weekday)
}

# This function samples arrivals with a categorical distribution in the number of patients pr day
# and a beta distribution on the time of the day for arrival.
sample_nday_hour10 = function(parameters,N){
  Nweekday = floor(N/7)*5 + min(N%%7,5) # Number of weekdays in N days (assuming day 1 is a Monday)
  Nweekend = floor(N/7)*2 + max(N%%7 - 5,0) # Number of weekend days in N days (assuming day 1 is a Monday)
  
  weekdays = sample(x = parameters[[1]]$Var1,size = Nweekday, replace = TRUE, prob = parameters[[1]]$Prob)
  weekends = sample(x = parameters[[2]]$Var1,size = Nweekend, replace = TRUE, prob = parameters[[2]]$Prob)
  weekdays = rep(0:(length(weekdays)-1),weekdays)
  weekends = rep(0:(length(weekends)-1),weekends)
  weekdays = (weekdays %/% 5)*7 + weekdays %% 5
  weekends = 5 + (weekends %/% 2)*7 + weekends %% 2
  weekdays = weekdays  + (rbeta(length(weekdays),parameters[[3]][1],parameters[[3]][2]) + 10/24) %% 1
  weekends = weekends  + (rbeta(length(weekends),parameters[[3]][1],parameters[[3]][2]) + 10/24) %% 1
  adm_time = sort(c(weekdays,weekends))
  adm_weekday = ceiling(adm_time) %% 7
  adm_weekday[adm_weekday==0] = 7
  list(adm_time,adm_weekday)
}

## This function samples n LOS for the specified type in units of days.

sample_LOS = function(type,parameters,n){
  # type is one of lognorm, loglogis or bootstrap
  if (type == "lognorm"){
    if (length(parameters) == 2){
      parameters[3] = 200 # default maximum LOS to 200 days
    }
    pmin(rlnorm(n,parameters[1],parameters[2]),parameters[3])
  } else if(type == "loglogis"){
    if (length(parameters) == 2){
      parameters[3] = 200 # default maximum LOS to 200 days
    }
    pmin(rllogis(n,parameters[1],parameters[2]),parameters[3])
  } else if (type == "bootstrap"){
    sample(size = n, x = parameters, replace = TRUE)
  } else{
    stop('Specify a proper arrival model: "lognorm", "loglogis", or "bootstrap"')
  }
}

## This function generates patient observations for N days
# It calss the functions for generaing arrivals and LOS and merges the stream of patients in a data frame
sample_patients = function(N,Arr_parameters,LOS_parameters,ref_spec = NULL,spec = NULL,plan_adm = NULL){
  if (length(Arr_parameters) != length(LOS_parameters)){
    stop("Provide the same length of arrival and LOS data")
  }
  types = names(Arr_parameters)
  if (is.null(types)){types = names(LOS_parameters)}
  if (is.null(types)){types = 1:length(Arr_parameters)}
  
  if (is.null(ref_spec)){ref_spec = types}
  if (is.null(plan_adm)){plan_adm = rep("Unplanned",length(Arr_parameters))}
  plan_adm[!(plan_adm %in% c("Planned","Unplanned"))] = "Unplanned" # All plan_adm not recognized are defaulted to Unplanned
  if (is.null(spec)){
    spec = 1:length(Arr_parameters)
  }else {
    spec = as.numeric(as.factor(spec)) # Force spec to be integers
  }
  
  
  df = data.frame()
  for (i in 1:length(Arr_parameters)){
    arr = sample_arrival(Arr_parameters[[i]][[1]],Arr_parameters[[i]][[2]],N)
    dis = arr[[1]] + sample_LOS(LOS_parameters[[i]][[1]],LOS_parameters[[i]][[2]],length(arr[[1]]))
    temp = data.frame(type = types[i], adm_time = arr[[1]], dis_time = dis, adm_weekday = arr[[2]],ref_spec=ref_spec[i],plan_adm = plan_adm[[i]],spec = spec[i])
    df = rbind(df,temp)
  }
  df = df[order(df$adm_time),]
  df = cbind(id = seq(1,nrow(df)),df)
  
  
  df
}

# This function takes the output of sample_patients and determines the admitted, rejected and replanned patients in a pooled ICU.
# Replanned can be duplicated multiple times, so it counts the events of replanning, not the patients.  
# It adds the number of occupied beds after admission of each patient to the data sets.
# It returns a data set for admitted patients, one for rejected patients and one for replanned patients

process_queue_pooled = function(sim,c,blocking_time = 0.5,replan_time = 1){
  sim$adm_time_eff = ifelse(sim$plan_adm == "Planned",sim$adm_time - blocking_time,sim$adm_time)
  
  sim$occ_beds_eff = NA
  sim_rej = data.frame()
  sim_rep = data.frame()
  sim = sim[order(sim$adm_time_eff),]
  i <- 1
  
  while (i <= nrow(sim)) {
    sim$occ_beds_eff[i] = sum(sim$adm_time_eff <= sim$adm_time_eff[i] & sim$dis_time > sim$adm_time_eff[i])
    if (sim$occ_beds_eff[i] <= c){  # Admitted patients
      i = i+1
    }else if (sim$occ_beds_eff[i] > c & sim$plan_adm[i] == "Unplanned"){ # Rejected patients
      sim_rej = rbind(sim_rej,sim[i,])
      sim$dis_time[i] = 0
      i = i+1
    }else if (sim$occ_beds_eff[i] > c & sim$plan_adm[i] == "Planned"){ # Replanned patients
      sim_rep = rbind(sim_rep,sim[i,])
      sim$dis_time[i] = sim$dis_time[i]+replan_time
      sim$adm_time[i] = sim$adm_time[i]+replan_time
      sim$adm_time_eff[i] = sim$adm_time_eff[i]+replan_time
      sim = sim[order(sim$adm_time_eff),]
    }
  }
  sim = sim[order(sim$adm_time),] 
  sim = sim[sim$dis_time>0,]
  sim$occ_beds = sapply(sim$adm_time, function(x) sum(sim$adm_time <= x & sim$dis_time > x))
  list(sim,sim_rej,sim_rep)
}

## This function takes the output of sample_patients and determines the admitted, rejected and replanned patients 
# in a specialized ICU.
# It takes c as an input, a vector of the capacities of each of the specialized ICUs
# It adds the number of occupied beds after admission of each patient to the data sets and the number of the ICU.
# It returns a data set for admitted patients, rejected patients, replanned patients 
# Replanned can be duplicated multiple times, so it counts the events of replanning, not the patients.  
process_queue_specialized = function(sim,c,blocking_time = 0.5,replan_time = 1){
  if (length(c) != length(unique(sim$spec))){
    stop("Specify the capacity c for each of the specialized units")
  }
  blocking_time = rep(blocking_time,length.out = length(c))
  replan_time = rep(replan_time,length.out = length(c))
  sim_list = list()
  for (i in 1:length(c)){
    sim_list[[i]] = process_queue_pooled(sim[sim$spec == i,],c[i],blocking_time[i],replan_time[i])
  }
  sim_adm = do.call("rbind",lapply(sim_list, function(x) x[[1]]))    #rbind(sim1[[1]],sim2[[1]],sim3[[1]],sim4[[1]])
  sim_rej = do.call("rbind",lapply(sim_list, function(x) x[[2]]))    #rbind(sim1[[2]],sim2[[2]],sim3[[2]],sim4[[2]])
  sim_rep = do.call("rbind",lapply(sim_list, function(x) x[[3]]))    #rbind(sim1[[3]],sim2[[3]],sim3[[3]],sim4[[3]])
  sim_adm = sim_adm[order(sim_adm$adm_time),]
  if (nrow(sim_rej)>0) sim_rej = sim_rej[order(sim_rej$adm_time),]
  if (nrow(sim_rep)>0) sim_rep =  sim_rep[order(sim_rep$adm_time),]
  names(sim_adm)[names(sim_adm) == "occ_beds_eff"] = "occ_beds_eff_spec"
  if (nrow(sim_rej)>0) names(sim_rej)[names(sim_rej) == "occ_beds_eff"] = "occ_beds_eff_spec"
  if (nrow(sim_rep)>0) names(sim_rep)[names(sim_rep) == "occ_beds_eff"] = "occ_beds_eff_spec"
  sim_adm$occ_beds = sapply(sim_adm$adm_time, function(x) sum(sim_adm$adm_time <= x & sim_adm$dis_time > x))
  sim_adm$occ_beds_spec = NA
  for (i in 1:length(c)){
    sim_adm[sim_adm$spec == i,"occ_beds_spec"] = sapply(sim_adm$adm_time[sim_adm$spec == i], function(x) sum(sim_adm$adm_time[sim_adm$spec == i] <= x & sim_adm$dis_time[sim_adm$spec == i] > x))
  } 
  list(sim_adm,sim_rej,sim_rep)
}
