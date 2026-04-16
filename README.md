# vLLM Voxtral + Whisper ASR

Docker containerization for deploying speech transcription models with OpenAI-compatible APIs:

1. **Voxtral-Mini-4B-Realtime-2602** (vLLM) - Mistral AI's high-performance model
2. **Whisper** (Speaches/CPU-compatible) - OpenAI's proven transcription model with **M4A support**

> ⚠️ **Important**: Voxtral currently requires GPU. For CPU-only deployments, use the Whisper alternative (see below).
> 
> 📱 **iPhone Users**: Whisper supports M4A files natively (perfect for iPhone voice memos!)

## Which Model Should I Use?

| Feature | Voxtral (vLLM) | Whisper (Speaches) |
|---------|----------------|-------------|
| **Hardware** | GPU required | ✅ **CPU works!** |
| **Performance** | Excellent (GPU) | Good (optimized for CPU) |
| **Languages** | 13 languages | 99 languages |
| **M4A Support** | ✅ Yes | ✅ **Yes (iPhone voice memos)** |
| **Real-time streaming** | ✅ Yes (<500ms) | ❌ No |
| **Batch transcription** | ✅ Yes | ✅ Yes |
| **Setup difficulty** | Medium | Easy |
| **Best for** | GPU users, real-time needs | CPU users, iPhone voice memos |

**Quick recommendation:**
- 🎯 **Have GPU?** → Use Voxtral
- 💻 **CPU only or iPhone voice memos?** → Use Whisper (fully supported)

## Features

**Voxtral** is a multilingual audio transcription model that supports 13 languages. Perfect for:
- 📁 **Batch transcription**: Upload audio files and get text transcriptions
- 🎙️ **Real-time streaming**: Live transcription with sub-500ms latency (GPU only)
- 🌍 **Multilingual support**: 13 languages
- ⚡ **High performance**: Optimized for speed and accuracy

**Whisper** (via Speaches) is OpenAI's robust transcription model, optimized for CPU. Perfect for:
- 💻 **CPU deployment**: Works great without GPU
- 📱 **iPhone voice memos**: Native M4A/AAC support
- 📁 **Batch transcription**: Reliable file-based transcription
- 🌍 **Multilingual support**: 99 languages
- 🔌 **OpenAI-compatible API**: Easy integration

## Common Use Cases

**For batch/file transcription** (your use case):
- ✅ **Voxtral on GPU**: Fastest, excellent accuracy
- ✅ **Whisper on CPU**: Good speed, proven reliability, works without GPU

**For real-time streaming transcription**:
- ✅ **Voxtral on GPU only**: Sub-500ms latency
- ❌ **Whisper**: Not designed for real-time

## Prerequisites

### Voxtral (GPU Deployment)
- Docker and Docker Compose
- NVIDIA GPU with CUDA support (minimum 8GB VRAM)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

### Whisper (CPU Deployment - Recommended if no GPU)
- Docker and Docker Compose
- x86_64 or ARM64 CPU
- 4GB+ RAM recommended
- **No GPU required!**

## Quick Start

### Option A: Whisper (CPU - Works Now!) 🎯 Recommended for CPU

1. **Start the Whisper service:**

```bash
docker compose -f docker-compose-whisper.yaml up -d
```

2. **Check if it's running:**

```bash
curl http://localhost:9000/health
```

3. **Transcribe an audio file:**

```bash
# Works with MP3, WAV, M4A (iPhone voice memos!), and more
curl -X POST "http://localhost:9000/v1/audio/transcriptions" \
  -F "file=@your-audio.mp3" \
  -F "model=base"
```

**iPhone voice memo example (M4A):**

```bash
curl -X POST "http://localhost:9000/v1/audio/transcriptions" \
  -F "file=@voice_memo.m4a" \
  -F "model=base" \
  -F "language=en"
```

**Response:**
```json
{
  "text": "Your transcribed text here"
}
```

That's it! The Whisper service will:
- Download the model on first run (~150MB for base model)
- Cache it for future use
- Be ready to transcribe audio files on CPU
- **Support M4A files natively** (iPhone voice memos work perfectly!)

### Option B: Voxtral (GPU Required)

