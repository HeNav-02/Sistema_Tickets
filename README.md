# Sistema de Gestión de Reparaciones.
Proyecto Integrador de  la materia dual "Microprocesadores".
Este sistema permite gestionar órdenes de reparación, usuarios y roles dentro de un sistema de servicios técnicos.

# Tecnologías utilizadas/por utilizar:

* Python
* FastAPI
* PostgreSQL
* HTML
* JavaScript
* Git / GitHub

Framework principal del backend: FastAPI.

# Instalación del proyecto

## 1. Clonar el repositorio

[git clone https://github.com/TU_USUARIO/sistema-reparaciones.git](https://github.com/HeNav-02/Sistema_Tickets.git)

cd Sistema_Tickets

## 2. Instalar dependencias

pip install -r herraientas.txt

## 3. Crear base de datos

Crear la base de datos en PostgreSQL:

CREATE DATABASE sistema_reparaciones;

Luego ejecutar el script SQL:

psql -U postgres -d Sistema_tickets -f Base_datos/Sistema_reparaciones.sql

## 4. Ejecutar el servidor

uvicorn main:app --reload

El servidor se ejecutará en:

http://127.0.0.1:8000

# Funcionalidades del sistema

* Registro de usuarios
* Inicio de sesión
* Gestión de roles
* Registro de reparaciones
* Consulta de órdenes de servicio

# Autor

Efrain Natanael Hernandez Navarro
