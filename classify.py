import numpy
import sklearn
from sklearn import svm
from sklearn.tree import DecisionTreeClassifier
from sklearn import neighbors
from sklearn import preprocessing
from sklearn.multiclass import OneVsOneClassifier
from sklearn.multiclass import OneVsRestClassifier

import urllib.parse
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

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
# scaler = preprocessing.StandardScaler().fit(train['data'])
classifier = OneVsOneClassifier(sklearn.svm.LinearSVC(penalty='l1', dual=False))
# classifier = sklearn.svm.LinearSVC(penalty='l1', dual=False)
# classifier = sklearn.neighbors.KNeighborsClassifier(p=1, n_neighbors=3)
# classifier = DecisionTreeClassifier(random_state=13)
# classifier.fit( scaler.transform(train['data']), train['labels'])
for i in range(1):
	classifier.fit( train['data'], train['labels'])
# classifier.fit(train['data'][0::2], train['labels'][0::2])
# for real, predicted in zip(train['labels'][1::2], classifier.predict(train['data'][1::2])):
# 	print(real, predicted)

# to_predict = read_unlabeled_csv('unlabbeled.tsv')
# for predicted in classifier.predict(scaler.transform(to_predict)):
# 	print(predicted)

# for predicted in classifier.predict(to_predict):
# 	print(predicted)

def predict(query):
	return classifier.predict(numpy.array([query]))[0]


# Web server


class S(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_GET(self):
        uri = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(uri.query)
        query_array = params.get('q')
        
        if query_array == None || len(query_array) == 0:
        	self.send_response(400)
        	self.end_headers()
        	return

        query = json.loads(query_array[0])
        message = predict(query)

        print(str(query) + " => " + message)

        self._set_headers()
        self.wfile.write(bytes(message, "utf8"))
        
def run(server_class=HTTPServer, handler_class=S, port=8000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print("Starting httpd...")
    httpd.serve_forever()

if __name__ == "__main__":
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()