1. **Build and start the service:**

```bash
docker compose up -d --build
```

2. **Check health:**

```bash
curl http://localhost:8000/health
```

3. **Test transcription:**

```bash
curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
  -F "file=@your-audio.mp3" \
  -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602"
```

The Voxtral service will:
- Download the model from HuggingFace on first run (~4GB)
- Start the vLLM server on port 8000
- Provide GPU-accelerated transcription

---

## Usage Examples

### Whisper API (OpenAI-Compatible, CPU)

Running on port 9000 by default. **Fully supports M4A files (iPhone voice memos)!**

**Basic transcription:**

```bash
curl -X POST "http://localhost:9000/v1/audio/transcriptions" \
  -F "file=@meeting.mp3" \
  -F "model=base"
```

**Response:**
```json
{
  "text": "This is the transcribed text from your audio file."
}
```

**iPhone voice memo (M4A file):**

```bash
curl -X POST "http://localhost:9000/v1/audio/transcriptions" \
  -F "file=@voice_memo.m4a" \
  -F "model=base" \
  -F "language=en"
```

**With verbose output (includes timestamps):**

```bash
curl -X POST "http://localhost:9000/v1/audio/transcriptions" \
  -F "file=@podcast.wav" \
  -F "model=base" \
  -F "response_format=verbose_json"
```

**Response with timestamps:**
```json
{
  "task": "transcribe",
  "language": "en",
  "duration": 10.5,
  "text": "Hello world",
  "segments": [
    {
      "id": 0,
      "start": 0.0,
      "end": 0.5,
      "text": "Hello",
      "no_speech_prob": 0.01
    },
    {
      "id": 1,
      "start": 0.5,
      "end": 1.0,
      "text": "world",
      "no_speech_prob": 0.02
    }
  ]
}
```

**Auto-detect language:**

```bash
curl -X POST "http://localhost:9000/v1/audio/transcriptions" \
  -F "file=@unknown-language.mp3" \
  -F "model=base"
```

**Translate to English (for non-English audio):**

```bash
curl -X POST "http://localhost:9000/v1/audio/translations" \
  -F "file=@spanish-audio.mp3" \
  -F "model=base"
```

**Supported audio formats:**
- ✅ **M4A** (iPhone voice memos)
- ✅ MP3, MP4, MPEG, MPGA
- ✅ WAV, WEBM, OGG, FLAC
- ✅ Virtually any format (FFmpeg support)

**Python client example (OpenAI-compatible):**

```python
from openai import OpenAI

# Point to local Whisper service
client = OpenAI(
    base_url="http://localhost:9000/v1",
    api_key="not-needed"
)

# Transcribe any audio file (including M4A!)
with open("voice_memo.m4a", "rb") as f:
    transcription = client.audio.transcriptions.create(
        model="base",
        file=f,
        language="en",
        response_format="verbose_json"
    )

print(transcription.text)
```

**Batch processing multiple files (including M4A):**

```python
from openai import OpenAI
from pathlib import Path

client = OpenAI(
    base_url="http://localhost:9000/v1",
    api_key="not-needed"
)

audio_dir = Path("./audio_files")
output_dir = Path("./transcriptions")
output_dir.mkdir(exist_ok=True)

# Process all audio files (MP3, M4A, WAV, etc.)
for audio_file in audio_dir.glob("*"):
    if audio_file.suffix.lower() in ['.mp3', '.m4a', '.wav', '.flac', '.ogg']:
        print(f"Transcribing {audio_file.name}...")
        
        with open(audio_file, "rb") as f:
            transcription = client.audio.transcriptions.create(
                model="base",
                file=f,
                language="en"
            )
        
        output_file = output_dir / f"{audio_file.stem}.txt"
        output_file.write_text(transcription.text)
        print(f"✓ Saved to {output_file}")
```

### Voxtral API (GPU Only)

**Basic transcription with curl:**

```bash
curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
  -F "file=@/path/to/audio.mp3" \
  -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602"
```

**Response:**
```json
{
  "text": "This is the transcribed text from your audio file."
}
```

**With language specification:**

```bash
curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
  -F "file=@/path/to/meeting.wav" \
  -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602" \
  -F "language=en" \
  -F "response_format=json"
```

