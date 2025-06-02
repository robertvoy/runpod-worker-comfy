# Stage 1: Base image with common dependencies
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1 \
    && ln -sf /usr/bin/python3.10 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install comfy-cli
RUN pip install comfy-cli

# Install ComfyUI
RUN /usr/bin/yes | comfy --workspace /comfyui install --cuda-version 11.8 --nvidia --version 0.3.26 --skip-manager

# Change working directory to ComfyUI
WORKDIR /comfyui

# ---- Install Custom Nodes ----
# Navigate to the custom nodes directory
WORKDIR /comfyui/custom_nodes

# Clone the ComfyUI_essentials repository
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git ComfyUI_essentials

# Navigate into the cloned directory and install its requirements
WORKDIR /comfyui/custom_nodes/ComfyUI_essentials
RUN pip install -r requirements.txt

# Go back to custom_nodes directory BEFORE cloning TeaCache
WORKDIR /comfyui/custom_nodes

# Clone the ComfyUI_essentials repository
RUN git clone https://github.com/welltop-cn/ComfyUI-TeaCache ComfyUI-TeaCache

# Navigate into the cloned directory and install its requirements
WORKDIR /comfyui/custom_nodes/ComfyUI-TeaCache
RUN pip install -r requirements.txt

# Go back to the main ComfyUI directory
WORKDIR /comfyui
# ---- End Custom Nodes ----

# Install runpod
RUN pip install runpod requests

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Go back to the root
WORKDIR /

# Add scripts
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start container
CMD ["/start.sh"]
