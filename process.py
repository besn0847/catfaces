# import the necessary packages
from skimage.measure import compare_ssim
import argparse
import imutils
import cv2
from os import listdir
from os.path import isfile, join

ap = argparse.ArgumentParser()
ap.add_argument("-r", "--reference", required=True,
	help="reference image file")
ap.add_argument("-s", "--source", required=True,
	help="directory where to find all images to be processed")
ap.add_argument("-t", "--target", required=True,
	help="directory where to extract all deltas")
args = vars(ap.parse_args())

PREFIX = "extract"
SRCDIR = args["source"]
DSTDIR = args["target"]
REFERE = args["reference"]

IMGFILES = [f for f in listdir(SRCDIR) if isfile(join(SRCDIR, f))]

imageR = cv2.imread(REFERE)
count = 0

for f in IMGFILES:
	print("Processing:",join(SRCDIR, f))
	imageD = cv2.imread(join(SRCDIR, f))	

	grayA = cv2.cvtColor(imageR, cv2.COLOR_BGR2GRAY)
	grayB = cv2.cvtColor(imageD, cv2.COLOR_BGR2GRAY)

	(score, diff) = compare_ssim(grayA, grayB, full=True)
	diff = (diff * 255).astype("uint8")
	print("SSIM: {}".format(score))

	thresh = cv2.threshold(diff, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)[1]
	cnts = cv2.findContours(thresh.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
	cnts = imutils.grab_contours(cnts)

	for c in cnts:
		(x, y, w, h) = cv2.boundingRect(c)
		if w > 100 and h > 100:
			count += 1
			#cv2.rectangle(imageD, (x, y), (x + w, y + h), (0, 0, 255), 2)
			print(join(DSTDIR,PREFIX+str(count)+".jpg"))
			cv2.imwrite(join(DSTDIR,PREFIX+str(count)+".jpg"), imageD[y:y+h, x:x+w])

