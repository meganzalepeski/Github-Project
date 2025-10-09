FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# Create Python 3.10 env and install fenics + mshr from conda-forge
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.11 && \
    conda install -y -n pypodgp -c conda-forge fenics mshr numpy scipy matplotlib && \
    conda clean -afy
ENV PATH="/opt/conda/envs/pypodgp/bin:${PATH}"

WORKDIR /app
# Copy the PyPOD-GP submodule contents into the image
COPY external/PyPOD-GP /app

# Install repo Python deps
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# Ensure torch exists (CPU wheels) if not provided in requirements.txt
RUN python - <<'PY' || pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
import importlib, sys
sys.exit(0) if importlib.util.find_spec('torch') else sys.exit(1)
PY

# Default: print help
CMD ["python","run_pod.py","-h"]
