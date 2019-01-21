import cv2
import pickle
import argparse
import numpy as np
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

ap = argparse.ArgumentParser()
ap.add_argument("-m", "--model", required=True,
	help="json file with trained model to use")
ap.add_argument("-w", "--weights", required=True,
	help="h5 file with trained model to use")
ap.add_argument("-l", "--labels", required=True,
	help="image labels")
ap.add_argument("-i", "--image", required=True,
	help="image to analyse")
args = vars(ap.parse_args())

with open(args["model"], 'r') as f:
	model = model_from_json(f.read())

model .load_weights(args["weights"])
image = cv2.imread(args["image"])
lb = pickle.loads(open(args["labels"], "rb").read())

image = cv2.resize(image, (96, 96))
image = image.astype("float") / 255.0
image = img_to_array(image)
image = np.expand_dims(image, axis=0)

probas = model.predict(image)[0]

idx = np.argmax(probas)
label = lb.classes_[idx]
proba = probas[idx]

print("Cat: " + label + " with probability:" + str(proba))
