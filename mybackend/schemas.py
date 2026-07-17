from pydantic import BaseModel, EmailStr
from typing import Optional

class RegisterRequest(BaseModel):

    first_name: str
    last_name: str
    email: str
    phone: str
    pin: str

    user_type: str
    monthly_budget: Optional[int] = None
    salary: Optional[int] = None
   
class LoginRequest(BaseModel):
    email: EmailStr
    pin: str

class CategoryKeywordCreate(BaseModel):
    keyword: str
    category: str

class TransactionCreate(BaseModel):
    user_id: int
    amount: float
    merchant_name: str
    category: Optional[str] = None
    note: Optional[str] = None
    raw_sms: Optional[str] = None

class TransactionUpdate(BaseModel):
    category: Optional[str] = None
    note: Optional[str] = None
    amount: Optional[float] = None
    merchant_name: Optional[str] = None