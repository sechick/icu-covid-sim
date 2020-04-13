## Optimizing specialized ICU bed partition
# This function does not prescribe the optimal bed partition. It outputs data to help optimize the bed partition.
# The output is a set of data frames with the performance measures for the range of bed capacities specified in c_specs.
# Such output can be used to optimize the bed partition but this function does not optimize, it just generates the data
# that a decision maker can use to make decisions for optimizing the partieion of the ICU
OptimizePartition = function(Arr_parameters=NULL,LOS_parameters=NULL,c_specs=rbind(c(6,11,5,6),c(7,12,6,7)),N=20,K=182.5,ref_spec = NULL,spec=NULL,plan_adm=NULL,blocking_time_spec=0.5,replan_time_spec = 1){

#### Setup parameters and functions ####
source("Simulation4.R") # create the necessary functions for the simulation

# Create Arrival of patients following the distributions prescribed in Arr_parameters and LOS_parameters
# The third parameter is the number of days
warm_up = 120 # number of days used to warm up the queue
horizon = N*K # length of simulation
n = horizon + warm_up # Number of days simulated including warm up period
sim = sample_patients(n,Arr_parameters,LOS_parameters,ref_spec = ref_spec,spec = spec,plan_adm = plan_adm)
spec_nr = length(unique(sim$spec))

# function to compute the occupancy rate
mean_occupancy = function(sim_event,start_occupancy,t0,dt){ # sim_event - dataframe after processed pooled/spec/flex simulations
  #t0 = start time; dt - full time period
  sim_event_local = sim_event[sim_event$time >= t0 & sim_event$time < (t0+dt),] 
  #filters the records at the moment of time from t0 till time dt.
  occupancy = start_occupancy # start_occupancy - how many beds are occupied at time t0.
  y = occupancy * (sim_event_local$time[1] - t0) # y = occupancy*time (time after t0 and before the 1st time in sim_ev_local)
  occupancy = occupancy + ifelse(sim_event_local$event[1] == "adm", 1, ifelse(sim_event_local$event[1] == "dis",-1,0))
  # occupancy + 1 (if admition) -1 (if discharge), 0 (if else)
  for(i in 2:nrow(sim_event_local)){
    y = y + occupancy * (sim_event_local$time[i] - sim_event_local$time[i-1]) # y=sum of each row occupancy*its time period
    occupancy = occupancy + ifelse(sim_event_local$event[i] == "adm", 1, ifelse(sim_event_local$event[i] == "dis",-1,0))
    #occupancy of next row
  }
  y = y + occupancy * (t0 + dt - sim_event_local$time[nrow(sim_event_local)])# y=sum of each row occupancy*its time period
  y = y/dt # mean occupancy (sum divided by the total time period)
  y
}

# perf_list is a list of dataframes. Each dataframe has columns: cap - capacity (number of beds)
# rej_rate, occ_rate, rep_rate, frac_rep, planned - number of planned patients, unplanned - number of unplanned patients. 
# perf_list is the analogous list that includes the standard deviation over the sampled periods for all the performance measures in perf_list

perf_list = rep(list(data.frame(cap = numeric(),rej_rate = numeric(), occ_rate = numeric(),rep_rate = numeric(),planned = numeric(),unplanned = numeric())),spec_nr)
names(perf_list) = paste0("spec",1:spec_nr)
perf_SD_list = perf_list # is it the standard deviation for each cell of perf_list?

#### Start of the loop ####

for (i in 1:nrow(c_specs)){#2:25
  c_spec = c_specs[i,]
  ##### Process data for the given capacity ####
  ## Specialized ICU
  temp = process_queue_specialized(sim,c_spec,0.5,1) #simulation for specialized design
  sim_adm_special = temp[[1]] # admitted patients
  sim_rej_special = temp[[2]] # rejected patients
  sim_rep_special = temp[[3]] # replanned events
  # Remove first 4 months (warm_up days) of observations to warm-up the queue
  sim_adm_special$adm_time = sim_adm_special$adm_time - warm_up
  sim_adm_special$dis_time = sim_adm_special$dis_time - warm_up
  sim_adm_special$adm_time_eff = sim_adm_special$adm_time_eff - warm_up
  sim_adm_special = sim_adm_special[sim_adm_special$dis_time >= 0,]
  sim_rej_special$adm_time = sim_rej_special$adm_time - warm_up
  sim_rej_special$dis_time = sim_rej_special$dis_time - warm_up
  sim_rej_special$adm_time_eff = sim_rej_special$adm_time_eff - warm_up
  sim_rej_special = sim_rej_special[sim_rej_special$adm_time >= 0,]
  sim_rep_special$adm_time = sim_rep_special$adm_time - warm_up
  sim_rep_special$dis_time = sim_rep_special$dis_time - warm_up
  sim_rep_special$adm_time_eff = sim_rep_special$adm_time_eff - warm_up
  sim_rep_special = sim_rep_special[sim_rep_special$adm_time_eff >= 0,]
  temp = sim_adm_special[sim_adm_special$plan_adm == "Planned",] 
  # below res(reserved) we use adm_time_eff for planned patients (using temp, not sim_adm_special) to account time when bed is already booked but not occupied by patient.  
  sim_event_special = rbind(data.frame(event = rep("adm",nrow(sim_adm_special)), time = sim_adm_special$adm_time, spec = sim_adm_special$spec, id = sim_adm_special$id, plan_adm = sim_adm_special$plan_adm),
                            data.frame(event = rep("res",nrow(temp)), time = temp$adm_time_eff, spec = temp$spec, id = temp$id, plan_adm = temp$plan_adm),
                            data.frame(event = rep("dis",nrow(sim_adm_special)), time = sim_adm_special$dis_time, spec = sim_adm_special$spec, id = sim_adm_special$id, plan_adm = sim_adm_special$plan_adm),
                            data.frame(event = rep("rej",nrow(sim_rej_special)), time = sim_rej_special$adm_time, spec = sim_rej_special$spec, id = sim_rej_special$id, plan_adm = sim_rej_special$plan_adm),
                            data.frame(event = rep("rep",nrow(sim_rep_special)), time = sim_rep_special$adm_time_eff, spec = sim_rep_special$spec, id = sim_rep_special$id, plan_adm = sim_rep_special$plan_adm)
  )
  sim_event_special = sim_event_special[sim_event_special$time >= 0 & sim_event_special$time <= horizon,]
  sim_event_special = sim_event_special[order(sim_event_special$time),]
  
  # Sectioning for estimating standard deviations
  times = (0:N)*K
  
  ##### Save performance statistics ####
  
  for (specialism in 1:spec_nr){
    sim_adm_special_spec = sim_adm_special[sim_adm_special$spec == specialism,]
    sim_rej_special_spec = sim_rej_special[sim_rej_special$spec == specialism,]
    sim_event_special_spec = sim_event_special[sim_event_special$spec == specialism,]
    sim_rep_special_spec = sim_rep_special[sim_rep_special$spec == specialism,]
    
    # 1) Rejection rate
    out = sapply(times,function(x) sum(sim_rej_special_spec$adm_time <= x))
    rej_n = diff(out)/K
    out = sapply(times,function(x) sum(sim_adm_special_spec$adm_time <= x & sim_adm_special_spec$plan_adm == "Unplanned"))
    adm_n = diff(out)/K
    arr_n = adm_n + rej_n # number of arrived = admitted+rejected (it only includes unplanned patients)
    rej_rate_mean = sum(rej_n) / sum(arr_n) #rejection rate here is number of rejected / total number arrived
    rej_rate_SD = sd(rej_n/arr_n)
    
    
    # 2) occupancy rate
    occ_n = sapply(times[1:(length(times)-1)],function(t) {start_occupancy = sum(sim_adm_special_spec$adm_time <= t & sim_adm_special_spec$dis_time > t)
                                              mean_occupancy(sim_event_special_spec,start_occupancy,t,K)})
    occ_rate_mean = mean(occ_n/c_spec[specialism])
    occ_rate_SD = sd(occ_n/c_spec[specialism])
    
    # 3) Replanned patients
    out = sapply(times,function(x) sum(sim_rep_special_spec$adm_time_eff <= x))
    rep_n = diff(out)/K
    planned_n = sapply(times, function(x) sum((sim_adm_special_spec$plan_adm == "Planned") * (sim_adm_special_spec$adm_time_eff <= x)))
    planned_n = diff(planned_n)/K
    rep_planned_mean = sum(rep_n)/sum(planned_n) # replannings per planned patient
    rep_planned_SD = sd(rep_n/planned_n)
    
    
    # bind results to perf_list
    perf_list[[specialism]] = rbind(perf_list[[specialism]],
                                    data.frame(cap = c_spec[specialism],rej_rate = rej_rate_mean, occ_rate = occ_rate_mean,rep_rate = rep_planned_mean,planned = sum(planned_n*K),unplanned = sum(arr_n*K)))
    perf_SD_list[[specialism]] = rbind(perf_SD_list[[specialism]],
                                    data.frame(cap = c_spec[specialism],rej_rate = rej_rate_SD, occ_rate = occ_rate_SD,rep_rate = rep_planned_SD,planned = sd(planned_n*K),unplanned = sd(arr_n*K)))
  }
}

return(list(perf_list,perf_SD_list))

}