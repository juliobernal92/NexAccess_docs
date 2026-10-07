CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- EMPLEADOS
-- ============================================================

CREATE TABLE empleado (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid(),
    cedula          VARCHAR(20) NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    apellido        VARCHAR(100) NOT NULL,
    email           VARCHAR(150),
    telefono        VARCHAR(30),

    activo          BOOLEAN NOT NULL DEFAULT TRUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_empleado_uuid UNIQUE (uuid),
    CONSTRAINT uq_empleado_cedula UNIQUE (cedula),
    CONSTRAINT uq_empleado_email UNIQUE (email)
);


-- ============================================================
-- ROLES
-- Ej:
-- EMPLEADO
-- SEGURIDAD
-- RRHH
-- ADMINISTRADOR
-- ============================================================

CREATE TABLE rol (
    id              BIGSERIAL PRIMARY KEY,
    codigo          VARCHAR(50) NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    descripcion     VARCHAR(255),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_rol_codigo UNIQUE (codigo)
);


-- ============================================================
-- RELACIÓN EMPLEADO - ROL
-- Un empleado puede tener más de un rol.
-- ============================================================

CREATE TABLE empleado_rol (
    id_empleado     BIGINT NOT NULL,
    id_rol          BIGINT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (id_empleado, id_rol),

    CONSTRAINT fk_empleado_rol_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES empleado(id),

    CONSTRAINT fk_empleado_rol_rol
        FOREIGN KEY (id_rol)
        REFERENCES rol(id)
);


-- ============================================================
-- ÁREAS FÍSICAS
-- Ej:
-- RECEPCION
-- ADMINISTRACION
-- TESORERIA
-- DATACENTER
-- RRHH
-- ============================================================

CREATE TABLE area (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid(),
    codigo          VARCHAR(50) NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    descripcion     VARCHAR(255),
    restringida     BOOLEAN NOT NULL DEFAULT TRUE,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_area_uuid UNIQUE (uuid),
    CONSTRAINT uq_area_codigo UNIQUE (codigo)
);


-- ============================================================
-- PERMISOS DE ACCESO POR ROL
-- Define qué rol puede ingresar a qué área.
-- ============================================================

CREATE TABLE permiso_acceso (
    id              BIGSERIAL PRIMARY KEY,

    id_rol          BIGINT NOT NULL,
    id_area         BIGINT NOT NULL,

    hora_desde      TIME,
    hora_hasta      TIME,

    lunes           BOOLEAN NOT NULL DEFAULT TRUE,
    martes          BOOLEAN NOT NULL DEFAULT TRUE,
    miercoles       BOOLEAN NOT NULL DEFAULT TRUE,
    jueves          BOOLEAN NOT NULL DEFAULT TRUE,
    viernes         BOOLEAN NOT NULL DEFAULT TRUE,
    sabado          BOOLEAN NOT NULL DEFAULT FALSE,
    domingo         BOOLEAN NOT NULL DEFAULT FALSE,

    activo          BOOLEAN NOT NULL DEFAULT TRUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_permiso_rol
        FOREIGN KEY (id_rol)
        REFERENCES rol(id),

    CONSTRAINT fk_permiso_area
        FOREIGN KEY (id_area)
        REFERENCES area(id),

    CONSTRAINT uq_permiso_rol_area
        UNIQUE (id_rol, id_area)
);


-- ============================================================
-- CREDENCIALES NFC
--
-- FISICA  = tarjeta / llavero NFC
-- DIGITAL = teléfono
--
-- No conviene guardar datos sensibles innecesarios de la tarjeta.
-- uid representa el identificador lógico utilizado por el sistema.
-- ============================================================

CREATE TABLE credencial (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid(),

    id_empleado     BIGINT NOT NULL,

    uid             VARCHAR(150) NOT NULL,

    tipo            VARCHAR(20) NOT NULL,

    nombre          VARCHAR(100),

    activa          BOOLEAN NOT NULL DEFAULT TRUE,

    fecha_emision   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_expiracion TIMESTAMPTZ,

    revocada_at     TIMESTAMPTZ,
    motivo_revocacion VARCHAR(255),

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_credencial_uuid UNIQUE (uuid),
    CONSTRAINT uq_credencial_uid UNIQUE (uid),

    CONSTRAINT ck_credencial_tipo
        CHECK (tipo IN ('FISICA', 'DIGITAL')),

    CONSTRAINT fk_credencial_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES empleado(id)
);


-- ============================================================
-- DISPOSITIVOS
--
-- MARCACION = registra entrada/salida laboral
-- ACCESO    = controla una puerta
-- MIXTO     = ambas funciones
-- ============================================================

