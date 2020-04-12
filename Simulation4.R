#ANDRES#
## This function samples the arrival times for the specified type of patient in units of days for N days. 
# It returns a list with the first element containing the arrival times in units of days and the second element the day of the week where 1 is Monday and Sunday is 
# It assmes that day 1 is a Monday and day 7 is Sunday.
# To change the distributions I only need to change this function

# Unlike Simulation2.R, the flexible ICU transfers patients to their correct ICU when a bed becomes available
library(actuar)

sample_arrival = function(type,parameters,N){
  # type is one of Poisson or daily
  if (type == "Poisson"){
    sample_Poisson(parameters,N)
  }else if (type == "daily"){
    sample_nday_hour10(parameters,N)
  } else {
    stop('Specify a proper arrival model: "Poisson" or "Daily"')
  }
  
}

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

## This function samples n LOS for the specified type of patient in units of days.
# To change the sampling distributions I only need to change this function
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
      # if (i %in% ceiling(nrow(sim)*c(1/4,1/2,3/4))){print(paste0(floor(i/nrow(sim)*100),"%"))} # print progress
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

#ANDRES#+replanned patients
## This function takes the output of sample_patients and determines the admitted, rejected and replanned patients 
#in a specialized ICU.
# It also takes c as an input, a vector of the capacities of the four specialized ICUs
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
  # ifelse(sim_adm$spec == 1,sapply(sim_adm$adm_time[sim_adm$spec == 1], function(x) sum(sim_adm$adm_time[sim_adm$spec == 1] <= x & sim_adm$dis_time[sim_adm$spec == 1] > x)),
  #                                ifelse(sim_adm$spec == 2,sapply(sim_adm$adm_time[sim_adm$spec == 2], function(x) sum(sim_adm$adm_time[sim_adm$spec == 2] <= x & sim_adm$dis_time[sim_adm$spec == 2] > x)),
  #                                       ifelse(sim_adm$spec == 3,sapply(sim_adm$adm_time[sim_adm$spec == 3], function(x) sum(sim_adm$adm_time[sim_adm$spec == 3] <= x & sim_adm$dis_time[sim_adm$spec == 3] > x)),
  #                                              sapply(sim_adm$adm_time[sim_adm$spec == 4], function(x) sum(sim_adm$adm_time[sim_adm$spec == 4] <= x & sim_adm$dis_time[sim_adm$spec == 4] > x)))))
  # 
  list(sim_adm,sim_rej,sim_rep)
}

## This function takes the output of sample_patients and determines the admitted and rejected patients in a flexible ICU.
# It also takes c as an input, a vector of the capacities of the four specialized ICUs
# It also takes shares as an input, a vector of the specialized ICU that takes patients from another one.
# For instance, shares = c(2,3,4,1), means that ICU1 can send patients to ICU2 if ICU1 is full. ICU2 can send patients to ICU3, ICU3 to ICU4 and ICU4 to ICU1.
# It adds the number of occupied beds after admission of each patient to the data sets and the number of the ICU.
# It returns a data set for admitted patients and one for rejected patients

