CREATE DATABASE IF NOT EXISTS app_unificada_uae
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE app_unificada_uae;

CREATE TABLE usuarios (
  id_usuario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_completo VARCHAR(150) NOT NULL,
  email VARCHAR(254) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol ENUM('Estudiante', 'Docente', 'Admin', 'Caja', 'Cocina', 'CCE') NOT NULL,
  semestre TINYINT UNSIGNED,
  grupo VARCHAR(20),
  CONSTRAINT chk_email_institucional CHECK
    (email REGEXP '^[A-Za-z0-9._%+-]+@uae[.]edu[.]mx$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categorias (
  id_categoria INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE productos (
  id_producto INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_categoria INT UNSIGNED NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  stock INT UNSIGNED NOT NULL DEFAULT 0,
  CONSTRAINT chk_precio CHECK (precio >= 0),
  FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pedidos (
  id_pedido INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT UNSIGNED NOT NULL,
  fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('Pendiente', 'En preparacion', 'Listo', 'Entregado') NOT NULL DEFAULT 'Pendiente',
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE detalles_pedido (
  id_pedido INT UNSIGNED NOT NULL,
  id_producto INT UNSIGNED NOT NULL,
  cantidad INT UNSIGNED NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_pedido, id_producto),
  CONSTRAINT chk_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_precio_unitario CHECK (precio_unitario >= 0),
  FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
  FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE horarios_clases (
  id_horario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  materia VARCHAR(150) NOT NULL,
  aula VARCHAR(50) NOT NULL,
  dia_semana ENUM('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo') NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  semestre TINYINT UNSIGNED NOT NULL,
  grupo VARCHAR(20) NOT NULL,
  id_profesor INT UNSIGNED NOT NULL,
  CONSTRAINT chk_horario CHECK (hora_fin > hora_inicio),
  FOREIGN KEY (id_profesor) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE rutas_transporte (
  id_ruta INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_ruta VARCHAR(150) NOT NULL,
  horario_salida TIME NOT NULL,
  estatus ENUM('Activa', 'Inactiva') NOT NULL DEFAULT 'Activa'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE puntos_parada (
  id_punto_parada INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_ruta INT UNSIGNED NOT NULL,
  orden SMALLINT UNSIGNED NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  UNIQUE (id_ruta, orden),
  FOREIGN KEY (id_ruta) REFERENCES rutas_transporte(id_ruta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE solicitudes_transporte (
  id_solicitud INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT UNSIGNED NOT NULL,
  id_ruta INT UNSIGNED,
  tipo ENUM('Contingencia', 'Horario extraordinario') NOT NULL,
  descripcion TEXT NOT NULL,
  fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
  FOREIGN KEY (id_ruta) REFERENCES rutas_transporte(id_ruta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE alertas_salud (
  id_alerta INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT UNSIGNED NOT NULL,
  tipo_emergencia VARCHAR(100) NOT NULL,
  ubicacion_campus VARCHAR(150) NOT NULL,
  descripcion TEXT NOT NULL,
  estado ENUM('Pendiente', 'Atendida', 'Cerrada') NOT NULL DEFAULT 'Pendiente',
  fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE anuncios (
  id_anuncio INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(150) NOT NULL,
  contenido TEXT NOT NULL,
  categoria VARCHAR(100) NOT NULL,
  fecha_publicacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_autor INT UNSIGNED NOT NULL,
  FOREIGN KEY (id_autor) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE votaciones (
  id_votacion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(150) NOT NULL,
  descripcion TEXT NOT NULL,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin DATETIME NOT NULL,
  activa BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_fechas_votacion CHECK (fecha_fin > fecha_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE opciones_votacion (
  id_opcion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_votacion INT UNSIGNED NOT NULL,
  texto VARCHAR(255) NOT NULL,
  UNIQUE (id_votacion, id_opcion),
  FOREIGN KEY (id_votacion) REFERENCES votaciones(id_votacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE votos_usuarios (
  id_votacion INT UNSIGNED NOT NULL,
  id_usuario INT UNSIGNED NOT NULL,
  id_opcion INT UNSIGNED NOT NULL,
  UNIQUE (id_votacion, id_usuario),
  FOREIGN KEY (id_votacion, id_opcion) REFERENCES opciones_votacion(id_votacion, id_opcion),
  FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
