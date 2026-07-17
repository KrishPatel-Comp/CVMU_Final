import requests

BASE_URL = "http://localhost:8000"

def test_transactions():
    user_id = 1 # Assuming user 1 exists
    
    # Create
    print("Creating transaction...")
    resp = requests.post(f"{BASE_URL}/transactions/", json={
        "user_id": user_id,
        "amount": 500.0,
        "merchant_name": "Test Merchant",
        "category": "Food",
        "note": "A test note",
        "raw_sms": "Rs 500 spent at Test Merchant"
    })
    print(resp.json())
    
    # Get
    print("\nGetting transactions...")
    resp = requests.get(f"{BASE_URL}/transactions/", params={"user_id": user_id})
    txs = resp.json()
    print(f"Found {len(txs)} transactions")
    for tx in txs:
        print(f"- {tx['merchant_name']}: {tx['amount']} ({tx['transaction_date']})")

if __name__ == "__main__":
    try:
        test_transactions()
    except Exception as e:
        print(f"Error: {e}")
