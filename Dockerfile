FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# Python 3.10 (per README) and conda-forge stack
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.10 pip && \
    conda install -y -n pypodgp -c conda-forge fenics mshr numpy scipy matplotlib && \
    conda clean -afy


# Make the env active by default
ENV CONDA_DEFAULT_ENV=pypodgp
ENV PATH="/opt/conda/envs/pypodgp/bin:${PATH}"
ENV MPLBACKEND=Agg

WORKDIR /app
# Copy the PyPOD-GP submodule contents into the image
COPY external/PyPOD-GP /app

# Let pip see PyTorch CPU wheels so torch==2.3.0 (from requirements.txt) can resolve
ENV PIP_EXTRA_INDEX_URL="https://download.pytorch.org/whl/cpu"

# Install repo deps (including torch from requirements.txt)
RUN python -m pip install --upgrade pip && \
    if [ -f requirements.txt ]; then \
      python -m pip install --no-cache-dir -r requirements.txt; \
    fi

# Sanity check: fail build if these imports break
RUN python - <<'PY'
import torch, dolfin, mshr, sys
print("Python:", sys.version)
print("Torch:", torch.__version__)
print("dolfin OK:", dolfin.__version__)
print("mshr OK")
PY

# Run via conda to guarantee the correct env at runtime
ENTRYPOINT ["conda","run","--no-capture-output","-n","pypodgp"]
CMD ["python","run_pod.py","-h"]
