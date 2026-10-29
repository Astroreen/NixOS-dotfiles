#!/usr/bin/env python3
"""Minimal faster-whisper HTTP transcription server.

Drop-in compatible with the whisper.cpp server interface used by the Astro
dashboard: ``GET /`` (health/liveness) and ``POST /inference`` (multipart
``file`` + ``language``) -> ``{"text": "..."}``.

The model is loaded at startup and kept resident (GPU VRAM). With
``FW_IDLE_UNLOAD`` > 0 (seconds) its weights are dropped after that much
idle time, which frees the VRAM for other services; the next request loads
them again (about a second, the files stay in the page cache).
"""

import asyncio
import io
import os
import time
from contextlib import asynccontextmanager, suppress

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
IDLE_UNLOAD = int(os.environ.get("FW_IDLE_UNLOAD", "0"))

_state: dict = {"model": None, "last_used": time.monotonic()}


def ensure_model() -> None:
    """Populate MODEL_PATH from HuggingFace on first run."""
    if os.path.exists(os.path.join(MODEL_PATH, "model.bin")):
        return
    from huggingface_hub import snapshot_download

    os.makedirs(MODEL_PATH, exist_ok=True)
    snapshot_download(MODEL_REPO, local_dir=MODEL_PATH)


async def unload_when_idle() -> None:
    """Drop the weights (not the CTranslate2 object) once idle long enough.

    Requests run on the event loop without awaiting, so this never runs in
    the middle of a transcription.
    """
    while True:
        await asyncio.sleep(min(IDLE_UNLOAD, 30))
        whisper = _state["model"].model
        if whisper.model_is_loaded and time.monotonic() - _state["last_used"] >= IDLE_UNLOAD:
            whisper.unload_model()
            print(f"model unloaded after {IDLE_UNLOAD}s idle", flush=True)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    ensure_model()
    _state["model"] = WhisperModel(MODEL_PATH, device=DEVICE, compute_type=COMPUTE_TYPE)
    _state["last_used"] = time.monotonic()
    watcher = asyncio.create_task(unload_when_idle()) if IDLE_UNLOAD > 0 else None
    try:
        yield
    finally:
        if watcher is not None:
            watcher.cancel()
            with suppress(asyncio.CancelledError):
                await watcher
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
    whisper = _state["model"].model
    if not whisper.model_is_loaded:
        whisper.load_model()
    lang = None if language in ("", "auto", "None", "null") else language
    segments, _info = _state["model"].transcribe(
        io.BytesIO(data),
        language=lang,
        beam_size=5,
        vad_filter=True,
    )
    text = "".join(segment.text for segment in segments).strip()
    _state["last_used"] = time.monotonic()
    return JSONResponse({"text": text})


if __name__ == "__main__":
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")