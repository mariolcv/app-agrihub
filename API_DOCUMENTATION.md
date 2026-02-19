# Documentación de API - ERP AgrihHub

**Versión:** 1.0  
**Fecha:** Febrero 2026  
**Base URL:** `http://tu-servidor.com` o `https://tu-dominio.com`

---

## 📋 Tabla de Contenidos

1. [Autenticación](#autenticación)
2. [Dashboard](#dashboard)
3. [Notificaciones](#notificaciones)
4. [Producción Agrícola](#producción-agrícola)
   - [Empleados](#empleados)
   - [Nóminas](#nóminas)
   - [Parcelas](#parcelas)
   - [Recursos](#recursos)
   - [Accesorios](#accesorios)
   - [Vehículos](#vehículos)
   - [Tareas](#tareas)
5. [Análisis](#análisis)
6. [Utilidades](#utilidades)

---

## 🔐 Autenticación

La API utiliza cookies HTTP-only para la autenticación. Los tokens se manejan automáticamente en las cookies.

### Headers requeridos (después del login)

```
Cookie: access_token=<token>; refresh_token=<refresh_token>
```

### POST `/api/auth/login`

Inicia sesión en el sistema.

**Body:**
```json
{
  "email": "usuario@ejemplo.com",
  "password": "tu_contraseña"
}
```

**Respuesta exitosa (200):**
```json
{
  "id": "123",
  "email": "usuario@ejemplo.com",
  "name": "Juan Pérez",
  "role": "admin",
  "avatar": "/uploads/avatars/juan.jpg"
}
```

**Cookies establecidas:**
- `access_token` (válido 15 minutos)
- `refresh_token` (válido 90 días)

**Errores:**
- `400`: Credenciales faltantes
- `401`: Credenciales inválidas

---

### POST `/api/auth/register`

Activa la cuenta de un empleado pre-registrado en el sistema. Los empleados son creados previamente por un administrador, quien les proporciona un código secreto de un solo uso (`one_time_pswd`). Este endpoint permite al empleado activar su cuenta configurando su nombre de usuario y contraseña.

**Flujo:**
1. Un administrador crea un usuario en el sistema asociado a un empleado y genera un `first_time_code`
2. El administrador proporciona al empleado su `empleadoId` y el `first_time_code`
3. El empleado usa este endpoint para activar su cuenta (solo puede hacerse una vez)
4. Una vez activada, el empleado puede iniciar sesión con sus credenciales

**Body:**
```json
{
  "username": "usuario123",
  "password": "contraseña_segura",
  "confirmPassword": "contraseña_segura",
  "empleadoId": 5,
  "one_time_pswd": 123456
}
```

**Campos:**
- `username` (requerido): Nombre de usuario único, mínimo 3 caracteres
- `password` (requerido): Contraseña, mínimo 6 caracteres
- `confirmPassword` (requerido): Debe coincidir exactamente con password
- `empleadoId` (requerido): ID del empleado que se desea activar
- `one_time_pswd` (requerido): Código secreto proporcionado por el administrador

**Respuesta exitosa (200):**
```json
{
  "id": "124",
  "username": "usuario123",
  "email": "usuario@ejemplo.com",
  "role": "user",
  "avatar": "/uploads/avatars/foto.jpg",
  "message": "¡Cuenta activada exitosamente! Ya puedes iniciar sesión con tus credenciales"
}
```

**Errores:**
- `400`: Datos inválidos, campos faltantes, o contraseñas no coinciden
- `401`: Código secreto (one_time_pswd) incorrecto
- `403`: La cuenta ya fue activada previamente
- `404`: Empleado no encontrado o no tiene usuario pre-creado
- `409`: Nombre de usuario ya en uso o usuario ya activado

---

### GET `/api/auth/me`

Obtiene información del usuario autenticado.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "id": "123",
  "name": "Juan Pérez",
  "email": "usuario@ejemplo.com",
  "role": "admin",
  "avatar": "/uploads/avatars/juan.jpg"
}
```

**Errores:**
- `401`: No autenticado

---

### POST `/api/auth/refresh`

Renueva el access token usando el refresh token.

**Headers:**
```
Cookie: refresh_token=<refresh_token>
```

**Respuesta exitosa (200):**
```json
{
  "id": "123",
  "email": "usuario@ejemplo.com",
  "name": "Juan Pérez",
  "role": "admin",
  "avatar": "/uploads/avatars/juan.jpg"
}
```

**Cookies actualizadas:**
- `access_token` (nuevo token de 15 minutos)
- `refresh_token` (nuevo token de 90 días)

**Nota:** Implementa rotación de tokens - el refresh token anterior queda revocado.

**Errores:**
- `401`: Refresh token inválido o expirado

---

### POST `/api/auth/logout`

Cierra la sesión del usuario.

**Headers:**
```
Cookie: refresh_token=<refresh_token>
```

**Respuesta exitosa (200):**
```json
{
  "ok": true
}
```

**Cookies eliminadas:**
- `access_token`
- `refresh_token`

---

## 📊 Dashboard

### GET `/api/dashboard/stats`

Obtiene estadísticas generales del dashboard.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "gastoTotalCampana": 125430.50,
  "anioActual": 2026
}
```

**Descripción de campos:**
- `gastoTotalCampana`: Suma total de gastos desde el 1 de enero (empleados + recursos)
- `anioActual`: Año actual del sistema

**Errores:**
- `401`: No autenticado
- `500`: Error al obtener estadísticas

---

## 🔔 Notificaciones

### GET `/api/notifications/list`

Obtiene la lista de notificaciones del usuario autenticado.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "title": "Nueva tarea asignada",
    "message": "Se te ha asignado la tarea de poda en Finca Norte",
    "severity": "INFO",
    "createdAt": "2026-02-15",
    "isRead": false
  },
  {
    "id": 2,
    "title": "Alerta de recursos",
    "message": "El nivel de fertilizante está bajo",
    "severity": "WARNING",
    "createdAt": "2026-02-14",
    "isRead": true
  }
]
```

**Valores de `severity`:**
- `INFO`: Información general
- `WARNING`: Advertencia
- `ERROR`: Error
- `CRITICAL`: Crítico

**Errores:**
- `401`: No autenticado

---

### GET `/api/notifications/unread-count`

Obtiene el contador de notificaciones no leídas.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "count": 5
}
```

**Errores:**
- `401`: No autenticado

---

### POST `/api/notifications/[id]/read`

Marca una notificación como leída.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la notificación

**Ejemplo:** `/api/notifications/123/read`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Notificación marcada como leída"
}
```

**Errores:**
- `400`: ID inválido
- `401`: No autenticado
- `404`: Notificación no encontrada

---

## 🌾 Producción Agrícola

### Empleados

#### GET `/api/produccion-agricola/empleados/index`

Obtiene lista de empleados visibles, opcionalmente filtrados por cargo.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters:**
- `cargo` (opcional): Filtra empleados por cargo

**Ejemplo:** `/api/produccion-agricola/empleados/index?cargo=Operario`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nombre": "Juan Pérez",
      "cargo": "Operario",
      "cargo2": null,
      "valores": {}
    },
    {
      "id": 2,
      "nombre": "María García",
      "cargo": "Operario",
      "cargo2": "Tractorista",
      "valores": {}
    }
  ],
  "total": 2
}
```

---

#### GET `/api/produccion-agricola/empleados/all`

Obtiene todos los empleados (activos e inactivos).

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nombre": "Juan Pérez",
      "foto": "/uploads/empleados/juan.jpg",
      "cargo": "Operario",
      "cargo2": null,
      "visible": true
    },
    {
      "id": 2,
      "nombre": "Pedro López",
      "foto": null,
      "cargo": "Tractorista",
      "cargo2": null,
      "visible": false
    }
  ]
}
```

---

#### GET `/api/produccion-agricola/empleados/[id]`

Obtiene detalles de un empleado específico.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID del empleado

**Ejemplo:** `/api/produccion-agricola/empleados/123`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "nombre": "Juan Pérez",
    "cargo": "Operario",
    "cargo2": "Tractorista",
    "visible": true
  }
}
```

**Errores:**
- `400`: ID inválido
- `404`: Empleado no encontrado o no disponible

---

#### POST `/api/produccion-agricola/empleados/new`

Crea un nuevo empleado.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "nombre": "Carlos Martínez",
  "cargo": "Operario",
  "cargo2": "",
  "foto": "/uploads/empleados/carlos.jpg",
  "nuevoCargo": {
    "nombre": "Supervisor",
    "costePorHora": 15.50
  }
}
```

**Campos:**
- `nombre` (requerido): min 1, máx 50 caracteres
- `cargo` (opcional): máx 50 caracteres
- `cargo2` (opcional): máx 50 caracteres
- `foto` (opcional): máx 50 caracteres, ruta de la foto
- `nuevoCargo` (opcional): Si se proporciona, crea un nuevo tipo de cargo
  - `nombre` (requerido): min 1, máx 50 caracteres
  - `costePorHora` (requerido): número >= 0

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Empleado creado exitosamente",
  "data": {
    "id": 125,
    "nombre": "Carlos Martínez"
  }
}
```

**Errores:**
- `400`: Datos inválidos o ya existe empleado con esos datos
- `401`: No autenticado
- `500`: Error del servidor

---

#### DELETE `/api/produccion-agricola/empleados/[id]`

Da de baja a un empleado (cambia `visible` a `false`).

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID del empleado

**Ejemplo:** `/api/produccion-agricola/empleados/123`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Empleado dado de baja exitosamente"
}
```

**Errores:**
- `400`: ID inválido
- `404`: Empleado no encontrado

---

#### POST `/api/produccion-agricola/empleados/[id]/reactivar`

Reactiva un empleado dado de baja (cambia `visible` a `true`).

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID del empleado

**Ejemplo:** `/api/produccion-agricola/empleados/123/reactivar`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Empleado reactivado exitosamente"
}
```

**Errores:**
- `400`: ID inválido
- `404`: Empleado no encontrado

---

#### GET `/api/produccion-agricola/cargos-empleados`

Obtiene la lista de cargos posibles para empleados.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "cargo": "Operario",
      "coste_default_por_hora": 12.50
    },
    {
      "id": 2,
      "cargo": "Tractorista",
      "coste_default_por_hora": 15.00
    },
    {
      "id": 3,
      "cargo": "Supervisor",
      "coste_default_por_hora": 18.50
    }
  ]
}
```

---

### Nóminas

#### POST `/api/produccion-agricola/empleados/nomina`

Crea una nómina para un empleado.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "id_empleado": 5,
  "anio": 2026,
  "mes": 2,
  "salario_bruto": 1800.00,
  "horas_trabajadas": 160
}
```

**Campos:**
- `id_empleado` (requerido): número entero positivo
- `anio` (requerido): entre 2000 y año actual + 1
- `mes` (requerido): entre 1 y 12
- `salario_bruto` (requerido): número positivo <= 999999.99
- `horas_trabajadas` (requerido): número positivo <= 744 (31 días × 24 horas)

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Nómina creada exitosamente",
  "nomina": {
    "id": 45,
    "id_empleado": 5,
    "anio": 2026,
    "mes": 2,
    "salario_bruto": 1800.00,
    "horas_trabajadas": 160,
    "fecha_registro": "2026-02-15T10:30:00.000Z"
  }
}
```

**Efectos secundarios:**
- Actualiza automáticamente el `coste_por_hora` de todos los gastos del empleado en ese mes/año
- Recalcula el `coste_total` de todas las tareas completadas en las que trabajó el empleado ese mes

**Errores:**
- `400`: Datos inválidos o ya existe nómina para ese mes/año
- `404`: Empleado no encontrado

---

#### GET `/api/produccion-agricola/empleados/[id]/nominas`

Obtiene las últimas 6 nóminas de un empleado.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID del empleado

**Ejemplo:** `/api/produccion-agricola/empleados/5/nominas`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 45,
      "anio": 2026,
      "mes": 2,
      "salario_bruto": 1800.00,
      "horas_trabajadas": 160,
      "coste_hora_calculado": 11.25,
      "fecha_registro": "2026-02-15T10:30:00.000Z"
    },
    {
      "id": 44,
      "anio": 2026,
      "mes": 1,
      "salario_bruto": 1750.00,
      "horas_trabajadas": 165,
      "coste_hora_calculado": 10.61,
      "fecha_registro": "2026-01-31T12:00:00.000Z"
    }
  ]
}
```

