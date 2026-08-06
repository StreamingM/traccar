import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { DataSource } from 'typeorm';

// Cargar variables de entorno
dotenv.config();

const app: Express = express();
const PORT = process.env.PORT || 3000;

// Inicializar DataSource de TypeORM (PostgreSQL)
export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432'),
  username: process.env.DATABASE_USER || 'postgres',
  password: process.env.DATABASE_PASSWORD || 'postgres',
  database: process.env.DATABASE_NAME || 'plataforma_gps_crm',
  synchronize: false, // Usaremos migraciones en lugar de sincronización automática
  logging: process.env.LOG_LEVEL === 'debug',
  migrations: ['dist/database/migrations/*.js'],
  entities: ['dist/entities/*.js'],
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Middleware de logging simple
app.use((req: Request, res: Response, next: NextFunction) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Rutas de prueba
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  });
});

app.get('/api/version', (req: Request, res: Response) => {
  res.json({
    version: '1.0.0',
    name: 'Plataforma GPS CRM Backend',
    traccar_url: process.env.TRACCAR_API_URL,
  });
});

// Manejo de errores global
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Error interno del servidor',
    timestamp: new Date().toISOString(),
  });
});

// Iniciar servidor
async function startServer() {
  try {
    // Conectar a la base de datos
    await AppDataSource.initialize();
    console.log('✅ Base de datos conectada correctamente');

    // Iniciar servidor Express
    app.listen(PORT, () => {
      console.log(`🚀 Servidor backend iniciado en puerto ${PORT}`);
      console.log(`   Health check: http://localhost:${PORT}/health`);
      console.log(`   API version: http://localhost:${PORT}/api/version`);
      console.log(`   Traccar motor: ${process.env.TRACCAR_API_URL}`);
    });
  } catch (error) {
    console.error('❌ Error iniciando servidor:', error);
    process.exit(1);
  }
}

startServer();
