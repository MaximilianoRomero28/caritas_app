from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL=os.getenv("DATABASE_URL")

if DATABASE_URL.startswith("sqlite"):
    argumentos={"check_same_thread": False}
else:
    argumentos={"connect_timeout": 10}


engine= create_engine(
    DATABASE_URL,
    connect_args=argumentos,
    pool_pre_ping=True,
    pool_recycle=300
)

session_local=sessionmaker(autoflush=False,bind=engine)

base=declarative_base()

def get_db():
    db=session_local()
    try:
        yield db
    finally:
        db.close()