#
# Handle arguments
#
options(echo=FALSE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
par_K           = args[1]
to_print        = args[2]
fn_data_train   = args[3] # headed {score (1-corr, 0-incorr), student, item, HF (skills, ~-separated)}
fn_data_predict = args[4] # headed {score (1-corr, 0-incorr), student, item, HF (skills, ~-separated)}
fn_result       = args[5] 
fn_voc_student  = args[6]
fn_voc_skill    = args[7]
fn_voc_item     = args[8]
optim_method    = args[9]
if(is.na(optim_method) || optim_method=="") { optim_method="BFGS" }


# par_K = 0.4
# fn_data_train="./data/produced/b89__data__all.txt"
# fn_data_predict="./data/produced/b89__data__all.txt"
# fn_result="./result/b89__result__all.txt"
# fn_voc_student="./data/produced/b89__voc_student.txt"
# fn_voc_skill="./data/produced/b89__voc_HF.txt"
# fn_voc_item="./data/produced/b89__voc_item.txt"

# handle required packages
suppressWarnings(suppressMessages(library(pROC)))
source("./code/fit_evaluate_EloUI_includes_K.R")


#
# Data 
#

if(to_print %in% c("fit.objective","fit.gradient","objective","gradient","gradient.co")) {
  data = NULL
  fn_R_data = sub(".txt",".RData",fn_data_train)
  if(!file.exists(fn_R_data)) {
    data = elo_read_data(fn_data_train, fn_voc_student, fn_voc_skill, fn_voc_item)
    save(file=fn_R_data,list=c("data"))
  } else {
    load(fn_R_data)
  }
}
if(to_print=="predict") {
  data = NULL
  fn_R_data = sub(".txt",".RData",fn_data_predict)
  if(!file.exists(fn_R_data)) {
    data = elo_read_data(fn_data_predict, fn_voc_student, fn_voc_skill, fn_voc_item)
    save(file=fn_R_data,list=c("data"))
  } else {
    load(fn_R_data)
  }
}

#
# Fit
#
if(to_print=="fit.objective") {
  par_lower=0.0001
  par_upper=10
  par_init=as.numeric(par_K)
  s <- Sys.time()
  # lbfgs.result = nloptr::lbfgs(x0=par_init, fn=objective, gr=NULL, lower=par_lower, upper=par_upper,
  #                              control = list(xtol_rel=1e-7, maxeval=200), d=data)
  
  # lbfgs.result = nloptr::lbfgs(x0=par_init, fn=objective_core_cpp, gr=NULL, lower=par_lower, upper=par_upper,
  #                              control = list(xtol_rel=1e-7, maxeval=200), y=data$y, student=data$student, 
  #                              item=data$item, skill_i=data$skill_i,skill_n=data$skill_n,skill=data$skill, 
  #                              nG=data$nG, nI=data$nI, nK=data$nK, toreturn="objective")

  lbfgs.result = optim(par=par_init, fn=objective, gr=NULL, method=optim_method,
                       # lower=par_lower, upper=par_upper,
                       control = list(factr=1e-7, maxit=200, trace=1, REPORT=1),
                       d=data)
  print(lbfgs.result)
  f <- Sys.time()
  print(f-s)
}

if(to_print=="fit.gradient") {
  par_lower=0.0001
  par_upper=10
  par_init=as.numeric(par_K)
  s <- Sys.time()
  # lbfgs.result = nloptr::lbfgs(x0=par_init, fn=objective, gr=gradient, lower=par_lower, upper=par_upper,
  #                              control = list(xtol_rel=1e-4, maxeval=100), d=data)
  # lbfgs.result = nloptr::lbfgs(x0=par_init, fn=objective_core_cpp, gr=NULL, lower=par_lower, upper=par_upper,
  #                              control = list(xtol_rel=1e-7, maxeval=200), y=data$y, student=data$student, 
  #                              item=data$item, skill_i=data$skill_i,skill_n=data$skill_n,skill=data$skill, 
  #                              nG=data$nG, nI=data$nI, nK=data$nK, toreturn="gradient")
  lbfgs.result = optim(par=par_init, fn=objective, gr=gradient, method=optim_method,
                       # lower=par_lower, upper=par_upper,
                       # control = list(reltol=1e-4, maxit=100),
                       control = list(factr=1e-7, maxit=200, trace=1, REPORT=1),
                       d=data)
  # lbfgs.result = nloptr::nloptr(x0=par_init, eval_f=objective, eval_grad_f=gradient,
  #                      lb=par_lower, ub=par_upper,
  #                      # control = list(reltol=1e-4, maxit=100),
  #                      opts = list(maxit=100, algorithm=optim_method), #xtol_rel=1e-8, 
  #                      d=data)
  
  
  # lbfgs.result = lbfgs::lbfgs(objective, gradient, vars=par_init, d=data,
  #                              epsilon=1e-4, max_iterations=200)
  # cl = makeCluster(1)
  # setDefaultCluster(cl=cl)
  # lbfgs.result = optimParallel::optimParallel(par=par_init, fn=objective_core, gr=gradient_core, lower=par_lower, upper=par_upper,
  #                              d=data)
  # stopCluster(cl)
  print(lbfgs.result)
  f <- Sys.time()
  print(f-s)
}

#
# Prediction data
#
# cat("~ Printing prediction...\n")
if(to_print=="predict") {
  predicted = prediction(as.numeric(par_K), data)
  dp = data.frame(Observation=data$y,Correct=predicted,Incorrect=(1.0-predicted))
  fn_predict = sub("data","predict",sub("./data/produced/","./predict/",fn_data_predict))
  write.table(dp,file=fn_predict,sep="\t",row.names=FALSE,col.names=TRUE, quote=FALSE)
  predictions=predicted;
  save(file="./temp/temp.RData",list=c("predictions"))
  
  # cat("~ Printing results...\n")
  rmse_full <- rmse(data$y,predicted)
  acc_full <- acc(data$y,predicted)
  auc_full <- as.numeric(auc(data$y,predicted))
  cat("RMSE, ACC, ROC ",rmse_full, acc_full, auc_full)
  cat(paste("fit__accuracy\t",acc_full,"\n",sep=""),file=fn_result,append=FALSE,sep="")
  cat(paste("fit__rmse\t",rmse_full,"\n",sep=""),file=fn_result,append=TRUE,sep="")
  cat(paste("fit__auc\t",as.numeric(auc_full),"\n",sep=""),file=fn_result,append=TRUE,sep="")
}

#
# Get Objective
#
# cat("~ Printing objective\n")
# fn_data_train="./data/produced/ds392__data__all.txt"
if(to_print=="objective") {
  # cat(to_print,"\n")
  # toreturn = "objective"
  # obj = objective_core_cpp(as.numeric(par_K), data$y, data$student, data$item, data$skill_i,
  #                          data$skill_n,data$skill, data$nG, data$nI, data$nK, toreturn="objective")
  # obj = objective_core_cpp(as.numeric(par_K), data, "objective")
  # obj = objective_core(as.numeric(par_K), data, toreturn="objective", values=NULL)
  obj = objective(as.numeric(par_K), data)
  cat(sprintf("%.6f",obj))
}

#
# Get Gradient
#
# cat("~ Printing gradient\n")
if(to_print=="gradient") {
  # cat(to_print,"\n")
  # gradient = objective_core_cpp(as.numeric(par_K), data$y, data$student, data$item, data$skill_i, 
  #                          data$skill_n,data$skill, data$nG, data$nI, data$nK, toreturn="gradient")
  # gradient = objective_core(as.numeric(par_K), data, toreturn="gradient", values=NULL)
  # gradient = objective_core_cpp(as.numeric(par_K), data, toreturn="gradient")
  grad = gradient(as.numeric(par_K), data)
  cat(sprintf("%.6f",grad))
}

#
# Get Gradient computational
#
# cat("~ Printing gradient\n")
if(to_print=="gradient.co") {
  # cat(to_print,"\n")
  # objective_core(as.numeric(par_K), data, toreturn="gradient", values=NULL)
  # gradient = nloptr::nl.grad(as.numeric(par_K), objective_core, d=data, toreturn="objective", values=NULL)
  gradient = nloptr::nl.grad(as.numeric(par_K), objective, d=data)
  cat(sprintf("%.6f",gradient))
}



# cat("~ Done!\n")
