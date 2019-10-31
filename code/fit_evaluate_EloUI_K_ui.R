#
# Handle arguments
#
options(echo=FALSE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
par_K_ui = c(0,0)
par_K_ui[1]     = args[1]
par_K_ui[2]     = args[2]
to_print        = args[3]
fn_data_train   = args[4] # headed {score (1-corr, 0-incorr), student, item, HF (skills, ~-separated)}
fn_data_predict = args[5] # headed {score (1-corr, 0-incorr), student, item, HF (skills, ~-separated)}
fn_result       = args[6] 
fn_voc_student  = args[7]
fn_voc_skill    = args[8]
fn_voc_item     = args[9]
# optim_method    = args[10]
# if(optim_method=="") { optim_method="BFGS" }

# par_K_ui = c(0.4,0.4)
# fn_data_train="./data/produced/ds76__data__all.txt"
# fn_data_predict="./data/produced/ds76__data__all.txt"
# fn_result="./result/ds76__result__all.txt"
# fn_voc_student="./data/produced/ds76__voc_student.txt"
# fn_voc_skill="./data/produced/ds76__voc_HF.txt"
# fn_voc_item="./data/produced/ds76__voc_item.txt"
# to_print="objective"

# handle required packages
suppressWarnings(suppressMessages(library(pROC)))
source("./code/fit_evaluate_EloUI_includes_K_ui.R")


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
  par_lower=rep( 0.0001,2)
  par_upper=rep(10.0000,2)
  par_init=as.numeric(par_K_ui)
  s <- Sys.time()
  # lbfgs.result = nloptr::lbfgs(x0=par_init, fn=objective, gr=NULL, lower=par_lower, upper=par_upper,
  #                              control = list(xtol_rel=1e-7, maxeval=200), d=data)
  lbfgs.result = optim(par=par_init, fn=objective, gr=NULL, method="BFGS",
                       # lower=par_lower, upper=par_upper,
                       # control = list(reltol=1e-4, maxit=100),
                       control = list(factr=1e-7, maxit=200, trace=1, REPORT=1),
                       d=data)
  print(lbfgs.result)
  f <- Sys.time()
  print(f-s)
}

if(to_print=="fit.gradient") {
  par_lower=rep( 0.0001,2)
  par_upper=rep(10.0000,2)
  par_init=as.numeric(par_K_ui)
  s <- Sys.time()
  # lbfgs.result = nloptr::lbfgs(x0=par_init, fn=objective, gr=gradient, lower=par_lower, upper=par_upper,
  #                              control = list(xtol_rel=1e-4, maxeval=100), d=data)
  lbfgs.result = optim(par=par_init, fn=objective, gr=gradient, method="BFGS",
                       # lower=par_lower, upper=par_upper,
                       # control = list(reltol=1e-4, maxit=100),
                       control = list(factr=1e-7, maxit=200, trace=1, REPORT=1),
                       d=data)
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
  predicted = objective_core(as.numeric(par_K_ui), data, toreturn="prediction", values=NULL)
  dp = data.frame(Observation=data$y,Correct=predicted,Incorrect=(1.0-predicted))
  fn_predict = sub("data","predict",sub("./data/produced/","./predict/",fn_data_predict))
  write.table(dp,file=fn_predict,sep="\t",row.names=FALSE,col.names=TRUE, quote=FALSE)
  
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
if(to_print=="objective") {
  # cat(to_print,"\n")
  obj = objective(as.numeric(par_K_ui), data)
  cat(sprintf("%.6f",obj))
}

#
# Get Gradient
#
# cat("~ Printing gradient\n")
if(to_print=="gradient") {
  # cat(to_print,"\n")
  grad = gradient(as.numeric(par_K_ui), data)
  cat(sprintf("%.6f",grad))
}

#
# Get Gradient computational
#
# cat("~ Printing gradient\n")
if(to_print=="gradient.co") {
  # cat(to_print,"\n")
  # objective_core(as.numeric(par_K), data, toreturn="gradient", values=NULL)
  gradient = nloptr::nl.grad(as.numeric(par_K_ui), objective, d=data)
  cat(sprintf("%.6f",gradient))
}


# cat("~ Done!\n")
