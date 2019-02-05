## CatFaces - Train a neural network to detect cat fur 
This repo includes the source code to train a neural network to detect my cats name based on their fur. This approach can be applied to any monitoring camera with limited and recurrent traffic detected.

There are 4 main steps : 
 1. Prepare the dataset extracted from a video monitoring file created through motion detection ;
 2. Train & export the deep neural network to be able associate cat fur to a cat name (this requires a GPU)
 3. Test the neural network against a new dataset through command line
 4. Create a microservice able to respond to REST API call to detect a cat in a picture 

### 1. Prepare the dataset
 The dataset is based on a video monitoring file which is built from the Motion software. Each frame is extracted in a folder ('images/'); for example in the picture below #1 and #2 are frames directly extracted from the video file through the following command line : 

> ffmpeg -i cat.avi cat%4d.jpg

Then a reference frame is chosen where there is no motion object : here frame #1 is our 'reference.jpg' file which will be used to detect any motion objects. The masking techniques are applied (images #3 and #4) to detect pixel difference between the 2 pictures and only large deltas are kept. This leads to picture #5 detecting the cat itself; it is then easy to extract the sample as in #6.

Batch processing can be achieved through this command line:
> python process.py -r reference.jpg -s images/ -t extract/

Have a look to this repository to check the extracts thru this process : https://github.com/besn0847/catfaces/tree/master/dataset/mikado

Finally, you have to classify one by one each thumbnail in the dataset folder with the name of the animal. The dataset is ready for training.

![Data extraction process](https://github.com/besn0847/catfaces/raw/master/data_extraction.png)
### 2. Train & export the deep neural network
Next step is to train the network and this is better achieved using a GPU unless wanting to wait for long hours. Simply launch the following command line (use the Docker image from https://cloud.docker.com/u/besn0847/repository/docker/besn0847/x86-tfcv2)

> python train_cnn.py -d dataset/ 

This will result into three files :

 - **cat_labels.bin** : the cat name label file
 - **cat_model_architecture.json** : the neural network architecture
 - **cat_neural_model.h5** : the neural network trained weights

A minimum 100+ pictures per animal is required as well as some thumbnails for false positives classified as 'nocat'.

### 3. Test your trained network
You can easily test your trained network with the following command line :

> python cnn.py -m cat_model_architecture.json -w cat_neural_model.h5 -l cat_labels.bin -i testset/bagguy/extract001.jpg

The result looks like :

> Cat: bagguy with probability: 0.9976345

We are now ready to proceed to expose the algorithm thru a webservice.

### 4. Expose the model thru a webservice
Simply use the startup script to launch a microservice  thru :

> docker run -ti --name catfaces -v ./Volumes/catfaces/:/conf/ -p 5000:5000 --entrypoint /startup.sh catfaces

And you can simply curl the image to get the same result :

> curl -X PUT -F image_file=@testset/bagguy/extract001.jpg
 http://localhost:5000/process

Result will be the same as in section 3.

 ### 5. Acknowledgment
 Most of the ideas and code is coming from [Adrian Rosebrock](https://twitter.com/PyImageSearch) at https://www.pyimagesearch.com/. I learnt a lot from your outstanding websites and tutorials. Merci ! 
