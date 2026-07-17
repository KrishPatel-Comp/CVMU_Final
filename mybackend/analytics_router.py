from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta

from database import get_db
from models import Transaction

budgets = {
    "Food": 3000,
    "Shopping": 5000,
    "Transport": 2000,
    "Bills": 4000,
    "Entertainment": 2500
}

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/monthly-summary")
def monthly_summary(user_id: int, db: Session = Depends(get_db)):

    current_month = datetime.now().month
    current_year = datetime.now().year

    transactions = db.query(Transaction).filter(
        func.extract('month', Transaction.transaction_date) == current_month,
        func.extract('year', Transaction.transaction_date) == current_year,
        Transaction.user_id == user_id
    ).all()

    total_spent = sum([t.amount for t in transactions])

    category_breakdown = {}

    for t in transactions:
        if t.category in category_breakdown:
            category_breakdown[t.category] += float(t.amount)
        else:
            category_breakdown[t.category] = float(t.amount)

    return {
        "total_spent": float(total_spent),
        "category_breakdown": category_breakdown
    }

@router.get("/monthly-comparison")
def monthly_comparison(user_id: int, db: Session = Depends(get_db)):

    now = datetime.now()

    current_month = now.month
    current_year = now.year

    last_month_date = now - timedelta(days=30)
    last_month = last_month_date.month
    last_month_year = last_month_date.year

    # Current month spending
    current_transactions = db.query(Transaction).filter(
        func.extract('month', Transaction.transaction_date) == current_month,
        func.extract('year', Transaction.transaction_date) == current_year,
        Transaction.user_id == user_id
    ).all()

    current_total = sum([t.amount for t in current_transactions])

    # Last month spending
    last_transactions = db.query(Transaction).filter(
        func.extract('month', Transaction.transaction_date) == last_month,
        func.extract('year', Transaction.transaction_date) == last_month_year,
        Transaction.user_id == user_id
    ).all()

    last_total = sum([t.amount for t in last_transactions])

    difference = float(current_total) - float(last_total)

    # Humorous insights
    if difference < 0:
        message = f"You spent ₹{abs(difference)} less than last month. Your wallet is proud of you 😄"
    elif difference > 0:
        message = f"You spent ₹{difference} more than last month. Maybe Amazon missed you too much 😅"
    else:
        message = "You spent exactly the same as last month. Perfect balance ⚖️"

    return {
        "current_month_spending": float(current_total),
        "last_month_spending": float(last_total),
        "difference": difference,
        "insight": message
    }

@router.get("/top-categories")
def top_categories(user_id: int, db: Session = Depends(get_db)):

    results = db.query(
        Transaction.category,
        func.sum(Transaction.amount).label("total")
    ).filter(
        Transaction.user_id == user_id
    ).group_by(
        Transaction.category
    ).order_by(
        func.sum(Transaction.amount).desc()
    ).all()

    categories = []

    for r in results:
        categories.append({
            "category": r.category,
            "total_spent": float(r.total)
        })

    return categories

@router.get("/recent-transactions")
def recent_transactions(user_id: int, db: Session = Depends(get_db)):

    transactions = db.query(Transaction).filter(
        Transaction.user_id == user_id
    ).order_by(
        Transaction.transaction_date.desc()
    ).limit(5).all()

    results = []

    for t in transactions:
        results.append({
            "merchant": t.merchant_name,
            "amount": float(t.amount),
            "category": t.category,
            "date": t.transaction_date
        })

    return results

@router.get("/budget-warning")
def budget_warning(user_id: int, db: Session = Depends(get_db)):

    results = db.query(
        Transaction.category,
        func.sum(Transaction.amount).label("total")
    ).filter(
        Transaction.user_id == user_id
    ).group_by(Transaction.category).all()

    warnings = []

    for r in results:

        category = r.category
        spent = float(r.total)

        if category in budgets:

            limit = budgets[category]
            percentage = (spent / limit) * 100

            if percentage >= 80 and percentage < 100:
                warnings.append(
                    f"You have used {int(percentage)}% of your {category} budget."
                )

            if percentage >= 100:
                warnings.append(
                    f"You crossed your {category} budget. Time to slow down 😅"
                )

    return {
        "warnings": warnings
    }