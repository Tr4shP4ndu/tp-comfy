# Specify the base image
FROM nvidia/cuda:12.6.1-runtime-ubuntu22.04 AS base

# For amd64 architecture
FROM base AS base-amd64

ENV NV_CUDNN_VERSION=9.3.0.75-1
ENV NV_CUDNN_PACKAGE_NAME=libcudnn9-cuda-12
ENV NV_CUDNN_PACKAGE=libcudnn9-cuda-12=${NV_CUDNN_VERSION}

# For arm64 architecture
FROM base AS base-arm64

ENV NV_CUDNN_VERSION=9.3.0.75-1
ENV NV_CUDNN_PACKAGE_NAME=libcudnn9-cuda-12
ENV NV_CUDNN_PACKAGE=libcudnn9-cuda-12=${NV_CUDNN_VERSION}

# Select the appropriate architecture
ARG TARGETARCH
FROM base-${TARGETARCH}

LABEL maintainer="NVIDIA CORPORATION <cudatools@nvidia.com>"
LABEL com.nvidia.cudnn.version="${NV_CUDNN_VERSION}"

# Prevent interactive prompts during the build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London

# Install cuDNN
RUN apt-get update && apt-get install -y --no-install-recommends \
    ${NV_CUDNN_PACKAGE} \
    && apt-mark hold ${NV_CUDNN_PACKAGE_NAME} \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.12 and development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
    git \
    build-essential \
    curl \
    ca-certificates \
    aria2 \
    gnupg \
    lsb-release \
    tzdata \
    && add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.12 python3.12-distutils python3.12-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic links for Python
RUN ln -sf /usr/bin/python3.12 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.12 /usr/bin/python

# Download and install pip using get-pip.py
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && python3.12 /tmp/get-pip.py \
    && rm /tmp/get-pip.py

# Upgrade pip and setuptools
RUN python3.12 -m pip install --upgrade pip setuptools

# Install PyTorch and torchvision
RUN pip3 install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    -f https://download.pytorch.org/whl/cu124

# Optional: Install Python packages from a requirements file
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Set default command to Python
CMD ["python3"]
