# Creating Apptainer Containers from Dockerfile and requirements.txt

## What is Apptainer?

Apptainer (formerly known as Singularity) is a containerization platform designed specifically for high-performance computing (HPC) environments, scientific computing, and research workflows. It provides a secure, portable way to package and run applications across different computing environments.

### Key Features of Apptainer:
- **Single-file containers**: Applications are packaged into a single `.sif` (Singularity Image Format) file
- **No root daemon**: Unlike Docker, Apptainer doesn't require a root daemon to run containers
- **User-space execution**: Containers run with the same user privileges as the person executing them
- **HPC-friendly**: Designed for shared computing resources and batch job systems
- **MPI support**: Native support for Message Passing Interface (MPI) applications
- **GPU support**: Seamless integration with NVIDIA GPUs and CUDA

## Apptainer vs Docker vs Conda

| Feature | Apptainer | Docker | Conda |
|---------|-----------|--------|-------|
| **Primary Use Case** | HPC, scientific computing | Application deployment, microservices | Package/environment management |
| **Root Privileges** | Not required to run | Requires root daemon | Not required |
| **Container Format** | Single `.sif` file | Layered filesystem | Environment directories |
| **Security Model** | User-space, no privilege escalation | Root daemon (security concerns in HPC) | File permissions only |
| **HPC Integration** | Excellent (job schedulers, MPI) | Limited | Good |
| **Portability** | Extremely portable (single file) | Good (multi-layer images) | Platform dependent |
| **Build Process** | Requires root for building | Requires Docker daemon | No special privileges |
| **Networking** | Uses host networking by default | Isolated networking | No networking features |
| **Storage** | Binds host directories | Volumes and bind mounts | Direct file system access |
| **Reproducibility** | Excellent (immutable images) | Good (image layers) | Good (environment files) |


## Prerequisites

- Apptainer/Singularity installed on your system
- Your Dockerfile and requirements.txt files
- Access to pre-built images or fakeroot/unprivileged build capabilities

## Method 1: Direct Conversion from Dockerfile

### Step 1: Convert Dockerfile to Apptainer Definition File

Create a new file called `container.def` (or any name ending in `.def`):

```bash
Bootstrap: docker
From: python:3.9-slim

%files
    requirements.txt /tmp/requirements.txt
    # Add other files from your Dockerfile COPY/ADD commands

%post
    # Update system packages
    apt-get update && apt-get install -y \
        build-essential \
        && rm -rf /var/lib/apt/lists/*
    
    # Install Python requirements
    pip install --no-cache-dir -r /tmp/requirements.txt
    
    # Add other commands from your Dockerfile RUN instructions
    # Clean up
    apt-get clean

%environment
    # Set environment variables (from Dockerfile ENV commands)
    export PATH=/usr/local/bin:$PATH
    export PYTHONPATH=/app:$PYTHONPATH

%runscript
    # Default command to run (from Dockerfile CMD/ENTRYPOINT)
    exec python "$@"

%labels
    Author your.email@example.com
    Version v1.0
    Description My application container

%help
    This container runs my Python application.
    Usage: apptainer run container.sif [arguments]
```

### Step 2: Build the Container

```bash
# Build the container using fakeroot (no root required)
apptainer build --fakeroot container.sif container.def

# Or build in a sandbox for development
apptainer build --fakeroot --sandbox container_sandbox/ container.def

# Alternative: Remote build (if available)
apptainer build --remote container.sif container.def
```

## Method 2: Build from Docker Image

If you already have a Docker image built:

```bash
# Build Apptainer container directly from Docker image
apptainer build container.sif docker://your-docker-image:tag

# Or from Docker Hub
apptainer build container.sif docker://python:3.9-slim
```

## Method 3: Using Fakeroot for Unprivileged Builds

Apptainer supports building containers without root privileges using fakeroot:

```bash
# Enable fakeroot if not already configured
# (This may require one-time admin setup)

# Build with fakeroot
apptainer build --fakeroot myapp.sif myapp.def

# Build from Docker Hub without privileges
apptainer build --fakeroot container.sif docker://python:3.9-slim
```us
```

## Key Differences: Dockerfile vs Apptainer Definition

| Dockerfile | Apptainer Definition | Purpose |
|------------|---------------------|---------|
| `FROM` | `Bootstrap: docker` + `From:` | Base image |
| `COPY/ADD` | `%files` | Copy files |
| `RUN` | `%post` | Build-time commands |
| `ENV` | `%environment` | Environment variables |
| `CMD/ENTRYPOINT` | `%runscript` | Default execution |
| `LABEL` | `%labels` | Metadata |

## Common Sections in Apptainer Definition Files

### %files
Copy files from host to container during build:
```
%files
    requirements.txt /tmp/
    src/ /app/src/
    config.yaml /etc/myapp/
```

### %post
Commands executed during container build (like RUN in Docker):
```
%post
    apt-get update
    pip install -r /tmp/requirements.txt
    mkdir -p /app/data
    chmod 755 /app/scripts/run.sh
```

### %environment
Set environment variables:
```
%environment
    export LC_ALL=C
    export PATH=/app/bin:$PATH
    export PYTHONPATH=/app:$PYTHONPATH
```

### %runscript
Default command when running the container:
```
%runscript
    cd /app
    exec python main.py "$@"
```

### %test
Commands to test the container after build:
```
%test
    python --version
    pip list
    python -c "import numpy; print('NumPy works!')"
