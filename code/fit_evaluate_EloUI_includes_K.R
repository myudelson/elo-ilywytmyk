#
#
# Elo constants and library functions
#
# 


#
# Helper functions
#

# functions
sigmoid = function(x) {
  1 / ( 1 + exp(-x) )
}
rmse = function(actual,expected){
  sqrt(mean((actual - expected)^2))
}
acc = function(actual,expected){
  mean((expected>=0.5)*1==actual)
}
logit = function(p) {
  log( p/(1-p) )
}

safelogit = function(p) {
  log( safeprob(p)/(1-safeprob(p)) )
}

#
eta_ = 1e-10
safeprob = function(x) {
  x[x<=0] = eta_;
  x[x>=1] = 1-eta_;
  return(x)
}

#
# functions for generating names
#

# count of prior opportunities
# nm_opp = function(x) { return(paste("n_",as.character(x),sep="")) }
# count of prior correct opportunities
# nm_opp_corr = function(x) { return(paste("n_",as.character(x),"_correct",sep="")) }

#
# Read and Prepare Data
#

elo_read_data = function(fn_data, fn_voc_stu, fn_voc_ski, fn_voc_itm) {
  voc_stu = read.delim(fn_voc_stu,sep= "\t",stringsAsFactors = FALSE)
  voc_ski = read.delim(fn_voc_ski,sep= "\t",stringsAsFactors = FALSE)
  voc_itm = read.delim(fn_voc_itm,sep= "\t",stringsAsFactors = FALSE)
  d = read.delim(fn_data, header = TRUE, sep= "\t", stringsAsFactors = FALSE)
  # # vvv subset data removing missing skills
  # d = d[d$HF!=".",]
  # # ^^^ 
  y = d$score
  student = match(d$student, voc_stu$name)
  item = match(d$item, voc_itm$name)
  N = dim(d)[1]
  skill_n = unlist(lapply(d$HF,FUN=function(x){length(strsplit(x,"~")[[1]])}))
  skill_i = rep(0,N)
  sum=1;
  for(t in 1:N) {
    skill_i[t] = sum;
    sum = sum + skill_n[t]
  }
  skill_stacked = unlist(lapply(d$HF,FUN=function(x){strsplit(x,"~")}))
  sum(skill_n)==length(skill_stacked)
  # TRUE
  skill=match(skill_stacked, voc_ski$name)
  nI = dim(voc_itm)[1]
  nG = dim(voc_stu)[1]
  nK = dim(voc_ski)[1]
  
  data = list(y=y, student=student, item=item, skill_i=skill_i, skill_n=skill_n,
              skill=skill, nI=nI, nG=nG, nK=nK, 
              voc_stu=voc_stu, voc_itm=voc_itm, voc_ski=voc_ski)

  return(data)
}



#
# Elo Master Objective
#

# par --  parameters of the model
# y ... skill -- the data
# toreturn -- what is being returned ("objective","prediction","values","trackables")
# values -- the values of the trackable parameters if they are set before hand
#objective function bits of actual and expected

library(Rcpp)
sourceCpp("code/EloUI_K_objective.cpp")

# R version
objective_0 = function(par_K, d) {
  return ( objective_core(par_K, d, toreturn="objective", values=NULL) )
}
# R version
gradient_0 = function(par_K, d) {
  return ( objective_core(par_K, d, toreturn="gradient", values=NULL) )
}

# C version
objective = function(par_K, d) {
  return ( objective_core_cpp(par_K, d, d$nG, d$nI, d$nK, toreturn="objective") )
}
# C version
gradient = function(par_K, d) {
  return ( objective_core_cpp(par_K, d, d$nG, d$nI, d$nK, toreturn="gradient") )
}
prediction = function(par_K, d) {
  return ( objective_core_cpp(par_K, d, d$nG, d$nI, d$nK, toreturn="prediction") )
}


library(Rcpp)


