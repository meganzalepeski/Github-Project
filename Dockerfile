# Github-Project/Dockerfile
# If quay.io is blocked, try: docker.io/fenicsproject/stable:current
FROM quay.io/fenicsproject/stable:current
SHELL ["/bin/bash","-lc"]

# Put repo code at /app
WORKDIR /app
# Copy your submodule contents into the image
COPY external/PyPOD-GP /app

# Python deps for the repo
RUN python3 -m pip install --upgrade pip && \
    if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi && \
    python3 - <<'PY' || pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
import importlib, sys
sys.exit(0) if importlib.util.find_spec('torch') else sys.exit(1)
PY

# Default: print help so container "works" even without data
CMD ["python3", "run_pod.py", "-h"]
