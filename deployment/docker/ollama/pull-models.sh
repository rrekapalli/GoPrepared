#!/usr/bin/env bash
set -euo pipefail
ollama pull llama3.2 || ollama pull mistral