#!!!!!!!!!!!!!!! This function is outdated
process_queue_flexible = function(sim,c,shares,blocking_time = 0.5,replan_time = 1){
  # blocking_time = rep(blocking_time,length.out = length(c))
  # replan_time = rep(replan_time,length.out = length(c))
  sim$adm_time_eff = ifelse(sim$plan_adm == "Planned",sim$adm_time - blocking_time,sim$adm_time)
  sim$ICU_spec = NA
  
  sim$occ_beds_eff_spec1 = 0 # These are the number of beds occupied in each specialism
  sim$occ_beds_eff_spec2 = 0
  sim$occ_beds_eff_spec3 = 0
  sim$occ_beds_eff_spec4 = 0
  sim_rej = data.frame()
  sim_rep = data.frame()
  sim_transfer = data.frame()
  sim$transfer_time = NA
  
  sim = sim[order(sim$adm_time_eff),]
  
  columns = paste0("occ_beds_eff_spec",1:4)
  # First arrival is always admitted
  sim$ICU_spec[1] = sim$spec[1]
  sim[1,columns[sim$spec[1]]] = 1
  sim_current = sim[1,] # Current patients in the ICU
  i = 2
  
  while (i <= nrow(sim)){
    discharged = sim_current[sim_current$dis_time <= sim$adm_time_eff[i],] # discharges since last admitted patient
    discharged = discharged[order(discharged$dis_time),]
    
    if (nrow(discharged) > 0){
      dis1 = sum(discharged$ICU_spec == 1)
      dis2 = sum(discharged$ICU_spec == 2)
      dis3 = sum(discharged$ICU_spec == 3)
      dis4 = sum(discharged$ICU_spec == 4)
    } else{
      dis1 = 0
      dis2 = 0
      dis3 = 0
      dis4 = 0
    }
    
    # Remove the discharged patients
    sim$occ_beds_eff_spec1[i] = sim$occ_beds_eff_spec1[i-1] - dis1
    sim$occ_beds_eff_spec2[i] = sim$occ_beds_eff_spec2[i-1] - dis2
    sim$occ_beds_eff_spec3[i] = sim$occ_beds_eff_spec3[i-1] - dis3
    sim$occ_beds_eff_spec4[i] = sim$occ_beds_eff_spec4[i-1] - dis4
    
    ###########
    ## Check whether patients not in their specialized ICU can be transfered to the correct ICU
    sim_transfer = sim_current[sim_current$ICU_spec != sim_current$spec & sim_current$dis_time > sim$adm_time_eff[i],] 
    # Patients who are waiting to be transferred 
    transferred_ids = c()
    repeat{ # if a place gets free from a transferred patient we might transfer another one
      count = 0
      if (nrow(sim_transfer)>0) {# check if we can transfer from ref to a correct one (one time now)
        for (a in 1:nrow(sim_transfer)){
          if (sim[i, columns[sim_transfer$spec[a]]] < c[sim_transfer$spec[a]]) {
            count = count+1
            sim[i, columns[shares[sim_transfer$spec[a]]]] = sim[i, columns[shares[sim_transfer$spec[a]]]] - 1 #transfer from ref
            sim[i, columns[sim_transfer$spec[a]]] = sim[i,columns[sim_transfer$spec[a]]] + 1 #add to correct
            opened_bed = discharged[discharged$ICU_spec == sim_transfer$spec[a],][1,]
            discharged = discharged[discharged$id != opened_bed$id,]
            sim$transfer_time[sim$id == sim_transfer$id[a]] = opened_bed$dis_time
            transferred_ids = c(transferred_ids,sim_transfer$id[a])
            sim_transfer = sim_transfer[-c(a),]
            # The line below can only be excuted if the patient is admitted, otherwise the logic of the function does not work anymore
            # sim_current$ICU_spec[sim_current$id == sim_transfer$id[a]] = sim_transfer$spec[a] #adjust his current ICU in current
            break
          }
        }
      }
      if (count == 0) break # condition to break out of repeat
    }
    ###########
    
    if (sim[i, columns[sim$spec[i]]] < c[sim$spec[i]]){ # Admitted patients
      sim[i, columns[sim$spec[i]]] = sim[i,columns[sim$spec[i]]] + 1
      sim$ICU_spec[i] = sim$spec[i]
      sim_current = rbind(sim_current, sim[i,])
      sim_current = sim_current[sim_current$dis_time > sim$adm_time_eff[i],] # Discharge patients
      sim_current$ICU_spec[sim_current$id %in% transferred_ids] = sim_current$spec[sim_current$id %in% transferred_ids] #adjust current ICU of transferred patients
      i = i+1
    } else if (sim[i, columns[shares[sim$spec[i]]]] < c[shares[sim$spec[i]]]){ # Redirect patient to partner ICU
      sim[i, columns[shares[sim$spec[i]]]] = sim[i, columns[shares[sim$spec[i]]]] + 1
      sim$ICU_spec[i] = shares[sim$spec[i]]
      sim_current = rbind(sim_current, sim[i,])
      sim_current = sim_current[sim_current$dis_time > sim$adm_time_eff[i],] # Discharge patients
      sim_current$ICU_spec[sim_current$id %in% transferred_ids] = sim_current$spec[sim_current$id %in% transferred_ids] #adjust current ICU of transferred patients
      # sim_transfer = rbind(sim_transfer, sim[i,]) #add to a df of patients who are in a referred department
      i = i+1
    } else if (sim$plan_adm[i] == "Unplanned") { # Reject patient
      sim_rej = rbind(sim_rej,sim[i,])
      sim = sim[-c(i),]
    } else if (sim$plan_adm[i] == "Planned"){ # Reschedule patient for the next day. Should we consider replanning for the next weekday? Right now patients can be replanned for a Sunday
      sim_rep = rbind(sim_rep,sim[i,])
      sim$adm_time[i] = sim$adm_time[i] + 1
      sim$adm_time_eff[i] = sim$adm_time_eff[i] + 1
      sim$dis_time[i] = sim$dis_time[i] + 1
      sim = sim[order(sim$adm_time_eff),]
    } else {
      stop("Unknown situation")
    }
  }
  
  sim_adm = sim[order(sim$adm_time),]
  sim_adm$transfer_time[is.na(sim_adm$transfer_time) & sim_adm$spec == sim_adm$ICU_spec] = sim_adm$adm_time[is.na(sim_adm$transfer_time) & sim_adm$spec == sim_adm$ICU_spec]
  sim_adm$transfer_time[is.na(sim_adm$transfer_time) & sim_adm$spec != sim_adm$ICU_spec] = sim_adm$dis_time[is.na(sim_adm$transfer_time) & sim_adm$spec != sim_adm$ICU_spec]
  if (nrow(sim_rej) > 0){sim_rej = sim_rej[order(sim_rej$adm_time),]}else{sim_rej = 0}
  sim_adm$occ_beds = sapply(sim_adm$adm_time, function(x) sum(sim_adm$adm_time <= x & sim_adm$dis_time > x))
  sim_adm$occ_beds_ICU_spec = ifelse(sim_adm$ICU_spec == 1,sapply(sim_adm$adm_time[sim_adm$ICU_spec == 1], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 1] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 1] > x)),
                                     ifelse(sim_adm$ICU_spec == 2,sapply(sim_adm$adm_time[sim_adm$ICU_spec == 2], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 2] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 2] > x)),
                                            ifelse(sim_adm$ICU_spec == 3,sapply(sim_adm$adm_time[sim_adm$ICU_spec == 3], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 3] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 3] > x)),
                                                   sapply(sim_adm$adm_time[sim_adm$ICU_spec == 4], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 4] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 4] > x)))))
  
  sim_rej$occ_beds = sapply(sim_rej$adm_time, function(x) sum(sim_adm$adm_time <= x & sim_adm$dis_time > x))
  sim_rej$occ_beds_spec = ifelse(sim_rej$spec == 1,sapply(sim_rej$adm_time[sim_rej$spec == 1], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 1] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 1] > x)),
                                 ifelse(sim_rej$spec == 2,sapply(sim_rej$adm_time[sim_rej$spec == 2], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 2] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 2] > x)),
                                        ifelse(sim_rej$spec == 3,sapply(sim_rej$adm_time[sim_rej$spec == 3], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 3] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 3] > x)),
                                               sapply(sim_rej$adm_time[sim_rej$spec == 4], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 4] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 4] > x)))))
  
  sim_rep$occ_beds = sapply(sim_rep$adm_time, function(x) sum(sim_adm$adm_time <= x & sim_adm$dis_time > x))
  sim_rep$occ_beds_spec = ifelse(sim_rep$spec == 1,sapply(sim_rep$adm_time[sim_rep$spec == 1], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 1] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 1] > x)),
                                 ifelse(sim_rep$spec == 2,sapply(sim_rep$adm_time[sim_rep$spec == 2], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 2] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 2] > x)),
                                        ifelse(sim_rep$spec == 3,sapply(sim_rep$adm_time[sim_rep$spec == 3], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 3] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 3] > x)),
                                               sapply(sim_rep$adm_time[sim_rep$spec == 4], function(x) sum(sim_adm$adm_time[sim_adm$ICU_spec == 4] <= x & sim_adm$dis_time[sim_adm$ICU_spec == 4] > x)))))
  
  list(sim_adm,sim_rej,sim_rep)
}



