# Plant Imaginatio - Frontend

Aplicación móvil desarrollada en Flutter para el cuidado de plantas virtuales.

## 🚀 Estado del Proyecto

**El backend FastAPI ha sido deprecado.** El proyecto actualmente funciona con Flutter + Unity sin necesidad de backend externo.

## 🛠️ Tecnologías

| Componente | Tecnología |
|------------|------------|
| Frontend | Flutter 3.x |
| Game Engine | Flame |
| Render 3D | Unity |
| Persistencia | SharedPreferences (local) |
| Formato de datos | JSON (.tree) |

## 📱 Características

- **Minijuegos de recursos**: Sol (10 min cooldown), Agua (10 min cooldown), Composta (3 min cooldown)
- **Sistema de evolución**: Semilla → Arbusto → Planta → ENT
- **Gestión de plantas**: Selección, evolución, muerte por falta de recursos
- **Decay pasivo**: Los recursos aplicados disminuyen cada 10 minutos
- **Persistencia local**: Recursos y progreso guardados en SharedPreferences
- **Export a Unity**: Archivo `.tree` sincronizado con Unity para renderizado 3D

## 📁 Estructura del Proyecto

```
plant-imaginatio/
├── frontend/           # Aplicación Flutter
│   ├── lib/
│   │   ├── modules/   # Módulos de negocio
│   │   │   ├── plant_game/     # Juego de plantas
│   │   │   ├── inventory/     # Inventario
│   │   │   └── main_menu/     # Menú principal
│   │   ├── services/  # Servicios (storage, minijuegos)
│   │   ├── models/    # Modelos de datos
│   │   └── core/      # Configuración (router)
│   └── assets/        # Recursos (imágenes, sprites)
└── backend/           # DEPRECADO - FastAPI (ya no se usa)
```

## 🎮 Flujo del Juego

1. El usuario inicia sesión
2. Se carga la planta activa desde SharedPreferences
3. Puede jugar minijuegos para obtener recursos (sol, agua, composta)
4. Los recursos se aplican a la planta activa
5. Al cumplir requisitos, la planta evoluciona automáticamente
6. Los datos se exportan a `.tree` para Unity

## 🔧 Comandos Útiles

```bash
# Instalar dependencias
cd frontend
flutter pub get

# Modo desarrollo
flutter run

# Build debug
flutter build apk --debug

# Build release
flutter build apk --release
```

## 📋 Notas Importantes

- Los cooldowns de minijuegos se almacenan en SharedPreferences (no en .tree)
- El archivo `.tree` está diseñado para compatibilidad con Unity
- Los recursos de Flutter (sol, agua, composta, fertilizante) se persisten separadamente
- Sistema de fases: `semilla` → `arbusto` → `planta` → `ent`
- Decay: cada 10 minutos se descuenta 1 unidad de sol/agua aplicada

## 👥 Equipo

- Frontend: Flutter/Flutter
- 3D: Unity
- Lógica de plantas: Documentada en `backend/LOGICA_PLANTAS.md`