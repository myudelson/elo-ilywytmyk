
# Elo, I love you, won't you tell me your name

Michael Yudelson, ACT, Inc., [:email:](mailto:myudelson@gmail.com)

Paper persented at EC-TEL, 2019 in Delft, Netherlands, 16-19 September 2019

## Abstract

Elo is a rating schema used for tracking player level in individual and, sometimes, team sports, most notably – in chess. Also, it has  found use in the area of tracking learner proficiency. Similar to the 1PL IRT (Rasch), Elo rating schema could be extended to serve the most demanding needs of learner skill tracking. Elo's advantage is that it has fewer parameters. However, the computational efficiency side of the search for the best-fitting values of these parameters is rarely discussed. In this paper, we are focusing on questions of implementing Elo and a gradient-based approach to find optimal values of its parameters. Also, we compare several variants of Elo to learning modeling approaches like Bayesian Knowledge Tracing. Our results show that the use of analytical gradients results in computational and, sometimes, statistical fit improvements on small and large datasets alike.

Paper: [PDF](./paper/2019ECTEL_Yudelson_Elo.pdf), slides: [PDF](./paper/2019_EC-TEL_Yudelson_slides.pdf).

## Notes

Repository contains the code that was used to write the paper. The data is not part of the repo but can be obtained from the links given below.


## Structure of the repository

The following **data tags** are used throughout file names to denote datasets.

- `ds76` – Geometry Area (1996-97) data.
- `ds392` – Geometry Area Study.
- `a89` – KDD Cup 2010, Algebra Course 2008-209 from Carnegie Learning, Challenge Data Set A.
- `b89` – KDD Cup 2010, Bridge to Algebra Course 2008-209 from Carnegie Learning , Challenge Data Set A.


Folder structure.

- README.md – this file.
- actnext-cdmx-elo-ilywytmyk.Rproj – RStudio project file.
- `make_elo_ilywytmyk_{datatag}.sh` – a central make file containing shell-script model-computing code for the **data tag** dataset.
- `bin` – compiled binary files.
- `code` – source code and scripts.
	- `code/hmm` – HMM-scalable command line tool, cf. [http://yudelson.info/hmm-scalable/](http://yudelson.info/hmm-scalable/).
	- `code/liblinear` – a modded LIBLINEAR utility with mixed-effect binomial regression solver added, cf. [https://github.com/IEDMS/liblinear-mixed-models](https://github.com/IEDMS/liblinear-mixed-models).
- `data/source` – Source data – files downloaded from LearnSphere and KDD Cup 2010 go here. The data is not included with the repository. KDD Cup 2010 data can be obtained from [http://pslcdatashop.org/KDDCup/](http://pslcdatashop.org/KDDCup/) (registration required). LearnSphere data can be obtained from [http://pslcdatashop.web.cmu.edu](http://pslcdatashop.web.cmu.edu ) (registration required):
	- `ds76` [https://pslcdatashop.web.cmu.edu/DatasetInfo?datasetId=76](https://pslcdatashop.web.cmu.edu/DatasetInfo?datasetId=76) is available automatically.
	- `ds392` [https://pslcdatashop.web.cmu.edu/DatasetInfo?datasetId=392](https://pslcdatashop.web.cmu.edu/DatasetInfo?datasetId=392) requires approval of data owner.

- `data/produced` – Files produced from the source data files.
- `dump` – Data dumps for restoring later in the middle of some computational process.
- `model` – Modeling result files. We added a `__to_compare` suffix to all model files so that you can verify your fitting results.
- `predict` – Prediction results. We have removed prediction results of the two larger datasets to conserve space. We have added a `__to_compare` suffix to prediction files so that you can verify your fitting results.
- `result` – Files with model-fitting accuracy are saved here.
- `temp` – Intended for temporary files
