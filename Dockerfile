FROM alpine:3.7

# Based on https://github.com/tatsushid/docker-alpine-py3-tensorflow-jupyter/blob/master/Dockerfile
# Changes:
# - Bumping versions of Bazel and Tensorflow
# - Add -Xmx to the Java params when building Bazel
# - Disable TF_GENERATE_BACKTRACE and TF_GENERATE_STACKTRACE

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV LOCAL_RESOURCES 2048,.5,1.0
ENV BAZEL_VERSION 0.10.0
RUN apk add --no-cache python3 python3-tkinter py3-numpy py3-numpy-f2py freetype libpng libjpeg-turbo imagemagick graphviz git
RUN apk add --no-cache --virtual=.build-deps \
        bash \
        cmake \
        curl \
        freetype-dev \
        g++ \
        libjpeg-turbo-dev \
        libpng-dev \
        linux-headers \
        make \
        musl-dev \
        openblas-dev \
        openjdk8 \
        patch \
        perl \
        python3-dev \
        py-numpy-dev \
        rsync \
        sed \
        swig \
        zip \
    && cd /tmp \
    && pip3 install --no-cache-dir wheel \
    && $(cd /usr/bin && ln -s python3 python)

# Bazel download
RUN curl -SLO https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip \
    && mkdir bazel-${BAZEL_VERSION} \
    && unzip -qd bazel-${BAZEL_VERSION} bazel-${BAZEL_VERSION}-dist.zip

# Bazel install
RUN cd bazel-${BAZEL_VERSION} \
    && sed -i -e 's/-classpath/-J-Xmx8192m -J-Xms128m -classpath/g' scripts/bootstrap/compile.sh \
    && bash compile.sh \
    && cp -p output/bazel /usr/bin/

# Download Tensorflow
ENV TENSORFLOW_VERSION 1.7.0
RUN cd /tmp \
    && curl -SL https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERSION}.tar.gz \
        | tar xzf -

# Build Tensorflow
RUN cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && : musl-libc does not have "secure_getenv" function \
    && sed -i -e '/JEMALLOC_HAVE_SECURE_GETENV/d' third_party/jemalloc.BUILD \
    && sed -i -e '/define TF_GENERATE_BACKTRACE/d' tensorflow/core/platform/default/stacktrace.h \
    && sed -i -e '/define TF_GENERATE_STACKTRACE/d' tensorflow/core/platform/stacktrace_handler.cc \
    && PYTHON_BIN_PATH=/usr/bin/python \
        PYTHON_LIB_PATH=/usr/lib/python3.6/site-packages \
        CC_OPT_FLAGS="-march=native" \
        TF_NEED_JEMALLOC=1 \
        TF_NEED_GCP=0 \
        TF_NEED_HDFS=0 \
        TF_NEED_S3=0 \
        TF_ENABLE_XLA=0 \
        TF_NEED_GDR=0 \
        TF_NEED_VERBS=0 \
        TF_NEED_OPENCL=0 \
        TF_NEED_CUDA=0 \
        TF_NEED_MPI=0 \
        bash configure
RUN cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && bazel build -c opt --local_resources ${LOCAL_RESOURCES} //tensorflow/tools/pip_package:build_pip_package
RUN cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
RUN cp /tmp/tensorflow_pkg/tensorflow-${TENSORFLOW_VERSION}-cp36-cp36m-linux_x86_64.whl /root

# Make sure it's built properly
RUN pip3 install --no-cache-dir /root/tensorflow-${TENSORFLOW_VERSION}-cp36-cp36m-linux_x86_64.whl \
    && python3 -c 'import tensorflow'

RUN echo -e '@edge http://nl.alpinelinux.org/alpine/edge/main' \
    >> /etc/apk/repositories

RUN apk add --update --no-cache \
        python3 py2-pip py3-numpy \
        build-base openblas-dev unzip wget cmake libjpeg libjpeg-turbo-dev libpng-dev jasper-dev tiff-dev libwebp-dev clang-dev linux-headers python3-dev

RUN mkdir /data && \
        mkdir /conf && \
        mkdir /bootstrap && \
        rm /usr/bin/python && \
        ln -s /usr/bin/python3.6 /usr/bin/python

RUN pip3 install --upgrade pip && \
        pip3 install --upgrade argparse numpy

ENV CC /usr/bin/clang
ENV CXX /usr/bin/clang++
ENV OPENCV_VERSION 3.4.4

RUN mkdir /opt && cd /opt && \
        wget https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
        unzip ${OPENCV_VERSION}.zip && \
        rm -rf ${OPENCV_VERSION}.zip

RUN mkdir -p /opt/opencv-${OPENCV_VERSION}/build && \
        cd /opt/opencv-${OPENCV_VERSION}/build && \
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
                -D PYTHON3_EXECUTABLE=/usr/bin/python \
                -D PYTHON3_INCLUDE_DIR=/usr/include/python3.6m/ \
                -D PYTHON3_LIBRARY=/usr/lib/libpython3.so \
                -D PYTHON_LIBRARY=/usr/lib/libpython3.so \
                -D PYTHON3_PACKAGES_PATH=/usr/lib/python3.6/site-packages/ \
                -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/lib/python3.6/site-packages/numpy/core/include/ \
                .. && \
                make VERBOSE=1 && \
                make && \
                make install

 RUN cd /usr/python && \
        python setup.py develop && \
        rm -rf /opt/opencv-${OPENCV_VERSION}/

RUN apk del --purge \
        python3-dev libjpeg-turbo-dev libpng-dev jasper-dev tiff-dev libwebp-dev clang-dev linux-headers build-base openblas-dev unzip wget cmake

RUN apk add --update --no-cache \
        libpng libwebp tiff jasper libstdc++

RUN rm -rf /bazel* && \
	rm -rf /tmp/tensorflow* && \
	rm  /root/tensorflow-* && \
	rm -rf /root/.cache/bazel/ 

RUN echo -e 'http://nl.alpinelinux.org/alpine/edge/testing' \
	>> /etc/apk/repositories && \
    apk update && \
    apk add --update --no-cache \
	clang hdf5 hdf5-dev && \ 
    pip install pillow keras sklearn 

