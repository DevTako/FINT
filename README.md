Bienvenido a FINT: Sistema de Gestión Financiera & Monitor Cambiario

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![NodeJS](https://img.shields.io/badge/Node.js-18%2B-339933?logo=nodedotjs&logoColor=white)
![Express](https://img.shields.io/badge/Express-4.x-000000?logo=express&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20MVC-blueviolet)

Aplicación financiera multiplataforma orientada al mercado venezolano, con registro contable nativo en Bolívares (Bs.), monitor de tasas en tiempo real (BCV y Binance P2P) y calculadora cambiaria con análisis de brecha de mercado.

</div>

Resumen del Proyecto

FINT es una solución integral diseñada para resolver los desafíos de contabilidad personal en economías con doble referencia monetaria. Permite a los usuarios llevar el control de sus finanzas en moneda de curso legal (VES / Bs.) garantizando al mismo tiempo referencias internacionales en tiempo real (USD) respaldadas por las tasas oficiales del Banco Central de Venezuela (BCV) y el mercado P2P de Binance.

Características Principales

- 🇻🇪 Finanzas 100% Nativas en Bolívares (Bs.): Todos los saldos, ingresos, egresos y presupuestos operan bajo formato bancario oficial venezolano (puntuación para miles y comas para decimales).
- Integración Oficial con BCV: Scraping directo y sincronización automática de la tasa oficial del Banco Central de Venezuela para USD y EUR.
- Monitor Binance P2P / Cripto: Consulta en vivo de cotizaciones USDT/VES y USDC/VES mediante APIs de libros P2P (CriptoYa & DolarApi) con mitigación contra bloqueos 403 (Cloudflare bypass).
- Calculadora Cambiaria & Análisis de Brecha: Herramienta interactiva bidireccional que calcula equivalencias al instante e informa el diferencial y porcentaje de brecha cambiaria entre el mercado oficial y el paralelo/cripto.
- Gestión de Presupuestos: Establecimiento de techos de gasto por categoría (Alimentos, Vivienda, Transporte, etc.) con indicadores de progreso visual.
- UI Moderna y Adaptativa: Construida con Flutter y Material Design 3, soporte completo para tema oscuro (Dark Mode) y tema claro.

Stack Tecnológico

Frontend
- Framework: Flutter 3.x (Dart SDK)
- Diseño UI: Material Design 3 (Material You)
- Gráficos y Renderizado: Canvas 2D / Skia (`CustomPainter`)
- Gestión de Formatos: `package:intl` y formateador numérico personalizado
- Networking: `package:http` con servicios desacoplados (`ApiService`)

Backend
- Runtime: Node.js (v18+)
- Framework Web: Express.js 4.x
- Base de Datos: MySQL 8.0 (con `mysql2/promise` y Pool de Conexiones)
- Scraping & Data Fetching: `axios`, `cheerio`, `https-agent`
- Cache en Memoria:`node-cache` (TTL configurable de 15 minutos para optimizar ancho de banda)

---

Arquitectura del Sistema


                      ┌─────────────────────────┐
                      │    Cliente Flutter      │
                      │  (Web, Desktop, Mobile) │
                      └────────────┬────────────┘
                                   │  HTTP / JSON
                                   ▼
                      ┌─────────────────────────┐
                      │   Servidor Express.js   │
                      │       (Node.js)         │
                      └───────┬────────────┬────┘
                              │            │
            ┌─────────────────┴─┐        ┌─┴──────────────────┐
            ▼                   ▼        ▼                    ▼
     ┌─────────────┐     ┌─────────────┐┌─────────────┐┌─────────────┐
     │  MySQL DB   │     │ Node-Cache  ││ Web Oficial ││ CriptoYa /  │
     │  (Port 3306)│     │  (15m TTL)  ││    BCV      ││ Binance P2P │
     └─────────────┘     └─────────────┘└─────────────┘└─────────────┘


Puesta en Marcha de forma Local

 Requisitos Previos
- Node.js ≥ 18
- Flutter SDK ≥ 3.19
- Servidor MySQL activo (puerto 3306)

 Configurar la Base de Datos
1. Inicia tu servicio de MySQL (XAMPP, WAMP o nativo).
2. Crea la base de datos e importa las tablas:
   ```sql
   CREATE DATABASE fint_db;
   ```

Iniciar el Backend
bash
cd backend
npm install
npm run dev
```
El servidor quedará activo en `http://localhost:3000`.

Iniciar la Aplicación Flutter
En una nueva terminal:
bash
flutter pub get
flutter run -d edge   # o windows, chrome, etc.

Endpoints de la API REST

| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/api/login` | Autenticación y obtención de sesión |
| `POST` | `/api/register` | Registro de nuevos usuarios |
| `GET` | `/api/financial-data` | Retorna balance, transacciones y presupuestos |
| `POST` | `/api/transaction` | Registra un ingreso o egreso en Bs. |
| `GET` | `/api/currency/venezuela` | Obtiene tasas actualizadas de BCV y Binance P2P |
| `GET` | `/api/currency/rates` | Tasas internacionales de respaldo |

Desarrollado como proyecto de ingeniería de software con arquitectura limpia, desacoplamiento modular y enfoque en soluciones para el mercado real.
