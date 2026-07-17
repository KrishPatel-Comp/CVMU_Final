from sqlalchemy import Column, Integer, String, Boolean, TIMESTAMP, Text, Numeric, ForeignKey, DateTime
from sqlalchemy.sql import func
from database import Base
from datetime import datetime


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    first_name = Column(String(15), nullable=False)
    last_name = Column(String(15), nullable=False)

    email = Column(String(30), unique=True, index=True, nullable=False)
    phone = Column(String(12), unique=True, nullable=False)

    hashed_pin = Column(Text, nullable=False)

    # NEW FIELDS (Hackathon feature)
    user_type = Column(String(15))        # student / employed / unemployed
    monthly_budget = Column(Integer)      # for student & unemployed
    salary = Column(Integer)              # for employed users

    is_fingerprint_enabled = Column(Boolean, default=False)

    failed_attempts = Column(Integer, default=0)
    is_locked = Column(Boolean, default=False)
    locked_until = Column(DateTime, nullable=True)

    created_at = Column(TIMESTAMP, server_default=func.now())


class OTPVerification(Base):
    __tablename__ = "otp_verifications"

    id = Column(Integer, primary_key=True, index=True)
    phone = Column(String(12), nullable=False)
    otp_code = Column(String(6), nullable=False)
    expires_at = Column(TIMESTAMP, nullable=False)
    is_verified = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.now())


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    amount = Column(Numeric(10, 2), nullable=False)
    merchant_name = Column(String(30))
    category = Column(String(20))
    transaction_date = Column(TIMESTAMP, server_default=func.now())
    note = Column(Text, nullable=True)
    raw_sms = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())


class CategoryKeyword(Base):
    __tablename__ = "category_keywords"

    id = Column(Integer, primary_key=True, index=True)
    keyword = Column(String(25), nullable=False)
    category = Column(String(20), nullable=False)