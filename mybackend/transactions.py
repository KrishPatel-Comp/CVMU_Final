from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import re

from database import get_db
from models import Transaction, CategoryKeyword, User
from schemas import TransactionCreate, TransactionUpdate

router = APIRouter(prefix="/transactions", tags=["Transactions"])

# -----------------------------
# Helper function to detect category
# -----------------------------
def detect_category(merchant_name: str, db: Session):
    merchant = merchant_name.lower()
    keywords = db.query(CategoryKeyword).all()

    for k in keywords:
        if k.keyword.lower() in merchant:
            return k.category
    return "Others"

# -----------------------------
# Manual transaction entry
# -----------------------------
@router.post("/")
def create_transaction(request: TransactionCreate, db: Session = Depends(get_db)):

    category = request.category if request.category else detect_category(request.merchant_name, db)

    new_transaction = Transaction(
        user_id=request.user_id,
        amount=request.amount,
        merchant_name=request.merchant_name,
        category=category,
        note=request.note,
        raw_sms=request.raw_sms
    )

    db.add(new_transaction)
    db.commit()
    db.refresh(new_transaction)

    return {
        "message": "Transaction saved",
        "id": new_transaction.id,
        "category_detected": category
    }

@router.put("/{transaction_id}")
def update_transaction(transaction_id: int, request: TransactionUpdate, db: Session = Depends(get_db)):
    tx = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    if request.category is not None:
        tx.category = request.category
    if request.note is not None:
        tx.note = request.note
    if request.amount is not None:
        tx.amount = request.amount
    if request.merchant_name is not None:
        tx.merchant_name = request.merchant_name
        
    db.commit()
    db.refresh(tx)
    return {"message": "Transaction updated", "transaction": {
        "id": tx.id,
        "category": tx.category,
        "note": tx.note,
        "amount": float(tx.amount),
        "merchant_name": tx.merchant_name
    }}

@router.delete("/{transaction_id}")
def delete_transaction(transaction_id: int, db: Session = Depends(get_db)):
    tx = db.query(Transaction).filter(Transaction.id == transaction_id).first()
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    db.delete(tx)
    db.commit()
    return {"message": "Transaction deleted"}

# -----------------------------
# Get all transactions
# -----------------------------
@router.get("/")
def get_transactions(user_id: int, db: Session = Depends(get_db)):
    transactions = db.query(Transaction).filter(Transaction.user_id == user_id).all()
    return transactions

# -----------------------------
# Process SMS and automatically create transaction
# -----------------------------
@router.post("/process-sms")
def process_sms(user_id: int, raw_sms: str, db: Session = Depends(get_db)):

    # 1️⃣ Get user info
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # 2️⃣ Extract amount
    amount_match = re.search(r"(?:Rs\.?|INR|₹)\s?(\d+)", raw_sms)
    if not amount_match:
        raise HTTPException(status_code=400, detail="Amount not found")
    amount = float(amount_match.group(1))

    # 3️⃣ Extract merchant
    merchant_match = re.search(r"(?:to|at)\s([A-Za-z0-9]+)", raw_sms)
    merchant = merchant_match.group(1) if merchant_match else "Unknown"

    # 4️⃣ Detect category
    category = detect_category(merchant, db)

    # 5️⃣ Calculate suggested food budget
    if user.user_type in ["student", "unemployed"]:
        suggested_food_budget = user.monthly_budget * 0.5 / 4  # weekly approx
    else:
        suggested_food_budget = user.salary * 0.5 / 30  # daily approx

    # 6️⃣ Split transactions if overspend
    transactions_to_save = []

    if category == "Food" and amount > suggested_food_budget:
        main_amount = suggested_food_budget
        extra_amount = amount - suggested_food_budget

        # Main Food transaction
        transactions_to_save.append(Transaction(
            user_id=user_id,
            amount=main_amount,
            merchant_name=merchant,
            category="Food",
            raw_sms=raw_sms
        ))

        # Overspend → Fun category
        transactions_to_save.append(Transaction(
            user_id=user_id,
            amount=extra_amount,
            merchant_name=merchant,
            category="Fun",
            raw_sms=raw_sms
        ))

    else:
        transactions_to_save.append(Transaction(
            user_id=user_id,
            amount=amount,
            merchant_name=merchant,
            category=category,
            raw_sms=raw_sms
        ))

    # 7️⃣ Save all transactions
    for tx in transactions_to_save:
        db.add(tx)
    db.commit()

    # 8️⃣ Return all transaction splits
    return {
        "message": "Transaction processed",
        "transactions": [
            {"merchant": tx.merchant_name, "amount": float(tx.amount), "category": tx.category}
            for tx in transactions_to_save
        ]
    }