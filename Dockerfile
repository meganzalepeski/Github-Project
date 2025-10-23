FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# --- Create env and install core stack with strict conda-forge (includes sympy 1.10.1) ---
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.10 && \
    conda run -n pypodgp conda config --env --add channels conda-forge && \
    conda run -n pypodgp conda config --env --set channel_priority strict && \
    conda install -y -n pypodgp -c conda-forge \
      "fenics==2019.1.0" "mshr==2019.1.0" "petsc<3.18" "mpi4py<4" \
      numpy scipy h5py pandas matplotlib "sympy==1.10.1" && \
    conda clean -afy

# Run subsequent commands inside that env
SHELL ["conda","run","-n","pypodgp","/bin/bash","-c"]

# ---- Project files ----
WORKDIR /app
COPY external/PyPOD-GP /app

# --- Create a pip constraints file that forbids SymPy upgrades ---
RUN echo "sympy==1.10.1" > /tmp/constraints.txt
ENV PIP_CONSTRAINT=/tmp/constraints.txt

# ---- Torch CPU wheels ----
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir --no-deps \
      torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Default behavior: show help (env auto-activated via entrypoint)
ENTRYPOINT ["conda","run","--no-capture-output","-n","pypodgp"]
CMD ["python","run_pod.py","-h"]
