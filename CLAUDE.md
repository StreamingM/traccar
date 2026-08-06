# Traccar — Contexto para Claude Code

Traccar es un motor GPS open source (backend Java). Soporta 200+ protocolos de rastreadores GPS y 2000+ modelos de dispositivos. Expone una REST API y sirve la web app (submódulo `traccar-web`, ver `.gitmodules`). Licencia Apache 2.0.

## Entorno de build (verificado 2026-08-05)

- **Java**: 21 (Eclipse Adoptium Temurin 21.0.12) — requerido, `sourceCompatibility`/`targetCompatibility` = `VERSION_21` en `build.gradle`.
- **Gradle Wrapper**: 9.5.1 (`gradle/wrapper/gradle-wrapper.properties`). Usar siempre `./gradlew` / `.\gradlew.bat`, no un Gradle instalado globalmente.
- Nombre del proyecto raíz: `tracker-server` (`settings.gradle`), proyecto de módulo único (no multi-módulo).
- `assemble` genera el jar en `target/` y copia dependencias a `target/lib` (tarea `copyDependencies`).
- Punto de entrada: `org.traccar.Main` (`Main-Class` en el manifest del jar).

### ⚠️ Gotcha conocido en Windows: build falla en `checkstyleMain`

Con `core.autocrlf=true` en la config de git (común en Windows), el checkout reescribe los finales de línea LF → CRLF. El repo **no tiene `.gitattributes`**, así que nada fuerza LF. La regla Checkstyle `NewlineAtEndOfFile` exige LF y falla con cientos de archivos en CRLF (`gradle/checkstyle.xml`).

- `compileJava`, `test`, `jar` y `assemble` **sí compilan y pasan** — el código en sí es correcto.
- Solo la tarea `checkstyleMain` (parte de `build`/`check`) falla por este motivo.
- Soluciones (no aplicadas todavía, requieren decisión del usuario):
  - `git config core.autocrlf false` + re-checkout (`git rm --cached -r . && git checkout .`), o
  - añadir un `.gitattributes` con `* text eol=lf` al repo, o
  - ejecutar `./gradlew assemble` / `./gradlew compileJava test` en vez de `build` cuando solo se quiera verificar compilación.

## Arquitectura

### Arranque (`Main.java`)
1. Crea un `Injector` de Guice combinando `MainModule` (config, bindings generales), `DatabaseModule` (storage/DB) y `WebModule` (Jetty, Jersey, servlets).
2. Config: XML pasado como argumento (o `./debug.xml` si no hay argumentos — usado en desarrollo local).
3. Arranca servicios `LifecycleObject`: `ScheduleManager`, `ServerManager`, `WebServer`, `BroadcastService`.
4. Soporta modo servicio de Windows (`--install` / `--uninstall` / `--service`, ver `WindowsService.java`).

### Ingesta de posiciones GPS (Netty)
- `ServerManager` levanta un `TrackerServer`/`TrackerConnector` (TCP/UDP/HTTP/MQTT) por cada protocolo habilitado en config.
- Cada protocolo vive en `src/main/java/org/traccar/protocol/` (~675 archivos: un decoder/encoder/protocol por fabricante — Teltonika, Suntech, Meitrack, etc.). Extienden `BaseProtocol`, `BaseProtocolDecoder`/`BaseProtocolEncoder`, y usan frame decoders (`BaseFrameDecoder`, `CharacterDelimiterFrameDecoder`) para trocear el stream en mensajes.
- `BasePipelineFactory.initChannel()` arma el pipeline Netty por conexión, en este orden:
  1. Handlers de transporte del protocolo (`addTransportHandlers`, frame decoding).
  2. `IdleStateHandler` (timeout), `OpenChannelHandler`, forwarding opcional, `NetworkMessageHandler`, logging.
  3. Handlers específicos del protocolo (`addProtocolHandlers` — el decoder real que produce `Position`).
  4. `RemoteAddressHandler` → `ProcessingHandler` (pipeline post-proceso, ver abajo) → `MainEventHandler`.

### Post-procesamiento de posiciones (`handler/`)
`ProcessingHandler` encadena handlers que enriquecen cada `Position` antes de persistir: `DistanceHandler`, `MotionHandler`, `EngineHoursHandler`, `GeocoderHandler`, `GeofenceHandler`, `GeolocationHandler` (fallback wifi/cell), `SpeedLimitHandler`, `MapMatcherHandler`, `ComputedAttributesHandler` (atributos definidos por el usuario vía expresiones JEXL), `DriverHandler`, `CopyAttributesHandler`, `OutdatedHandler`, `TimeHandler`, `HemisphereHandler`, terminando en `DatabaseHandler` + `PostProcessHandler`.
- `handler/events/` genera eventos (alarmas, geofence enter/exit, overspeed, etc.) a partir de posiciones procesadas.
- `handler/network/` son los handlers Netty de bajo nivel (reenvío, logging, ack, dirección remota).

