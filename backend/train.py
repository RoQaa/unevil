import os
import librosa
import numpy as np
from sklearn.ensemble import RandomForestClassifier
import joblib

def extract_audio_features(file_path):
    y, sr = librosa.load(file_path, sr=None)

    mfcc = np.mean(librosa.feature.mfcc(y=y, sr=sr), axis=1)
    spectral_centroid = np.mean(librosa.feature.spectral_centroid(y=y, sr=sr))
    zero_crossing = np.mean(librosa.feature.zero_crossing_rate(y))

    return np.concatenate([mfcc, [spectral_centroid, zero_crossing]])

X = []
y = []

# Human = 0
for file in os.listdir("dataset/human"):
    path = os.path.join("dataset/human", file)
    features = extract_audio_features(path)
    X.append(features)
    y.append(0)

# AI = 1
for file in os.listdir("dataset/ai"):
    path = os.path.join("dataset/ai", file)
    features = extract_audio_features(path)
    X.append(features)
    y.append(1)

# تدريب الموديل
model = RandomForestClassifier(n_estimators=100)
model.fit(X, y)

# حفظه
joblib.dump(model, "audio_model.pkl")

print("Model saved ✔️")