import requests

response = requests.get(
    "https://huggingface.co/api/models/MelodyMachine/Deepfake-Audio-Detection-V2",
    timeout=10
)
print(f"MelodyMachine: {response.status_code}")

response = requests.get(
    "https://huggingface.co/api/models/piotroles/wav2vec2-large-xlsr-53-deepfake-detection",
    timeout=10
)
print(f"piotroles: {response.status_code}")
