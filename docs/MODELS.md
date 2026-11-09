# Models

C Around ships small models so the first scan works offline, and offers two
optional packs for heavier features.

## Bundled

| File | Bytes | Input | Output | Purpose |
|---|---:|---|---|---|
| `assets/models/yolov8n.onnx` | 12,851,145 | 1×3×640×640 float32, RGB, 0..1 | 1×84×8400 | 80 COCO classes |
| `assets/models/yamnet.onnx` | 16,093,603 | 1×N float32 waveform at 16 kHz | 521 class scores | AudioSet sound classes |
| `assets/models/yamnet_class_map.csv` | 14,096 | — | — | Class index → display name |
| `assets/models/det_500m.onnx` | 2,524,817 | 1×3×640×640 float32 | scores, boxes, keypoints | SCRFD face detection |
| `assets/models/w600k_mbf.onnx` | 13,616,099 | 1×3×112×112 float32 | 512 floats | MobileFaceNet embedding |

### YOLOv8n

- Letterbox to 640×640, fill with black, divide by 255.
- Output is `[1, 84, 8400]`: four box values (`cx`, `cy`, `w`, `h` in input
  pixels) followed by 80 class scores.
- `PriorityEngine.decodeYolo` converts centre boxes to normalised edges, removes
  letterbox padding, applies the confidence threshold and non-max suppression.
- Direction: centre X below 0.34 is "on your left", above 0.66 is "on your
  right", otherwise "ahead". Close means box height ≥ 0.32; very close ≥ 0.55.

### YAMNet

- 16 kHz mono PCM16 from `MicrophoneSource`.
- Windows of 0.975 s (15,600 samples), overlapping.
- Only mapped AudioSet labels are announced. The map covers fire and smoke
  alarms, sirens, glass, gunshots, horns, a baby crying, dogs, shouting, alarm
  clocks, thunder, doorbells and knocking. Everything else is ignored on
  purpose: a confident-sounding wrong alert is worse than silence.
- Scores below 0.18 are discarded.

### Face pipeline

SCRFD `det_500m`:

- Input 640×640, letterboxed, `(pixel - 127.5) / 128`.
- Three strides (8, 16, 32), two anchors per cell.
- Output order per stride: scores, boxes, keypoints.
- Decode `distance2bbox`: centre ± distance × stride.
- Score threshold 0.55, NMS 0.3.
- The largest face is enrolled; a face smaller than 8% of the frame is rejected.

MobileFaceNet `w600k_mbf`:

- Crop and align the face to 112×112.
- Output 512 floats, L2-normalised.
- Matching uses cosine similarity. Threshold **0.58**. A weak match returns no
  name instead of a guess.
- Measured during development: different people scored ≤ 0.48; the same person
  scored about 0.97.

## Optional packs

### Moondream 2 (Windows and Linux)

| File | Bytes | Source |
|---|---:|---|
| `text.gguf` | 919,494,048 | `https://huggingface.co/salivosa/moondream2-gguf/resolve/main/moondream2-q4_k.gguf` |
| `mmproj.gguf` | 909,777,984 | `https://huggingface.co/moondream/moondream2-gguf/resolve/main/moondream2-mmproj-f16.gguf` |
| `llama-server.exe` / `llama-server` | archive | `https://github.com/ggml-org/llama.cpp/releases/download/b12224/` (Windows CPU x64 zip or Ubuntu x64 tar.gz) |

Pinned build: `b12224`. Bumping it changes both desktop URLs and must be tested
against the current GGUF before release.

Server configuration:

```text
-m text.gguf --mmproj mmproj.gguf --chat-template-file moondream.jinja
-c 2048 -np 1 -t 4 --host 127.0.0.1 --port 18420 --no-webui
```

Environment: `LLAMA_MEDIA_MARKER=<__media__>`.

The chat template puts media markers and text in one user turn:

```text
{% for message in messages %}{% if message['role'] == 'user' %}{% for part in message['content'] %}{% if part['type'] == 'media_marker' %}{{ part['text'] }}{% endif %}{% endfor %}

Question: {% for part in message['content'] %}{% if part['type'] == 'text' %}{{ part['text'] }}{% endif %}{% endfor %}

Answer:{% endif %}{% endfor %}
```

Requests go to `/v1/chat/completions`; health is `/health`. The image part is
sent **before** the text part in the OpenAI content array.

Prompts (verified against real photos):

- Describe: `Describe what is directly ahead for a blind person. Name only the important people, objects and obstacles, and say where they are. Use one short sentence. Do not guess.`
- Read text: `What words are visible in this image? Return only the words.`

### Whisper tiny captions (all platforms)

| File | Bytes |
|---|---:|
| `tiny-encoder.int8.onnx` | 12,937,772 |
| `tiny-decoder.int8.onnx` | 89,855,401 |
| `tiny-tokens.txt` | 816,730 |
| **Total** | **103,609,903** |

sherpa-onnx configuration:

```text
OfflineRecognizerConfig(
  model: OfflineModelConfig(
    whisper: OfflineWhisperModelConfig(
      encoder: tiny-encoder.int8.onnx,
      decoder: tiny-decoder.int8.onnx,
      language: 'en',
      task: 'transcribe',
    ),
    tokens: tiny-tokens.txt,
    modelType: 'whisper',
  ),
)
```

The recogniser is created after the pack is installed. Audio is 16 kHz mono
PCM16 converted to float32 in `[-1, 1]`.

## Model installation

`ModelManager` writes each pack to `<app support>/model_packs/<pack id>/`. A
download is written to a temporary file, checked against the expected byte size,
then moved into place. A pack is considered installed only when every required
file exists. There is no partial-install state exposed to the UI.

## What is not claimed

- Android does not run Moondream 2 in 1.0.
- The detector knows the 80 COCO classes; it does not name arbitrary objects.
- Face recognition can be wrong in poor light or at an angle; the threshold
  refuses weak matches but does not guarantee identity.
- No model output is a distance measurement.