```


## Complete Example: CUDA Development Container

Let's walk through converting a real-world Dockerfile for a CUDA-enabled development environment:

**Original Dockerfile:**
```dockerfile
FROM nvidia/cuda:12.8.0-devel-ubuntu24.04
LABEL maintainer="disi-Unibo-NLP"
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app
ENV APP_PATH=/app
# Install dependencies including python3.12-venv
RUN apt-get update -y && \
 apt-get install -y curl \
 git \
 bash \
 nano \
 python3.12 \
 python3-pip \
 python3.12-venv && \
 apt-get autoremove -y && \
 apt-get clean -y && \
 rm -rf /var/lib/apt/lists/*
# Create and activate virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
# Now pip commands work normally
RUN pip install --upgrade pip
RUN pip install wrapt --upgrade --ignore-installed
RUN pip install gdown
#RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
COPY build/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
ENV DEBIAN_FRONTEND=dialog
```

**Converted Apptainer Definition (`cuda-dev.def`):**
```
Bootstrap: docker
From: nvidia/cuda:12.8.0-devel-ubuntu24.04

%files
    build/requirements.txt /tmp/requirements.txt

%post
    # Set non-interactive mode for apt
    export DEBIAN_FRONTEND=noninteractive
    
    # Install system dependencies
    apt-get update -y && \
    apt-get install -y \
        curl \
        git \
        bash \
        nano \
        python3.12 \
        python3-pip \
        python3.12-venv && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*
    
    # Create and activate virtual environment
    python3 -m venv /opt/venv
    
    # Activate venv and install Python packages
    . /opt/venv/bin/activate
    pip install --upgrade pip
    pip install wrapt --upgrade --ignore-installed
    pip install gdown
    
    # Install requirements
    pip install --no-cache-dir -r /tmp/requirements.txt
    
    # Optional: Install PyTorch with CUDA support
    # pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
    
    # Create app directory
    mkdir -p /app

%environment
    export DEBIAN_FRONTEND=dialog
    export APP_PATH=/app
    export PATH="/opt/venv/bin:$PATH"
    export PYTHONPATH="/app:$PYTHONPATH"
    
    # CUDA environment variables (if needed)
    export CUDA_HOME=/usr/local/cuda
    export PATH="$CUDA_HOME/bin:$PATH"
    export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"

%runscript
    cd /app
    exec "$@"

%labels
    Maintainer disi-Unibo-NLP
    Description CUDA development environment with Python 3.12
    Version 1.0
    CUDA_Version 12.8.0
    Base_OS Ubuntu 24.04

%help
    This container provides a CUDA-enabled Python development environment.
    
    Usage:
        # Run interactively
        apptainer shell --nv cuda-dev.sif
        
        # Execute Python script
        apptainer exec --nv cuda-dev.sif python script.py
        
        # Check CUDA availability
        apptainer exec --nv cuda-dev.sif python -c "import torch; print(torch.cuda.is_available())"
    
    Note: Use --nv flag to enable NVIDIA GPU support.

%test
    # Test basic functionality
    python3 --version
    pip --version
    
    # Test virtual environment
    . /opt/venv/bin/activate
    python -c "import sys; print('Virtual env active:', '/opt/venv' in sys.executable)"
    
    # Test CUDA (if available)
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi
    fi
```

### Key Conversion Notes:

1. **Base Image**: Used the same NVIDIA CUDA base image for compatibility
2. **File Copying**: Moved `COPY` command to `%files` section
3. **RUN Commands**: Consolidated into `%post` section with proper shell activation
4. **Environment Variables**: Split between build-time and runtime environments
5. **Virtual Environment**: Properly activated within the build process
6. **CUDA Support**: Added appropriate environment variables and help text
7. **Testing**: Added comprehensive tests including CUDA availability check

### Building the Container:

Now that we have the definition file (`cuda-dev.def`), we need to build the actual container:

```bash
# Build the .sif container from the .def definition file
apptainer build --fakeroot cuda-dev.sif cuda-dev.def

# This creates the executable container file: cuda-dev.sif
# The build process will:
# 1. Pull the NVIDIA CUDA base image
# 2. Copy your requirements.txt file
# 3. Install all system packages and Python dependencies
# 4. Create the virtual environment
# 5. Package everything into a single .sif file
```

### Running the Container:

Once built, you can use the `.sif` file:

```bash
# Run with GPU support (interactive shell)
apptainer shell --nv cuda-dev.sif

# Execute a Python script with GPU access
apptainer exec --nv cuda-dev.sif python train_model.py

# Test CUDA functionality
apptainer exec --nv cuda-dev.sif python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# Run the default command (from %runscript)
apptainer run --nv cuda-dev.sif python my_script.py
```

### File Structure Summary:

After following this example, you'll have:
- `cuda-dev.def` - The definition file (recipe)
- `cuda-dev.sif` - The actual container (executable)
- `build/requirements.txt` - Your Python dependencies

The `.sif` file is the one you distribute and run - it's completely self-contained!

### Important GPU Considerations:

- **Always use `--nv` flag** when running containers that need GPU access
- **Host NVIDIA drivers** must be compatible with the container's CUDA version
- **GPU binding** is automatic with the `--nv` flag
- **Multiple GPUs** are accessible by default when using `--nv`

This example demonstrates how to handle complex Dockerfiles with system dependencies, virtual environments, and GPU support while maintaining all functionality in the Apptainer conversion.