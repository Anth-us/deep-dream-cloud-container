# Deep Dream Cloud Container

Originally forked from [CloudDream](https://github.com/VISIONAI/clouddream).

That project creates a neat Docker-based service for computing Deep Dream images and videos, with a slick HTTP preview.

This project has a simpler purpose: To provide a Python programming platform for computing [Deep Dream](https://en.wikipedia.org/wiki/DeepDream) images using [Caffe](http://caffe.berkeleyvision.org/) with the [Bat Country](https://github.com/jrosebr1/bat-country) Python library.

The target host is [AWS EC2 instances](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using_cluster_computing.html) with GPU processing, using [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) to access [CUDA](http://www.nvidia.com/object/cuda_home_new.html).
