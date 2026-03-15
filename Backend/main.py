from fastapi import FastAPI
from Database import get_connection
from pydantic import BaseModel

#Levantar conexión uvicorn: python -m uvicorn main:app --reload

app = FastAPI()
@app.get("/")
def home():
    return {"mensaje": "Sistema de reparaciones funcionando"}

@app.get("/tickets")
def obtener_tickets():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT ticket_id, descripcion_problema, estado
        FROM tickets
    """)

    tickets = cursor.fetchall()

    cursor.close()
    conn.close()

    return tickets

@app.post("/tickets")
def crear_ticket(equipo_id: int, usuario_creador: int, descripcion: str):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO tickets (equipo_id, usuario_creador, descripcion_problema)
        VALUES (%s, %s, %s)
    """, (equipo_id, usuario_creador, descripcion))

    conn.commit()

    cursor.close()
    conn.close()

    return {"mensaje": "Ticket creado correctamente"}

@app.put("/tickets/{ticket_id}/estado")
def cambiar_estado(ticket_id: int, estado: str):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        UPDATE tickets
        SET estado = %s
        WHERE ticket_id = %s
    """, (estado, ticket_id))

    conn.commit()

    cursor.close()
    conn.close()

    return {"mensaje": "Estado actualizado"}

@app.get("/metricas")
def ver_metricas():

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT ticket_id, estatus, timestamp
        FROM metrics_logs
        ORDER BY timestamp DESC
    """)

    datos = cursor.fetchall()

    cursor.close()
    conn.close()

    return datos

class LoginRequest(BaseModel):
    correo: str
    password: str

@app.delete("/tickets/{ticket_id}")
def eliminar_ticket(ticket_id: int):
    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "DELETE FROM metrics_logs WHERE ticket_id = %s",
            (ticket_id,)
        )

        cursor.execute(
            "DELETE FROM tickets WHERE ticket_id = %s RETURNING ticket_id",
            (ticket_id,)
        )

        eliminado = cursor.fetchone()
        conn.commit()

        if eliminado:
            return {"mensaje": "Ticket eliminado correctamente"}
        else:
            return {"mensaje": "Ticket no encontrado"}

    except Exception as excepcion:
        conn.rollback()
        return {"error": str(excepcion)}

    finally:
        cursor.close()
        conn.close()

@app.post("/login")
def login(request: LoginRequest):

    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT u.usuario_id, u.nombre, r.nombre
        FROM usuarios u
        JOIN usuarios_roles ur ON u.usuario_id = ur.usuario_id
        JOIN roles r ON ur.rol_id = r.id
        WHERE u.correo = %s AND u.password = %s
    """, (request.correo, request.password))

    usuario = cursor.fetchall()

    cursor.close()
    conn.close()

    if usuario:
        roles = [r[2] for r in usuario]

        return {
            "mensaje": "Login correcto",
            "usuario_id": usuario[0][0],
            "nombre": usuario[0][1],
            "roles": roles
        }
    else:
        return {"mensaje": "Credenciales incorrectas"}