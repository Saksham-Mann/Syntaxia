"""A completely clean service module using environment variables."""
import os

DATABASE_URL = os.getenv("DATABASE_URL")
API_KEY = os.getenv("API_KEY")

def process_data(items):
    return [x * 2 for x in items]
