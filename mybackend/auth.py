from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import re
import random

from database import get_db
from models import User
from schemas import RegisterRequest
from utils import hash_pin

router = APIRouter()
otp_store = {}
def generate_otp():
    return str(random.randint(100000, 999999))

@router.post("/register")
def register_user(request: RegisterRequest, db: Session = Depends(get_db)):

    # Validate PIN (4 or 6 digits only)
    if not re.fullmatch(r"\d{4}|\d{6}", request.pin):
        raise HTTPException(status_code=400, detail="PIN must be 4 or 6 digits")

    # Check if email already exists
    existing_email = db.query(User).filter(User.email == request.email).first()
    if existing_email:
        raise HTTPException(status_code=400, detail="Email already registered")

    # Check if phone already exists
    existing_phone = db.query(User).filter(User.phone == request.phone).first()
    if existing_phone:
        raise HTTPException(status_code=400, detail="Phone number already registered")

    # Hash PIN
    hashed = hash_pin(request.pin)

    # Create new user
    new_user = User(
    first_name=request.first_name,
    last_name=request.last_name,
    email=request.email,
    phone=request.phone,
    hashed_pin=hashed,
    user_type=request.user_type,
    monthly_budget=request.monthly_budget,
    salary=request.salary
)

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {
        "message": "User registered successfully",
        "user": {
            "id": new_user.id,
            "first_name": new_user.first_name,
            "last_name": new_user.last_name,
            "email": new_user.email,
            "phone": new_user.phone,
            "user_type": new_user.user_type,
        },
    }

from schemas import LoginRequest
from utils import verify_pin
from datetime import datetime, timedelta


@router.post("/login")
def login_user(request: LoginRequest, db: Session = Depends(get_db)):

    user = db.query(User).filter(User.email == request.email).first()

    if not user:
        raise HTTPException(status_code=400, detail="Invalid email or PIN")

    # Check if temporarily locked
    if user.locked_until and user.locked_until > datetime.utcnow():
        raise HTTPException(
            status_code=403,
            detail="Account temporarily locked. Try again later."
        )

    # If lock time passed → reset
    if user.locked_until and user.locked_until <= datetime.utcnow():
        user.failed_attempts = 0
        user.locked_until = None
        user.is_locked = False
        db.commit()

    # Verify PIN
    if not verify_pin(request.pin, user.hashed_pin):
        user.failed_attempts += 1

        if user.failed_attempts >= 3:
            user.locked_until = datetime.utcnow() + timedelta(minutes=15)
            user.is_locked = True

        db.commit()

        raise HTTPException(status_code=400, detail="Invalid email or PIN")

    # Successful login
    user.failed_attempts = 0
    user.locked_until = None
    user.is_locked = False
    db.commit()

    return {
        "message": "Login successful",
        "user": {
            "id": user.id,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "email": user.email,
            "phone": user.phone,
            "user_type": user.user_type,
        },
    }

@router.post("/send-otp")
def send_otp(email: str):

    otp = generate_otp()
    otp_store[email] = {
    "otp": otp,
    "expires": datetime.utcnow() + timedelta(minutes=5)
}

    return {
        "message": "OTP generated successfully",
        "otp": otp   # for testing
    }

@router.post("/verify-otp")
def verify_otp(email: str, otp: str):

    data = otp_store.get(email)

    if not data:
        raise HTTPException(status_code=400, detail="OTP not requested")

    if datetime.utcnow() > data["expires"]:
        del otp_store[email]
        raise HTTPException(status_code=400, detail="OTP expired")

    if data["otp"] != otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    del otp_store[email]

    return {"message": "OTP verified successfully"} 