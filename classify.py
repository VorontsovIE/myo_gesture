import numpy
import sklearn
from sklearn import svm
from sklearn.tree import DecisionTreeClassifier
from sklearn import neighbors
from sklearn import preprocessing
from sklearn.multiclass import OneVsOneClassifier
from sklearn.multiclass import OneVsRestClassifier
from sklearn import linear_model
from threading import Lock
import pickle
import urllib.parse
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
import os.path

model_save_filename = 'sgd_params.bin'

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

classifier = None
lock = Lock()
def predict(query):
    lock.acquire()
    try:
        return classifier.predict(numpy.array([query]))[0]
    finally:
        lock.release()

def partial_fit(query, letter):
    lock.acquire()
    try:
        classifier.partial_fit(numpy.array([query]), numpy.array([letter]), classes=all_letters)
    finally:
        lock.release()

def save_classfier(filename):
    lock.acquire()
    try:
        with open(filename, 'wb') as fw:
            pickle.dump(classifier, fw)
    finally:
        lock.release()

def load_classfier(filename):
    global classifier
    lock.acquire()
    try:
        with open(filename, 'rb') as f:
            classifier = pickle.load(f)
    finally:
        lock.release()
# Web server

if os.path.isfile(model_save_filename):
    load_classfier(model_save_filename)
    print('Model loaded')
else:
    # train = read_train_csv('train.tsv')
    # scaler = preprocessing.StandardScaler().fit(train['data'])
    # classifier = OneVsOneClassifier(sklearn.svm.LinearSVC(penalty='l1', dual=False))
    classifier = sklearn.linear_model.SGDClassifier()
    # classifier = sklearn.svm.LinearSVC(penalty='l1', dual=False)
    # classifier = sklearn.neighbors.KNeighborsClassifier(p=1, n_neighbors=3)
    # classifier = DecisionTreeClassifier(random_state=13)
    # classifier.fit( scaler.transform(train['data']), train['labels'])
    all_letters = numpy.array([chr(i) for i in range(ord('a'), ord('z')+1)])
    # for i in range(1):
    #     classifier.partial_fit( train['data'], train['labels'], classes=all_letters)
    # classifier.fit(train['data'][0::2], train['labels'][0::2])
# for real, predicted in zip(train['labels'][1::2], classifier.predict(train['data'][1::2])):
#     print(real, predicted)

# to_predict = read_unlabeled_csv('unlabbeled.tsv')
# for predicted in classifier.predict(scaler.transform(to_predict)):
#     print(predicted)

# for predicted in classifier.predict(to_predict):
#     print(predicted)




letter_to_fit = None

class S(BaseHTTPRequestHandler):
    def vector_from_uri(self, qs):
        if qs == None or len(qs) == 0:
            self.send_response(400)
            self.end_headers()
        return json.loads(qs[0])

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

    def return_ok(self, msg='ok\n'):
        self._set_headers()
        self.wfile.write(bytes(msg, "utf8"))

    def do_GET(self):
        global letter_to_fit
        uri = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(uri.query)
        if len(params.keys()) != 1:
            self.send_response(400)
            self.end_headers()
            return
        pseudo_endpoint = list(params.keys())[0]
        if pseudo_endpoint == 'predict':
            query = self.vector_from_uri( params.get('predict') )
            if query:
                message = predict(query)
                print(message)
                self.return_ok(msg=message)
        elif pseudo_endpoint == 'learn':
            query = self.vector_from_uri( params.get('learn') )
            if query:
                if letter_to_fit and ('a' <= letter_to_fit <= 'z'):
                    partial_fit(query, letter_to_fit)
                    print(query, '<--', letter_to_fit)
                self.return_ok()
        elif pseudo_endpoint == 'set_letter':
            letter_to_fit = str.lower(params.get('set_letter')[0])
            if letter_to_fit == '.':
                print('Save model')
                save_classfier(model_save_filename)
            self.return_ok()


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