**Verbose JSON response (includes word-level timestamps):**

```bash
curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
  -F "file=@/path/to/podcast.m4a" \
  -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602" \
  -F "language=es" \
  -F "response_format=verbose_json"
```

**Response with timestamps:**
```json
{
  "text": "Full transcription text here",
  "segments": [
    {
      "id": 0,
      "start": 0.0,
      "end": 3.5,
      "text": "First segment of speech"
    },
    {
      "id": 1,
      "start": 3.5,
      "end": 7.2,
      "text": "Second segment of speech"
    }
  ],
  "language": "es"
}
```

**Supported audio formats:**
- MP3, MP4, MPEG, MPGA, M4A
- WAV, WEBM
- FLAC, OGG

### Expected Processing Times

| Deployment | 1-minute audio | 10-minute audio | 60-minute audio |
|------------|----------------|-----------------|-----------------|
| **GPU** | ~2-5 seconds | ~20-30 seconds | ~2-3 minutes |
| **CPU** | ~15-30 seconds | ~2-5 minutes | ~15-30 minutes |

*Note: Times are approximate and vary based on hardware, audio quality, and language.*

### Batch Processing Multiple Files

**Using a bash script:**

```bash
#!/bin/bash
for audio_file in *.mp3; do
  echo "Transcribing $audio_file..."
  curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
    -F "file=@$audio_file" \
    -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602" \
    -F "language=en" \
    -o "${audio_file%.mp3}.json"
  echo "Saved to ${audio_file%.mp3}.json"
done
```

**Using Python:**

```python
import os
from pathlib import Path
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="not-needed"
)

# Process all audio files in a directory
audio_dir = Path("./audio_files")
output_dir = Path("./transcriptions")
output_dir.mkdir(exist_ok=True)

for audio_file in audio_dir.glob("*.mp3"):
    print(f"Transcribing {audio_file.name}...")
    
    with open(audio_file, "rb") as f:
        transcription = client.audio.transcriptions.create(
            model="mistralai/Voxtral-Mini-4B-Realtime-2602",
            file=f,
            language="en",
            response_format="verbose_json"
        )
    
    # Save transcription
    output_file = output_dir / f"{audio_file.stem}.txt"
    output_file.write_text(transcription.text)
    print(f"✓ Saved to {output_file}")
```

### Simple Python Client Example

```python
from openai import OpenAI

# Point to your local vLLM instance
client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="not-needed"
)

# Transcribe a single audio file
with open("meeting.mp3", "rb") as audio_file:
    transcription = client.audio.transcriptions.create(
        model="mistralai/Voxtral-Mini-4B-Realtime-2602",
        file=audio_file,
        language="en",  # Optional: specify language
        response_format="verbose_json"  # Options: json, text, verbose_json
    )

print(transcription.text)

# With verbose_json, you also get timestamps
if hasattr(transcription, 'segments'):
    for segment in transcription.segments:
        print(f"[{segment.start}s - {segment.end}s]: {segment.text}")
```

---

### Real-time Streaming (WebSocket API) - Advanced

⚠️ **Note**: Real-time streaming requires GPU deployment for low latency. This is an advanced use case.

For real-time audio streaming with incremental transcription, use the WebSocket API:

**Python WebSocket client example:**

```python
import asyncio
import json
import base64
import websockets

async def stream_audio_transcription(audio_path: str):
    uri = "ws://localhost:8000/v1/realtime"
    
    async with websockets.connect(uri) as ws:
        # Wait for session creation
        response = json.loads(await ws.recv())
        print(f"Session ID: {response['id']}")
        
        # Configure session
        await ws.send(json.dumps({
            "type": "session.update",
            "model": "mistralai/Voxtral-Mini-4B-Realtime-2602"
        }))
        
        # Read and send audio file
        with open(audio_path, "rb") as f:
            audio_data = f.read()
            
            # Send in chunks (e.g., 4KB)
            chunk_size = 4096
            for i in range(0, len(audio_data), chunk_size):
                chunk = audio_data[i:i + chunk_size]
                await ws.send(json.dumps({
                    "type": "input_audio_buffer.append",
                    "audio": base64.b64encode(chunk).decode("utf-8")
                }))
        
        # Signal end of audio
        await ws.send(json.dumps({
            "type": "input_audio_buffer.commit",
            "final": True
        }))
        
        # Receive transcription results
        print("Transcription: ", end="", flush=True)
        while True:
            response = json.loads(await ws.recv())
            
            if response["type"] == "transcription.delta":
                # Incremental transcription updates
                print(response["delta"], end="", flush=True)
            elif response["type"] == "transcription.done":
                # Final complete transcription
                print(f"\n\nComplete: {response['text']}")
                break

# Run the transcription
asyncio.run(stream_audio_transcription("audio.mp3"))
```

