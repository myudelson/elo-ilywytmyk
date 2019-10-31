#
#
# 'Elo, I love you, won't you tell me your K (ilywytmyk)
#
#

#
# DataShop dataset 76, Geometry Area
#
time unzip -q -c ./data/source/ds76_student_step_2019_0215_115051.zip ds76_student_step_All_Data_74_2018_0912_072214.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) { print "score","student","item","HF","opp"; next;} skill=$89; gsub("~~", "~", skill); opp=$90; gsub("~~", "~", opp); skill=(skill=="")?".":(skill); opp=(opp=="")?"":(opp); print (($15=="correct")?1:0),$3,$5"__"$7,skill,opp;}' > data/produced/ds76__data__all.txt
wc -l ./data/produced/ds76__data__all.txt
# 5105 ./data/produced/ds76__data__all.txt

# data for BKT
time unzip -q -c ./data/source/ds76_student_step_2019_0215_115051.zip ds76_student_step_All_Data_74_2018_0912_072214.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) {next;} skill=$89; gsub("~~", "~", skill); opp=$90; gsub("~~", "~", opp); skill=(skill=="")?".":(skill); opp=(opp=="")?"":(opp); print (($15=="correct")?1:2),$3,$5"__"$7,skill,opp;}' > data/produced/ds76__datahmm__all.txt
wc -l ./data/produced/ds76__datahmm__all.txt
# 5104 ./data/produced/ds76__datahmm__all.txt

#
# Compile HMM-Scalable and LIBLINEAR code and move it to ./bin
#
cd ./code/hmm
make all
mv trainhmm ../../bin/
mv predicthmm ../../bin/
mv inputconvert ../../bin/
cd ../..


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
	 K[$4]++;
	 if(K[$4]==1){
		 nk++; 
		 VK[$4]=nk;
	 }
 }END{
	 print "id","name" > "./data/produced/ds76__voc_student.txt"
	 for(u in VU) {
		 print VU[u],u > "./data/produced/ds76__voc_student.txt";
	 }
	 print "id","name" > "./data/produced/ds76__voc_item.txt"
	 for(i in VI) {
		 print VI[i],i > "./data/produced/ds76__voc_item.txt";
	 }
	 print "id","name" > "./data/produced/ds76__voc_HF.txt"
	 for(k in VK) {
		 print VK[k],k > "./data/produced/ds76__voc_HF.txt";
	 }
 }' ./data/produced/ds76__data__all.txt


# BKT
# BKT model
fn_datahmm_train=./data/produced/ds76__datahmm__all.txt
fn_modelhmm=./model/ds76__modelhmm__all.txt
fn_predicthmm=./predict/ds76__predicthmm__all.txt
./bin/trainhmm -s 1.4 -p 1 -e 0.001 -m 1 -d , ${fn_datahmm_train} ${fn_modelhmm} ${fn_predicthmm}
# trained model LL=   2536.6008395 (   2536.6008395), AIC=5193.201679, BIC=5585.468469, RMSE=0.403359 (0.403359), Acc=0.766262 (0.766262)
# timing: overall 0.000000 seconds, read 0.009247, fit 0.023005, predict 0.007607


#
# Try Elo UI K, DS76
#

fn_data_train=./data/produced/ds76__data__all.txt
fn_data_predict=./data/produced/ds76__data__all.txt
fn_result=./result/ds76__result__all.txt
fn_voc_student=./data/produced/ds76__voc_student.txt
fn_voc_skill=./data/produced/ds76__voc_HF.txt
fn_voc_item=./data/produced/ds76__voc_item.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.4 fit.objective $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.3582755
# 
# $value
# [1] 2639.463
# 
# $counts
# function gradient
#       15        4
# 
# $convergence
# [1] 0
# 
# $message
# NULL
# 
# Time difference of 0.009812117 secs
fn_result=./result/ds76__result__all__EloUI_K__obj.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.3582755 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.4139422 0.7452978 0.7030052
cat ${fn_result}
# fit__accuracy   0.745297805642633
# fit__rmse       0.413942211960866
# fit__auc        0.70300519238297



Rscript ./code/fit_evaluate_EloUI_K.R 0.4 fit.gradient $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.3701644
# 
# $value
# [1] 2639.584
# 
# $counts
# function gradient
#       55        5
# 
# $convergence
# [1] 0
# 
# $message
# NULL
# 
# Time difference of 0.03927803 secs
fn_result=./result/ds76__result__all__EloUI_K__gra.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.3701644 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.4139905 0.7466693 0.7034098
cat ${fn_result}
# fit__accuracy   0.746669278996865
# fit__rmse       0.413990499882166
# fit__auc        0.703409793653352

#
# Try Elo UI K ui
#

Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4 0.4 fit.objective $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.2618898 0.4426819
# 
# $value
# [1] 2633.754
# 
# $counts
# function gradient
#       19        6
# 
# $convergence
# [1] 0
# 
# $message
# NULL
# 
# Time difference of 0.03109002 secs
fn_result=./result/ds76__result__all__EloUI_K_ui__opt.txt
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.2618898 0.4426819 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.413746 0.7443182 0.7071527
cat ${fn_result}
# fit__accuracy   0.744318181818182
# fit__rmse       0.413746009819593
# fit__auc        0.707152663789502

Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4 0.4 fit.gradient $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.2603241 0.4517278
# 
# $value
# [1] 2633.783
# 
# $counts
# function gradient
#       69        7
# 
# $convergence
# [1] 0
# 
# $message
# NULL
# 
# Time difference of 0.04015899 secs
fn_result=./result/ds76__result__all__EloUI_K_ui__gra.txt
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.2603241 0.4517278 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.4137828 0.7437304 0.7073585
cat ${fn_result}
# fit__accuracy   0.743730407523511
# fit__rmse       0.413782769540073
# fit__auc        0.707358459455992