---

#### PUT `/api/produccion-agricola/empleados/nominas/[id]`

Actualiza una nómina existente.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Parámetros de ruta:**
- `id`: ID de la nómina

**Body:**
```json
{
  "anio": 2026,
  "mes": 2,
  "salario_bruto": 1850.00,
  "horas_trabajadas": 165
}
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Nómina actualizada exitosamente",
  "data": {
    "id": 45,
    "id_empleado": 5,
    "anio": 2026,
    "mes": 2,
    "salario_bruto": 1850.00,
    "horas_trabajadas": 165,
    "coste_hora_calculado": 11.21,
    "fecha_registro": "2026-02-15T10:30:00.000Z"
  }
}
```

**Efectos secundarios:**
- Recalcula automáticamente el `coste_por_hora`
- Actualiza gastos de empleados del mes
- Recalcula costes de tareas afectadas

**Errores:**
- `400`: ID inválido o datos incorrectos, nómina duplicada
- `404`: Nómina no encontrada

---

#### DELETE `/api/produccion-agricola/empleados/nominas/[id]`

Elimina una nómina.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la nómina

**Ejemplo:** `/api/produccion-agricola/empleados/nominas/45`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Nómina eliminada exitosamente"
}
```

**Errores:**
- `400`: ID inválido
- `404`: Nómina no encontrada

---

### Parcelas

#### GET `/api/produccion-agricola/parcelas/index`

Obtiene parcelas agrupadas por finca y variedad.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "finca": "Finca Norte",
      "superficie_total": 45.50,
      "numero_parcelas": 12,
      "variedades": [
        {
          "variedad": "Catherina",
          "ano_plantacion": "2015",
          "superficie": 25.30,
          "fruto": "Melocotón",
          "situacion_especial": null,
          "parcelas_count": 7,
          "parajes": ["Paraje Alto", "Paraje Bajo"]
        },
        {
          "variedad": "Big Top",
          "ano_plantacion": "2018",
          "superficie": 20.20,
          "fruto": "Melocotón",
          "situacion_especial": "Regadío",
          "parcelas_count": 5,
          "parajes": ["Paraje Centro"]
        }
      ]
    }
  ]
}
```

---

#### GET `/api/produccion-agricola/parcelas/options`

Obtiene opciones únicas para campos de parcelas.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters:**
- `field` (requerido): `finca` o `variedad`

**Ejemplo:** `/api/produccion-agricola/parcelas/options?field=finca`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    "Finca Norte",
    "Finca Sur",
    "Finca Este"
  ]
}
```

**Errores:**
- `400`: Campo requerido inválido

---

#### GET `/api/produccion-agricola/parcelas/[id]`

Obtiene detalles de una parcela específica.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la parcela

**Ejemplo:** `/api/produccion-agricola/parcelas/15`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "id": 15,
    "propietario": "Juan Pérez",
    "finca": "Finca Norte",
    "paraje": "Paraje Alto",
    "poligono": 5,
    "num_parcela": "123A",
    "superficie": 3.5,
    "num_arboles": 350,
    "variedad": "Catherina",
    "ano_plantacion": "2015",
    "situacion_especial": null,
    "fruto": "Melocotón",
    "distancia_almacen_km": 12.5
  }
}
```

**Errores:**
- `400`: ID inválido
- `404`: Parcela no encontrada

---

#### POST `/api/produccion-agricola/parcelas/new`

Crea una nueva parcela.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "propietario": "Juan Pérez",
  "finca": "Finca Norte",
  "paraje": "Paraje Alto",
  "poligono": 5,
  "num_parcela": "123A",
  "superficie": 3.5,
  "num_arboles": 350,
  "variedad": "Catherina",
  "ano_plantacion": "2015",
  "situacion_especial": null,
  "fruto": "Melocotón",
  "distancia_almacen_km": 12.5
}
```

**Campos:**
- `finca` (requerido): min 1, máx 50 caracteres
- `propietario` (opcional): máx 20 caracteres
- `paraje` (opcional): máx 50 caracteres
- `poligono` (opcional): número entero
- `num_parcela` (opcional): máx 20 caracteres
- `superficie` (opcional): número positivo
- `num_arboles` (opcional): entero positivo
- `variedad` (opcional): máx 50 caracteres
- `ano_plantacion` (opcional): máx 10 caracteres
- `situacion_especial` (opcional): máx 50 caracteres
- `fruto` (opcional): máx 50 caracteres
- `distancia_almacen_km` (opcional): número positivo

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Parcela creada exitosamente",
  "data": {
    "id": 125,
    "finca": "Finca Norte",
    "paraje": "Paraje Alto",
    ...
  }
}
```

**Errores:**
- `400`: Datos inválidos
- `500`: Error al crear parcela

---

#### PUT `/api/produccion-agricola/parcelas/[id]`

