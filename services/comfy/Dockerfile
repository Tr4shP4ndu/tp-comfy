FROM pytorch/pytorch:2.4.1-cuda11.8-cudnn9-runtime

# Set non-interactive mode for Debian frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
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
    wget \
    software-properties-common \
    libssl-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    zlib1g-dev \
    libffi-dev \
    xz-utils \
    liblzma-dev \
    curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python 3.12 from source with SSL and LZMA support
RUN wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz && \
    tar -xf Python-3.12.0.tgz && \
    cd Python-3.12.0 && \
    ./configure --enable-optimizations --with-ensurepip=install \
        --with-lto --enable-shared \
        LDFLAGS="-Wl,-rpath=/usr/local/lib" && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf Python-3.12.0 Python-3.12.0.tgz

# Set Python 3.12 as default
RUN ln -sf /usr/local/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/local/bin/python3.12 /usr/bin/python

# Upgrade pip and install core dependencies
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install virtualenv

# Set environment variables
ENV ROOT=/comfy

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${ROOT} && \
    cd ${ROOT} && \
    git checkout master && \
    git reset --hard 079eccc92a82b16727f9ff88da613e8b1f078eae

# Install Python dependencies
COPY python_packages.txt ${ROOT}/

RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install -r ${ROOT}/requirements.txt && \
    python3 -m pip install -r ${ROOT}/python_packages.txt && \
    python3 -m pip install \
      gitpython \
      deepdiff \
      piexif \
      matplotlib \
      numexpr \
      omegaconf \
      frontend \
      PyOpenGL-accelerate \
      ffmpeg-python \
      dlib \
      insightface \
      numba

# Set working directory
WORKDIR ${ROOT}

# Copy other required files
COPY . /docker/

# Make entrypoint script executable and copy extra model paths
RUN chmod +x /docker/entrypoint.sh && cp /docker/extra_model_paths.yaml ${ROOT}

# Set environment variables for application
ENV NVIDIA_VISIBLE_DEVICES=all PYTHONPATH="${PYTHONPATH}:${PWD}"

# Expose application port
EXPOSE 7860

# Define entrypoint and default command
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD ["python3", "-u", "main.py", "--listen", "--port", "7860"]
