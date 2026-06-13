# 🧴 SkinDiary

Un diario sencillo para llevar el seguimiento del cuidado de tu piel. Registra cada día cómo
notas tu piel, qué productos usaste, etiquetas y notas, e incluso una foto. SkinDiary te
muestra un resumen con tu racha de registros y la evolución de tu estado.

Este es el **MVP**: una aplicación web autónoma que funciona 100% en el navegador, sin
servidor ni dependencias externas. Los datos se guardan localmente en tu navegador
(`localStorage`).

## ✨ Funcionalidades del MVP

- **Crear, editar y eliminar** entradas diarias.
- **Estado de la piel** con escala visual de 5 niveles (de 😣 a 😄).
- **Productos** y **etiquetas** asociados a cada entrada.
- **Notas** de texto libre.
- **Foto opcional** por entrada (almacenada localmente como dataURL).
- **Búsqueda** por notas, productos o etiquetas.
- **Filtro** por estado de la piel.
- **Resumen**: total de entradas, racha de días consecutivos, estado medio y último registro.
- **Persistencia local** en `localStorage` (no se envía nada a ningún servidor).
- **Diseño responsive** pensado para móvil y escritorio.

## 🚀 Cómo usarlo

No requiere instalación ni `build`. Solo necesitas abrir `index.html`.

Opción rápida (doble clic):

- Abre `index.html` en tu navegador.

Opción recomendada (servidor estático local, evita restricciones de algunos navegadores):

```bash
# Con Python
python3 -m http.server 8000

# o con Node
npx serve .
```

Luego visita `http://localhost:8000`.

## 📁 Estructura del proyecto

```
SkinDiary/
├── index.html         # Estructura de la app
├── styles/
│   └── main.css       # Estilos
└── js/
    ├── storage.js     # Capa de persistencia (localStorage) y modelo de datos
    └── app.js         # Lógica de interfaz y orquestación
```

## 🧩 Modelo de datos

Cada entrada del diario tiene esta forma:

```js
{
  id: "uuid",
  date: "2026-06-13",   // YYYY-MM-DD
  condition: 4,          // 1..5 (estado de la piel)
  products: ["Limpiador", "Niacinamida"],
  tags: ["sol", "descanso"],
  notes: "Piel más calmada hoy.",
  photo: "data:image/...", // o null
  createdAt: "ISO",
  updatedAt: "ISO"
}
```

## 🗺️ Próximos pasos (fuera del MVP)

- Sincronización en la nube y cuentas de usuario.
- Gráficas de evolución del estado de la piel.
- Recordatorios de rutina.
- Exportar / importar datos (JSON / CSV).

## 📝 Licencia

MIT