Actualiza una parcela existente.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Parámetros de ruta:**
- `id`: ID de la parcela

**Body:** (mismo formato que POST, todos los campos opcionales)
```json
{
  "superficie": 4.0,
  "num_arboles": 400
}
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Parcela actualizada exitosamente",
  "data": {
    "id": 15,
    "superficie": 4.0,
    "num_arboles": 400,
    ...
  }
}
```

**Errores:**
- `400`: ID o datos inválidos
- `404`: Parcela no encontrada
- `500`: Error al actualizar

---

#### DELETE `/api/produccion-agricola/parcelas/[id]`

Elimina una parcela.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la parcela

**Ejemplo:** `/api/produccion-agricola/parcelas/15`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Parcela eliminada exitosamente"
}
```

**Errores:**
- `400`: ID inválido
- `404`: Parcela no encontrada
- `500`: Error al eliminar

---

#### GET `/api/produccion-agricola/parcelas/allRaw`

Obtiene todas las parcelas en formato simplificado (campos básicos sin agrupación).

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "finca": "Finca Norte",
      "variedad": "Catherina",
      "paraje": "Paraje Alto",
      "ano_plantacion": "2015",
      "fruto": "Melocotón"
    },
    {
      "id": 2,
      "finca": "Finca Norte",
      "variedad": "Big Top",
      "paraje": "Paraje Bajo",
      "ano_plantacion": "2018",
      "fruto": "Melocotón"
    }
  ]
}
```

**Uso típico:** Listas de selección rápidas, autocompletado.

---

#### GET `/api/produccion-agricola/parcelas/by-finca`

Obtiene todas las parcelas de una finca específica.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters:**
- `finca` (requerido): Nombre de la finca

**Ejemplo:** `/api/produccion-agricola/parcelas/by-finca?finca=Finca%20Norte`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "propietario": "Juan Pérez",
      "finca": "Finca Norte",
      "paraje": "Paraje Alto",
      "poligono": 5,
      "num_parcela": "123A",
      "superficie": 3.5,
      "num_arboles": 350,
      "variedad": "Catherina",
      "ano_plantacion": "2015",
      "situacion_especial": null,
      "fruto": "Melocotón",
      "distancia_almacen_km": 12.5
    }
  ]
}
```

**Errores:**
- `400`: Nombre de finca requerido
- `500`: Error al obtener parcelas

---

#### GET `/api/produccion-agricola/parcelas/finca-paraje-unique`

Obtiene combinaciones únicas de finca-paraje para filtros jerárquicos.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "value": "Finca Norte|Paraje Alto",
      "label": "Finca Norte - Paraje Alto",
      "finca": "Finca Norte",
      "paraje": "Paraje Alto"
    },
    {
      "value": "Finca Norte|Paraje Bajo",
      "label": "Finca Norte - Paraje Bajo",
      "finca": "Finca Norte",
      "paraje": "Paraje Bajo"
    },
    {
      "value": "Finca Sur|",
      "label": "Finca Sur",
      "finca": "Finca Sur",
      "paraje": null
    }
  ]
}
```

**Uso típico:** Selección jerárquica de ubicaciones.

---

#### GET `/api/produccion-agricola/parcelas/autocompletar-new`

Obtiene valores únicos para campos de autocompletado en formularios de nueva parcela.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters (todos opcionales):**
- `finca`: Filtrar por finca
- `paraje`: Filtrar por paraje
- `propietario`: Filtrar por propietario
- `variedad`: Filtrar por variedad
- `ano_plantacion`: Filtrar por año de plantación
- `situacion_especial`: Filtrar por situación especial

**Ejemplo:** `/api/produccion-agricola/parcelas/autocompletar-new?finca=Finca%20Norte`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "fincas": ["Finca Norte", "Finca Sur", "Finca Este"],
    "parajes": ["Paraje Alto", "Paraje Bajo", "Paraje Centro"],
    "propietarios": ["Juan Pérez", "María García", "Pedro López"],
    "variedades": ["Catherina", "Big Top", "Rich Lady"],
    "anos_plantacion": ["2015", "2016", "2018", "2020"],
    "situaciones_especiales": ["Regadío", "Secano", "Ecológico"]
  }
}
```

**Funcionalidad:** 
- Búsqueda normalizada (elimina acentos)
- Los query params filtran progresivamente las opciones disponibles
- Ideal para autocompletado inteligente en formularios

---

#### POST `/api/produccion-agricola/parcelas/ids`

Obtiene información de múltiples parcelas por sus IDs.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "ids": [1, 5, 10, 15]
}
```

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "finca": "Finca Norte",
    "variedad": "Catherina",
    "paraje": "Paraje Alto",
    "ano_plantacion": "2015",
    "fruto": "Melocotón"
  },
  {
    "id": 5,
    "finca": "Finca Sur",
    "variedad": "Big Top",
    "paraje": null,
    "ano_plantacion": "2018",
    "fruto": "Melocotón"
  }
]
```

**Errores:**
- `400`: Se requiere un array de IDs
- `500`: Error al obtener parcelas

---

#### GET `/api/produccion-agricola/parcelas/opciones-inteligentes`

Sistema inteligente de filtrado jerárquico de parcelas con autocompletado progresivo.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters (todos opcionales):**
- `finca`: Nombre de finca
- `paraje`: Nombre de paraje
- `variedad`: Nombre de variedad
- `ano_plantacion`: Año de plantación

**Ejemplo 1 - Sin filtros:** `/api/produccion-agricola/parcelas/opciones-inteligentes`

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "opciones": {
      "fincas": [
        { "finca": "Finca Norte" },
        { "finca": "Finca Sur" }
      ],
      "parajes": [],
      "variedades": [],
      "anos_plantacion": []
    },
    "mostrar": {
      "paraje": false,
      "variedad": false,
      "ano_plantacion": false
    },
    "parcela_id": null,
    "total_coincidencias": 0
  }
}
```

**Ejemplo 2 - Con finca:** `/api/produccion-agricola/parcelas/opciones-inteligentes?finca=Finca%20Norte`

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "opciones": {
      "fincas": [
        { "finca": "Finca Norte" },
        { "finca": "Finca Sur" }
      ],
      "parajes": [
        { "paraje": "Paraje Alto" },
        { "paraje": "Paraje Bajo" }
      ],
      "variedades": [
        { "variedad": "Catherina" },
        { "variedad": "Big Top" }
      ],
      "anos_plantacion": []
    },
    "mostrar": {
      "paraje": true,
      "variedad": true,
      "ano_plantacion": false
    },
    "parcela_id": null,
    "total_coincidencias": 12
  }
}
```

**Ejemplo 3 - Filtros completos (parcela única):**  
`/api/produccion-agricola/parcelas/opciones-inteligentes?finca=Finca%20Norte&paraje=Paraje%20Alto&variedad=Catherina&ano_plantacion=2015`

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "opciones": {
      "fincas": [...],
      "parajes": [...],
      "variedades": [...],
      "anos_plantacion": [
        { "ano_plantacion": "2015" }
      ]
    },
    "mostrar": {
      "paraje": true,
      "variedad": true,
      "ano_plantacion": true
    },
    "parcela_id": 15,
    "total_coincidencias": 1
  }
}
```

**Lógica de funcionamiento:**
1. Sin filtros: Solo muestra fincas disponibles
2. Con finca: Habilita parajes y variedades de esa finca
3. Con finca + paraje/variedad: Filtra opciones progresivamente
4. Con todos los filtros: Retorna `parcela_id` si hay coincidencia única

**Uso típico:** Formularios inteligentes que guían al usuario paso por paso.

---

#### GET `/api/produccion-agricola/finca/[finca]`

Obtiene todas las parcelas de una finca específica usando el nombre como parámetro de ruta.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `finca`: Nombre de la finca (URL encoded, espacios pueden ser guiones)

