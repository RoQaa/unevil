import requests

SIGHTENGINE_API_USER = "1130323748"
SIGHTENGINE_API_SECRET = "KgLiiWfEgeBrKKb7xTGB7otycRBy2aVV"

response = requests.post(
    "https://api.sightengine.com/1.0/check.json",
    data={
        "models": "genai",
        "api_user": SIGHTENGINE_API_USER,
        "api_secret": SIGHTENGINE_API_SECRET,
    },
    # files={"media": ("image.jpg", b"123", "image/jpeg")}  # sending dummy bytes might fail or just return not image
)
print(response.status_code)
print(response.text)