### API REST (`api/`)
- JAX-RS (Jersey) sobre Jetty. Recursos en `api/resource/`: `DeviceResource`, `PositionResource`, `EventResource`, `GeofenceResource`, `ReportResource`, `NotificationResource`, `CommandResource`, `UserResource`, `SessionResource`, `ShareResource`, `OrderResource`, `OidcResource`, `HealthResource`, etc.
- `api/security/` maneja autenticación (sesión, tokens, OpenID/LDAP vía `database/OpenIdProvider.java` y `database/LdapProvider.java`).
- Definición OpenAPI completa en `openapi.yaml` (raíz del repo).
- WebSocket para tiempo real: ver `AsyncSocket.java` / `AsyncSocketServlet.java`.
- MCP (Model Context Protocol) server embebido: `web/McpServerHolder.java`, `web/McpAuthFilter.java` — expone funcionalidad de Traccar como servidor MCP.

### Persistencia (`storage/`, `database/`, `schema/`)
- `Storage` es la abstracción de acceso a datos; `DatabaseStorage` (SQL vía JDBC/HikariCP) y `MemoryStorage` (tests/temporal) son las implementaciones.
- Soporta H2, MySQL, MariaDB, PostgreSQL, SQL Server (drivers en `build.gradle`).
- Migraciones con Liquibase: changelogs en `schema/` (`changelog-4.0-clean.xml` en adelante, uno por versión).
- `database/` contiene managers de dominio (no solo SQL): `NotificationManager`, `StatisticsManager`, `CommandsManager`, `MediaManager`, `LocaleManager`, `PositionBatchWriter`, `BufferingManager`.
- `session/` gestiona conexiones de dispositivos activas (`ConnectionManager`, `DeviceSession`) y cache en memoria (`session/cache/CacheManager`).

### Notificaciones y comandos
- `notification/` + `notificators/`: envío de alertas por email (`mail/`), SMS (`sms/` — soporta HTTP gateway y AWS SNS), Firebase push, Telegram, etc.
- `command/`: envío de comandos a dispositivos (reboot, configuración remota, etc.), específico por protocolo cuando aplica.
- `broadcast/`: sincronización entre múltiples instancias de Traccar (cluster) vía Redis/RabbitMQ/Kafka.
- `forward/`: reenvío de posiciones a sistemas externos (webhooks, MQTT, Kafka, etc.).

### Otros módulos relevantes
- `geocoder/`: reverse geocoding (múltiples proveedores).
- `geofence/`: evaluación de geocercas (geometrías vía `org.locationtech.jts`/`spatial4j`).
- `mapmatcher/`: ajuste de posiciones a la red vial.
- `speedlimit/`: límites de velocidad por vía (Overpass/OSM).
- `reports/`: generación de reportes (viajes, paradas, resumen, eventos) — plantillas Excel con JXLS en `templates/`.
- `config/`: `Config`, `Keys` (catálogo central de claves de configuración), `ConfigKey`.
- `schedule/`: tareas periódicas (`TaskExpirations`, `TaskHealthCheck`, `TaskDeviceInactivityCheck`, keepalive de websockets, etc.), orquestadas por `ScheduleManager`.

## Tests
- `src/test/java/org/traccar/` refleja la estructura de `src/main` (protocol, handler, reports, storage, geofence, etc.).
- JUnit 5 (Jupiter) + Mockito. `BaseTest.java` es la base común. `ProtocolTest.java` tiene helpers para testear decoders de protocolo.
- Ejecutar: `./gradlew test` (o `./gradlew compileJava compileTestJava test` para evitar el gotcha de Checkstyle en Windows).

## Convenciones
- Checkstyle obligatorio en `checkstyleMain` (no en tests: `checkstyleTest.enabled = false`), config en `gradle/checkstyle.xml`. Incluye regla de fin de línea LF — ver gotcha de Windows arriba.
- Archivos fuente en UTF-8 (`compileJava.options.encoding = "UTF-8"`).
- Versión actual del jar: `6.14.5` (atributo `Implementation-Version` en `build.gradle`, tarea `jar`).