**Note:** For WebSocket streaming, audio must be in PCM16 format at 16kHz sample rate for optimal performance.

### Audio Format Conversion

If you need to convert audio to the optimal format (PCM16 @ 16kHz):

```python
import librosa
import soundfile as sf

# Load audio and convert to 16kHz mono
audio, sr = librosa.load("input.mp3", sr=16000, mono=True)

# Save as WAV (PCM16)
sf.write("output.wav", audio, 16000, subtype='PCM_16')
```

## Configuration

### Whisper Configuration (docker-compose-whisper.yaml)

Whisper is powered by **Speaches** (faster-whisper server) with native M4A support.

**Environment Variables:**

- `WHISPER__MODEL`: Model size - `tiny`, `base` (recommended), `small`, `medium`, `large`, `turbo`
  - `tiny` - Fastest, less accurate (~40MB)
  - `base` - **Recommended for CPU** - good balance (~150MB)
  - `small` - Better accuracy, slower (~500MB)
  - `medium` - High accuracy, slow (~1.5GB)
  - `large` - Best accuracy, very slow (~3GB)
  - `turbo` - Latest OpenAI model, faster than large

- `WHISPER__COMPUTE_TYPE`: CPU optimization - `int8` (recommended), `int8_float32`, `float16`
  - `int8` - **Fastest on CPU**, 4x faster than original
  - Lower precision = faster, but minimal accuracy loss

- `WHISPER__DEVICE`: `cpu` or `cuda` (use `cpu` for this setup)

- `WHISPER__LANGUAGE`: Default language (optional, auto-detect if not set)
  - Examples: `en`, `es`, `fr`, `de`, `zh`, etc.

- `WHISPER__WORD_TIMESTAMPS`: Enable word-level timestamps (`true`/`false`)

- `WHISPER__CPU_THREADS`: Number of CPU threads (auto-detect by default)

**Example - Optimize for speed:**

```yaml
environment:
  - WHISPER__MODEL=tiny  # Fastest model
  - WHISPER__COMPUTE_TYPE=int8  # Maximum CPU optimization
  - WHISPER__LANGUAGE=en  # Skip language detection
  - WHISPER__CPU_THREADS=4
```

**Example - Optimize for accuracy:**

```yaml
environment:
  - WHISPER__MODEL=small  # Better accuracy
  - WHISPER__COMPUTE_TYPE=int8
  - WHISPER__WORD_TIMESTAMPS=true  # Get word-level timestamps
```

**Port Configuration:**

Whisper runs on port 9000 (mapped from internal 8000). To change external port:

```yaml
ports:
  - "YOUR_PORT:8000"  # Note: internal port is 8000
```

**Memory Limits:**

Adjust based on your system and model size:

```yaml
deploy:
  resources:
    limits:
      memory: 8G  # Increase for larger models
    reservations:
      memory: 4G
```

### Voxtral Configuration (docker-compose.yaml)

**Environment Variables:**

- `VLLM_VERSION`: vLLM Docker image version (default: `latest`)
- `VLLM_DISABLE_COMPILE_CACHE`: Disable compilation cache (set to `1`)
- `VLLM_MAX_AUDIO_CLIP_FILESIZE_MB`: Maximum audio file size in MB (default: `25`)

**Port Configuration:**

Voxtral runs on port 8000 by default. To change:

```yaml
ports:
  - "YOUR_PORT:8000"
```

**Audio Configuration:**

For optimal performance with long recordings, you may need to increase the maximum model length:

```yaml
environment:
  - VLLM_DISABLE_COMPILE_CACHE=1
entrypoint:
  - vllm
  - serve
  - mistralai/Voxtral-Mini-4B-Realtime-2602
  - --compilation_config
  - '{"cudagraph_mode": "PIECEWISE"}'
  - --max-model-len
  - "45000"  # For ~1 hour recordings (formula: recording_seconds / 0.08)
```

**Recording length guidelines:**
- Default max-model-len: 131072 tokens (~3 hours)
- For 1 hour: --max-model-len 45000
- For 30 minutes: --max-model-len 22500
- Formula: `recording_seconds / 0.08`

**GPU Configuration:**

By default, all available GPUs are used. To limit GPU usage, modify the `docker-compose.yaml`:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1  # Use only 1 GPU
          capabilities: [gpu]
```

## API Endpoints

### Whisper (Speaches) - Port 9000

**OpenAI-compatible endpoints:**
- `POST /v1/audio/transcriptions` - Transcribe audio to text
  - Parameters: `file` (required), `model`, `language`, `response_format` (json, text, verbose_json)
  - **Supports M4A files natively!**
- `POST /v1/audio/translations` - Translate audio to English
- `GET /v1/models` - List available models
- `GET /health` - Health check

**Full documentation:** [Speaches API Docs](https://github.com/speaches-ai/speaches)

### Voxtral vLLM (Port 8000)

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics
- `GET /v1/models` - List available models
- `POST /v1/audio/transcriptions` - Audio transcription (OpenAI-compatible)
- `POST /v1/audio/translations` - Audio translation to English
- `WS /v1/realtime` - WebSocket streaming for real-time transcription

**Full documentation:**
- [vLLM Audio API](https://docs.vllm.ai/en/latest/serving/openai_compatible_server/#transcriptions-api)
- [OpenAI Audio API Reference](https://platform.openai.com/docs/api-reference/audio)

## Monitoring

**View logs:**

```bash
# For Whisper (CPU)
docker compose -f docker-compose-whisper.yaml logs -f

# For Voxtral (GPU)
docker compose logs -f
```

**Check resource usage:**

```bash
# For Whisper
docker stats whisper-asr

# For Voxtral
docker stats voxtral-voxtral-1
```

**Monitor GPU usage (Voxtral only):**

```bash
nvidia-smi -l 1
```

**Monitor CPU usage (Whisper):**

```bash
# Monitor overall CPU usage
htop

# Or use docker stats
docker stats --no-stream
```

## Troubleshooting

### Whisper Service Issues

**Service won't start:**

1. Check if container is running:
```bash
docker compose -f docker-compose-whisper.yaml ps
```

2. View logs:
```bash
docker compose -f docker-compose-whisper.yaml logs
```

3. Verify you have enough disk space for models (~150MB for base model)

**Slow transcription:**

This is expected on CPU. To improve speed:
- Use a smaller model: Change `ASR_MODEL=tiny` in docker-compose-whisper.yaml
- Use `faster_whisper` engine (default, already optimized)
- Process shorter audio clips
- Upgrade CPU or add more cores

**Out of memory:**

Increase Docker memory limits or use a smaller model:
```yaml
environment:
  - ASR_MODEL=tiny  # Smallest, fastest
```

**Model download fails:**

Check internet connection and disk space. Models are cached in the volume, so subsequent starts are faster.

### Voxtral Service Issues (GPU)

**Service won't start:**

1. Verify GPU is available:
```bash
nvidia-smi
```

2. Check Docker GPU support:
```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

3. View logs for errors:
```bash
docker compose logs
```

**Voxtral CPU deployment fails with "Engine core initialization failed":**

This is expected. Voxtral requires GPU and does not work on CPU with current vLLM versions.

**Solutions:**
1. **Use Whisper instead** (recommended for CPU):
   ```bash
   docker compose -f docker-compose-whisper.yaml up -d
   ```

2. **Use GPU deployment** if you have GPU access:
   ```bash
   docker compose up -d --build
   ```

### General Issues

**Out of memory errors:**

**Whisper:** Use a smaller model or increase Docker memory limits.

