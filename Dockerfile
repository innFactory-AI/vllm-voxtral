ARG VLLM_VERSION=latest

FROM vllm/vllm-openai:${VLLM_VERSION}

RUN pip install --no-cache-dir \
    soxr \
    librosa \
    soundfile \
    && pip install --no-cache-dir --upgrade transformers

ENV VLLM_DISABLE_COMPILE_CACHE=1

CMD ["vllm", "serve", "mistralai/Voxtral-Mini-4B-Realtime-2602", \
     "--compilation_config", "'{\"cudagraph_mode\": \"PIECEWISE\"}'"]
