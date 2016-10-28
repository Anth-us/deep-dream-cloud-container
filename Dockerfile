FROM ubuntu:14.04

ENV PYTHONPATH /opt/caffe/python

# Add caffe binaries to path
ENV PATH $PATH:/opt/caffe/.build_release/tools

# Get dependencies
RUN apt-get update && apt-get install -y \
  bc \
  cmake \
  curl \
  gcc-4.6 \
  g++-4.6 \
  gcc-4.6-multilib \
  g++-4.6-multilib \
  gfortran \
  git \
  libprotobuf-dev \
  libleveldb-dev \
  libsnappy-dev \
  libopencv-dev \
  libboost-all-dev \
  libhdf5-serial-dev \
  liblmdb-dev \
  libjpeg62 \
  libfreeimage-dev \
  libatlas-base-dev \
  pkgconf \
  protobuf-compiler \
  python-dev \
  python-pip \
  unzip \
  wget \
  python-numpy \
  python-scipy \
  python-pandas \
  python-sympy \
  python-nose

# Add pin priority to some graphical packages to stop them installing and borking the build
RUN echo "Package: xserver-xorg*\nPin: release *\nPin-Priority: -1" >> /etc/apt/preferences
RUN echo "Package: unity*\nPin: release *\nPin-Priority: -1" >> /etc/apt/preferences
RUN echo "Package: gnome*\nPin: release *\nPin-Priority: -1" >> /etc/apt/preferences

# Install CUDA headers for compiling things that use CUDA.
RUN wget --progress=dot:giga https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda-repo-ubuntu1404-8-0-local_8.0.44-1_amd64-deb
# This is a separate step so that we can cache the CUDA download in a layer,
# because otherwise working on this was a little painful.
RUN dpkg -i cuda-repo-ubuntu1404-8-0-local_8.0.44-1_amd64-deb && \
  apt-get update && \
  apt-get -y install cuda

# Use gcc 4.6
RUN update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-4.6 30 && \
  update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-4.6 30 && \
  update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 30 && \
  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.6 30

# Clone the Caffe repo
RUN cd /opt && git clone https://github.com/BVLC/caffe.git

# Glog
RUN cd /opt && wget https://github.com/google/glog/archive/v0.3.4.tar.gz && \
  tar zxvf v0.3.4.tar.gz && \
  cd /opt/glog-0.3.4 && \
  ./configure && \
  make && \
  make install

# Workaround for error loading libglog:
#   error while loading shared libraries: libglog.so.0: cannot open shared object file
# The system already has /usr/local/lib listed in /etc/ld.so.conf.d/libc.conf, so
# running `ldconfig` fixes the problem (which is simpler than using $LD_LIBRARY_PATH)
# TODO: looks like this needs to be run _every_ time a new docker instance is run,
#       so maybe LD_LIBRARY_PATh is a better approach (or add call to ldconfig in ~/.bashrc)
RUN ldconfig

# Gflags
RUN cd /opt && \
  wget https://github.com/schuhschuh/gflags/archive/master.zip && \
  unzip master.zip && \
  cd /opt/gflags-master && \
  mkdir build && \
  cd /opt/gflags-master/build && \
  export CXXFLAGS="-fPIC" && \
  cmake .. && \
  make VERBOSE=1 && \
  make && \
  make install

# Build Caffe core
RUN cd /opt/caffe && \
    for req in $(cat python/requirements.txt) pydot; do pip install $req; done && \
    mkdir build && cd build && \
    cmake -DUSE_CUDNN=1 .. && \
    make -j"$(nproc)"

# Add ld-so.conf so it can find libcaffe.so
#ADD caffe-ld-so.conf /etc/ld.so.conf.d/

# Run ldconfig again (not sure if needed)
RUN ldconfig

RUN cd /opt/caffe && \
  (pip install pyyaml)

# Prerequisite for the next step.
RUN cd /opt/caffe && \
  (pip install Cython)

# Install python deps
RUN cd /opt/caffe && \
  (pip install -r python/requirements.txt)

# Numpy include path hack - github.com/BVLC/caffe/wiki/Setting-up-Caffe-on-Ubuntu-14.04
#RUN NUMPY_EGG=`ls /usr/local/lib/python2.7/dist-packages | grep -i numpy` && \
#  ln -s /usr/local/lib/python2.7/dist-packages/$NUMPY_EGG/numpy/core/include/numpy /usr/include/python2.7/numpy

# Build Caffe python bindings.
RUN cd /opt/caffe/build && \
  cmake -DUSE_CUDNN=1 .. && \
  make pycaffe

# Make + run tests
RUN cd /opt/caffe/build && make test && make runtest

#Download GoogLeNet
RUN /opt/caffe/scripts/download_model_binary.py /opt/caffe/models/bvlc_googlenet

# Install Bat Country
RUN cd /opt/caffe && \
  (pip install bat-country)

# Install CUDArray
RUN git clone https://github.com/andersbll/cudarray.git && \
  cd cudarray && \
  make && \
  make install && \
  python setup.py install

# Install DeepPy
RUN git clone https://github.com/andersbll/deeppy.git && \
  cd deeppy && \
  python setup.py install
