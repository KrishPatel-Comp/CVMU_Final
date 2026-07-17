import bcrypt

def hash_pin(pin: str):
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pin.encode(), salt).decode()

def verify_pin(plain_pin: str, hashed_pin: str):
    return bcrypt.checkpw(
        plain_pin.encode(),
        hashed_pin.encode()
    )