**Voxtral:** The model requires approximately 8GB of VRAM. Use a GPU with sufficient memory.

**Audio file too large:**

For Voxtral, increase the file size limit:

```yaml
environment:
  - VLLM_MAX_AUDIO_CLIP_FILESIZE_MB=100
```

**Unsupported audio format:**

Both services support most formats. If you encounter issues, convert using ffmpeg:

```bash
ffmpeg -i input.avi -vn -ar 16000 -ac 1 output.wav
```

**Model download is slow:**

Models are downloaded on first run and cached. Subsequent starts are much faster.

For Whisper, models are ~40MB (tiny) to ~3GB (large).
For Voxtral, the model is ~4GB.

## Stopping the Service

**Whisper (CPU):**

```bash
docker compose -f docker-compose-whisper.yaml down
```

**Voxtral (GPU):**

```bash
docker compose down
```

**To also remove cached models:**

```bash
# Whisper
docker compose -f docker-compose-whisper.yaml down -v

# Voxtral
docker compose down -v
```

## Tech Stack

### Whisper (Speaches)
- **Speaches**: OpenAI-compatible Whisper API server
- **faster-whisper**: Optimized Whisper implementation (4x faster on CPU)
- **PyAV**: Bundled FFmpeg for universal audio format support (including M4A)
- **Docker**: Containerization

### Voxtral vLLM
- **vLLM**: High-performance LLM inference engine
- **Voxtral-Mini-4B-Realtime-2602**: Mistral AI's real-time transcription model
- **CUDA**: GPU acceleration
- **Docker**: Containerization
- **Audio Processing**: librosa, soundfile, soxr

## Model Comparison

| Feature | Whisper (Speaches/CPU) | Voxtral (GPU) |
|---------|---------------|---------------|
| **Hardware** | ✅ CPU (no GPU needed) | GPU required (8GB+ VRAM) |
| **M4A Support** | ✅ **Native (iPhone voice memos)** | ✅ Yes |
| **Model Size** | 40MB - 3GB (configurable) | ~4GB |
| **Processing Speed (1min audio)** | 5-30s (depends on model size) | 2-5s |
| **Languages** | 99 languages | 13 languages |
| **Batch Transcription** | ✅ Yes | ✅ Yes |
| **Real-time Streaming** | ❌ No | ✅ Yes (<500ms) |
| **Word Timestamps** | ✅ Yes | ✅ Yes |
| **API Compatibility** | ✅ OpenAI-compatible | ✅ OpenAI-compatible |
| **Docker Image** | `ghcr.io/speaches-ai/speaches` | Custom vLLM build |
| **Port** | 9000 | 8000 |
| **Best For** | **iPhone voice memos**, CPU users, batch processing | GPU users, real-time, high throughput |

## Supported Languages

**Whisper** supports 99 languages including:
- English, Spanish, French, German, Italian, Portuguese
- Chinese, Japanese, Korean, Arabic, Russian, Hindi
- And 87 more languages ([full list](https://github.com/openai/whisper#available-models-and-languages))

**Voxtral** supports 13 languages:
- English (en), Spanish (es), French (fr), Portuguese (pt)
- Hindi (hi), German (de), Dutch (nl), Italian (it)
- Arabic (ar), Chinese (zh), Japanese (ja), Korean (ko), Russian (ru)

## License

MIT License - Copyright 2026 innFactory AI Consulting

## Resources

### Whisper (Speaches)
- [Speaches GitHub](https://github.com/speaches-ai/speaches)
- [OpenAI Whisper](https://github.com/openai/whisper)
- [faster-whisper](https://github.com/SYSTRAN/faster-whisper)

### Voxtral vLLM
- [vLLM Documentation](https://docs.vllm.ai/)
- [vLLM Audio/Realtime API](https://docs.vllm.ai/en/latest/serving/openai_compatible_server/#realtime-api)
- [Mistral AI Voxtral](https://mistral.ai/news/voxtral/)
- [Voxtral HuggingFace Model](https://huggingface.co/mistralai/Voxtral-Mini-4B-Realtime-2602)
- [OpenAI Audio API Reference](https://platform.openai.com/docs/api-reference/audio)
