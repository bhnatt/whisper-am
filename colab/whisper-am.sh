#!/usr/bin/env bash
# whisper-am command for the Colab terminal. builds the venv on first run, then transcribes.
#
# usage : bash /content/whisper-am/colab/whisper-am.sh [data_dir] [options]
#         bash /content/whisper-am/colab/whisper-am.sh --help
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="${WHISPER_AM_VENV:-/content/whisper-am-venv}"
export WHISPER_AM_VENV="$VENV"

bash "$REPO_DIR/colab/setup.sh"

# let ctranslate2 find cuBLAS/cuDNN from the pip wheels instead of the system CUDA
NVIDIA_LIBS="$(ls -d "$VENV"/lib/python3.*/site-packages/nvidia/*/lib 2>/dev/null | paste -sd: -)"
export LD_LIBRARY_PATH="$NVIDIA_LIBS${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONNOUSERSITE=1 # ignore packages in ~/.local

cd "$REPO_DIR"
exec "$VENV/bin/python" -u transcribe.py "$@"
