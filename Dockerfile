FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# Create Python 3.11 env and install fenics + mshr from conda-forge
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.11 && \
    conda install -y -n pypodgp -c conda-forge fenics mshr numpy scipy matplotlib && \
    conda clean -afy

# Make the env active by default for subsequent RUN commands
SHELL ["conda", "run", "-n", "pypodgp", "/bin/bash", "-c"]

WORKDIR /app
COPY external/PyPOD-GP /app

# Install Python deps + PyTorch (CPU) **inside pypodgp env**
RUN python -m pip install --upgrade pip && \
    if [ -f requirements.txt ]; then python -m pip install --no-cache-dir -r requirements.txt || true; fi && \
    python -m pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu && \
    python - <<'PY'
import torch
print("Torch installed OK:", torch.__version__)
PY

# Default command: run help
CMD ["conda", "run", "--no-capture-output", "-n", "pypodgp", "python", "run_pod.py", "-h"]
