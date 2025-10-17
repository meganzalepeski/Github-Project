FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# ---- Core env: Python 3.10 + stable FEniCS classic stack ----
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.10 && \
    conda install -y -n pypodgp -c conda-forge \
      "fenics==2019.1.0" "mshr==2019.1.0" \
      "petsc<3.18" "slepc<3.18" \
      "mpi4py<4" \
      numpy scipy h5py pandas matplotlib && \
    conda clean -afy

# Run subsequent commands inside that env
SHELL ["conda","run","-n","pypodgp","/bin/bash","-c"]

# ---- Project files ----
WORKDIR /app
COPY external/PyPOD-GP /app

# ---- Torch CPU wheels ----
RUN python -m pip install --upgrade pip && \
    python -m pip install --no-cache-dir \
      torch torchvision torchaudio \
      --index-url https://download.pytorch.org/whl/cpu

# Default behavior: show help (env auto-activated via entrypoint)
ENTRYPOINT ["conda","run","--no-capture-output","-n","pypodgp"]
CMD ["python","run_pod.py","-h"]
