import requests
import json
import sys
import os
from dotenv import load_dotenv

load_dotenv()

sys.stdout.reconfigure(encoding='utf-8')

HUGGINGFACE_API_KEY = os.getenv("HUGGINGFACE_API_KEY", "")

headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}

try:
    print("Checking Hugging Face API connection...")
    response = requests.get(
        "https://huggingface.co/api/models/MelodyMachine/Deepfake-Audio-Detection-V2",
        headers=headers,
        timeout=10
    )
    
    if response.status_code == 200:
        print("[SUCCESS] The Token is valid and the model is reachable.")
        data = response.json()
        print(f"Model ID: {data.get('id')}")
        print(f"Pipeline Tag: {data.get('pipeline_tag')}")
        print("\nAll Good! Your backend will now correctly use Hugging Face for audio.")
    elif response.status_code == 401:
        print("[ERROR] The Token is INVALID or expired (401 Unauthorized).")
    elif response.status_code == 404:
        print("[ERROR] Model not found (404).")
    else:
        print(f"[UNKNOWN] Status {response.status_code}")

except Exception as e:
    print(f"[CONNECTION ERROR] {e}")