CREATE TABLE dispositivo (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid(),

    codigo          VARCHAR(50) NOT NULL,
    nombre          VARCHAR(100) NOT NULL,

    tipo            VARCHAR(20) NOT NULL,

    id_area         BIGINT,

    descripcion     VARCHAR(255),

    activo          BOOLEAN NOT NULL DEFAULT TRUE,

    ultima_conexion TIMESTAMPTZ,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_dispositivo_uuid UNIQUE (uuid),
    CONSTRAINT uq_dispositivo_codigo UNIQUE (codigo),

    CONSTRAINT ck_dispositivo_tipo
        CHECK (tipo IN ('ACCESO', 'MARCACION', 'MIXTO')),

    CONSTRAINT fk_dispositivo_area
        FOREIGN KEY (id_area)
        REFERENCES area(id)
);


-- ============================================================
-- EVENTOS DE ACCESO
--
-- Registra TODOS los intentos:
-- autorizado o rechazado.
--
-- Es importante no eliminar estos registros.
-- ============================================================

CREATE TABLE evento_acceso (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid(),

    id_empleado     BIGINT,
    id_credencial   BIGINT,
    id_dispositivo  BIGINT NOT NULL,
    id_area         BIGINT,

    fecha_hora      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    resultado       VARCHAR(20) NOT NULL,
    motivo          VARCHAR(100),

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_evento_acceso_uuid UNIQUE (uuid),

    CONSTRAINT ck_evento_resultado
        CHECK (resultado IN ('AUTORIZADO', 'RECHAZADO')),

    CONSTRAINT fk_evento_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES empleado(id),

    CONSTRAINT fk_evento_credencial
        FOREIGN KEY (id_credencial)
        REFERENCES credencial(id),

    CONSTRAINT fk_evento_dispositivo
        FOREIGN KEY (id_dispositivo)
        REFERENCES dispositivo(id),

    CONSTRAINT fk_evento_area
        FOREIGN KEY (id_area)
        REFERENCES area(id)
);


-- ============================================================
-- MARCACIONES DE ASISTENCIA
--
-- ENTRADA
-- SALIDA
-- ============================================================

CREATE TABLE marcacion (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid(),

    id_empleado     BIGINT NOT NULL,
    id_credencial   BIGINT,
    id_dispositivo  BIGINT NOT NULL,

    tipo            VARCHAR(20) NOT NULL,
    fecha_hora      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_marcacion_uuid UNIQUE (uuid),

    CONSTRAINT ck_marcacion_tipo
        CHECK (tipo IN ('ENTRADA', 'SALIDA')),

    CONSTRAINT fk_marcacion_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES empleado(id),

    CONSTRAINT fk_marcacion_credencial
        FOREIGN KEY (id_credencial)
        REFERENCES credencial(id),

    CONSTRAINT fk_marcacion_dispositivo
        FOREIGN KEY (id_dispositivo)
        REFERENCES dispositivo(id)
);


-- ============================================================
-- USUARIOS DEL PORTAL WEB
--
-- Separados del empleado porque no necesariamente todos los
-- empleados tendrán acceso administrativo al sistema.
-- ============================================================

CREATE TABLE usuario (
    id              BIGSERIAL PRIMARY KEY,
    uuid            UUID NOT NULL DEFAULT gen_random_uuid(),

    id_empleado     BIGINT,

    username        VARCHAR(100) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,

    rol_sistema     VARCHAR(30) NOT NULL,

    activo          BOOLEAN NOT NULL DEFAULT TRUE,

    ultimo_login    TIMESTAMPTZ,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_usuario_uuid UNIQUE (uuid),
    CONSTRAINT uq_usuario_username UNIQUE (username),

    CONSTRAINT ck_usuario_rol_sistema
        CHECK (
            rol_sistema IN (
                'ADMIN',
                'SEGURIDAD',
                'RRHH'
            )
        ),

    CONSTRAINT fk_usuario_empleado
        FOREIGN KEY (id_empleado)
        REFERENCES empleado(id)
);


--Indices propuestos para mejorar el rendimiento de las consultas
-- Eventos de acceso por empleado y fecha
CREATE INDEX idx_evento_acceso_empleado_fecha
    ON evento_acceso (id_empleado, fecha_hora DESC);

-- Eventos por dispositivo
CREATE INDEX idx_evento_acceso_dispositivo_fecha
    ON evento_acceso (id_dispositivo, fecha_hora DESC);

-- Marcaciones de asistencia
CREATE INDEX idx_marcacion_empleado_fecha
    ON marcacion (id_empleado, fecha_hora DESC);

-- Búsqueda rápida de credencial NFC
CREATE INDEX idx_credencial_uid_activa
    ON credencial (uid)
    WHERE activa = TRUE;

-- Permisos
CREATE INDEX idx_permiso_area
    ON permiso_acceso (id_area);

CREATE INDEX idx_empleado_activo
    ON empleado (activo);