**Ejemplo:** `/api/produccion-agricola/finca/Finca-Norte`

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "propietario": "Juan Pérez",
    "finca": "Finca Norte",
    "paraje": "Paraje Alto",
    "poligono": 5,
    "num_parcela": "123A",
    "superficie": 3.5,
    "num_arboles": 350,
    "variedad": "Catherina",
    "ano_plantacion": "2015",
    "situacion_especial": null,
    "fruto": "Melocotón",
    "distancia_almacen_km": 12.5
  }
]
```

**Respuesta si no hay parcelas:**
```json
[]
```

**Errores:**
- `400`: Nombre de finca requerido
- `500`: Error al obtener datos

---

#### GET `/api/produccion-agricola/fitosanitarios`

Obtiene tareas fitosanitarias (tratamientos y fertilización) de parcelas específicas en un rango de fechas.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters:**
- `parcela_ids` (requerido): Array JSON de IDs de parcelas, ejemplo: `[1,2,3]`
- `fecha_desde` (opcional): Fecha inicio en formato YYYY-MM-DD
- `fecha_hasta` (opcional): Fecha fin en formato YYYY-MM-DD

**Ejemplo:**  
`/api/produccion-agricola/fitosanitarios?parcela_ids=[1,5,10]&fecha_desde=2026-01-01&fecha_hasta=2026-06-30`

**Respuesta exitosa (200):**
```json
[
  {
    "id": 45,
    "tipo_tarea": "Tratamiento fitosanitario",
    "nombre": "Aplicación insecticida",
    "fecha_inicio": "2026-02-15T00:00:00.000Z",
    "fecha_final": "2026-02-15T00:00:00.000Z",
    "notas": "Tratamiento preventivo",
    "completada": true,
    "parcelas": [
      {
        "id": 1,
        "finca": "Finca Norte",
        "paraje": "Paraje Alto"
      }
    ],
    "gastos_recursos": [
      {
        "id_recurso": 15,
        "cantidad": 12.5,
        "recursos": {
          "nombre": "Insecticida XYZ",
          "unidad_consumo": "L"
        }
      }
    ]
  },
  {
    "id": 46,
    "tipo_tarea": "Fertilizar",
    "nombre": "Abonado primavera",
    "fecha_inicio": "2026-03-20T00:00:00.000Z",
    "fecha_final": "2026-03-22T00:00:00.000Z",
    "notas": "NPK 15-15-15",
    "completada": true,
    "parcelas": [
      {
        "id": 1,
        "finca": "Finca Norte"
      }
    ],
    "gastos_recursos": [
      {
        "id_recurso": 10,
        "cantidad": 150.0,
        "recursos": {
          "nombre": "Fertilizante NPK 15-15-15",
          "unidad_consumo": "kg"
        }
      }
    ]
  }
]
```

**Retorna array vacío si:**
- No hay parcelas especificadas
- No hay tareas fitosanitarias en ese rango

**Tipos de tarea incluidos:**
- "Fertilizar"
- "Tratamiento fitosanitario"
- "Aplicar fitosanitario"

**Uso típico:** Cuadernos de campo, registro fitosanitario, cumplimiento normativo.

---

#### GET `/api/produccion-agricola/plagas`

Obtiene registros de plagas detectadas en parcelas específicas.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters:**
- `parcela_ids` (requerido): Array JSON de IDs de parcelas
- `fecha_desde` (opcional): Fecha inicio
- `fecha_hasta` (opcional): Fecha fin

**Ejemplo:**  
`/api/produccion-agricola/plagas?parcela_ids=[1,5,10]&fecha_desde=2026-01-01&fecha_hasta=2026-12-31`

**Respuesta exitosa (200):**
```json
[
  {
    "id": 12,
    "id_parcela": 1,
    "nombre_plaga": "Pulgón verde",
    "descripcion": "Infestación moderada en hojas jóvenes",
    "fecha_detectada": "2026-05-15T00:00:00.000Z",
    "severidad": "media",
    "tratamiento_aplicado": "Insecticida sistémico",
    "id_empleado_detector": 5,
    "parcelas": {
      "id": 1,
      "finca": "Finca Norte",
      "paraje": "Paraje Alto",
      "variedad": "Catherina"
    },
    "empleados": {
      "id": 5,
      "nombre": "Juan Pérez",
      "cargo": "Operario"
    }
  }
]
```

**Retorna array vacío si:**
- No hay parcelas especificadas
- No hay plagas registradas

**Límite:** Máximo 50 registros, ordenados por fecha descendente (más recientes primero)

**Uso típico:** Monitoreo fitosanitario, prevención de tratamientos.

---

### Recursos

#### GET `/api/produccion-agricola/recursos/index`

Obtiene lista de recursos visibles, opcionalmente filtrados por tipo de tarea.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters:**
- `tipo_tarea` (opcional): Filtra recursos por tipo de tarea

**Ejemplo:** `/api/produccion-agricola/recursos/index?tipo_tarea=Fertilizar`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "nombre": "Fertilizante NPK 15-15-15",
      "tipo_tarea": "Fertilizar",
      "unidad_consumo": "kg",
      "valores": {},
      "vehiculo_asociado_nombre": null
    },
    {
      "id": 11,
      "nombre": "Abono orgánico",
      "tipo_tarea": "Fertilizar",
      "unidad_consumo": "kg",
      "valores": {},
      "vehiculo_asociado_nombre": null
    }
  ]
}
```

---

#### GET `/api/produccion-agricola/recursos/all`

Obtiene todos los recursos visibles (lista simplificada).

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "nombre": "Fertilizante NPK 15-15-15",
      "unidad_consumo": "kg"
    },
    {
      "id": 11,
      "nombre": "Abono orgánico",
      "unidad_consumo": "kg"
    }
  ],
  "total": 2
}
```

---

#### GET `/api/produccion-agricola/recursos/complete`

Obtiene recursos completos con precios y materia activa, agrupados por tipo de tarea.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "Fertilizar": [
      {
        "id": 10,
        "nombre": "Fertilizante NPK 15-15-15",
        "foto": "/uploads/recursos/fertilizante.jpg",
        "tipo_tarea": "Fertilizar",
        "unidad_consumo": "kg",
        "precio_actual": 2.50,
        "fecha_precio_actual": "2026-01-15T00:00:00.000Z",
        "materia_activa": 0.15
      }
    ],
    "Tratamiento fitosanitario": [
      {
        "id": 15,
        "nombre": "Insecticida XYZ",
        "foto": null,
        "tipo_tarea": "Tratamiento fitosanitario",
        "unidad_consumo": "L",
        "precio_actual": 35.00,
        "fecha_precio_actual": "2026-02-01T00:00:00.000Z",
        "materia_activa": 0.25
      }
    ]
  }
}
```

---

#### POST `/api/produccion-agricola/recursos/new`

Crea un nuevo recurso con su precio inicial.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "nombre": "Fertilizante NPK 20-10-10",
  "unidad_consumo": "kg",
  "tipo_tarea": "Fertilizar",
  "precio": 3.50,
  "foto": "/uploads/recursos/fertilizante-npk.jpg",
  "kg_ma_por_unidad": 0.20
}
```

**Campos:**
- `nombre` (requerido): min 1, máx 50 caracteres
- `unidad_consumo` (requerido): min 1, máx 20 caracteres
- `tipo_tarea` (opcional): máx 50 caracteres (debe existir en posibles_tareas)
- `precio` (requerido): número >= 0
- `foto` (opcional): ruta de la imagen
- `kg_ma_por_unidad` (opcional): número >= 0, kilogramos de materia activa por unidad

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "id": 125,
    "nombre": "Fertilizante NPK 20-10-10",
    "precio_id": 456
  },
  "message": "Recurso creado exitosamente"
}
```

**Efectos secundarios:**
- Crea automáticamente un registro de precio asociado
- Si se proporciona `kg_ma_por_unidad`, crea registro de materia activa

**Errores:**
- `400`: Datos inválidos o tipo de tarea no existe
- `409`: Ya existe recurso con ese nombre

---

#### POST `/api/produccion-agricola/recursos/precio`

Crea un nuevo precio para un recurso existente.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "id_recurso": 10,
  "precio_unitario": 3.75,
  "fecha": "2026-02-15"
}
```

**Campos:**
- `id_recurso` (requerido): ID del recurso, entero positivo
- `precio_unitario` (requerido): número positivo <= 999999.99
- `fecha` (requerido): fecha válida en formato YYYY-MM-DD o ISO

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Precio del recurso actualizado exitosamente",
  "data": {
    "precio": {
      "id": 457,
      "id_recurso": 10,
      "precio_unitario": 3.75,
      "fecha": "2026-02-15T00:00:00.000Z"
    },
    "recurso": {
      "id": 10,
      "nombre": "Fertilizante NPK 15-15-15",
      "id_precio_actual": 457
    }
  }
}
```

**Efectos secundarios:**
- Actualiza automáticamente `id_precio_actual` en la tabla recursos

**Errores:**
- `400`: Datos inválidos
- `404`: Recurso no encontrado

---

#### GET `/api/produccion-agricola/recursos/[id]/precios`

Obtiene el historial de precios de un recurso.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID del recurso

