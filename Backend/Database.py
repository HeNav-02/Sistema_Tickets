import psycopg2

def get_connection():
    conn = psycopg2.connect(
        host="localhost",
        database="Test",
        user="postgres",
        password="Pass123"
    )

    return conn