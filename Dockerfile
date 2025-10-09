FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# 1) Create env on Python 3.10 (per README)
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.10 pip && \
    conda clean -afy

# 2) FEniCS + mshr (conda-forge) into that env
RUN conda install -y -n pypodgp -c conda-forge fenics mshr numpy scipy matplotlib && \
    conda clean -afy

# 3) PyTorch CPU wheels via pip *inside the env*
# (Pin to a py3.10-compatible set; adjust if you need other versions.)
RUN conda run -n pypodgp python -m pip install --upgrade pip && \
    conda run -n pypodgp python -m pip install --no-cache-dir \
      torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 \
      --index-url https://download.pytorch.org/whl/cpu

# Make the env active by default
ENV CONDA_DEFAULT_ENV=pypodgp
ENV PATH="/opt/conda/envs/pypodgp/bin:${PATH}"
ENV MPLBACKEND=Agg

WORKDIR /app
# Copy the PyPOD-GP submodule contents into the image
COPY external/PyPOD-GP /app

# Install requirements
RUN if [ -f requirements.txt ]; then \
      python -m pip install --no-cache-dir -r requirements.txt; \
    fi

# Build-time sanity check: fail if torch/fenics are missing
RUN python - <<'PY'
import sys
print("Python:", sys.version)
import torch, dolfin, mshr
print("Torch:", torch.__version__)
print("dolfin OK:", dolfin.__version__)
print("mshr OK")
PY

# Run via conda to guarantee the correct env at runtime
ENTRYPOINT ["conda","run","--no-capture-output","-n","pypodgp"]
CMD ["python","run_pod.py","-h"]
