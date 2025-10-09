# Github-Project/Dockerfile
FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# Python 3.10 + a stable Fenics stack (dolfin+mshr 2019.1)
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.10 && \
    conda install -y -n pypodgp -c conda-forge \
      "fenics==2019.1.0" "mshr==2019.1.0" \
      "petsc<3.18" "mpi4py<4" \
      numpy scipy matplotlib && \
    conda clean -afy

# Run all subsequent commands inside that env
SHELL ["conda","run","-n","pypodgp","/bin/bash","-c"]

WORKDIR /app
# Copy the PyPOD-GP submodule into the image
COPY external/PyPOD-GP /app

# Use requirements.txt for everything, but ignore the 'python==' line
RUN python -m pip install --upgrade pip && \
    awk '!/^python==/' requirements.txt > /tmp/reqs.txt && \
    python -m pip install --no-cache-dir -r /tmp/reqs.txt

# Default: show help
CMD ["conda","run","--no-capture-output","-n","pypodgp","python","run_pod.py","-h"]