**Ejemplo:** `/api/produccion-agricola/recursos/10/precios`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 457,
      "precio_unitario": 3.75,
      "fecha": "2026-02-15T00:00:00.000Z"
    },
    {
      "id": 456,
      "precio_unitario": 3.50,
      "fecha": "2026-01-15T00:00:00.000Z"
    },
    {
      "id": 455,
      "precio_unitario": 3.25,
      "fecha": "2025-12-01T00:00:00.000Z"
    }
  ]
}
```

**Respuesta en caso de error:**
```json
{
  "success": false,
  "error": "Error al obtener historial de precios",
  "data": []
}
```

**Orden:** Descendente por fecha (más recientes primero)

**Errores:**
- `400`: ID de recurso inválido

---

#### PUT `/api/produccion-agricola/recursos/precios/[id]`

Actualiza un precio existente de un recurso.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Parámetros de ruta:**
- `id`: ID del precio (no del recurso)

**Body:**
```json
{
  "precio_unitario": 3.85,
  "fecha": "2026-02-20"
}
```

**Campos:**
- `precio_unitario` (requerido): número positivo <= 999999.99
- `fecha` (requerido): fecha válida en formato YYYY-MM-DD

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Precio actualizado exitosamente",
  "data": {
    "id": 457,
    "id_recurso": 10,
    "precio_unitario": 3.85,
    "fecha": "2026-02-20T00:00:00.000Z"
  }
}
```

**Errores:**
- `400`: ID inválido o datos incorrectos
- `500`: Error al actualizar

---

#### DELETE `/api/produccion-agricola/recursos/precios/[id]`

Elimina un precio del historial de un recurso.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID del precio (no del recurso)

**Ejemplo:** `/api/produccion-agricola/recursos/precios/457`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Precio eliminado exitosamente"
}
```

**Comportamiento especial:**
- Si el precio eliminado es el `id_precio_actual` del recurso, actualiza automáticamente el recurso para usar el precio más reciente
- Si no hay más precios, establece `id_precio_actual` a `null`

**Errores:**
- `400`: ID inválido
- `404`: Precio no encontrado
- `500`: Error al eliminar

---

#### PUT `/api/produccion-agricola/recursos/[id]`

Actualiza un recurso existente.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Parámetros de ruta:**
- `id`: ID del recurso

*Nota: Este endpoint no está implementado en el código proporcionado pero está en la estructura de carpetas.*

---

#### DELETE `/api/produccion-agricola/recursos/[id]`

Da de baja un recurso (cambia `visible` a `false`).

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID del recurso

*Nota: Este endpoint no está implementado en el código proporcionado pero está en la estructura de carpetas.*

---

### Accesorios

#### GET `/api/produccion-agricola/accesorios/index`

Obtiene lista de accesorios activos, opcionalmente filtrados por tipo de tarea.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters:**
- `tipo_tarea` (opcional): Filtra accesorios por tipo

**Ejemplo:** `/api/produccion-agricola/accesorios/index?tipo_tarea=Arado`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nombre": "Arado de disco",
      "tipo": "Arado"
    },
    {
      "id": 2,
      "nombre": "Cultivador",
      "tipo": "Arado"
    }
  ]
}
```

---

#### GET `/api/produccion-agricola/accesorios/all`

Obtiene todos los accesorios activos con sus tarifas actuales.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "nombre": "Arado de disco",
      "tipo": "Arado",
      "activo": true,
      "factor_consumo": 1.5,
      "coste_hora": 8.50
    },
    {
      "id": 2,
      "nombre": "Cultivador",
      "tipo": "Arado",
      "activo": true,
      "factor_consumo": 1.2,
      "coste_hora": 6.00
    }
  ]
}
```

**Descripción de campos:**
- `factor_consumo`: Multiplicador del consumo de combustible (1.0 = sin cambio, >1.0 aumenta consumo)
- `coste_hora`: Coste adicional por hora de uso del accesorio

---

#### POST `/api/produccion-agricola/accesorios/index`

Crea un nuevo accesorio con su tarifa inicial.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "nombre": "Sembradora",
  "tipo": "Siembra",
  "factor_consumo": 1.3,
  "coste_hora": 7.50
}
```

**Campos:**
- `nombre` (requerido): máx 100 caracteres
- `tipo` (opcional): máx 60 caracteres (debe existir en posibles_tareas)
- `factor_consumo` (requerido): entre 0.1 y 5.0
- `coste_hora` (opcional): número >= 0

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Apero creado exitosamente",
  "data": {
    "accesorio": {
      "id": 25,
      "nombre": "Sembradora",
      "tipo": "Siembra",
      "activo": true
    },
    "tarifa": {
      "id": 78,
      "id_accesorio": 25,
      "fecha_inicio": "2026-02-15T10:30:00.000Z",
      "coste_hora": 7.50,
      "factor_consumo": 1.3
    }
  }
}
```

**Errores:**
- `400`: Datos inválidos o tipo de tarea no existe
- `409`: Ya existe accesorio activo con ese nombre

---

#### DELETE `/api/produccion-agricola/accesorios/[id]`

Elimina un accesorio.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID del accesorio

**Ejemplo:** `/api/produccion-agricola/accesorios/25`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Apero eliminado exitosamente"
}
```

**Errores:**
- `400`: ID inválido
- `404`: Accesorio no encontrado

---

### Vehículos

#### GET `/api/produccion-agricola/vehiculos/index`

Obtiene lista de vehículos (información básica).

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "matricula": "1234ABC",
      "nombre": "Tractor John Deere",
      "marca": "John Deere",
      "modelo": "6150R",
      "tipo": "agrícola",
      "combustible": "diesel",
      "accesorio": null,
      "valores": {}
    },
    {
      "matricula": "5678DEF",
      "nombre": "Camión Iveco",
      "marca": "Iveco",
      "modelo": "Daily",
      "tipo": "transporte de mercancías",
      "combustible": "diesel",
      "accesorio": null,
      "valores": {}
    }
  ]
}
```

**Valores de `tipo`:**
- `agrícola`: Vehículos agrícolas (consumo por hora)
- `transporte de mercancías`: Camiones (consumo por km)
- `transporte de personas`: Vehículos de pasajeros (consumo por km)

**Valores de `combustible`:**
- `diesel`
- `gasolina`

---

#### GET `/api/produccion-agricola/vehiculos/all`

Obtiene todos los vehículos con sus tarifas de consumo actuales.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "matricula": "1234ABC",
      "nombre": "Tractor John Deere",
      "tipo": "agrícola",
      "marca": "John Deere",
      "modelo": "6150R",
      "combustible": "diesel",
      "foto": "/uploads/vehiculos/tractor.jpg",
      "consumo_l_hora": 15.5,
      "consumo_l_km": null
    },
    {
      "matricula": "5678DEF",
      "nombre": "Camión Iveco",
      "tipo": "transporte de mercancías",
      "marca": "Iveco",
      "modelo": "Daily",
      "combustible": "diesel",
      "foto": null,
      "consumo_l_hora": null,
      "consumo_l_km": 0.25
    }
  ]
}
```

**Descripción de campos de consumo:**
- `consumo_l_hora`: Litros por hora (solo para vehículos agrícolas)
- `consumo_l_km`: Litros por kilómetro (para vehículos de transporte)

---

#### POST `/api/produccion-agricola/vehiculos/index`

Crea un nuevo vehículo con su tarifa de consumo.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "matricula": "9999XYZ",
  "nombre": "Tractor New Holland",
  "tipo": "agrícola",
  "marca": "New Holland",
  "modelo": "T7",
  "combustible": "diesel",
  "consumo": 18.0,
  "foto": "/uploads/vehiculos/new-holland.jpg"
}
```

**Campos:**
- `matricula` (requerido): min 1, máx 10 caracteres
- `nombre` (requerido): min 1, máx 50 caracteres
- `tipo` (requerido): `agrícola`, `transporte de mercancías`, `transporte de personas`
- `marca` (requerido): min 1, máx 50 caracteres
- `modelo` (opcional): máx 50 caracteres (por defecto "-")
- `combustible` (requerido): `gasolina` o `diesel`
- `consumo` (requerido): número positivo (L/hora para agrícola, L/km para transporte)
- `foto` (opcional): ruta de la imagen

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Vehículo creado exitosamente",
  "vehiculo": {
    "matricula": "9999XYZ",
    "nombre": "Tractor New Holland",
    "tipo": "agrícola",
    "marca": "New Holland",
    "modelo": "T7",
    "combustible": "diesel",
    "foto": "/uploads/vehiculos/new-holland.jpg"
  }
}
```

**Efectos secundarios:**
- Crea automáticamente la tarifa de consumo en `tarifa_vehiculo`
- Para vehículos agrícolas: `L_hora` = consumo, `L_km` = 0
- Para vehículos de transporte: `L_km` = consumo, `L_hora` = 0

**Errores:**
- `400`: Datos inválidos o matrícula ya existe

