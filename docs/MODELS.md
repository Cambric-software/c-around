# Bundled Models — C Around v1.0.3

All models bundled in the APK run entirely on-device. No data is sent to any server.

---

## What is bundled (works immediately after install)

| Model | File | Size | Purpose |
|---|---|---|---|
| YOLOv8n | `yolov8n.onnx` | 12 MB | Object detection — 80 COCO classes |
| YAMNet | `yamnet.onnx` | 15 MB | Sound classification — 521 AudioSet classes |
| Face detector | `det_500m.onnx` | 2.4 MB | Detect face bounding boxes |
| Face embedder | `w600k_mbf.onnx` | 13 MB | Generate face recognition vectors |

**Total bundled model size: ~43 MB** (included in the 120 MB APK)

---

## YOLOv8n — Object Detection

- Input: 640×640 RGB, letterboxed
- Output: bounding boxes + 80 class scores
- Runs on CPU via ONNX Runtime (~200–400 ms on mid-range Android)
- Triggered every 2.5 seconds during awareness scanning
- Classes announced: person, car, truck, bus, motorcycle, train, bicycle, dog, knife, scissors, chair, couch, dining table, potted plant, bench, traffic light, stop sign, backpack, bottle, cup

**What YOLO can and cannot do:**
- ✅ Detects common outdoor objects, vehicles, people
- ✅ Works in reasonable daylight
- ⚠️ Lower accuracy in dark or low-contrast environments
- ⚠️ Small or distant objects may be missed
- ❌ Cannot read text, describe scenes in natural language (that's Whisper/Moondream)

---

## YAMNet — Sound Classification

- Input: 15,600 mono samples at 16 kHz (~1 second windows)
- Output: 521 AudioSet class probabilities
- Runs on CPU via ONNX Runtime
- Only classes above 0.18 confidence and mapped in `sound_events.dart` are announced

**Detected sounds:**
Fire alarm, siren, breaking glass, possible gunshot, car horn, baby crying, dog barking, shouting, alarm clock, doorbell, knocking, thunder

---

## Face Recognition (det_500m + w600k_mbf)

- Two-stage: detect face box → extract 512-dim embedding vector
- Similarity: cosine distance, threshold 0.4
- Stored: float32 vectors in SQLite (not photos)
- Works at: ≥40×40 px face region, reasonable front-facing angle

**Accuracy notes:**
- Best results with well-lit, front-facing photos
- Mask or sunglasses will reduce accuracy
- Up to ~10 enrolled people tested reliably

---

## Optional: Whisper (live captions)

- **NOT bundled** — too large (~99 MB)
- Available as a model pack download from Settings → Model packs
- Provides offline speech-to-text in the Talk → Live captions screen
- Uses sherpa-onnx Whisper tiny (multilingual)

---

## Optional: Moondream (scene description)

- **Desktop only** (Windows/Linux) — requires running llama-server binary
- Provides natural language scene description: "There is a table with a cup..."
- On Android: YOLO-based description is used instead ("I can see car ahead, person on your left")
- Available as a model pack download from Settings → Model packs (desktop)

---

## Runtime

All models run via [ONNX Runtime](https://onnxruntime.ai/) on the CPU. No GPU required. No internet. No server.
