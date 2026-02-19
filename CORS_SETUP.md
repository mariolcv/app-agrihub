# Configuración CORS para el Backend

## Problema Actual

```
Access to fetch at 'http://localhost:3000/api/auth/login' from origin 'http://localhost:53683' 
has been blocked by CORS policy: Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource
```

**Causa:** Flutter web ejecuta desde un origen diferente (puerto 53683) al backend (puerto 3000). Los navegadores bloquean estas peticiones cross-origin por seguridad.

---

## Solución: Configurar CORS en tu Backend Node.js/Nuxt.js

### Opción 1: Middleware para Express/Nuxt

Agrega esto en tu servidor (antes de las rutas):

```typescript
// Si usas Express directamente
import cors from 'cors';

app.use(cors({
  origin: '*', // En producción usa el dominio específico
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Cookie'],
}));
```

### Opción 2: Configuración Manual de Headers

Si no puedes usar el paquete cors:

```typescript
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Cookie');
  res.header('Access-Control-Allow-Credentials', 'true');
  
  // Manejar preflight requests
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  
  next();
});
```

### Opción 3: Configuración en Nuxt.js (nuxt.config.ts)

```typescript
export default defineNuxtConfig({
  nitro: {
    routeRules: {
      '/api/**': {
        cors: true,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, Cookie',
          'Access-Control-Allow-Credentials': 'true',
        },
      },
    },
  },
});
```

---

## Alternativa: Probar en Android/iOS (Sin CORS)

Si no quieres/puedes modificar el backend ahora:

```powershell
# Ver dispositivos disponibles
flutter devices

# Ejecutar en emulador Android
flutter run -d android

# Ejecutar en emulador iOS (solo macOS)
flutter run -d ios
```

Los emuladores móviles **NO tienen restricciones CORS** porque no son navegadores web.

---

## Solo para Desarrollo: Chrome sin seguridad

**⚠️ NO USES EN PRODUCCIÓN**

```powershell
# Windows
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=C:/temp/chrome"

# Linux/Mac
flutter run -d chrome --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome"
```

---

## Verificar que funciona

Después de configurar CORS, deberías ver estos headers en la respuesta:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, Cookie
Access-Control-Allow-Credentials: true
```

Puedes verificarlos en las DevTools del navegador (F12 → Network → clic en request → Headers).
