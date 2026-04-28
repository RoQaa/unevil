import requests

HIVE_API_KEY = "rA32plxTBppeSChHLViatw=="

headers = {
    "Authorization": f"Token {HIVE_API_KEY}",
    "Accept": "application/json"
}

try:
    # Just checking auth with a dummy call or checking account info if possible
    # A common Hive API endpoint is https://api.thehive.ai/api/v2/task/sync
    response = requests.post("https://api.thehive.ai/api/v2/task/sync", headers=headers, data={'classes': 'ai_generated'})
    print(response.status_code)
    print(response.text)
except Exception as e:
    print(e)
