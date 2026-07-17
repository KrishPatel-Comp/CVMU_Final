from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import CategoryKeyword
from schemas import CategoryKeywordCreate

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.post("/")
def add_keyword(request: CategoryKeywordCreate, db: Session = Depends(get_db)):

    new_keyword = CategoryKeyword(
        keyword=request.keyword.lower(),
        category=request.category
    )

    db.add(new_keyword)
    db.commit()
    db.refresh(new_keyword)

    return {"message": "Keyword added successfully"}


@router.get("/")
def get_keywords(db: Session = Depends(get_db)):

    keywords = db.query(CategoryKeyword).all()

    return keywords