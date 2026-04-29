# import requests

# response = requests.get(
#     "https://huggingface.co/api/models/MelodyMachine/Deepfake-Audio-Detection-V2",
#     timeout=10
# )
# print(f"MelodyMachine: {response.status_code}")

# response = requests.get(
#     "https://huggingface.co/api/models/piotroles/wav2vec2-large-xlsr-53-deepfake-detection",
#     timeout=10
# )
# print(f"piotroles: {response.status_code}")

# import requests

# API_URL = "https://api-inference.huggingface.co/models/MelodyMachine/Deepfake-Audio-Detection-V2"

# headers = {
#     "Authorization": "Bearer YOUR_TOKEN"
# }

# with open(r"E:\unevil\Ai_test\generate_beat_box_au_#1-1777293003545.wav", "rb") as f:
#     res = requests.post(API_URL, headers=headers, data=f)

# print(res.status_code)
# print(res.text)

from transformers import AutoFeatureExtractor, AutoModelForAudioClassification
import torch
import librosa

MODEL_NAME = "garystafford/wav2vec2-deepfake-voice-detector"

feature_extractor = AutoFeatureExtractor.from_pretrained(MODEL_NAME)
model = AutoModelForAudioClassification.from_pretrained(MODEL_NAME)

def detect_fake_audio(audio_path):
    audio, sr = librosa.load(audio_path, sr=16000)

    inputs = feature_extractor(
        audio,
        sampling_rate=16000,
        return_tensors="pt",
        padding=True
    )

    with torch.no_grad():
        logits = model(**inputs).logits

    predicted_class_id = torch.argmax(logits, dim=-1).item()
    confidence = torch.softmax(logits, dim=-1)[0][predicted_class_id].item()

    label = model.config.id2label[predicted_class_id]

    return {
        "label": label,
        "confidence": round(confidence * 100, 2)
    }
    
result = detect_fake_audio("..\Ai_test\AI Sound.mp3")
print(result)