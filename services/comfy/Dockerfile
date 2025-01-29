FROM pytorch/pytorch:2.4.1-cuda11.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1

# Install system dependencies and Python 3.12
RUN apt-get update && \
    apt-get install -y \
    git \
    build-essential \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    python3-opencv \
    libmupdf-dev \
    mupdf \
    mupdf-tools \
    libglib2.0-0 \
    wget \
    software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.12 python3.12-distutils python3.12-venv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Update alternatives to make Python 3.12 the default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    update-alternatives --set python3 /usr/bin/python3.12

# Install pip for Python 3.12
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

# Set environment variables
ENV ROOT=/comfy

# Clone the repository and install Python dependencies
RUN --mount=type=cache,target=/root/.cache/pip \
    git clone https://github.com/comfyanonymous/ComfyUI.git ${ROOT} && \
    cd ${ROOT} && \
    git checkout master && \
    git reset --hard 276f8fce9f5a80b500947fb5745a4dde9e84622d && \
    pip install -r requirements.txt && \
    pip install \
      gitpython \
      deepdiff \
      piexif \
      matplotlib \
      numexpr \
      omegaconf \
      frontend \
      PyOpenGL-accelerate \
      ffmpeg \
      dlib \
      insightface \
      numba

# Set working directory /comfy
WORKDIR ${ROOT}

# Copy other required files
COPY . /docker/

# Copy the python_packages.txt file into the container
COPY python_packages.txt ${ROOT}/

# Clone the repository and install Python dependencies from Custom Nodes
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r ${ROOT}/python_packages.txt

RUN chmod u+x /docker/entrypoint.sh && cp /docker/extra_model_paths.yaml ${ROOT}

# Set environment variables for the application
ENV NVIDIA_VISIBLE_DEVICES=all PYTHONPATH="${PYTHONPATH}:${PWD}" CLI_ARGS=""

# Expose port for the application
EXPOSE 7860

# Define entrypoint and default command
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD python -u main.py --listen --port 7860 ${CLI_ARGS}
