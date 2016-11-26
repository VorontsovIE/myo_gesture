import numpy
import sklearn
from sklearn import svm
from sklearn.tree import DecisionTreeClassifier

def read_train_csv(filename):
	with open(filename) as f:
		data = []
		labels = []
		for line in f.readlines():
			infos = line.split()
			features = [float(x) for x in infos[0:-1]]
			label = infos[-1]
			data.append(features)
			labels.append(label)
		return {'data': numpy.array( data ), 'labels': numpy.array(labels)}

def read_unlabeled_csv(filename):
	with open(filename) as f:
		data = []
		for line in f.readlines():
			features = [float(x) for x in line.split()]
			data.append(features)
		return numpy.array( data )

train = read_train_csv('train.tsv')
# classifier = sklearn.svm.LinearSVC()
classifier = DecisionTreeClassifier(random_state=13)
classifier.fit(train['data'], train['labels'])
# classifier.fit(train['data'][0::2], train['labels'][0::2])
# for real, predicted in zip(train['labels'][1::2], classifier.predict(train['data'][1::2])):
# 	print(real, predicted)

to_predict = read_unlabeled_csv('unlabbeled.tsv')
for predicted in classifier.predict(to_predict):
	print(predicted)
