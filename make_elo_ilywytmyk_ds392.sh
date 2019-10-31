#
#
# 'Elo, I love you, won't you tell me your K (ilywytmyk)
#
#

#
# DataShop dataset 392, Geometry Area
#
time unzip -q -c ./data/source/ds392_student_step_2019_0224_162040.zip ds392_student_step_All_Data_1310_2018_0407_051724.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) { print "score","student","item","HF","opp"; next;} skill=$35; gsub("~~", "~", skill); opp=$36; gsub("~~", "~", opp); skill=(skill=="")?".":(skill); opp=(opp=="")?"":(opp); print (($15=="correct")?1:0),$3,$5"__"$7,skill,opp;}' > data/produced/ds392__data__all.txt
# note, we remove rows missing skill labels
wc -l ./data/produced/ds392__data__all.txt
# 128493 ./data/produced/ds392__data__all.txt

time unzip -q -c ./data/source/ds392_student_step_2019_0224_162040.zip ds392_student_step_All_Data_1310_2018_0407_051724.txt | awk "-F\t" 'BEGIN{OFS="\t"} {if(NR==1) {next;} skill=$35; gsub("~~", "~", skill); opp=$36; gsub("~~", "~", opp); skill=(skill=="")?".":(skill); opp=(opp=="")?"":(opp); print (($15=="correct")?1:2),$3,$5"__"$7,skill,opp;}' > data/produced/ds392__datahmm__all.txt
wc -l ./data/produced/ds392__datahmm__all.txt
# 128492 ./data/produced/ds392__datahmm__all.txt

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
	 n=split($4,KK,"~");
	 for(i=1;i<=n;i++) {
  	 K[ KK[i] ]++;
  	 if(K[ KK[i] ]==1){
  		 nk++; 
  		 VK[ KK[i] ]=nk;
  	 }
	 }
 }END{
	 print "id","name" > "./data/produced/ds392__voc_student.txt"
	 for(u in VU) {
		 print VU[u],u > "./data/produced/ds392__voc_student.txt";
	 }
	 print "id","name" > "./data/produced/ds392__voc_item.txt"
	 for(i in VI) {
		 print VI[i],i > "./data/produced/ds392__voc_item.txt";
	 }
	 print "id","name" > "./data/produced/ds392__voc_HF.txt"
	 for(k in VK) {
		 print VK[k],k > "./data/produced/ds392__voc_HF.txt";
	 }
 }' ./data/produced/ds392__data__all.txt


# BKT
# BKT model
fn_datahmm_train=./data/produced/ds392__datahmm__all.txt
fn_modelhmm=./model/ds392__modelhmm__all.txt
fn_predicthmm=./predict/ds392__predicthmm__all.txt
./bin/trainhmm -s 1.4 -p 1 -e 0.001 -m 1 -d ~ ${fn_datahmm_train} ${fn_modelhmm} ${fn_predicthmm}
# trained model LL=  27893.3015515 (  14789.8317592), AIC=56178.603103, BIC=58092.273000, RMSE=0.240084 (0.328004), Acc=0.928929 (0.853602)
# timing: overall 0.000000 seconds, read 0.173246, fit 0.184221, predict 0.121494

#
# Try Elo UI K, ds392
#

fn_data_train=./data/produced/ds392__data__all.txt
fn_data_predict=./data/produced/ds392__data__all.txt
fn_result=./result/ds392__result__all.txt
fn_voc_student=./data/produced/ds392__voc_student.txt
fn_voc_skill=./data/produced/ds392__voc_HF.txt
fn_voc_item=./data/produced/ds392__voc_item.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.4 fit.objective $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 1.043116
# 
# $value
# [1] 27929.71
# 
# $counts
# function gradient
#       32        6
# 
# $convergence
# [1] 0
# 
# $message
# NULL
# 
# Time difference of 0.3036358 secs
fn_result=./result/ds392__result__all__EloUI_K__obj.txt
Rscript ./code/fit_evaluate_EloUI_K.R 1.043116 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.2416937 0.9299178 0.7888181
cat ${fn_result}
# fit__accuracy   0.929917815895153
# fit__rmse       0.241693652804538
# fit__auc        0.78881808337362

Rscript ./code/fit_evaluate_EloUI_K.R 0.4 fit.gradient $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.9380959
# 
# $value
# [1] 27956.59
# 
# $counts
# function gradient
#       58        5
# 
# $convergence
# [1] 0
# 
# $message
# NULL
# 
# Time difference of 0.4380469 secs
fn_result=./result/ds392__result__all__EloUI_K__gra.txt
Rscript ./code/fit_evaluate_EloUI_K.R 0.9380959 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.2419719 0.9298011 0.7873065
cat ${fn_result}
fit__accuracy   0.929801077109859
fit__rmse       0.241971866912876
fit__auc        0.78730647619846


#
# Try Elo UI K ui
#

Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4 0.4 fit.objective $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.4127849 1.5169027
# 
# $value
# [1] 27269.39
# 
# $counts
# function gradient
#       41        9
# 
# $convergence
# [1] 0
# 
# $message
# NULL
# 
# Time difference of 0.718111 secs
fn_result=./result/ds392__result__all__EloUI_K_ui__opt.txt
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4127849 1.5169027 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.2411712 0.9282835 0.8121008
cat ${fn_result}
# fit__accuracy   0.928283472901037
# fit__rmse       0.241171243046598
# fit__auc        0.812100783442751


Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4 0.4 fit.gradient $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# $par
# [1] 0.4188397 1.5332782
# 
# $value
# [1] 27269.76
# 
# $counts
# function gradient
#      126       11
# 
# $convergence
# [1] 0
# 
# $message
# NULL
# 
# Time difference of 1.0657 secs
fn_result=./result/ds392__result__all__EloUI_K_ui__gra.txt
Rscript ./code/fit_evaluate_EloUI_K_ui.R 0.4188397 1.5332782 predict $fn_data_train $fn_data_predict $fn_result $fn_voc_student $fn_voc_skill $fn_voc_item
# RMSE, ACC, ROC  0.2411714 0.9283224 0.8121504
cat ${fn_result}
# fit__accuracy   0.928322385829468
# fit__rmse       0.241171370361057
# fit__auc        0.812150390896619

