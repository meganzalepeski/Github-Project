FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# Create Python 3.11 env and install fenics + mshr from conda-forge
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.11 && \
    conda install -y -n pypodgp -c conda-forge fenics mshr numpy scipy matplotlib && \
    conda clean -afy

# Make the env active by default
ENV CONDA_DEFAULT_ENV=pypodgp
ENV PATH="/opt/conda/envs/pypodgp/bin:${PATH}"

WORKDIR /app
# Copy the PyPOD-GP submodule contents into the image
COPY external/PyPOD-GP /app

# Install repo Python deps (allow fail if torch pin is incompatible), then add PyTorch CPU wheels
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt || true; fi && \
    python - <<'PY' || pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
import importlib, sys
sys.exit(0) if importlib.util.find_spec('torch') else sys.exit(1)
PY

# Default: print help so the container "works" even without data
CMD ["python","run_pod.py","-h"]
