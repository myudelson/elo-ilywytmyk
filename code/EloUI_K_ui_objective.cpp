#include <Rcpp.h>
using namespace Rcpp;
#include <math.h>
#include <iostream>
#include <fstream>
#include <string>

// This is a simple example of exporting a C++ function to R. You can
// source this function into an R session using the Rcpp::sourceCpp 
// function (or via the Source button on the editor toolbar). Learn
// more about Rcpp at:
//
//   http://www.rcpp.org/
//   http://adv-r.had.co.nz/Rcpp.html
//   http://gallery.rcpp.org/
//

// [[Rcpp::export]]


  
NumericVector objective_core_cpp(NumericVector par_K, List d, const int nG, const int nI, const int nK, std::string toreturn){ 
  // IntegerVector nn;
  // nn = d["nG"];
  // int nG = nn[1];
  // nn = d["nI"];
  // int nI = nn[1];
  // nn = d["nK"];
  // int nK = nn[1];

  IntegerVector y = d["y"];
  IntegerVector student = d["student"];
  IntegerVector item = d["item"];
  IntegerVector skill_i = d["skill_i"];
  IntegerVector skill_n = d["skill_n"];
  IntegerVector skill = d["skill"];

  // int nG = nG_[1];
  // int nI = nI_[1];
  // int nK = nK_[1];
  
  NumericVector values_stu(nG, 0.0);
  // double* values_stu = new double[nG];
  for(int t=0;t<nG;t++) values_stu[t] = 0.0;
  NumericVector values_itm(nI, 0.0);
  for(int t=0;t<nI;t++) values_itm[t] = 0.0;
  
  IntegerVector counts_stu(nG, 0);
  for(int t=0;t<nG;t++) counts_stu[t] = 0;
  IntegerVector counts_itm(nI, 0);
  for(int t=0;t<nI;t++) counts_itm[t] = 0;
  
  NumericVector grad;
  NumericVector grad_errors_stu;
  NumericVector grad_errors_itm;
  if(toreturn=="gradient") {
    grad = NumericVector(2);
    grad[0] = 0.0;
    grad[1] = 0.0;
    grad_errors_stu = NumericVector(nG, 0.0);
    grad_errors_itm = NumericVector(nI, 0.0);
    for(int t=0;t<nG;t++) { grad_errors_stu[t]=0.0;};
    for(int t=0;t<nI;t++) { grad_errors_itm[t]=0.0;};
  }
  
  double objval = 0.0;
  int N = y.size();
  
  NumericVector predict(N, 0.0);
  for(int t=0;t<N;t++) predict[t]=0.0;

  int n_   = 0;
  int sig_ = 0;
  double K_s_   = par_K[0];
  double K_i_   = par_K[1];
  double m_t = 0.0;
  double pcorr = 0.0;
  double error = 0.0;
  // Rcout << "nG ="<< nG << ", nI =" << nI << ", K=" << K_ <<"\n";
  // Rcout << "N ="<< N <<"\n";
  // Rcout << "y.size() ="<< y.size() <<"\n";
  // Rcout << "student.size() ="<< student.size() <<"\n";
  // Rcout << "predict.size() ="<< predict.size() <<"\n";
  // Rcout << "counts_stu[1] ="<< counts_stu[1] <<"\n";
  // Rcout << "values_stu[1] ="<< values_stu[1] <<"\n";
  // Rcout << "predict[1] ="<< predict[1] <<"\n";
  // Rcout << "student[0] ="<< student[0] <<"\n";
  // Rcout << "y[0] ="<< y[0] <<"\n";
  // Rcout << "toreturn: '"<< toreturn <<"'\n";
  int student_t = 0;
  int item_t = 0;
  
  // std::ofstream out("temp_C.txt");
  // std::cout.rdbuf(out.rdbuf());
  // std::cout << "t\ty[t]\tstudent_t\titem_t\tpcorr\terror\tval_student_t\tval_item_t\n";
  
  for(int t=0; t<N; t++) {
    student_t = student[t]-1; // -1, because in data they were 1-starting
    item_t    = item[t]-1;    // -1, because in data they were 1-starting
    m_t = values_stu[student_t] - values_itm[item_t]; // the compensatory value to go into the sigma
    pcorr = 1 / ( 1 + exp(-m_t) ); //# skip sigmoid
    predict[t] = pcorr;
    error = y[t]-pcorr;
    pcorr += (pcorr==0)?1e-12:0;
    pcorr -= (pcorr==1)?1e-12:0;
    
    objval -= ( y[t] * log(pcorr) + (1-y[t]) * log (1-pcorr) );
    // Rcout << "t ="<< t<<" pcorr="<< pcorr << " objval ="<< objval << "\n";
    // if(t<=1) {
    //   Rcout << "objval ="<< objval <<"\n";
    // }

    // student
    n_   = counts_stu[student_t];
    sig_ = 1;
    values_stu[student_t] += sig_ * K_s_ * error;// #(y[t] - pcorr);
    counts_stu[student_t] ++;
    if(toreturn=="gradient") {
      if(n_>0) {
        grad[0] -= error * grad_errors_stu[student_t];
      }
      grad_errors_stu[student_t] += error;
    }

    // item
    n_   = counts_itm[item_t];
    sig_ = -1;
    values_itm[item_t] += sig_ * K_i_ * error;
    counts_itm[item_t] ++;
    if(toreturn=="gradient") {
      if(n_>0) {
        grad[1] -= error * grad_errors_itm[item_t];
      }
      grad_errors_itm[item_t] += error;
    }
    // std::cout << t <<"\t"<< y[t]<<"\t"<<student_t<<"\t"<<item_t<<"\t"<<pcorr<<"\t"<<error<<"\t"<<values_stu[student_t]<<"\t"<<values_itm[item_t]<<"\n";
  }
  
  // delete [] values_stu;
  
  if(toreturn=="objective") {
    // Rcout << "K="<<K_<<" Objective=" << objval <<"\n";
    return wrap(objval);
  } else if(toreturn=="gradient") {
    // Rcout << "K="<<K_<<" Gradient=" << grad[0] << "\n";
    return wrap(grad);
  } else if(toreturn=="prediction"){
    // Rcout << ", Prediction\n";
    return predict;
  }
  return wrap(0);
}