objective_core = function(par_K, d, toreturn="objective",values=NULL) {
  # cat("Pars",par_K,"\n")#,file="temp.txt") # check against error
  
  # rip out data from d
  y = d$y
  student = d$student
  item = d$item
  skill_i = d$skill_i
  skill_n = d$skill_n
  skill = d$skill
  nG = d$nG
  nI = d$nI
  nK = d$nK
  
  # initialize gradients
  grad_errors = list() # parameter-specific errors for gradients
  if(toreturn=="gradient") {
    grad = rep(0,2)
    grad_errors$stu = rep(0,nG)
    grad_errors$itm = rep(0,nI)
  }
  
  # initialize rating values
  if(is.null(values)) {
    # declare evaluation variables anew if they are part of the model spec
    values = list()
    values$stu = rep(0, nG) # values start with 0
    values$itm = rep(0, nI) # values start with 0
  }
  
  # setup trackables
  if(toreturn=="trackables") {
    # if there are skills, then the N_stack is potentially the sum of all lengths of skill tuples of all rows
    # otherwise it is simply N rows
    N_stack = ifelse(!is.null(skill), length(skill), length(student))
    trk = list(
      row_id  = 1:N_stack,
      stu_id  = rep(0,N_stack),
      itm_id  = rep(0,N_stack),
      corr    = rep(0,N_stack),
      pcorr    = rep(0,N_stack)
    )
    trk$stu        = rep(0,N_stack)
    trk$n_stu      = rep(0,N_stack)
    # trk$n_stu_corr = rep(0,N_stack)
    trk$itm        = rep(0,N_stack)
    trk$n_itm      = rep(0,N_stack)
    # trk$n_itm_corr = rep(0,N_stack)
  }
  
  # set up counts
  counts = list()
  counts[[ "n_stu" ]] = rep(0, nG)
  # counts[[ "n_stu_corr" ]] = rep(0, nG)
  counts[[ "n_itm" ]] = rep(0, nI)
  # counts[[ "n_itm_corr" ]] = rep(0, nI)
  
  # objective and N
  objval = 0
  N = length(y)
  
  # vector of predictions prediction - always define
  # if(toreturn=="prediction") {
  predict = rep(0,N)
  # }
  
  c_ = 1 # overall count for trackables
  for(t in 1:N) {
    # elicit current values
    m_t = values$stu[student[t]] - values$itm[item[t]]; # the compensatory value to go into the sigma
    # pcorr = sigmoid(m_t)
    pcorr = 1 / ( 1 + exp(-m_t) ) # skip sigmoid
    
    # always save prediction    
    predict[t] = pcorr
    
    # error, one of the components of the gradient too
    error = y[t]-pcorr
    
    if(toreturn=="trackables") {
      student_t = student[t]
      item_t = item[t]
      skill_ids_i = skill_ids[i]
      trk$stu_id[c_+i-1] = student_t
      trk$itm_id[c_+i-1] = item_t
      trk$corr[c_+i-1] = y[t]
      trk$pcorr[c_+i-1] = pcorr
    } # trackables
    
    # update values and counts
    # stu
    # student counts are kept no matter what
    n_   = counts$n_stu[student[t]]
    # n_c_ = counts$n_stu_corr[student[t]]
    sig_ = 1
    if(toreturn=="gradient") {
      if(n_ == 0) {
        grad[1] = grad[1] + (n_==0) * error * sig_ #elo_comp_signs[i]
      } else {
        grad[1] = grad[1] + error * grad_errors$stu[student[t]]
      }
      # update past errors        
      grad_errors$stu[student[t]] = grad_errors$stu[student[t]] + error
    }
    K_   = par_K[1];
    val_ = values$stu[student[t]]
    values$stu[student[t]] = val_ + sig_ * K_ * (y[t] - pcorr);
    counts$n_stu[student[t]] = n_   + 1
    # counts$n_stu_corr[student[t]] = n_c_ + 1 * (y[t]==1)
    
    # itm
    # item counts are kept no matter what
    n_   = counts$n_itm[item[t]]
    # n_c_ = counts$n_itm_corr[item[t]]
    sig_ = -1
    if(toreturn=="gradient") {
      if(n_ == 0) {
        grad[2] = grad[2] + (n_==0) * error * sig_ #elo_comp_signs[i]
      } else {
        grad[2] = grad[2] + error * grad_errors$itm[item[t]]
      }
      # update past errors        
      grad_errors$itm[item[t]] = grad_errors$itm[item[t]] + error
    }
    K_   = par_K[1];
    val_ = values$itm[item[t]]
    values$itm[item[t]] = val_ + sig_ * K_ * (y[t] - pcorr);
    counts$n_itm[item[t]] = n_   + 1
    # counts$n_itm_corr[item[t]] = n_c_ + 1 * (y[t]==1)
  } # for all T
  
  if(toreturn=="objective") {
    obj = NA
    # loglik
    obj = -sum( y * log(predict) + (1-y) * log (1-predict) ) 
    # rmse
    # obj= sum( (y-predict)^2 ) / N;
    # cat("  NegSumLogLik =",sprintf("%.6f", obj),"\n")
    return( obj )  
  } else if(toreturn=="values"){
    return( values )
  } else if(toreturn=="prediction"){
    return( predict )
  } else if(toreturn=="trackables"){
    return( trk )
  } else if(toreturn=="gradient"){
    # cat("  Grad =",sprintf("%.6f", grad),"\n")
    return( -grad )
  }
}
gradient_core = function(par_K, d, toreturn="gradient",values=NULL) {
  # cat("Pars",par_K,"\n")#,file="temp.txt") # check against error
  
  # rip out data from d
  y = d$y
  student = d$student
  item = d$item
  skill_i = d$skill_i
  skill_n = d$skill_n
  skill = d$skill
  nG = d$nG
  nI = d$nI
  nK = d$nK
  
  # initialize gradients
  grad_errors = list() # parameter-specific errors for gradients
  if(toreturn=="gradient") {
    grad = rep(0,2)
    grad_errors$stu = rep(0,nG)
    grad_errors$itm = rep(0,nI)
  }
  
  # initialize rating values
  if(is.null(values)) {
    # declare evaluation variables anew if they are part of the model spec
    values = list()
    values$stu = rep(0, nG) # values start with 0
    values$itm = rep(0, nI) # values start with 0
  }
  
  # setup trackables
  if(toreturn=="trackables") {
    # if there are skills, then the N_stack is potentially the sum of all lengths of skill tuples of all rows
    # otherwise it is simply N rows
    N_stack = ifelse(!is.null(skill), length(skill), length(student))
    trk = list(
      row_id  = 1:N_stack,
      stu_id  = rep(0,N_stack),
      itm_id  = rep(0,N_stack),
      corr    = rep(0,N_stack),
      pcorr    = rep(0,N_stack)
    )
    trk$stu        = rep(0,N_stack)
    trk$n_stu      = rep(0,N_stack)
    # trk$n_stu_corr = rep(0,N_stack)
    trk$itm        = rep(0,N_stack)
    trk$n_itm      = rep(0,N_stack)
    # trk$n_itm_corr = rep(0,N_stack)
  }
  
  # set up counts
  counts = list()
  counts[[ "n_stu" ]] = rep(0, nG)
  # counts[[ "n_stu_corr" ]] = rep(0, nG)
  counts[[ "n_itm" ]] = rep(0, nI)
  # counts[[ "n_itm_corr" ]] = rep(0, nI)
  
  # objective and N
  objval = 0
  N = length(y)
  
  # vector of predictions prediction - always define
  # if(toreturn=="prediction") {
  predict = rep(0,N)
  # }
  
  c_ = 1 # overall count for trackables
  for(t in 1:N) {
    # elicit current values
    m_t = values$stu[student[t]] - values$itm[item[t]]; # the compensatory value to go into the sigma
    # pcorr = sigmoid(m_t)
    pcorr = 1 / ( 1 + exp(-m_t) ) # skip sigmoid
    
    # always save prediction    
    predict[t] = pcorr
    
    # error, one of the components of the gradient too
    error = y[t]-pcorr
    
    if(toreturn=="trackables") {
      student_t = student[t]
      item_t = item[t]
      skill_ids_i = skill_ids[i]
      trk$stu_id[c_+i-1] = student_t
      trk$itm_id[c_+i-1] = item_t
      trk$corr[c_+i-1] = y[t]
      trk$pcorr[c_+i-1] = pcorr
    } # trackables
    
    # update values and counts
    # stu
    # student counts are kept no matter what
    n_   = counts$n_stu[student[t]]
    # n_c_ = counts$n_stu_corr[student[t]]
    sig_ = 1
    if(toreturn=="gradient") {
      if(n_ == 0) {
        grad[1] = grad[1] + (n_==0) * error * sig_ #elo_comp_signs[i]
      } else {
        grad[1] = grad[1] + error * grad_errors$stu[student[t]]
      }
      # update past errors        
      grad_errors$stu[student[t]] = grad_errors$stu[student[t]] + error
    }
    K_   = par_K[1];
    val_ = values$stu[student[t]]
    values$stu[student[t]] = val_ + sig_ * K_ * (y[t] - pcorr);
    counts$n_stu[student[t]] = n_   + 1
    # counts$n_stu_corr[student[t]] = n_c_ + 1 * (y[t]==1)
    
    # itm
    # item counts are kept no matter what
    n_   = counts$n_itm[item[t]]
    # n_c_ = counts$n_itm_corr[item[t]]
    sig_ = -1
    if(toreturn=="gradient") {
      if(n_ == 0) {
        grad[2] = grad[2] + (n_==0) * error * sig_ #elo_comp_signs[i]
      } else {
        grad[2] = grad[2] + error * grad_errors$itm[item[t]]
      }
      # update past errors        
      grad_errors$itm[item[t]] = grad_errors$itm[item[t]] + error
    }
    K_   = par_K[1];
    val_ = values$itm[item[t]]
    values$itm[item[t]] = val_ + sig_ * K_ * (y[t] - pcorr);
    counts$n_itm[item[t]] = n_   + 1
    # counts$n_itm_corr[item[t]] = n_c_ + 1 * (y[t]==1)
  } # for all T
  
  if(toreturn=="objective") {
    obj = NA
    # loglik
    obj = -sum( y * log(predict) + (1-y) * log (1-predict) ) 
    # rmse
    # obj= sum( (y-predict)^2 ) / N;
    # cat("  NegSumLogLik =",sprintf("%.6f", obj),"\n")
    return( obj )  
  } else if(toreturn=="values"){
    return( values )
  } else if(toreturn=="prediction"){
    return( predict )
  } else if(toreturn=="trackables"){
    return( trk )
  } else if(toreturn=="gradient"){
    # cat("  Grad =",sprintf("%.6f", grad),"\n")
    return( -grad )
  }
}
