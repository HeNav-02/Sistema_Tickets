CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(150)
);

CREATE TABLE usuarios (
    usuario_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);
Select * from usuarios
Select * from usuarios_roles
CREATE TABLE usuarios_roles (
    usuario_id INTEGER NOT NULL,
    rol_id INTEGER NOT NULL,
    PRIMARY KEY (usuario_id, rol_id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    FOREIGN KEY (rol_id) REFERENCES roles(id)
);

CREATE TABLE clientes (
    cliente_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(100)
);

CREATE TABLE equipos (
    equipo_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id INTEGER,
    marca VARCHAR(100),
    modelo VARCHAR(100),
    sku VARCHAR(100),
    numero_serie VARCHAR(100),
    descripcion TEXT,
    FOREIGN KEY (cliente_id) REFERENCES clientes(cliente_id)
);

CREATE TABLE tickets (
    ticket_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    equipo_id INTEGER NOT NULL,
    usuario_creador INTEGER NOT NULL,
    tecnico_asignado INTEGER,
    descripcion_problema TEXT NOT NULL,
    estado VARCHAR(50) DEFAULt 'Creado ',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre TIMESTAMP,
    FOREIGN KEY (equipo_id) REFERENCES equipos(equipo_id),
    FOREIGN KEY (usuario_creador) REFERENCES usuarios(usuario_id),
    FOREIGN KEY (tecnico_asignado) REFERENCES usuarios(usuario_id)
);

CREATE TABLE metrics_logs (
    metric_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id INTEGER NOT NULL,
    estatus VARCHAR(50) NOT NULL,
    tiempo_resolucion INTERVAL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id)
);

CREATE TABLE acciones_ticket (
    accion_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id INTEGER NOT NULL,
    tecnico_id INTEGER NOT NULL,
    descripcion TEXT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),
    FOREIGN KEY (tecnico_id) REFERENCES usuarios(usuario_id)
);

INSERT INTO roles (nombre, descripcion)
VALUES 
('Técnico','Permisos de creación, actualización y eliminación de tickets.'),
('Administrador','Permisos de creación, actualización y eliminación de usuarios y tickets.'),
('Cliente','Se crea el usuario de cliente.');

INSERT INTO usuarios (nombre, correo, contraseña)
VALUES
('Admin Principal', 'admin@sistema.com', '123456'),
('Juan Pérez','juan.tecnico@sistema.com','123456'),
('Ana Torres','ana.admin@sistema.com','123456'),
('Carlos López','carlos.tecnico@sistema.com','123456');

INSERT INTO usuarios_roles (usuario_id, rol_id)
VALUES
(1,2),
(2,1),
(3,2),
(4,1);

INSERT INTO clientes (nombre, telefono, correo)
VALUES
('Luis Martínez','5512345678','luis@email.com'),
('María García','5523456789','maria@email.com'),
('Pedro Sánchez','5534567890','pedro@email.com');

INSERT INTO equipos (cliente_id, marca, modelo, sku, numero_serie, descripcion)
VALUES
(1,'Dell','Latitude 5420','DL5420','SN123456','Laptop no enciende'),
(2,'HP','Pavilion 15','HP-PAV15','SN654321','Pantalla rota'),
(3,'Lenovo','ThinkPad T14','LN-T14','SN789123','Problema de batería');

INSERT INTO tickets (equipo_id, usuario_creador, tecnico_asignado, descripcion_problema)
VALUES
(1,1,2,'La laptop no enciende'),
(2,1,4,'Pantalla rota'),
(3,1,2,'Batería no carga');

CREATE OR REPLACE FUNCTION registrar_cambio_estado()
RETURNS TRIGGER AS $$
BEGIN

IF NEW.estado <> OLD.estado THEN

INSERT INTO metrics_logs (ticket_id, estatus)
VALUES (NEW.ticket_id, NEW.estado);

END IF;

RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cambio_estado
AFTER UPDATE ON tickets
FOR EACH ROW
EXECUTE FUNCTION registrar_cambio_estado();

CREATE OR REPLACE FUNCTION log_ticket_creado()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO metrics_logs (ticket_id, estatus)
    VALUES (NEW.ticket_id, 'Creado');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ticket_creado
AFTER INSERT ON tickets
FOR EACH ROW
EXECUTE FUNCTION log_ticket_creado();

CREATE OR REPLACE FUNCTION log_cambio_estado()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado <> OLD.estado THEN
        INSERT INTO metrics_logs (ticket_id, estatus)
        VALUES (NEW.ticket_id, NEW.estado);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cambio_estado
AFTER UPDATE ON tickets
FOR EACH ROW
EXECUTE FUNCTION log_cambio_estado();

CREATE OR REPLACE FUNCTION calcular_tiempo_resolucion()
RETURNS TRIGGER AS $$
DECLARE
    fecha_creacion TIMESTAMP;
BEGIN
    -- Solo calcular cuando el ticket se resuelve
    IF NEW.estado = 'Resuelto' THEN

        SELECT fecha_creacion
        INTO fecha_creacion
        FROM tickets
        WHERE ticket_id = NEW.ticket_id;

        UPDATE metrics_logs
        SET tiempo_resolucion = NEW.timestamp - fecha_creacion
        WHERE metric_id = NEW.metric_id;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_tiempo_resolucion
AFTER UPDATE ON metrics_logs
FOR EACH ROW
EXECUTE FUNCTION calcular_tiempo_resolucion();

CREATE OR REPLACE FUNCTION cerrar_ticket_fecha()
RETURNS TRIGGER AS $$
BEGIN

IF NEW.estado = 'Cerrado' AND OLD.estado <> 'Cerrado' THEN
    NEW.fecha_cierre := CURRENT_TIMESTAMP;
END IF;

RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_fecha_cierre
BEFORE UPDATE ON tickets
FOR EACH ROW
EXECUTE FUNCTION cerrar_ticket_fecha();

CREATE VIEW vista_tickets_activos AS
SELECT
t.ticket_id,
c.nombre AS cliente,
e.marca,
e.modelo,
t.descripcion_problema,
u.nombre AS tecnico_asignado,
t.estado,
t.fecha_creacion
FROM tickets t
JOIN equipos e ON t.equipo_id = e.equipo_id
JOIN clientes c ON e.cliente_id = c.cliente_id
LEFT JOIN usuarios u ON t.tecnico_asignado = u.usuario_id
WHERE t.estado <> 'Cerrado';

CREATE VIEW vista_tickets_por_tecnico AS
SELECT
u.nombre AS tecnico,
COUNT(t.ticket_id) AS total_tickets,
COUNT(CASE WHEN t.estado = 'En proceso' THEN 1 END) AS en_proceso,
COUNT(CASE WHEN t.estado = 'Cerrado' THEN 1 END) AS cerrados
FROM usuarios u
LEFT JOIN tickets t ON u.usuario_id = t.tecnico_asignado
GROUP BY u.nombre;

CREATE VIEW vista_tiempos_resolucion AS
SELECT
t.ticket_id,
c.nombre AS cliente,
u.nombre AS tecnico,
t.fecha_creacion,
t.fecha_cierre,
(t.fecha_cierre - t.fecha_creacion) AS tiempo_total
FROM tickets t
JOIN equipos e ON t.equipo_id = e.equipo_id
JOIN clientes c ON e.cliente_id = c.cliente_id
LEFT JOIN usuarios u ON t.tecnico_asignado = u.usuario_id
WHERE t.fecha_cierre IS NOT NULL;
