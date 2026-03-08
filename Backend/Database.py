import psycopg2

def get_connection():
    conn = psycopg2.connect(
        host="localhost",
        database="Sistema_reparaciones",
        user="postgres",
        password="Pass123"
    )

    return conn