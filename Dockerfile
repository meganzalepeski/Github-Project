FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# Create Python 3.11 env and install fenics + mshr from conda-forge
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.11 && \
    conda install -y -n pypodgp -c conda-forge fenics mshr numpy scipy matplotlib && \
    conda install -y -n pypodgp -c pytorch pytorch torchvision torchaudio cpuonly && \
    conda clean -afy

# Make the env active by default
ENV CONDA_DEFAULT_ENV=pypodgp
ENV PATH="/opt/conda/envs/pypodgp/bin:${PATH}"
ENV MPLBACKEND=Agg

WORKDIR /app
# Copy the PyPOD-GP submodule contents into the image
COPY external/PyPOD-GP /app

# Install requirements
RUN python -m pip install --upgrade pip && \
    if [ -f requirements.txt ]; then python -m pip install --no-cache-dir -r requirements.txt; fi

# Sanity check: make the build fail if torch isn't importable
RUN python - <<'PY'
import sys
print("Python:", sys.version)
import torch, mshr
print("Torch OK:", torch.__version__)
PY

# Run via conda to guarantee the correct env at runtime
ENTRYPOINT ["conda","run","--no-capture-output","-n","pypodgp"]
CMD ["python","run_pod.py","-h"]
