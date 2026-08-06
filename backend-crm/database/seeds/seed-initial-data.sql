-- Insertar Roles base
INSERT INTO roles (name, description) VALUES
('Super Admin', 'Acceso total al sistema'),
('Admin Empresa', 'Administrador de su empresa'),
('Gerente Operativo', 'Gestión de operaciones y dispositivos'),
('Operador Monitoreo', 'Visualización y monitoreo en tiempo real'),
('Vendedor', 'Gestión de clientes y cotizaciones'),
('Contador', 'Acceso a facturación y reportes financieros'),
('Soporte Técnico', 'Soporte a clientes y resolución de tickets');

-- Insertar Permisos por módulo
INSERT INTO permissions (name, description, module, action) VALUES
-- Módulo: Usuarios
('users.view', 'Ver lista de usuarios', 'users', 'view'),
('users.create', 'Crear nuevo usuario', 'users', 'create'),
('users.edit', 'Editar usuario', 'users', 'edit'),
('users.delete', 'Eliminar usuario', 'users', 'delete'),

-- Módulo: Empresas
('companies.view', 'Ver empresas', 'companies', 'view'),
('companies.create', 'Crear empresa', 'companies', 'create'),
('companies.edit', 'Editar empresa', 'companies', 'edit'),
('companies.delete', 'Eliminar empresa', 'companies', 'delete'),

-- Módulo: Dispositivos GPS
('devices.view', 'Ver dispositivos', 'devices', 'view'),
('devices.create', 'Crear dispositivo', 'devices', 'create'),
('devices.edit', 'Editar dispositivo', 'devices', 'edit'),
('devices.delete', 'Eliminar dispositivo', 'devices', 'delete'),
('devices.track', 'Ver posición en tiempo real', 'devices', 'track'),
('devices.history', 'Ver historial de posiciones', 'devices', 'history'),

-- Módulo: Facturación
('billing.view', 'Ver facturas', 'billing', 'view'),
('billing.create', 'Crear factura', 'billing', 'create'),
('billing.edit', 'Editar factura', 'billing', 'edit'),
('billing.delete', 'Eliminar factura', 'billing', 'delete'),
('billing.export', 'Exportar reportes de facturación', 'billing', 'export'),

-- Módulo: Clientes
('clients.view', 'Ver clientes', 'clients', 'view'),
('clients.create', 'Crear cliente', 'clients', 'create'),
('clients.edit', 'Editar cliente', 'clients', 'edit'),
('clients.delete', 'Eliminar cliente', 'clients', 'delete'),

-- Módulo: Reportes
('reports.view', 'Ver reportes', 'reports', 'view'),
('reports.create', 'Generar reportes', 'reports', 'create'),
('reports.export', 'Exportar reportes', 'reports', 'export'),

-- Módulo: Auditoría
('audit.view', 'Ver logs de auditoría', 'audit', 'view');

-- Asignar permisos a rol "Super Admin" (acceso a todo)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Super Admin';

-- Asignar permisos a rol "Admin Empresa"
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Admin Empresa'
  AND p.name IN (
    'users.view', 'users.create', 'users.edit', 'users.delete',
    'devices.view', 'devices.create', 'devices.edit', 'devices.delete',
    'devices.track', 'devices.history',
    'billing.view', 'billing.create', 'billing.edit', 'billing.export',
    'clients.view', 'clients.create', 'clients.edit',
    'reports.view', 'reports.create', 'reports.export',
    'audit.view'
  );

-- Asignar permisos a rol "Gerente Operativo"
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Gerente Operativo'
  AND p.name IN (
    'devices.view', 'devices.create', 'devices.edit',
    'devices.track', 'devices.history',
    'clients.view', 'reports.view', 'reports.create'
  );

-- Asignar permisos a rol "Operador Monitoreo"
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Operador Monitoreo'
  AND p.name IN (
    'devices.view', 'devices.track', 'devices.history',
    'reports.view'
  );

-- Asignar permisos a rol "Vendedor"
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Vendedor'
  AND p.name IN (
    'clients.view', 'clients.create', 'clients.edit',
    'devices.view',
    'reports.view'
  );

-- Asignar permisos a rol "Contador"
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Contador'
  AND p.name IN (
    'billing.view', 'billing.create', 'billing.edit',
    'billing.export',
    'reports.view', 'reports.export',
    'audit.view'
  );

-- Asignar permisos a rol "Soporte Técnico"
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'Soporte Técnico'
  AND p.name IN (
    'devices.view', 'devices.history',
    'clients.view',
    'reports.view',
    'audit.view'
  );

-- Crear empresa de prueba
INSERT INTO companies (name, tax_id, description) VALUES
('Empresa Test', '123456789', 'Empresa de prueba inicial');

-- Crear usuario Super Admin de prueba
INSERT INTO users (email, password_hash, first_name, last_name, role_id, active)
SELECT 'admin@plataforma.local', '$2a$10$5T5ruAbsHlFC4Bkc.1ZfKu1rM3bpdjmR4e1MhaOffp4KWeX6T0tKG', 'Admin', 'Sistema', id, true
FROM roles WHERE name = 'Super Admin';
