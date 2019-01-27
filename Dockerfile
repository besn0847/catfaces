FROM balenalib/rpi-raspbian:stretch
MAINTAINER franck@besnard.mobi

RUN apt-get update && \
	apt-get install -y --force-yes --no-install-recommends \
		cmake wget unzip clang libclang-dev && \
	apt-get install -y --force-yes --no-install-recommends \
		build-essential pkg-config && \
	apt-get install -y --force-yes --no-install-recommends \
		libjpeg-dev libtiff5-dev libjasper-dev libpng12-dev && \
	apt-get install -y --force-yes --no-install-recommends \
		libavcodec-dev libavformat-dev libswscale-dev libv4l-dev && \
	apt-get install -y --force-yes --no-install-recommends \
		libxvidcore-dev libx264-dev && \
	apt-get install -y --force-yes --no-install-recommends \
		libgtk2.0-dev libgtk-3-dev &&\
	apt-get install -y --force-yes --no-install-recommends \
		libatlas-base-dev gfortran && \
	apt-get install -y --force-yes --no-install-recommends \
		python3 python3-pip python3-dev && \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir /data && \
	mkdir /conf && \
	mkdir /bootstrap && \
	ln -s /usr/bin/python3.5 /usr/bin/python

RUN pip3 install --upgrade pip && \
	pip3 install --upgrade argparse numpy pillow tensorflow keras sklearn 

ENV CMAKE_C_COMPILER /usr/bin/clang
ENV CMAKE_CXX_COMPILER /usr/bin/clang++
ENV CMAKE_MAKE_PROGRAM /usr/bin/cmake
ENV OPENCV_VERSION 3.4.4

RUN mkdir /opencv && \
	cd /opencv && \
	wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
	wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
	unzip opencv.zip && \
	unzip opencv_contrib.zip && \
	rm opencv.zip opencv_contrib.zip && \
	cd opencv-${OPENCV_VERSION} && \
	mkdir build

RUN cd /opencv/opencv-${OPENCV_VERSION}/build && \
	cmake \
		-D CMAKE_BUILD_TYPE=RELEASE \
		-D CMAKE_INSTALL_PREFIX=/usr/ \
		-D WITH_FFMPEG=NO \
		-D WITH_IPP=NO \
		-D WITH_OPENEXR=NO \
		-D WITH_TBB=YES \
		-D BUILD_EXAMPLES=NO \
		-D BUILD_ANDROID_EXAMPLES=NO \
		-D INSTALL_PYTHON_EXAMPLES=NO \
		-D BUILD_DOCS=NO \
		-D BUILD_opencv_python2=NO \
		-D BUILD_opencv_python3=ON \
		-D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib-3.4.4/modules \
		-D PYTHON3_EXECUTABLE=/usr/bin/python3 \
		-D PYTHON3_INCLUDE_DIR=/usr/include/python3.5m/ \
		-D PYTHON3_LIBRARY=/usr/lib/arm-linux-gnueabihf/libpython3.5m.so \
		-D PYTHON_LIBRARY=/usr/lib/arm-linux-gnueabihf/libpython3.5m.so \
		-D PYTHON3_PACKAGES_PATH=/usr/local/lib/python3.5/dist-packages/ \
		-D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/lib/python3.5/dist-packages/numpy/core/include/ \
		.. && \
	make VERBOSE=1 && \
	make && \
	make install && \
	cd /usr/python && \
	python setup.py develop

RUN rm -rf /opencv/ && \
	apt-get update && \
	apt-get remove -y --force-yes \
		cmake wget unzip clang libclang-dev \
		python3-dev \
		build-essential pkg-config \
		libjpeg-dev libtiff5-dev libjasper-dev libpng12-dev \
		libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
		libxvidcore-dev libx264-dev\ 
		libgtk2.0-dev libgtk-3-dev \
		libatlas-base-dev gfortran \
		python3-dev	&& \
	apt-get install -y --force-yes --no-install-recommends \
		libatlas3-base \
		libjpeg62-turbo libtiff5 libjasper-runtime libpng12-0 \
		libxvidcore4 libx264-148 libgtk2.0-0 libgtk-3-0 \
		libavcodec57 libavformat57 libswscale4 libv4l-0	&& \
	apt-get autoremove && \
	rm -rf /var/lib/apt/lists/*
