#!/usr/bin/env bash
# Build an isolated python environment for whisper-am, independent of Colab's preinstalled packages.
#  - python itself is a uv-managed build (not Colab's system python)
#  - every package is pinned in colab/requirements.lock
#  - CUDA/cuDNN libraries come from pip wheels (not Colab's system CUDA). only the NVIDIA driver is used from the host.
#
# usage : bash colab/setup.sh          (idempotent. skips if the venv is already up to date)
#         FORCE=1 bash colab/setup.sh  (rebuild)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="${WHISPER_AM_VENV:-/content/whisper-am-venv}"
PYTHON_VERSION="3.11"
UV_VERSION="0.8.19"
LOCK="$REPO_DIR/colab/requirements.lock"
STAMP="$VENV/.lock.sha256"

export PATH="$HOME/.local/bin:$PATH"

lock_hash="$(sha256sum "$LOCK" | cut -d' ' -f1)"
if [[ "${FORCE:-0}" != "1" && -f "$STAMP" && "$(cat "$STAMP")" == "$lock_hash" ]] ; then
    echo "[setup] venv up to date : $VENV"
    exit 0
fi

if ! command -v uv >/dev/null || [[ "$(uv --version | cut -d' ' -f2)" != "$UV_VERSION" ]] ; then
    echo "[setup] installing uv $UV_VERSION"
    curl -LsSf "https://astral.sh/uv/$UV_VERSION/install.sh" | env UV_NO_MODIFY_PATH=1 sh >/dev/null
fi

if ! command -v ffmpeg >/dev/null ; then
    echo "[setup] installing ffmpeg"
    apt-get -qq update && apt-get -qq install -y ffmpeg >/dev/null
fi

echo "[setup] creating venv : $VENV (python $PYTHON_VERSION)"
rm -rf "$VENV"
uv venv --quiet --python "$PYTHON_VERSION" --python-preference only-managed "$VENV"

echo "[setup] installing packages from requirements.lock"
uv pip sync --quiet --python "$VENV/bin/python" "$LOCK"

echo "[setup] downloading nltk data"
"$VENV/bin/python" -c "import nltk; nltk.download('punkt', quiet=True); nltk.download('punkt_tab', quiet=True)"

echo "$lock_hash" > "$STAMP"
echo "[setup] done"
