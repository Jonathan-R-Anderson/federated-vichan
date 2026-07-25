"""
NSFW image-scoring microservice for vichan.

Runs Yahoo's open_nsfw model (via the maintained `opennsfw2` TensorFlow-2 port, which uses
the original Yahoo weights) and exposes a tiny HTTP API the php container calls:

    POST /score   body = raw image bytes  ->  {"score": 0.0 .. 1.0}
    GET  /healthz ->  "ok"

`score` is the model's probability that the image is NSFW (explicit). The board software
compares it against a per-board threshold and decides whether to reject or spoiler the upload.
The model is loaded once at startup; requests only run inference.
"""

import io
import os

import numpy as np
from flask import Flask, request, jsonify
from PIL import Image
import opennsfw2 as n2

app = Flask(__name__)

# Load the Yahoo open_nsfw model a single time (weights are baked into the image at build).
_model = n2.make_open_nsfw_model()

MAX_BYTES = int(os.environ.get("NSFW_MAX_BYTES", str(50 * 1024 * 1024)))


@app.get("/healthz")
def healthz():
    return "ok\n"


@app.get("/")
def index():
    return jsonify(service="open_nsfw", model="yahoo/open_nsfw (opennsfw2)", endpoint="/score")


@app.post("/score")
def score():
    data = request.get_data(cache=False)
    if not data:
        return jsonify(error="empty body"), 400
    if len(data) > MAX_BYTES:
        return jsonify(error="image too large"), 413

    try:
        image = Image.open(io.BytesIO(data)).convert("RGB")
    except Exception:
        return jsonify(error="not a decodable image"), 400

    try:
        # Yahoo preprocessing (resize to 256, center-crop 224, BGR mean subtraction).
        preprocessed = n2.preprocess_image(image, n2.Preprocessing.YAHOO)
        batch = np.expand_dims(preprocessed, axis=0)
        # Call the model directly rather than .predict(): predict() builds a fresh execution
        # function per call and misbehaves in a served/threaded context.
        preds = _model(batch, training=False)
        nsfw_probability = float(preds.numpy()[0][1])  # column 1 = NSFW
    except Exception as exc:  # noqa: BLE001 - report any inference failure to the caller
        return jsonify(error="inference failed: %s" % exc), 500

    return jsonify(score=nsfw_probability)


if __name__ == "__main__":
    # Dev entrypoint; production uses gunicorn (see Dockerfile).
    app.run(host="0.0.0.0", port=8080)
