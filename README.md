# vLLM Voxtral

Docker containerization for deploying Mistral AI's **Voxtral-Mini-4B-Realtime-2602** model using vLLM - a high-performance real-time speech transcription (ASR) model with OpenAI-compatible API.

**Voxtral** is a multilingual, real-time audio transcription model that supports 13 languages with sub-500ms latency, perfect for live transcription, voice assistants, and streaming audio applications.

## Prerequisites

- Docker and Docker Compose
- NVIDIA GPU with CUDA support
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

## Quick Start

1. **Build and start the service:**

```bash
docker compose up -d --build
```

The service will:
- Download the Voxtral model from HuggingFace (first run only)
- Start the vLLM server on port 8000
- Cache the model in a persistent volume

2. **Check if the service is running:**

```bash
curl http://localhost:8000/health
```

3. **List available models:**

```bash
curl http://localhost:8000/v1/models
```

## Model Capabilities

**Voxtral-Mini-4B-Realtime-2602** is a speech-to-text transcription model that:
- Transcribes audio in real-time with <500ms latency
- Supports 13 languages: English, Spanish, French, Portuguese, Hindi, German, Dutch, Italian, Arabic, Chinese, Japanese, Korean, Russian
- Processes streaming audio incrementally as it arrives
- Achieves offline-level accuracy with real-time performance

## Usage Examples

### Audio Transcription (REST API)

The transcription endpoint accepts audio files and returns text transcriptions.

**Basic transcription with curl:**

```bash
curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
  -F "file=@/path/to/audio.mp3" \
  -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602"
```

**With language specification:**

```bash
curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
  -F "file=@/path/to/audio.wav" \
  -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602" \
  -F "language=en" \
  -F "response_format=json"
```

**Verbose JSON response (includes timestamps):**

```bash
curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
  -F "file=@/path/to/audio.m4a" \
  -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602" \
  -F "language=es" \
  -F "response_format=verbose_json"
```

**Supported audio formats:**
- MP3, MP4, MPEG, MPGA, M4A
- WAV, WEBM
- FLAC, OGG

### Using OpenAI Python Client

You can use the official OpenAI Python client for audio transcription:

```python
from openai import OpenAI

# Point to your local vLLM instance
client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="not-needed"
)

# Transcribe an audio file
with open("audio.mp3", "rb") as audio_file:
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

### Real-time Streaming (WebSocket API)

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

### Environment Variables

- `VLLM_VERSION`: vLLM Docker image version (default: `latest`)
- `VLLM_DISABLE_COMPILE_CACHE`: Disable compilation cache (set to `1`)
- `VLLM_MAX_AUDIO_CLIP_FILESIZE_MB`: Maximum audio file size in MB (default: `25`)

### Audio Configuration

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

### Port Configuration

The service runs on port 8000 by default. To change it, modify the `docker-compose.yaml`:

```yaml
ports:
  - "YOUR_PORT:8000"
```

### GPU Configuration

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

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics
- `GET /v1/models` - List available models
- `POST /v1/audio/transcriptions` - Audio transcription (OpenAI-compatible)
- `POST /v1/audio/translations` - Audio translation to English
- `WS /v1/realtime` - WebSocket streaming for real-time transcription

For full API documentation, see:
- [vLLM Audio API](https://docs.vllm.ai/en/latest/serving/openai_compatible_server/#transcriptions-api)
- [OpenAI Audio API Reference](https://platform.openai.com/docs/api-reference/audio)

## Monitoring

**View logs:**

```bash
docker compose logs -f
```

**Check resource usage:**

```bash
docker stats voxtral-voxtral-1
```

**Monitor GPU usage:**

```bash
nvidia-smi -l 1
```

## Troubleshooting

### Service won't start

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

### Out of memory errors

The Voxtral-Mini-4B model requires approximately 8GB of VRAM. For long audio files, you may need to increase `--max-model-len` or use a GPU with more memory.

### Audio file too large

Increase the maximum file size limit:

```yaml
environment:
  - VLLM_MAX_AUDIO_CLIP_FILESIZE_MB=100
```

### Unsupported audio format

Convert your audio to a supported format (MP3, WAV, M4A, etc.) using ffmpeg:

```bash
ffmpeg -i input.avi -vn -ar 16000 -ac 1 output.wav
```

### Model download is slow

The model is downloaded on first run and cached. Subsequent starts will be much faster. To pre-download the model:

```bash
docker compose run --rm voxtral python -c "from huggingface_hub import snapshot_download; snapshot_download('mistralai/Voxtral-Mini-4B-Realtime-2602')"
```

## Stopping the Service

```bash
docker compose down
```

To also remove the cached model:

```bash
docker compose down -v
```

## Tech Stack

- **vLLM**: High-performance LLM inference engine with audio support
- **Voxtral-Mini-4B-Realtime-2602**: Mistral AI's real-time speech transcription model
- **Docker**: Containerization
- **CUDA**: GPU acceleration
- **Audio Processing**: librosa, soundfile, soxr

## Supported Languages

Voxtral supports transcription in 13 languages:
- English (en)
- Spanish (es)
- French (fr)
- Portuguese (pt)
- Hindi (hi)
- German (de)
- Dutch (nl)
- Italian (it)
- Arabic (ar)
- Chinese (zh)
- Japanese (ja)
- Korean (ko)
- Russian (ru)

## License

MIT License - Copyright 2026 innFactory AI Consulting

## Resources

- [vLLM Documentation](https://docs.vllm.ai/)
- [vLLM Audio/Realtime API](https://docs.vllm.ai/en/latest/serving/openai_compatible_server/#realtime-api)
- [Mistral AI Voxtral](https://mistral.ai/news/voxtral/)
- [OpenAI Audio API Reference](https://platform.openai.com/docs/api-reference/audio)
- [Voxtral HuggingFace Model](https://huggingface.co/mistralai/Voxtral-Mini-4B-Realtime-2602)