---

#### DELETE `/api/produccion-agricola/vehiculos/[matricula]`

Elimina un vehículo.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `matricula`: Matrícula del vehículo

**Ejemplo:** `/api/produccion-agricola/vehiculos/1234ABC`

*Nota: Este endpoint aparece en la estructura pero no se proporcionó el código.*

---

### Tareas

#### GET `/api/produccion-agricola/tareas/index`

Obtiene lista de tareas filtradas por fechas y opcionalmente por responsable y parcelas.

**Headers:**
```
Cookie: access_token=<token>
```

**Query Parameters:**
- `fecha_desde` (requerido): Fecha inicio en formato YYYY-MM-DD
- `fecha_hasta` (requerido): Fecha fin en formato YYYY-MM-DD
- `responsable` (opcional): Nombre del empleado responsable
- `tipo` (opcional): Tipo de tarea
- `parcela_ids` (opcional): JSON array con IDs de parcelas, ejemplo: `[1,2,3]`

**Ejemplo:** 
```
/api/produccion-agricola/tareas/index?fecha_desde=2026-01-01&fecha_hasta=2026-02-28&responsable=Juan%20P%C3%A9rez&parcela_ids=[1,5,10]
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 100,
      "tipo_tarea": "Poda",
      "nombre": "Poda de invierno",
      "fecha_inicio": "2026-01-15T00:00:00.000Z",
      "fecha_final": "2026-01-20T00:00:00.000Z",
      "responsable": "Juan Pérez",
      "completada": true,
      "parcelas_info": [
        "Finca Norte - Paraje Alto (Catherina)"
      ],
      "parcelas": [
        {
          "id": 1,
          "finca": "Finca Norte",
          "paraje": "Paraje Alto",
          "variedad": "Catherina",
          "ano_plantacion": "2015"
        }
      ]
    }
  ],
  "meta": {
    "tipo": "generic",
    "total": 1,
    "fechas": "2026-01-01 - 2026-02-28",
    "responsable": "Juan Pérez"
  }
}
```

**Errores:**
- `400`: Fechas requeridas

---

#### GET `/api/produccion-agricola/tareas/tipos-tarea`

Obtiene la lista de tipos de tareas posibles.

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    "Arado",
    "Fertilizar",
    "Poda",
    "Recolección",
    "Riego",
    "Tratamiento fitosanitario"
  ]
}
```

---

#### POST `/api/produccion-agricola/tareas/crear-tipo`

Crea un nuevo tipo de tarea.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "nombre": "Desbroce"
}
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Tipo de tarea creado exitosamente",
  "data": {
    "nombre": "Desbroce"
  }
}
```

**Errores:**
- `400`: Nombre requerido o ya existe (comparación case-insensitive)

---

#### POST `/api/produccion-agricola/tarea/new`

Crea una nueva tarea con todos sus gastos asociados.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:** (estructura compleja)
```json
{
  "tipo_tarea": "Poda",
  "nombre": "Poda de invierno 2026",
  "parcelas": [
    { "id": 1 },
    { "id": 5 }
  ],
  "fecha_inicio": "2026-01-15",
  "fecha_final": "2026-01-20",
  "responsable": "Juan Pérez",
  "id_empleado_responsable": 5,
  "completada": false,
  "notas": "Poda ligera, solo ramas secas",
  "gastos_empleados": [
    {
      "id": 5,
      "cargo": "Operario",
      "valores": {
        "2026-01-15": 8,
        "2026-01-16": 8,
        "2026-01-17": 6
      }
    },
    {
      "id": 10,
      "cargo": "Operario",
      "valores": {
        "2026-01-15": 8,
        "2026-01-16": 8
      }
    }
  ],
  "gastos_vehiculos": [
    {
      "matricula": "1234ABC",
      "accesorio": {
        "id": 2
      },
      "valores": {
        "2026-01-15": 5,
        "2026-01-16": 6
      }
    }
  ],
  "gastos_recursos": [
    {
      "id": 15,
      "valores": {
        "2026-01-15": 25.5,
        "2026-01-16": 30.0
      }
    }
  ]
}
```

**Estructura de campos:**
- `tipo_tarea` (requerido): Tipo de tarea (máx 255 caracteres)
- `nombre` (opcional): Nombre descriptivo (máx 50 caracteres)
- `parcelas` (requerido): Array con al menos 1 parcela, cada una con su `id`
- `fecha_inicio` (requerido): Formato YYYY-MM-DD
- `fecha_final` (requerido): Formato YYYY-MM-DD (>= fecha_inicio)
- `responsable` (opcional): Nombre del responsable (máx 255 caracteres)
- `id_empleado_responsable` (opcional): ID del empleado responsable
- `completada` (opcional): booleano, por defecto false
- `notas` (opcional): Máx 1000 caracteres
- `gastos_empleados` (opcional): Array de empleados
  - `id`: ID del empleado
  - `cargo`: Cargo del empleado
  - `valores`: Objeto con fechas (YYYY-MM-DD) como keys y horas como values
- `gastos_vehiculos` (opcional): Array de vehículos
  - `matricula`: Matrícula del vehículo
  - `accesorio` (opcional): Objeto con `id` del accesorio
  - `valores`: Objeto con fechas como keys y horas/viajes como values
- `gastos_recursos` (opcional): Array de recursos
  - `id`: ID del recurso
  - `valores`: Objeto con fechas como keys y consumos como values

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Tarea creada exitosamente",
  "tarea_id": 125
}
```

**Este es un endpoint complejo que:**
1. Valida todas las relaciones (parcelas, empleados, vehículos, recursos)
2. Crea la tarea principal
3. Crea relaciones N:N con parcelas (con pesos según superficie)
4. Crea gastos de empleados con costes por hora
5. Crea gastos de vehículos con tarifas
6. Crea gastos de recursos con precios
7. Genera consumos de combustible automáticamente
8. Si está completada, calcula el coste total

**Errores:**
- `400`: Datos inválidos, parcelas/empleados/vehículos no existen, fechas inconsistentes
- `500`: Error al crear la tarea

---

#### GET `/api/produccion-agricola/tarea/[id]/index`

Obtiene detalles completos de una tarea con todos sus gastos agrupados.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la tarea

**Ejemplo:** `/api/produccion-agricola/tarea/125/index`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "id": 125,
    "tipo_tarea": "Poda",
    "nombre": "Poda de invierno 2026",
    "fecha_inicio": "2026-01-15",
    "fecha_final": "2026-01-20",
    "id_empleado_responsable": 5,
    "completada": false,
    "notas": "Poda ligera, solo ramas secas",
    "parcelas": [
      {
        "id": 1,
        "finca": "Finca Norte",
        "paraje": "Paraje Alto",
        "variedad": "Catherina",
        "ano_plantacion": "2015",
        "peso": 0.6
      },
      {
        "id": 5,
        "finca": "Finca Sur",
        "paraje": null,
        "variedad": "Big Top",
        "ano_plantacion": "2018",
        "peso": 0.4
      }
    ],
    "gastos_empleados": [
      {
        "id": 5,
        "nombre": "Juan Pérez",
        "cargo": "Operario",
        "cargo2": null,
        "valores": {
          "2026-01-15": 8,
          "2026-01-16": 8,
          "2026-01-17": 6
        }
      }
    ],
    "gastos_vehiculos": [
      {
        "matricula": "1234ABC",
        "nombre": "Tractor John Deere",
        "marca": "John Deere",
        "modelo": "6150R",
        "tipo": "agrícola",
        "combustible": "diesel",
        "accesorio": {
          "id": 2,
          "nombre": "Cultivador",
          "tipo": "Arado"
        },
        "valores": {
          "2026-01-15": 5,
          "2026-01-16": 6
        }
      }
    ],
    "gastos_recursos": [
      {
        "id": 15,
        "nombre": "Abono orgánico",
        "tipo_tarea": "Fertilizar",
        "unidad_consumo": "kg",
        "valores": {
          "2026-01-15": 25.5,
          "2026-01-16": 30.0
        },
        "vehiculo_asociado_nombre": null
      }
    ]
  }
}
```

**Errores:**
- `400`: ID inválido
- `404`: Tarea no encontrada

---

#### PUT `/api/produccion-agricola/tarea/[id]/index`

Actualiza una tarea completa con todos sus gastos.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Parámetros de ruta:**
- `id`: ID de la tarea

**Body:** (mismo formato que GET, con modificaciones)
```json
{
  "tipo_tarea": "Poda",
  "nombre": "Poda de invierno 2026 - Actualizada",
  "parcelas": [...],
  "fecha_inicio": "2026-01-15",
  "fecha_final": "2026-01-22",
  "id_empleado_responsable": 5,
  "completada": true,
  "notas": "Completada exitosamente",
  "gastos_empleados": [...],
  "gastos_vehiculos": [...],
  "gastos_recursos": [...]
}
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Tarea actualizada con éxito"
}
```

