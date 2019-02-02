import cv2
import pickle
import argparse
import numpy as np
import tensorflow as tf
from PIL import Image
from keras.models import load_model
from keras.models import model_from_json
from keras.models import Sequential
from keras.layers.convolutional import Conv2D
from keras.layers.convolutional import MaxPooling2D
from keras.layers.core import Activation
from keras.layers.core import Flatten
from keras.layers.core import Dense
from keras.optimizers import Adam
from keras.preprocessing.image import img_to_array
from flask import Flask, render_template, request

app = Flask(__name__)
model = None

def init():
        print("Loading neural model")
        INPUT_MODEL_WEIGHTS = "/conf/cat_neural_model.h5"
        INPUT_MODEL_CONFIG = "/conf/cat_model_architecture.json" 
        INPUT_MODEL_CLASSES = "/conf/cat_labels.bin" 

        global graph
        graph = tf.get_default_graph() 
        #with open(INPUT_MODEL_CONFIG, 'r') as f:
        #       model = model_from_json(f.read())
        global model
        model = model_from_json(open(INPUT_MODEL_CONFIG, 'r').read())
        model.load_weights(INPUT_MODEL_WEIGHTS)

        global lb
        lb = pickle.loads(open(INPUT_MODEL_CLASSES, "rb").read())

@app.route('/process', methods=['POST','PUT'])      
def upload_file():                            
        file = request.files['image_file'] 
        image = cv2.imdecode(np.fromstring(file.read(), np.uint8), cv2.IMREAD_UNCHANGED)

        image = cv2.resize(image, (96, 96))
        image = image.astype("float") / 255.0
        image = img_to_array(image)
        image = np.expand_dims(image, axis=0)

        with graph.as_default():
            probas = model.predict(image)[0]

        idx = np.argmax(probas)
        label = lb.classes_[idx]
        proba = probas[idx]

        output = "Cat: " + label + " with probability:" + str(proba) + "\n"
        return output

if __name__ == '__main__':
        init()
        app.run(host='0.0.0.0')
