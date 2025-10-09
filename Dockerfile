# --- PyPOD-GP (CPU) ---
FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# 1) Create env with Python 3.10 (per README)
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.10 pip && \
    conda clean -afy

# 2) Install fenics/mshr into that env
RUN conda install -y -n pypodgp -c conda-forge fenics mshr numpy scipy matplotlib && \
    conda clean -afy


# Make the env active by default
ENV CONDA_DEFAULT_ENV=pypodgp
ENV PATH="/opt/conda/envs/pypodgp/bin:${PATH}"
ENV MPLBACKEND=Agg

# Let pip see PyTorch CPU wheels so torch==2.3.0 (from requirements.txt) can resolve
ENV PIP_EXTRA_INDEX_URL="https://download.pytorch.org/whl/cpu"

WORKDIR /app
# Copy the PyPOD-GP submodule contents into the image
COPY external/PyPOD-GP /app



# 3) Install deps (INCLUDING torch from requirements.txt) *inside* the env
RUN conda run -n pypodgp python -m pip install --upgrade pip && \
    if [ -f requirements.txt ]; then \
      conda run -n pypodgp python -m pip install --no-cache-dir -r requirements.txt; \
    fi

# Sanity check (fails build if imports break)
RUN conda run -n pypodgp python - <<'PY'
import sys; print("Python:", sys.version)
import torch, dolfin, mshr
print("torch:", torch.__version__)
print("dolfin:", dolfin.__version__)
print("mshr OK")
PY

# Run via conda to guarantee the correct env at runtime
ENTRYPOINT ["conda","run","--no-capture-output","-n","pypodgp"]
CMD ["python","run_pod.py","-h"]
