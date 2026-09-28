#!/usr/bin/env python3
"""Minimal faster-whisper HTTP transcription server.

Drop-in compatible with the whisper.cpp server interface used by the Astro
dashboard: ``GET /`` (health/liveness) and ``POST /inference`` (multipart
``file`` + ``language``) -> ``{"text": "..."}``.

The model is loaded once at startup and kept resident (GPU VRAM).
"""

import io
import os
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import JSONResponse, PlainTextResponse
from faster_whisper import WhisperModel

MODEL_PATH = os.environ["FW_MODEL"]
MODEL_REPO = os.environ.get("FW_MODEL_REPO", "Systran/faster-whisper-large-v3")
DEVICE = os.environ.get("FW_DEVICE", "cuda")
COMPUTE_TYPE = os.environ.get("FW_COMPUTE_TYPE", "float16")
HOST = os.environ.get("FW_HOST", "127.0.0.1")
PORT = int(os.environ.get("FW_PORT", "7777"))

_state: dict = {"model": None}


def ensure_model() -> None:
    """Populate MODEL_PATH from HuggingFace on first run."""
    if os.path.exists(os.path.join(MODEL_PATH, "model.bin")):
        return
    from huggingface_hub import snapshot_download

    os.makedirs(MODEL_PATH, exist_ok=True)
    snapshot_download(MODEL_REPO, local_dir=MODEL_PATH)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    ensure_model()
    _state["model"] = WhisperModel(MODEL_PATH, device=DEVICE, compute_type=COMPUTE_TYPE)
    try:
        yield
    finally:
        _state["model"] = None


app = FastAPI(lifespan=lifespan)


@app.get("/")
def health() -> PlainTextResponse:
    return PlainTextResponse("ok")


@app.post("/inference")
async def inference(
    file: UploadFile = File(...),
    language: str = Form("auto"),
    model: str = Form(""),
) -> JSONResponse:
    del model  # accepted for whisper.cpp compatibility; single resident model
    data = await file.read()
    lang = None if language in ("", "auto", "None", "null") else language
    segments, _info = _state["model"].transcribe(
        io.BytesIO(data),
        language=lang,
        beam_size=5,
        vad_filter=True,
    )
    text = "".join(segment.text for segment in segments).strip()
    return JSONResponse({"text": text})


if __name__ == "__main__":
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")