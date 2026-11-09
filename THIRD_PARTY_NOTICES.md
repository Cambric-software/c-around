# Third-party notices

C Around includes or downloads the components below. Each remains the property
of its publisher and is governed by its own licence, not by the proprietary
licence that covers Cambric's own code.

## Bundled models

| Component | Publisher | Licence | Used for |
|---|---|---|---|
| YOLOv8n ONNX weights | Ultralytics | **AGPL-3.0** | Object detection |
| YAMNet ONNX weights and class map | TensorFlow / Google | Apache-2.0 | Sound classification |
| SCRFD `det_500m.onnx` | InsightFace | **Non-commercial research only** (the InsightFace code is MIT; the pretrained model zoo is restricted) | Face detection |
| MobileFaceNet `w600k_mbf.onnx` | InsightFace | **Non-commercial research only** (same restriction) | Face embeddings |

### Distribution note

The YOLOv8n weights are AGPL-3.0, and the InsightFace pretrained models are
published for non-commercial research use. They are bundled so the app works
without a download and so the recognition behaviour could be measured during
development. **Before distributing C Around commercially, replace these weights
with permissively licensed models or obtain the appropriate licence from the
publisher.** Cambric's proprietary licence does not override those terms.

The optional model packs are downloaded by the person, not bundled:

| Pack | Publisher | Licence |
|---|---|---|
| Moondream 2 Q4_K GGUF and F16 mmproj | Moondream | Apache-2.0 |
| Whisper tiny int8 (sherpa-onnx conversion) | OpenAI Whisper | MIT |
| `llama-server` build `b12224` | ggml-org / llama.cpp | MIT |

## Runtime and libraries

| Component | Licence |
|---|---|
| Flutter and the Flutter engine | BSD-3-Clause |
| Dart SDK and Dart packages used by the app | BSD-3-Clause, MIT or Apache-2.0, per package |
| ONNX Runtime | MIT |
| sherpa-onnx | Apache-2.0 |
| SQLite and sqflite | Public domain (SQLite); BSD-2-Clause (sqflite) |
| Material Icons | Apache-2.0 |

The full dependency graph and resolved versions are recorded in
`app/pubspec.lock`. Each package ships its own licence file in the pub cache and
in the published package archive; those files govern that package.

## Assets

The C Around logo, icon set and download page were produced for this project by
Cambric Software. The alarm tone in `app/assets/audio/alarm.wav` was generated
for this project.
