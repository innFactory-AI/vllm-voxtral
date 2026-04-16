# vLLM Voxtral

Docker containerization for deploying Mistral AI's **Voxtral-Mini-4B-Realtime-2602** model using vLLM - a high-performance speech transcription (ASR) model with OpenAI-compatible API.

**Voxtral** is a multilingual audio transcription model that supports 13 languages. Perfect for:
- 📁 **Batch transcription**: Upload audio files and get text transcriptions
- 🎙️ **Real-time streaming**: Live transcription with sub-500ms latency (GPU only)
- 🌍 **Multilingual support**: Transcribe in 13 different languages
- 🔌 **OpenAI-compatible API**: Drop-in replacement for OpenAI's transcription API

## Common Use Cases

1. **File-based transcription** (Recommended - Works on both GPU and CPU):
   - Upload an audio file (MP3, WAV, M4A, etc.)
   - Get back the full transcription
   - No real-time requirements
   - Perfect for: Meeting recordings, podcasts, voicemails, interviews

2. **Real-time streaming transcription** (GPU required):
   - Stream audio as it's being recorded
   - Get incremental transcription updates
   - Sub-500ms latency
   - Perfect for: Live captioning, voice assistants

## Prerequisites

### For GPU Deployment
- Docker and Docker Compose
- NVIDIA GPU with CUDA support (minimum 8GB VRAM)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Best for: Production, fast processing, real-time streaming

### For CPU Deployment
- Docker and Docker Compose
- x86_64 or ARM64 CPU (8GB+ RAM recommended)
- Best for: Development, testing, batch processing where speed is not critical

## Quick Start

### GPU Deployment

1. **Build and start the service:**

```bash
docker compose up -d --build
```

### CPU Deployment

1. **Start the CPU service:**

```bash
docker compose -f docker-compose-cpu.yaml up -d
```

### Verify Service is Running

2. **Check health:**

```bash
curl http://localhost:8000/health
```

3. **Test with a quick transcription:**

```bash
curl -X POST "http://localhost:8000/v1/audio/transcriptions" \
  -F "file=@your-audio.mp3" \
  -F "model=mistralai/Voxtral-Mini-4B-Realtime-2602"
```

The service will:
- Download the Voxtral model from HuggingFace on first run (cached afterwards)
- Start the vLLM server on port 8000
- Be ready to accept audio files for transcription

## Model Capabilities

**Voxtral-Mini-4B-Realtime-2602** is a speech-to-text transcription model that:
- Supports 13 languages: English, Spanish, French, Portuguese, Hindi, German, Dutch, Italian, Arabic, Chinese, Japanese, Korean, Russian
- Works in two modes:
  - **Batch mode**: Upload complete audio files for transcription (works on GPU and CPU)
  - **Streaming mode**: Real-time transcription with <500ms latency (GPU only)
- Handles various audio formats: MP3, WAV, M4A, FLAC, OGG, and more

## Usage Examples

### Batch Transcription (File Upload → Text)

This is the most common use case and works well on both GPU and CPU deployments.

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

### Environment Variables

**Common Variables:**
- `VLLM_VERSION`: vLLM Docker image version (default: `latest`)
- `VLLM_DISABLE_COMPILE_CACHE`: Disable compilation cache (set to `1`)
- `VLLM_MAX_AUDIO_CLIP_FILESIZE_MB`: Maximum audio file size in MB (default: `25`)

**CPU-Specific Variables** (for `docker-compose-cpu.yaml`):
- `VLLM_CPU_KVCACHE_SPACE`: KV cache size in GB (default: `40`)
- `VLLM_CPU_OMP_THREADS_BIND`: CPU core binding (set to `auto` for automatic)
- `VLLM_CPU_NUM_OF_RESERVED_CPU`: Number of CPU cores reserved for framework (default: `1`)

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
# For GPU deployment
docker compose logs -f

# For CPU deployment
docker compose -f docker-compose-cpu.yaml logs -f
```

**Check resource usage:**

```bash
# For GPU deployment
docker stats voxtral-voxtral-1

# For CPU deployment
docker stats voxtral-voxtral-cpu-1
```

**Monitor GPU usage (GPU deployment only):**

```bash
nvidia-smi -l 1
```

**Monitor CPU usage (CPU deployment):**

```bash
# Monitor overall CPU usage
htop

# Or use docker stats for container-specific metrics
docker stats --no-stream
```

## Troubleshooting

### Service won't start (GPU deployment)

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

### Service won't start (CPU deployment)

1. Check if the container is running:
```bash
docker compose -f docker-compose-cpu.yaml ps
```

2. View logs for errors:
```bash
docker compose -f docker-compose-cpu.yaml logs
```

3. Verify you have enough RAM (model requires ~8-16GB system memory)

### Out of memory errors

**GPU deployment**: The Voxtral-Mini-4B model requires approximately 8GB of VRAM. For long audio files, you may need to increase `--max-model-len` or use a GPU with more memory.

**CPU deployment**: Increase Docker memory limits or system swap space. The model requires 8-16GB of system RAM.

### Slow transcription performance (CPU deployment)

This is expected behavior for CPU inference. See the comparison table above for expected processing times.

**Performance tips for CPU:**
- Process shorter audio clips
- Use batch processing for multiple files
- Consider GPU deployment if you need faster results
- Ensure your system has enough RAM (8-16GB recommended)

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

**GPU deployment:**

```bash
docker compose down
```

**CPU deployment:**

```bash
docker compose -f docker-compose-cpu.yaml down
```

To also remove the cached model (both deployments):

```bash
# GPU
docker compose down -v

# CPU
docker compose -f docker-compose-cpu.yaml down -v
```

## Tech Stack

- **vLLM**: High-performance LLM inference engine with audio support (GPU and CPU)
- **Voxtral-Mini-4B-Realtime-2602**: Mistral AI's real-time speech transcription model
- **Docker**: Containerization
- **CUDA**: GPU acceleration (GPU deployment only)
- **Audio Processing**: librosa, soundfile, soxr

## Deployment Comparison

| Feature | GPU Deployment | CPU Deployment |
|---------|----------------|----------------|
| **Processing Speed** | ⚡ Very Fast (2-5s for 1min audio) | 🐌 Slower (15-30s for 1min audio) |
| **Best For** | Production, high volume, real-time | Development, testing, low volume |
| **Batch Transcription** | ✅ Excellent | ✅ Good (if speed isn't critical) |
| **Real-time Streaming** | ✅ Yes (<500ms latency) | ❌ No (too slow) |
| **Hardware Required** | NVIDIA GPU (8GB+ VRAM) | x86_64 or ARM64 CPU (8GB+ RAM) |
| **Docker Compose File** | `docker-compose.yaml` | `docker-compose-cpu.yaml` |
| **Docker Image** | `voxtral-vllm` (custom built) | `vllm/vllm-openai-cpu` |
| **Cost** | Higher (GPU infrastructure) | Lower (standard CPU) |

**Recommendation:**
- 📁 **Batch transcription (file upload)**: Both GPU and CPU work fine. Use GPU for faster processing, CPU if speed isn't critical.
- 🎙️ **Real-time streaming**: GPU required - CPU is too slow for real-time.

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
