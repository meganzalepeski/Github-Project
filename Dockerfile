# Minimal, no-quay FEniCS + requirements.txt
FROM continuumio/miniconda3:latest
SHELL ["/bin/bash","-lc"]

# 1) Create a small env with Py 3.10 and a stable Fenics classic stack
RUN conda update -n base -c defaults -y conda && \
    conda create -y -n pypodgp python=3.10 && \
    conda install -y -n pypodgp -c conda-forge \
      "fenics==2019.1.0" "mshr==2019.1.0" \
      "petsc<3.18" "mpi4py<4" \
      numpy scipy && \
    conda clean -afy

# 2) Run subsequent commands inside that env
SHELL ["conda","run","-n","pypodgp","/bin/bash","-c"]

# 3) Bring project in
WORKDIR /app
COPY external/PyPOD-GP /app

# 4) Install Python deps from requirements.txt
#    (pip can't install Python itself, so ignore the python== line)
RUN python -m pip install --upgrade pip && \
    awk '!/^python==/' requirements.txt > /tmp/reqs.txt && \
    python -m pip install --no-cache-dir -r /tmp/reqs.txt

# 5) Default: print help so the container "works" without data
CMD ["conda","run","--no-capture-output","-n","pypodgp","python","run_pod.py","-h"]