**Este endpoint:**
1. Actualiza la información general de la tarea
2. Elimina y recrea todos los gastos
3. Si la tarea se marca como completada, calcula el coste total

**Errores:**
- `400`: ID o datos inválidos
- `404`: Tarea no encontrada

---

#### DELETE `/api/produccion-agricola/tarea/[id]/index`

Elimina una tarea y todos sus registros asociados.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la tarea

**Ejemplo:** `/api/produccion-agricola/tarea/125/index`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "message": "Tarea eliminada exitosamente"
}
```

**Este endpoint elimina automáticamente:**
1. La tarea principal
2. Todos los gastos de empleados asociados (`gasto_empleados`)
3. Todos los gastos de recursos asociados (`gasto_recursos`)
4. Todos los gastos de vehículos asociados (`gasto_vehiculos`)
5. Todas las relaciones con parcelas (`tareas_parcelas`)

**Nota:** Esta operación es irreversible. Se recomienda mostrar una confirmación al usuario antes de ejecutarla.

**Errores:**
- `400`: ID de tarea inválido
- `404`: Tarea no encontrada
- `500`: Error al eliminar la tarea

---

#### PATCH `/api/produccion-agricola/tareas/[id]`

Actualiza parcialmente una tarea (solo campos específicos).

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Parámetros de ruta:**
- `id`: ID de la tarea

**Body:** (todos los campos son opcionales)
```json
{
  "completada": true,
  "notas": "Tarea completada con éxito"
}
```

**Campos actualizables:**
- `completada`: booleano
- `tipo_tarea`: string
- `id_empleado_responsable`: número
- `notas`: string
- `fecha_inicio`: string YYYY-MM-DD
- `fecha_final`: string YYYY-MM-DD
- `id_parcela`: número

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "id": 125,
    "tipo_tarea": "Poda",
    "nombre": "Poda de invierno 2026",
    "fecha_inicio": "2026-01-15T00:00:00.000Z",
    "fecha_final": "2026-01-22T23:59:59.000Z",
    "responsable": "Juan Pérez",
    "completada": true,
    "parcela_info": "Finca Norte - Paraje Alto (Catherina) [2015]"
  }
}
```

**Errores:**
- `400`: ID inválido

---

#### GET `/api/produccion-agricola/tarea/[id]/empleados/index`

Obtiene los empleados que trabajaron en una tarea específica.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la tarea

**Ejemplo:** `/api/produccion-agricola/tarea/125/empleados/index`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "empleados": [
      {
        "id": 245,
        "empleado_id": 5,
        "nombre": "Juan Pérez",
        "cargo": "Operario",
        "cargo2": null,
        "horas": 22,
        "descripcion": null,
        "coste_por_hora": 12.50
      },
      {
        "id": 246,
        "empleado_id": 10,
        "nombre": "María García",
        "cargo": "Operario",
        "cargo2": "Tractorista",
        "horas": 16,
        "descripcion": null,
        "coste_por_hora": 12.50
      }
    ],
    "tarea": {
      "id": 125,
      "fecha_inicio": "2026-01-15",
      "fecha_final": "2026-01-20"
    }
  }
}
```

**Errores:**
- `400`: ID inválido
- `404`: Tarea no encontrada

---

#### GET `/api/produccion-agricola/tarea/[id]/empleados/disponibles`

Obtiene la lista de empleados disponibles (activos) para asignar a una tarea.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la tarea (usado para contexto, pero no afecta el resultado)

**Ejemplo:** `/api/produccion-agricola/tarea/125/empleados/disponibles`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "nombre": "Juan Pérez",
      "cargo": "Operario",
      "cargo2": null
    },
    {
      "id": 10,
      "nombre": "María García",
      "cargo": "Operario",
      "cargo2": "Tractorista"
    },
    {
      "id": 15,
      "nombre": "Pedro López",
      "cargo": "Supervisor",
      "cargo2": null
    }
  ],
  "total": 3
}
```

**Descripción:** 
Devuelve todos los empleados con `visible: true`, ordenados alfabéticamente por nombre.

**Uso típico:** Formularios de asignación de personal a tareas.

**Errores:**
- `400`: ID de tarea requerido
- `500`: Error al obtener empleados

---

#### PUT `/api/produccion-agricola/tarea/[id]/update-info`

Actualiza la información básica de una tarea sin modificar gastos.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Parámetros de ruta:**
- `id`: ID de la tarea

**Body:**
```json
{
  "tipo_tarea": "Poda",
  "nombre": "Poda de invierno actualizada",
  "fecha_inicio": "2026-01-15",
  "fecha_final": "2026-01-22",
  "id_empleado_responsable": 5,
  "estado": true,
  "notas": "Notas actualizadas",
  "parcela_ids": [1, 5, 10]
}
```

**Campos:**
- `tipo_tarea` (opcional): Tipo de tarea
- `nombre` (opcional): Nombre descriptivo (se guarda como `null` si es string vacío)
- `fecha_inicio` (opcional): Fecha de inicio
- `fecha_final` (opcional): Fecha de finalización
- `id_empleado_responsable` (opcional): ID del empleado responsable (se guarda como `null` si no se proporciona)
- `estado` (opcional): Estado de completitud (mapeado a campo `completada`)
- `notas` (opcional): Notas adicionales
- `parcela_ids` (opcional): Array de IDs de parcelas (elimina y recrea relaciones completas)

**Respuesta exitosa (200):**
```json
{
  "success": true
}
```

**Comportamiento especial:**
- Si se proporciona `parcela_ids`, elimina todas las relaciones `tareas_parcelas` existentes y crea nuevas
- No elimina ni crea pesos (campo `peso` en `tareas_parcelas` no se gestiona aquí)
- No afecta a los gastos asociados (empleados, vehículos, recursos)

**Respuesta de error:**
```json
{
  "success": false,
  "error": "Mensaje de error descriptivo"
}
```

**Uso típico:** Actualización rápida de metadatos de la tarea sin recalcular costes.

---

#### GET `/api/produccion-agricola/tarea/[id]/reporte-economico`

Obtiene un reporte económico detallado de una tarea con todos los gastos de personal y recursos.

**Headers:**
```
Cookie: access_token=<token>
```

**Parámetros de ruta:**
- `id`: ID de la tarea

**Ejemplo:** `/api/produccion-agricola/tarea/125/reporte-economico`

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "personal": [
      {
        "id": 5,
        "nombre": "Juan Pérez",
        "cargo": "Operario",
        "fecha": "2026-01-15T00:00:00.000Z",
        "consumo": 8,
        "coste_por_hora": 12.50
      },
      {
        "id": 5,
        "nombre": "Juan Pérez",
        "cargo": "Operario",
        "fecha": "2026-01-16T00:00:00.000Z",
        "consumo": 8,
        "coste_por_hora": 12.50
      },
      {
        "id": 10,
        "nombre": "María García",
        "cargo": "Operario",
        "fecha": "2026-01-15T00:00:00.000Z",
        "consumo": 6,
        "coste_por_hora": 12.50
      }
    ],
    "recursos": [
      {
        "id": 15,
        "nombre": "Abono orgánico",
        "unidad": "kg",
        "fecha": "2026-01-15T00:00:00.000Z",
        "consumo": 150.0,
        "precio_unitario": 2.50
      },
      {
        "id": 15,
        "nombre": "Abono orgánico",
        "unidad": "kg",
        "fecha": "2026-01-16T00:00:00.000Z",
        "consumo": 200.0,
        "precio_unitario": 2.50
      }
    ]
  }
}
```

**Descripción de campos:**

**Personal:**
- `id`: ID del empleado
- `nombre`: Nombre del empleado
- `cargo`: Cargo del empleado en el momento del gasto
- `fecha`: Fecha del gasto
- `consumo`: Horas trabajadas
- `coste_por_hora`: Coste por hora del empleado en esa fecha

**Recursos:**
- `id`: ID del recurso
- `nombre`: Nombre del recurso
- `unidad`: Unidad de consumo (kg, L, ud, etc.)
- `fecha`: Fecha del gasto
- `consumo`: Cantidad consumida
- `precio_unitario`: Precio unitario del recurso en esa fecha

**Cálculos derivados:**
- Coste personal por línea: `consumo × coste_por_hora`
- Coste recurso por línea: `consumo × precio_unitario`
- Coste total personal: Suma de todos los gastos de personal
- Coste total recursos: Suma de todos los gastos de recursos

**Uso típico:** 
- Análisis de costes detallados
- Reportes económicos
- Facturación interna
- Auditorías

**Errores:**
- `400`: ID de tarea requerido
- `500`: Error interno del servidor

---

## 📈 Análisis

### POST `/api/analisis`

Ejecuta análisis de indicadores económicos sobre grupos de parcelas.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: application/json
```

