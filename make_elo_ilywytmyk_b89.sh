
#
# KDD Cup 2010, Challenge Set B
#

# unit-section-problem-step results in  too many
# unit-section-problem results in 62,000 items
time unzip -q -c ./data/source/bridge_to_algebra_2008_2009.zip bridge_to_algebra_2008_2009_train.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) { print "score","student","item","HF";next; }skill=$20; gsub("~~", "~", skill); gsub("Unit ", "", $3); gsub(", Section ", "__", $3); skill=(skill=="")?".":(skill); gsub("~", "~"$3"__", skill); skill=(skill==".")?".":$3"__"skill; print $14,$2,$3"__"$4,skill;}' > data/produced/b89__data__all.txt
# real    1m56.011s
ls -al data/produced/b89__data__all.txt
# -rw-r--r--  1 myudelson  staff  2515844313 Apr 15 11:01 data/produced/b89__data__all.txt
wc -l data/produced/b89__data__all.txt
# 20012499 data/produced/b89__data__all.txt

# time unzip -q -c ./data/source/bridge_to_algebra_2008_2009.zip bridge_to_algebra_2008_2009_train.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) {next;} skill=$89; gsub("~~", "~", skill); opp=$90; gsub("~~", "~", opp); skill=(skill=="")?".":(skill); opp=(opp=="")?"":(opp); print (($15=="correct")?1:2),$3,$5"__"$7,skill,opp;}' > data/produced/b89__datahmm__all.txt
time unzip -q -c ./data/source/bridge_to_algebra_2008_2009.zip bridge_to_algebra_2008_2009_train.txt | gawk -F"\t" 'BEGIN{OFS="\t"} {if(NR==1)next; skill=$20; gsub("~~", "~", skill); if(skill=="") skill="."; else { skill=$3"__"skill; gsub(/~/, "~"$3"__",skill);} print 2-$14,$2,$3"__"$4,skill;}' > data/produced/b89__datahmm__all.txt
wc -l ./data/produced/b89__datahmm__all.txt
# 20012498 ./data/produced/b89__datahmm__all.txt

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
  print "id","name" > "./data/produced/b89__voc_student.txt"
  for(u in VU) {
  print VU[u],u > "./data/produced/b89__voc_student.txt";
  }
  print "id","name" > "./data/produced/b89__voc_item.txt"
  for(i in VI) {
  print VI[i],i > "./data/produced/b89__voc_item.txt";
  }
  print "id","name" > "./data/produced/b89__voc_HF.txt"
  for(k in VK) {
  print VK[k],k > "./data/produced/b89__voc_HF.txt";
  }
}' ./data/produced/b89__data__all.txt


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
fn_datahmm_train=./data/produced/b89__datahmm__all.txt
fn_modelhmm=./model/b89__modelhmm__all.txt
fn_predicthmm=./predict/b89__predicthmm__all.txt
./bin/trainhmm -s 1.4 -p 1 -e 0.001 -m 1 -d ~ ${fn_datahmm_train} ${fn_modelhmm} ${fn_predicthmm}
# input read, nO=2, nG=6043, nK=1499, nI=61848, nZ=1
# trained model LL=6906909.4036102 (4494546.1770776), AIC=13825810.807220, BIC=13914622.764968, RMSE=0.317750 (0.351205), Acc=0.872202 (0.833680)
# timing: overall 110.000000 seconds, read 36.057212, fit 51.224097, predict 22.770857


#
# Try Elo UI K, b89
#

fn_data_train=./data/produced/b89__data__all.txt
fn_data_predict=./data/produced/b89__data__all.txt
fn_result=./result/b89__result__all.txt
fn_voc_student=./data/produced/b89__voc_student.txt
fn_voc_skill=./data/produced/b89__voc_HF.txt
fn_voc_item=./data/produced/b89__voc_item.txt


Rscript ./code/fit_evaluate_EloUI_K.R 0.4 fit.objective $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# ***
# $par
# [1] 0.1212368
# $value
# [1] 7108867
# $counts
# function gradient
#       54        8
# $convergence
# [1] 0
# $message
# NULL
# Time difference of 53.87102 secs
fn_result=./result/b89__result__all__EloUI_K__obj.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.1212368 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.3263301 0.8652698 0.7380882
cat ${fn_result}
# fit__accuracy   0.865269792906413
# fit__rmse       0.32633010746442
# fit__auc        0.73808823986548

Rscript ./code/fit_evaluate_EloUI_K.R 0.4 fit.gradient $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.1171019
# $value
# [1] 7108948
# $counts
# function gradient
#       43        4
# $convergence
# [1] 0
# $message
# NULL
# Time difference of 38.136 secs
fn_result=./result/b89__result__all__EloUI_K__grad.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.1171019 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.3263434 0.86527 0.7380164
cat ${fn_result}
# fit__accuracy   0.865270042750285
# fit__rmse       0.326343373157331
# fit__auc        0.738016404272414


#
# Try Elo UI K, B89
#

# k_ui, b89
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4 0.4 fit.objective $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.1697292 0.0734257
# $value
# [1] 7101767
# $counts
# function gradient
#       68        9
# $convergence
# [1] 0
# $message
# NULL
# Time difference of 1.645137 mins
fn_result=./result/b89__result__all__EloUI_K_ui__obj.txt
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.1697292 0.0734257 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.3261334 0.8654355 0.7385635
cat ${fn_result}
# fit__accuracy   0.865435489362697
# fit__rmse       0.326133439871581
# fit__auc        0.738563468528592

Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4 0.4 fit.gradient $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.1071228 0.1267133
# $value
# [1] 7111965
# $counts
# function gradient
#       62        6
# $convergence
# [1] 0
# $message
# NULL
# Time difference of 1.092363 mins
fn_result=./result/b89__result__all__EloUI_K_ui__gra.txt
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.1071228 0.1267133 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.3264212 0.8652197 0.7377314
cat ${fn_result}
# fit__accuracy   0.865219724194351
# fit__rmse       0.326421216650455
# fit__auc        0.737731407591825

