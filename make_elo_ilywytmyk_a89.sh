
#
# KDD Cup 2010, Challenge Set A
#

# unit-section-problem-step results in 1,300,000 Million items, too many
# time unzip -q -c ./data/source/algebra_2008_2009.zip algebra_2008_2009_train.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) { print "score","student","item","HF";next; }skill=$20; gsub("~~", "~", skill); gsub("Unit ", "", $3); gsub(", Section ", "__", $3); skill=(skill=="")?".":(skill); gsub("~", "~"$3"__", skill); skill=(skill==".")?".":$3"__"skill; print $14,$2,$3"__"$4"__"$6,skill;}' > data/produced/a89__data__all_USPS.txt
# unit-section-problem results in 200,000 items
time unzip -q -c ./data/source/algebra_2008_2009.zip algebra_2008_2009_train.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) { print "score","student","item","HF";next; }skill=$20; gsub("~~", "~", skill); gsub("Unit ", "", $3); gsub(", Section ", "__", $3); skill=(skill=="")?".":(skill); gsub("~", "~"$3"__", skill); skill=(skill==".")?".":$3"__"skill; print $14,$2,$3"__"$4,skill;}' > data/produced/a89__data__all.txt
# real    0m54.521s
ls -al data/produced/a89__data__all.txt
# -rw-r--r--  1 myudelson  staff  904646754 Feb 23 15:35 data/produced/a89__data__all.txt
wc -l data/produced/a89__data__all.txt
# 8918055 data/produced/a89__data__all.txt

# time unzip -q -c ./data/source/algebra_2008_2009.zip algebra_2008_2009_train.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) {next;} skill=$89; gsub("~~", "~", skill); opp=$90; gsub("~~", "~", opp); skill=(skill=="")?".":(skill); opp=(opp=="")?"":(opp); print (($15=="correct")?1:2),$3,$5"__"$7,skill,opp;}' > data/produced/a89__datahmm__all.txt
time unzip -q -c ./data/source/algebra_2008_2009.zip algebra_2008_2009_train.txt | gawk -F"\t" 'BEGIN{OFS="\t"} {if(NR==1)next; skill=$20; gsub("~~", "~", skill); if(skill=="") skill="."; else { skill=$3"__"skill; gsub(/~/, "~"$3"__",skill);} print 2-$14,$2,$3"__"$4,skill;}' > data/produced/a89__datahmm__all.txt
wc -l ./data/produced/a89__datahmm__all.txt
# 8918054 ./data/produced/a89__datahmm__all.txt

#
# generate vocabularies
#
awk -F"\t" 'BEGIN{OFS="\t"}{
  if(FNR==1) next;
  U[$2]++;
  if(U[$2]==1){
    nu++; 
    VU[$2]=nu;
  }
  I[$3]++;
  if(I[$3]==1){
    ni++; 
    VI[$3]=ni;
  }
  n=split($4,ar,"~");
  for(i=1;i<=n;i++) {
    K[ar[i]]++;
    if(K[ar[i]]==1){
      nk++; 
      VK[ar[i]]=nk;
    }
  }
}END{
  print "id","name" > "./data/produced/a89__voc_student.txt"
  for(u in VU) {
  print VU[u],u > "./data/produced/a89__voc_student.txt";
  }
  print "id","name" > "./data/produced/a89__voc_item.txt"
  for(i in VI) {
  print VI[i],i > "./data/produced/a89__voc_item.txt";
  }
  print "id","name" > "./data/produced/a89__voc_HF.txt"
  for(k in VK) {
  print VK[k],k > "./data/produced/a89__voc_HF.txt";
  }
}' ./data/produced/a89__data__all.txt


#
# Compile HMM-Scalable and LIBLINEAR code and move it to ./bin
#
cd ./code/hmm
make all
mv trainhmm ../../bin/
mv predicthmm ../../bin/
mv inputconvert ../../bin/
cd ../..


# BKT
# BKT model
fn_datahmm_train=./data/produced/a89__datahmm__all.txt
fn_modelhmm=./model/a89__modelhmm__all.txt
fn_predicthmm=./predict/a89__predicthmm__all.txt
./bin/trainhmm -s 1.4 -p 1 -e 0.001 -m 1 -d ~ ${fn_datahmm_train} ${fn_modelhmm} ${fn_predicthmm}
# input read, nO=2, nG=3310, nK=899, nI=206596, nZ=1
# trained model LL=3412618.5222956 (1791887.2291228), AIC=6832429.044591, BIC=6882785.948188, RMSE=0.338934 (0.356205), Acc=0.857210 (0.830655)
# timing: overall 46.000000 seconds, read 14.030028, fit 22.703639, predict 9.503793


#
# Try Elo UI K, A89
#

fn_data_train=./data/produced/a89__data__all.txt
fn_data_predict=./data/produced/a89__data__all.txt
fn_result=./result/a89__result__all.txt
fn_voc_student=./data/produced/a89__voc_student.txt
fn_voc_skill=./data/produced/a89__voc_HF.txt
fn_voc_item=./data/produced/a89__voc_item.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.4 fit.objective $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par 
# [1] 0.1282274
# $value
# [1] 3447761
# $counts
# function gradient
#       38        7
# $convergence
# [1] 0
# $message
# NULL
# Time difference of 22.77954 secs
fn_result=./result/a89__result__all__EloUI_K__obj.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.1282274 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.3421905 0.8537731 0.6918536
cat ${fn_result}
# fit__accuracy   0.853773143782265
# fit__rmse       0.342190458890188
# fit__auc        0.691853595454638

Rscript ./code/fit_evaluate_EloUI_K.R 0.4 fit.gradient $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item 
# $par 
# [1] 0.09857082
# $value
# [1] 3450255
# $counts
# function gradient
#      45        4
# $convergence
# [1] 0
# $message
# NULL
# Time difference of 17.4038 secs
fn_result=./result/a89__result__all__EloUI_K__grad.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.09857082 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.3423407 0.853908 0.69014
cat ${fn_result}
# it__accuracy   0.853908038681982
# fit__rmse       0.342340721419068
# fit__auc        0.690140037330186

#
# Try Elo UI K_ui, A89
#

# k_ui, A89
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4 0.4 fit.objective $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par =
# [1] 0.19648665 0.03400951
# $value
# [1] 3437226
# $counts
# function gradient
#       62       10
# $convergence
# [1] 0
# $message
# NULL
# Time difference of 40.82713 secs
fn_result=./result/a89__result__all__EloUI_K_ui__obj.txt
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.19648665 0.03400951 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.3416737 0.8539156 0.6950288
cat ${fn_result}
# fit__accuracy   0.853915551531758
# fit__rmse       0.341673745878
# fit__auc        0.695028840026474


Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4 0.4 fit.gradient $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.16007980 0.07889287
# $value
# [1] 3440697
# $counts
# function gradient
#       146        6
# $convergence
# [1] 0
# $message
# NULL
# Time difference of  1.005907 mins
fn_result=./result/a89__result__all__EloUI_K_ui__gra.txt
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.16007980 0.07889287 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.3418514 0.8538902 0.693909
cat ${fn_result}
# fit__accuracy   0.853890209680273
# fit__rmse       0.341851421846828
# fit__auc        0.6939089555319