**Body:**
```json
{
  "grupos": [
    {
      "nombre": "Finca Norte",
      "ids": [1, 2, 3, 4, 5]
    },
    {
      "nombre": "Finca Sur",
      "ids": [10, 11, 12]
    }
  ],
  "startDate": "2026-01-01",
  "endDate": "2026-02-28",
  "indicators": [
    "coste_total_empleados",
    "coste_total_recursos",
    "coste_total_vehiculos",
    "coste_por_hectarea"
  ]
}
```

**Campos:**
- `grupos` (requerido): Array con al menos 1 grupo
  - `nombre`: Nombre descriptivo del grupo
  - `ids`: Array de IDs de parcelas
- `startDate` (requerido): Fecha inicio YYYY-MM-DD
- `endDate` (requerido): Fecha fin YYYY-MM-DD (>= startDate)
- `indicators` (opcional): Array de identificadores de indicadores

**Indicadores disponibles:**
- `coste_total_empleados`: Coste total de mano de obra
- `coste_total_recursos`: Coste total de recursos consumidos
- `coste_total_vehiculos`: Coste total de uso de vehículos
- `coste_por_hectarea`: Coste total por hectárea
- `horas_empleados`: Total de horas trabajadas por empleados
- Más indicadores definidos en el registro del sistema

**Respuesta exitosa (200):**
```json
{
  "ok": true,
  "data": {
    "coste_total_empleados": [
      {
        "grupo": "Finca Norte",
        "valor": 12500.50,
        "parcelas": [1, 2, 3, 4, 5]
      },
      {
        "grupo": "Finca Sur",
        "valor": 8750.25,
        "parcelas": [10, 11, 12]
      }
    ],
    "coste_total_recursos": [
      ...
    ],
    "coste_por_hectarea": [
      ...
    ]
  },
  "error": null
}
```

**Características:**
- Sistema de caché inteligente (cache general y por grupo)
- Solo calcula indicadores que no están en caché
- Agrega datos solo de las tablas necesarias para los indicadores solicitados

**Errores:**
- `400`: Datos inválidos, fechas incorrectas
- `500`: Error al calcular indicadores

---

## 🛠️ Utilidades

### POST `/api/upload-image`

Sube una imagen al servidor.

**Headers:**
```
Cookie: access_token=<token>
Content-Type: multipart/form-data
```

**Form Data:**
- `file` (requerido): Archivo de imagen
- `folder` (opcional): Carpeta destino (por defecto: "general")

**Formatos permitidos:**
- `.jpg`, `.jpeg`, `.png`, `.webp`

**Tamaño máximo:** 5 MB

**Ejemplo usando fetch:**
```javascript
const formData = new FormData();
formData.append('file', imageFile);
formData.append('folder', 'empleados');

const response = await fetch('/api/upload-image', {
  method: 'POST',
  body: formData,
  credentials: 'include' // Para incluir cookies
});
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "url": "/uploads/empleados/img_1708024800000_k3j5l9.jpg",
  "filename": "img_1708024800000_k3j5l9.jpg",
  "folder": "empleados"
}
```

**Errores:**
- `400`: Sin archivo, tipo no permitido, archivo muy grande
- `500`: Error al guardar archivo

**Carpetas disponibles:**
- `avatars`: Fotos de perfil de usuarios
- `empleados`: Fotos de empleados
- `recursos`: Imágenes de recursos
- `vehiculos`: Fotos de vehículos
- `general`: Otros archivos

---

### GET `/api/protected/users`

Obtiene lista de usuarios del sistema (solo administradores).

**Headers:**
```
Cookie: access_token=<token>
```

**Respuesta exitosa (200):**
```json
[
  {
    "id": 1,
    "username": "admin",
    "email": "admin@ejemplo.com",
    "rol": "admin",
    "created_at": "2025-01-01T00:00:00.000Z"
  },
  {
    "id": 2,
    "username": "usuario1",
    "email": "usuario@ejemplo.com",
    "rol": "user",
    "created_at": "2025-02-15T10:30:00.000Z"
  }
]
```

**Roles disponibles:**
- `admin`: Administrador (acceso completo)
- `user`: Usuario regular
- `guest`: Invitado (modo sin autenticación)

**Errores:**
- `401`: No autenticado
- `403`: Sin permisos (no es administrador)

---

## 🔒 Autenticación y Seguridad

### Modo de autenticación

El sistema soporta dos modos:

1. **Modo autenticado** (`ONLY_AUTH_USERS` != "false")
   - Requiere login con credenciales válidas
   - Tokens JWT en cookies HTTP-only
   - Access token: 15 minutos
   - Refresh token: 90 días con rotación

2. **Modo guest** (`ONLY_AUTH_USERS` = "false")
   - Permite acceso sin autenticación
   - Útil para desarrollo
   - Usuario simulado con rol "guest"

### Headers requeridos

Para endpoints protegidos, incluir cookies automáticamente:

```
Cookie: access_token=<token>; refresh_token=<refresh_token>
```

### Manejo de tokens expirados

1. El cliente recibe error 401
2. Intentar refrescar con `/api/auth/refresh`
3. Si falla el refresh, redirigir a login

### Ejemplo de interceptor (conceptual para Flutter/Dio):

```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Intentar refresh
        final refreshed = await refreshToken();
        if (refreshed) {
          // Reintentar request original
          return handler.resolve(await dio.fetch(error.requestOptions));
        } else {
          // Redirigir a login
          navigateToLogin();
        }
      }
      return handler.next(error);
    },
  ),
);
```

---

## 📝 Códigos de estado HTTP

- `200`: Éxito
- `400`: Solicitud incorrecta (datos inválidos)
- `401`: No autenticado
- `403`: Sin permisos
- `404`: Recurso no encontrado
- `409`: Conflicto (recurso duplicado)
- `500`: Error interno del servidor

---

## 🌐 Consideraciones para Flutter

### Manejo de cookies

Usar paquete `dio` con `CookieManager`:

```dart
final dio = Dio();
final cookieJar = CookieJar();
dio.interceptors.add(CookieManager(cookieJar));
```

### Serialización de fechas

Las fechas se devuelven en formato ISO 8601:
- `2026-02-15T10:30:00.000Z` (con hora)
- `2026-02-15` (solo fecha)

Parsear con:
```dart
DateTime.parse(dateString)
```

### Formatos de respuesta

Todas las respuestas son JSON. La mayoría siguen el patrón:

```json
{
  "success": true,
  "data": { ... },
  "message": "Operación exitosa"
}
```

O en caso de error:
```json
{
  "success": false,
  "error": "Mensaje de error"
}
```

### Multipart/FormData

Para subir imágenes, usar `FormData` de Dio:

```dart
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(
    imagePath,
    filename: 'foto.jpg',
  ),
  'folder': 'empleados',
});

final response = await dio.post('/api/upload-image', data: formData);
```

---

## 🔄 Flujos comunes

### Flujo de autenticación completa

1. **Login**: `POST /api/auth/login`
2. **Acceso a recursos**: Headers con cookies automáticas
3. **Token expira**: Error 401
4. **Refresh**: `POST /api/auth/refresh`
5. **Logout**: `POST /api/auth/logout`

### Flujo de creación de tarea

1. Obtener tipos de tarea: `GET /api/produccion-agricola/tareas/tipos-tarea`
2. Obtener empleados: `GET /api/produccion-agricola/empleados/index`
3. Obtener vehículos: `GET /api/produccion-agricola/vehiculos/index`
4. Obtener recursos: `GET /api/produccion-agricola/recursos/index`
5. Obtener parcelas: `GET /api/produccion-agricola/parcelas/index`
6. Crear tarea: `POST /api/produccion-agricola/tarea/new`

### Flujo de gestión de empleados

1. Listar empleados: `GET /api/produccion-agricola/empleados/all`
2. Crear empleado: `POST /api/produccion-agricola/empleados/new`
3. Subir foto: `POST /api/upload-image` (folder: "empleados")
4. Ver nóminas: `GET /api/produccion-agricola/empleados/[id]/nominas`
5. Crear nómina: `POST /api/produccion-agricola/empleados/nomina`

---

## 📞 Soporte

Para dudas o problemas con la API, contactar al equipo de desarrollo.

**Última actualización:** Febrero 15, 2026
