# Use the official FEniCS image (already has dolfin, mshr, PETSc, MPI)
FROM quay.io/fenicsproject/stable:current

# Set working directory
WORKDIR /app

# Copy your PyPOD-GP project into the image
COPY external/PyPOD-GP /app

# Upgrade pip and install requirements (ignore python== line)
RUN python3 -m pip install --upgrade pip && \
    awk '!/^python==/' requirements.txt > /tmp/reqs.txt && \
    pip install --no-cache-dir -r /tmp/reqs.txt

# Default command: show help so the container works even without arguments
CMD ["python3", "run_pod.py", "-h"]
