FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# Create Python 3.10 environment and install core FEniCS stack
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.10 && \
    conda install -y -n pypodgp -c conda-forge \
        "fenics==2019.1.0" "mshr==2019.1.0" \
        "petsc<3.18" "mpi4py<4" \
        numpy scipy h5py pandas && \
    conda clean -afy

# Run all subsequent commands inside that environment
SHELL ["conda", "run", "-n", "pypodgp", "/bin/bash", "-c"]

# Copy your project into the image
WORKDIR /app
COPY external/PyPOD-GP /app

# Install torch + torchvision + torchaudio (CPU versions)
RUN python -m pip install --upgrade pip && \
    python -m pip install --no-cache-dir \
        torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cpu

# Verify installs worked
RUN python - <<'PY'
import torch, dolfin
print("Torch:", torch.__version__)
print("Dolfin:", dolfin.__version__)
PY


# Default run behavior (print help text)
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "pypodgp"]
CMD ["python", "run_pod.py", "-h"]

