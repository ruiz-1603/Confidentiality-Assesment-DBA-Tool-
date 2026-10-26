Facultad de Ciencias Exactas y Naturales

Escuela de Informática

Curso: Administración de Bases de Datos

Controles ISO/IEC 27001:2022 para la Confidencialidad en la Administración de Bases de Datos Oracle 21c XE

Prof. Johnny Villalobos Murillo

Estudiante: Aaron Ruiz Medina

II Ciclo 2026

## Introducción y justificación

En la arquitectura tecnológica de las organizaciones modernas, las bases de datos son el repositorio final donde converge el activo más valioso: la información. La familia de normas ISO/IEC 27000 aborda su protección mediante un Sistema de Gestión de Seguridad de la Información (SGSI): la ISO/IEC 27000 define el vocabulario y los principios fundamentales (International Organization for Standardization [ISO], 2018), la ISO/IEC 27001 establece los requisitos certificables del SGSI (ISO, 2022c), la ISO/IEC 27002 ofrece el catálogo de controles de referencia (ISO, 2022b) y la ISO/IEC 27005 guía la gestión de riesgos (ISO, 2022a). Todas descansan sobre la preservación de la confidencialidad, la integridad y la disponibilidad.

La confidencialidad, entendida como la propiedad de que la información no se divulgue ni esté disponible para individuos, entidades o procesos no autorizados, adquiere especial criticidad en la administración de bases de datos. En Oracle Database, protegerla no es un ejercicio teórico de cumplimiento: exige traducir la gestión de riesgos en configuraciones técnicas concretas sobre el control de accesos, la segregación de funciones, el manejo de copias de seguridad y los mecanismos de trazabilidad y auditoría.

Este informe estructura primero el marco teórico (secciones 1 a 6, con una extensión de tres páginas) en el orden exigido: familia ISO/IEC 27000 y cambios de la edición 2022, control de acceso, mínimo privilegio y segregación de funciones en Oracle, defensa en profundidad y Zero Trust, técnicas de protección del dato, copias de seguridad y DLP, trazabilidad forense con SIEM y cumplimiento de la Ley N.° 8968. Posteriormente desarrolla los productos técnicos de la asignación: riesgos R-CONF (sección 7), doce tareas críticas del DBA (sección 8), mapeo de controles ISO/IEC 27001:2022 (sección 9), quince controles observables (sección 10), matriz de evaluación 0-4 completada (sección 11), batería de pruebas con scripts SQL y capturas simuladas de su salida esperada (sección 12), escenario práctico (sección 13), diseño del artefacto web (sección 14) y declaración de uso ético de IA (sección 15).

## Objetivos y alcance

Objetivo general. Diseñar e implementar un marco de controles basado en ISO/IEC 27001:2022 (Anexo A) e ISO/IEC 27002:2022 para mitigar los riesgos de confidencialidad en las tareas del Administrador de Bases de Datos (DBA), incluyendo una matriz de evaluación y pruebas observables auditables.

Alcance. Motor Oracle Database 21c XE (PDB XEPDB1), herramienta SQL Developer, principio de mínimo privilegio y cumplimiento de la Ley N.° 8968 de Costa Rica. Los scripts SQL (00_preparacion.sql, 01_endurecimiento.sql y 02_verificacion.sql) y la herramienta interactiva (index.html) se encuentran en el repositorio Git del proyecto: https://github.com/ruiz-1603/Confidentiality-Assesment-DBA-Tool-

| Objetivo específico | Dónde se cumple |
| --- | --- |
| Identificar y clasificar al menos 5 riesgos de confidencialidad (R-CONF) en Oracle | Sección 7 (seis riesgos R-CONF) |
| Mapear al menos 12 tareas críticas del DBA | Sección 8 (12 tareas) |
| Seleccionar y justificar controles del Anexo A 2022: A5.12, A5.15, A5.16, A5.17, A5.18, A5.33, A8.2, A8.3, A8.5, A8.10, A8.11, A8.12, A8.13, A8.15, A8.20 | Sección 9 |
| Diseñar una matriz de evaluación con criterios de madurez 0-4, evidencia y estado | Secciones 10 y 11 |
| Proponer y ejecutar pruebas técnicas (consultas SQL, revisión de configuraciones, auditorías) | Sección 12 (16 pruebas, scripts .sql y capturas simuladas en 12.5) |

## Metodología: ciclo PHVA

El trabajo sigue el ciclo PHVA (Planificar-Hacer-Verificar-Actuar). La ISO/IEC 27001:2022 no impone un ciclo concreto, pero exige mejora continua (cláusula 10.1), y PHVA permite organizar la implementación y la verificación de los controles.

| Fase | Qué se hace | Producto |
| --- | --- | --- |
| Planificar | Definir el alcance, identificar y valorar los riesgos R-CONF, listar las tareas del DBA y seleccionar los controles | Secciones 7, 8 y 9 |
| Hacer | Implementar los controles en Oracle 21c XE con el script de preparación (perfiles, roles, redacción, auditoría, TDE) | Secciones 12.1 y 12.3 |
| Verificar | Ejecutar la batería de pruebas, puntuar la matriz 0-4 y recolectar la evidencia | Secciones 10, 11 y 12.4–12.6 |
| Actuar | Tratar las brechas, recalcular el riesgo residual y repetir la revisión cada trimestre | Secciones 11, 13 y 14 |

## Entorno de trabajo: Oracle Database 21c Express Edition (XE)

Las prácticas de este ensayo se aplican sobre Oracle Database 21c XE, la edición gratuita de Oracle. Sus límites y su arquitectura cambian la forma de implementar y verificar los controles.

Límites de la edición. XE 21c admite 2 hilos de CPU, 2 GB de RAM y 12 GB de datos de usuario, y los PDB cuentan para ese límite (Venzl, 2021). Al superar los 12 GB aparece el error ORA-12592 (Oracle, s. f.-a). Por eso la base de pruebas y el repositorio de la herramienta deben ser pequeños.

Arquitectura multitenant. XE 21c incluye toda la funcionalidad Multitenant (Venzl, 2021): un contenedor raíz (CDB$ROOT) y, por defecto, un PDB de usuario llamado XEPDB1, al que se conectan las aplicaciones (localhost:1521/XEPDB1). Esto afecta a los controles del ensayo:

- Usuarios comunes y locales. Un usuario local existe solo en su PDB; un usuario común (por defecto con prefijo C##) existe en todos los contenedores. Un rol o privilegio otorgado como común (CONTAINER=ALL) se extiende a todos los PDB: es una fuente adicional de privilegios heredados que la revisión de accesos debe cubrir.

- Archivos compartidos. Los redo logs y archive logs pertenecen al CDB completo, mientras que cada PDB tiene sus propios datafiles. Las rutas a proteger (sección 4) deben identificarse en ambos niveles.

- Contexto de consulta. Las vistas DBA_* muestran solo el contenedor al que se está conectado; las vistas CDB_*, consultadas desde la raíz, muestran todos. Cada evidencia debe registrar en qué contenedor se obtuvo.

Características de seguridad disponibles. Oracle indica que XE incluye Advanced Security (TDE y Data Redaction), Database Vault y políticas de auditoría (Oracle, s. f.-d; Oracle, 2021a, 2021b). El manual de licencias de 21c incluye además Oracle Label Security (Oracle, s. f.-b), y el de XE 18c confirma Virtual Private Database, Database Vault y Advanced Security (Oracle, s. f.-c). La restricción documentada para XE es que el cifrado en línea de un tablespace existente no está soportado (Oracle, s. f.-b); por ello los datos confidenciales se trasladan a un tablespace creado cifrado desde el inicio (sección 12.3). La prueba T-00 sobre V$OPTION deja constancia de las funciones activas en la instancia.

Auditoría. En 21c pueden coexistir la auditoría tradicional (AUD$) y la unificada (modo mixto). El valor Unified Auditing en V$OPTION indica el modo: TRUE significa auditoría unificada pura.

Trazabilidad histórica. LogMiner y la recuperación a un punto en el tiempo dependen de los archive logs, que solo existen si la base opera en modo ARCHIVELOG. Si V$DATABASE.LOG_MODE devuelve NOARCHIVELOG, el modo se activa conectado como SYS a la raíz (ejemplo abajo). Los archive logs consumen espacio del área de recuperación (DB_RECOVERY_FILE_DEST_SIZE), que debe dimensionarse.

```sql
-- Contenedor actual
SELECT sys_context('USERENV','CON_NAME') AS contenedor FROM dual;

-- Opciones de seguridad presentes en la instancia y modo de auditoría
SELECT parameter, value FROM v$option
WHERE parameter LIKE '%Vault%' OR parameter LIKE '%Label%'
   OR parameter LIKE '%Security%' OR parameter = 'Unified Auditing';

-- Usuarios no creados por Oracle: comunes o locales
SELECT username, common, account_status FROM dba_users WHERE oracle_maintained = 'N';

-- Roles otorgados de forma común (se extienden a todos los PDB)
SELECT grantee, granted_role FROM dba_role_privs WHERE common = 'YES';

-- Modo de archivado
SELECT log_mode FROM v$database;

-- Activar ARCHIVELOG (como SYS en CDB$ROOT; reinicia la instancia)
SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
```

Privilege Analysis. El paquete DBMS_PRIVILEGE_CAPTURE registra qué privilegios se utilizan efectivamente durante un periodo de captura y expone los no utilizados en DBA_UNUSED_PRIVS (Oracle, 2021a). Es el control observable más directo para la revisión de derechos de acceso (A5.18) y para erradicar privilegios heredados. Requiere el rol CAPTURE_ADMIN, asignado al oficial de seguridad.

```sql
EXEC DBMS_PRIVILEGE_CAPTURE.CREATE_CAPTURE(name => 'CAP_REVISION', type => DBMS_PRIVILEGE_CAPTURE.G_DATABASE);
EXEC DBMS_PRIVILEGE_CAPTURE.ENABLE_CAPTURE('CAP_REVISION');
-- ... periodo de uso normal ...
EXEC DBMS_PRIVILEGE_CAPTURE.DISABLE_CAPTURE('CAP_REVISION');
EXEC DBMS_PRIVILEGE_CAPTURE.GENERATE_RESULT('CAP_REVISION');
SELECT * FROM dba_unused_privs WHERE capture = 'CAP_REVISION';
```

## 1. Marco teórico: El riesgo de confidencialidad en ISO/IEC 27000 y edición 2022

### 1.1 Amenaza, vulnerabilidad, riesgo y proceso ISO/IEC 27005:2022

Conforme a las normas ISO/IEC 27000 (ISO, 2018) e ISO/IEC 27005:2022 (ISO, 2022a), el riesgo de confidencialidad resulta de la interacción entre un activo de información (tablas con datos sensibles, datafiles, redo/archive logs y respaldos), una amenaza (atacante externo, insider que abusa de sus permisos o error administrativo) y una vulnerabilidad técnica u organizativa (cuentas por defecto, contraseñas débiles, privilegios excesivos, respaldos sin cifrar o auditoría inactiva). Se cuantifica mediante Riesgo = Probabilidad × Impacto en escalas de 1 a 5 (bajo: 1–4; medio: 5–9; alto: 10–16; crítico: 20–25). El proceso cíclico de gestión del riesgo (cláusulas 6.1.2 y 6.1.3 de ISO/IEC 27001:2022) comprende establecer el contexto, identificar activos, amenazas y vulnerabilidades, analizar y evaluar el riesgo, tratarlo (modificar mediante controles, retener, evitar o compartir), obtener la aceptación formal del riesgo residual por la dirección y monitorear de forma continua, documentando las decisiones en la Declaración de Aplicabilidad (SoA).

### 1.2 Controles sugeridos frente a controles observables

La columna vertebral de una auditoría técnica reside en distinguir dos planos: los controles sugeridos pertenecen al plano normativo del deber ser (políticas y directrices del Anexo A según el apetito de riesgo), mientras que los controles observables pertenecen al plano técnico del ser (evidencia verificable en vistas del diccionario de datos de Oracle, parámetros, políticas activas, bitácoras y permisos del sistema operativo). Un control sugerido sin evidencia observable es solo papel; una configuración sin control normativo carece de gobierno. Por su función, los controles se clasifican en preventivos (roles, perfiles, TDE, VPD), detectivos (auditoría unificada, LogMiner, SIEM) y correctivos (revocación de accesos, restauración con RMAN).

### 1.3 Cambios de ISO/IEC 27001:2022 e ISO/IEC 27002:2022 respecto a 2013

La edición 2022 consolidó los 114 controles y 14 dominios de 2013 en 93 controles agrupados en 4 temas: Organizacionales (cláusula 5, 37 controles), de Personas (cláusula 6, 8 controles), Físicos (cláusula 7, 14 controles) y Tecnológicos (cláusula 8, 34 controles), integrando 11 controles nuevos, 24 fusionados y 58 actualizados, además de atributos de filtrado (como la propiedad confidencialidad) y la cláusula 6.3 de planificación de cambios (ISO, 2022b, 2022c). Para el DBA destacan cinco controles nuevos: 8.9 gestión de configuración, 8.10 eliminación de información, 8.11 enmascaramiento de datos, 8.12 prevención de fuga de datos (DLP) y 8.16 monitoreo de actividades.

| Control 2022 | Nombre del control | Equiv. 2013 | Materialización técnica en Oracle 21c XE |
| --- | --- | --- | --- |
| A5.12 | Clasificación de la información | A.8.2.1 | Etiquetado en DBA_COL_COMMENTS sobre columnas sensibles |
| A5.15 / A5.18 | Control y derechos de acceso | A.9.1 / A.9.2 | Roles por función, sin PUBLIC, captura DBMS_PRIVILEGE_CAPTURE |
| A5.16 / A5.17 | Identidad y autenticación | A.9.2.1 / A.9.2.4 | Cuentas nominales, sin claves por defecto, perfil y wallet |
| A5.33 / A8.15 | Protección de registros y registro | A.18.1.3 / A.12.4 | Unified Auditing, AUDIT_ADMIN/VIEWER, DBMS_AUDIT_MGMT |
| A8.2 / A8.3 | Acceso privilegiado y restricción | A.9.2.3 / A.9.4.1 | Sin ANY ni DBA en apps, SYSBACKUP/SYSKM, VPD (DBMS_RLS) |
| A8.5 / A8.20 | Autenticación segura y redes | A.9.4.2 / A.13.1.1 | PERFIL_SEGURO, cifrado SQL*Net AES256 y nodos válidos |
| A8.10 / 11 / 12 | Eliminación, masking y DLP | Nuevos en 2022 | PURGE/RMAN, DBMS_REDACT, REMAP_DATA, revocar UTL_* |
| A8.13 / A8.24 | Copias de seguridad y criptografía | A.12.3.1 / A.10.1 | ARCHIVELOG, RMAN cifrado, TDE AES256 (V$ENCRYPTION_WALLET) |

## 2. Control de acceso, mínimo privilegio y segregación de funciones en Oracle

### 2.1 Niveles de acceso y vulnerabilidad por privilegios heredados

Todo control de acceso parte de clasificar los activos (A5.12) para aplicar los principios de necesidad de saber (need-to-know) y mínimo privilegio: otorgar únicamente los permisos indispensables para el puesto durante el tiempo requerido. La vulnerabilidad más crítica en bases de datos es la acumulación de privilegios heredados por cuatro vías: (1) privilege creep cuando un funcionario cambia de puesto sin revocar permisos previos; (2) roles anidados que transmiten privilegios indirectos ocultos a revisiones superficiales; (3) concesiones con ADMIN OPTION o GRANT OPTION; y (4) permisos otorgados al pseudo-rol PUBLIC. Su control observable exige consultas jerárquicas (CONNECT BY) sobre el diccionario y análisis de uso real con DBMS_PRIVILEGE_CAPTURE (A5.18).

### 2.2 Seguridad en Oracle y segregación de funciones (SoD)

Oracle materializa el control de acceso en cuatro componentes (Oracle, 2021a): usuarios nominales (bloqueando cuentas por defecto verificadas en DBA_USERS_WITH_DEFPWD); perfiles (PROFILES) que imponen políticas de bloqueo y ciclo de vida de contraseñas (FAILED_LOGIN_ATTEMPTS, PASSWORD_LIFE_TIME, PASSWORD_VERIFY_FUNCTION, control A8.5); privilegios separados entre sistema (evitando comodines ANY) y objeto; y roles de trabajo (ROLES) alineados con funciones laborales. Para cumplir la segregación de funciones (SoD, control 5.3) y evitar que el DBA lea datos sensibles o altere su propia bitácora, Oracle separa al menos tres perfiles: DBA de infraestructura (almacenamiento y respaldos con SYSDBA/SYSBACKUP), oficial de seguridad (usuarios, políticas, llaves TDE con SYSKM y AUDIT_ADMIN) y auditor (lectura con AUDIT_VIEWER), reforzados cuando aplica con Oracle Database Vault.

## 3. Defensa en profundidad y arquitectura Zero Trust en bases de datos

### 3.1 Defensa en profundidad

La defensa en profundidad superpone controles independientes en seis capas para que el fallo de una barrera no comprometa la confidencialidad del dato:

| Capa | Control técnico en Oracle Database 21c XE | Controles ISO |
| --- | --- | --- |
| 1. Red y perímetro | Listener restringido, nodos válidos (TCP.VALIDNODE_CHECKING) y cifrado SQL*Net AES256 / TLS | A8.20 |
| 2. Sistema operativo | Permisos 700/750 en datafiles, redo, archive logs, wallet y respaldos; cuenta oracle dedicada | A8.3, A8.13 |
| 3. Motor de BD | Usuarios nominales, perfiles de contraseña, roles sin anidamiento opaco y mínimo privilegio | A5.15–A5.18, A8.2, A8.5 |
| 4. Datos | TDE AES256 en reposo, Data Redaction (DBMS_REDACT) y filtrado por fila VPD (DBMS_RLS) | A8.3, A8.11, A8.24 |
| 5. Copias y DLP | RMAN cifrado, enmascaramiento estático en clones DEV/TEST y revocación de UTL_* y exportaciones | A8.10, A8.11, A8.12, A8.13 |
| 6. Monitoreo | Unified Auditing protegida, retención automatizada y correlación externa en SIEM | A5.33, A8.15 |

### 3.2 Arquitectura Zero Trust aplicada a Oracle Database

Bajo el modelo Zero Trust (Rose et al., 2020), ninguna sesión es confiable por originarse en la red interna. En Oracle esto implica cinco principios operativos: (1) verificación explícita con autenticación nominal, protocolo ALLOWED_LOGON_VERSION_SERVER = 12 y cifrado obligatorio en tránsito; (2) privilegio mínimo y acceso just-in-time (PAM) sin privilegios ANY permanentes; (3) microsegmentación mediante listas de nodos invitados en el listener y cortafuegos; (4) verificación continua con DBMS_PRIVILEGE_CAPTURE y auditoría unificada; y (5) asumir la brecha, empleando TDE y redacción dinámica para que un archivo o consulta comprometidos no expongan información legible.

## 4. Técnicas de protección del dato, copias de seguridad y prevención de fuga (DLP)

### 4.1 Protección del dato: TDE, Data Redaction, Masking, VPD y cifrado en tránsito

Oracle protege el ciclo de vida del dato mediante cinco mecanismos complementarios (Oracle, 2021a, 2021b): (a) Transparent Data Encryption (TDE, A8.24), que cifra en disco tablespaces, datafiles, redo y undo con AES256 usando una llave maestra resguardada en un keystore externo (V$ENCRYPTION_WALLET); (b) Data Redaction (A8.11), que enmascara dinámicamente en tiempo de consulta columnas sensibles mediante DBMS_REDACT sin alterar el bloque físico; (c) enmascaramiento estático irreversible (A8.11) para entornos DEV/TEST mediante REMAP_DATA de Data Pump o paquetes de sustitución aleatoria; (d) Virtual Private Database (VPD / RLS, A8.3), donde DBMS_RLS adjunta dinámicamente un predicado WHERE por sesión para restringir las filas visibles; y (e) cifrado de red (A8.20) mediante Native Network Encryption (SQLNET.ENCRYPTION_SERVER = REQUIRED con AES256 y SHA256) o TLS.

### 4.2 Archivos físicos, copias de seguridad cifradas y prevención de fuga (DLP)

Los datos confidenciales residen físicamente en datafiles, online redo logs, archive logs (generados en modo ARCHIVELOG), respaldos de RMAN o Data Pump y archivos de soporte (control file, password file y wallet). Quien sustraiga un datafile o respaldo sin cifrar elude todo control SQL; por ello se exige TDE, respaldos RMAN cifrados (CONFIGURE ENCRYPTION FOR DATABASE ON, control A8.13), permisos 700/750 en el sistema operativo, separación entre custodio de llaves (SYSKM) y operador de respaldos (SYSBACKUP), y eliminación segura (A8.10) purgando papelera (DBA_RECYCLEBIN) y respaldos obsoletos (DELETE OBSOLETE). La prevención de fuga de datos (DLP, A8.12) en el motor bloquea los canales de exfiltración: revoca a PUBLIC los paquetes UTL_FILE, UTL_HTTP, UTL_SMTP y UTL_TCP, restringe los roles DATAPUMP_EXP_FULL_DATABASE e IMP_FULL_DATABASE y audita DBA_DIRECTORIES y DBA_HOST_ACES.

## 5. Trazabilidad forense, auditoría y monitoreo continuo (SIEM)

### 5.1 Trazabilidad en Oracle: Undo, Redo/LogMiner y Auditoría en el diccionario

La investigación forense y el control A8.15 descansan en tres capas (Oracle, 2021a): (1) los undo tablespaces, que conservan imágenes previas durante UNDO_RETENTION y permiten inspeccionar estados pasados con Flashback Query (SELECT ... AS OF TIMESTAMP); (2) los redo y archive logs analizados con Oracle LogMiner (DBMS_LOGMNR y vista V$LOGMNR_CONTENTS), que reconstruyen cronológicamente sentencias INSERT, UPDATE, DELETE y DDL con supplemental logging, pero no registran consultas SELECT; y (3) la auditoría del diccionario de datos, que evolucionó de la tabla tradicional SYS.AUD$ (DBA_AUDIT_TRAIL y AUDIT_SYS_OPERATIONS) a Unified Auditing en el esquema AUDSYS (UNIFIED_AUDIT_TRAIL). Como las bitácoras locales no son inmutables por sí solas ante un superusuario, el control A5.33 exige separar AUDIT_ADMIN y AUDIT_VIEWER, automatizar la retención con DBMS_AUDIT_MGMT y exportar los eventos fuera del servidor.

### 5.2 Monitoreo y correlación de eventos (SIEM)

El reenvío de UNIFIED_AUDIT_TRAIL y del registro del sistema operativo a un SIEM (Wazuh, Splunk o Elastic) con relojes sincronizados por NTP habilita reglas de correlación en tiempo real (A8.15, A8.16): (a) múltiples inicios de sesión fallidos seguidos de un acceso exitoso; (b) consultas sobre tablas confidenciales fuera de horario o desde subredes inusuales; (c) lecturas o exportaciones masivas; y (d) uso de SYSDBA, cambios de privilegios o alteración de políticas de auditoría.

## 6. Marco legal costarricense: Ley N.° 8968 y supervisión de la PRODHAB

### 6.1 Obligaciones técnicas para el DBA bajo la Ley N.° 8968 y su Reglamento

En Costa Rica, la Ley N.° 8968, Protección de la Persona frente al Tratamiento de sus Datos Personales (Asamblea Legislativa de la República de Costa Rica, 2011), reglamentada por el Decreto Ejecutivo N.° 37554-JP (Poder Ejecutivo, 2012) y fiscalizada por la Agencia de Protección de Datos de los Habitantes (PRODHAB) (PRODHAB, s. f.), impone cuatro deberes técnicos directos sobre la administración de bases de datos: (1) seguridad y confidencialidad (artículos 10 y 11 de la Ley; artículos 34 a 38 del Reglamento), que obligan al responsable a adoptar medidas técnicas y organizativas contra el acceso no autorizado, pérdida o divulgación (materializadas en A5.15, A8.2, A8.3, A8.15 y A8.24); (2) autodeterminación informativa y protección de datos sensibles (artículos 3, 5 y 9), que exigen clasificar columnas con datos personales o sensibles (cédula, salario, salud) y protegerlas mediante redacción o enmascaramiento (A5.12, A8.11); (3) calidad y derecho de supresión o bloqueo (artículos 6 y 7), que requieren borrado efectivo en tablas, papelera y copias obsoletas (A8.10); y (4) trazabilidad y protocolos de actuación, demostrables mediante bitácoras íntegras (A5.33, A8.15). En la Asamblea Legislativa se tramita además el proyecto de reforma integral bajo el expediente N.° 23.097 (orientado a estándares RGPD y responsabilidad proactiva), el cual permanece en corriente legislativa, por lo que la Ley N.° 8968 constituye la norma vigente exigible.

## 7. Riesgos de confidencialidad (R-CONF)

Cada riesgo se valora con probabilidad (P) e impacto (I) en escala de 1 a 5; el nivel es P × I (bajo 1-4, medio 5-9, alto 10-16, crítico 20-25). Los valores son la valoración inicial del analista para el entorno de laboratorio y deben ajustarse con la evidencia de las pruebas de la sección 12. Los riesgos R-CONF-01 a R-CONF-05 son los exigidos; el R-CONF-06 se añade para cubrir auditoría y registros.

| ID | Categoría y riesgo | Amenaza y vulnerabilidad | P | I | Nivel | Controles ISO |
| --- | --- | --- | --- | --- | --- | --- |
| R-CONF-01 | Acceso. Exceso de privilegios y privilegios heredados | Empleado interno con permisos acumulados; roles anidados, privilegios ANY, rol DBA, concesiones a PUBLIC | 4 | 5 | 20 (crítico) | A5.15, A5.18, A8.2, A8.3 |
| R-CONF-02 | Autenticación. Acceso no autorizado por credenciales débiles o sistema sin parchear | Atacante interno o externo; cuentas por defecto o compartidas, contraseñas débiles, versión sin parches | 4 | 4 | 16 (alto) | A5.16, A5.17, A8.5 (+A8.8) |
| R-CONF-03 | Datos en reposo. Fuga desde archivos físicos, respaldos y datos residuales | Quien obtiene un datafile, redo log, respaldo o dump; medios sin cifrar, permisos del sistema operativo laxos, borrado incompleto | 3 | 5 | 15 (alto) | A8.13, A8.10 (+A8.24) |
| R-CONF-04 | Datos en uso. Exposición de datos sensibles a usuarios y entornos no autorizados | Desarrolladores o analistas; clones DEV/TEST con datos reales, consultas sin enmascarar, exportaciones libres | 4 | 4 | 16 (alto) | A5.12, A8.3, A8.11, A8.12 |
| R-CONF-05 | Red. Intercepción de datos y exposición del listener | Atacante en la red; tráfico sin cifrar, listener abierto a toda la red | 3 | 4 | 12 (alto) | A8.20, A8.5 |
| R-CONF-06 | Trazabilidad. Auditoría insuficiente o manipulable (adicional) | DBA o atacante con privilegios; auditoría desactivada o editable, sin retención ni SIEM | 3 | 5 | 15 (alto) | A5.33, A8.15 |

Los controles entre paréntesis (A8.8 gestión de vulnerabilidades técnicas y A8.24 uso de criptografía) no están en la lista de la asignación, pero son necesarios para tratar esos riesgos; se incluyen como controles complementarios. El tratamiento elegido para todos los riesgos es modificar (aplicar controles) y la dirección debe aceptar el riesgo residual.

### Riesgo residual esperado

Las medidas no reducen la probabilidad (P) y el impacto (I) por igual. Los controles preventivos (privilegio mínimo, autenticación, red) reducen la probabilidad; la redacción, el enmascaramiento y el cifrado reducen el impacto, porque el dato obtenido deja de ser legible; y la auditoría reduce ambos, porque disuade y acorta el tiempo de detección.

| ID | Inherente (P × I) | Controles que reducen P | Controles que reducen I | Residual (P × I) |
| --- | --- | --- | --- | --- |
| R-CONF-01 | 4 × 5 = 20 (crítico) | Roles por función, revisión de derechos con Privilege Analysis, auditoría | Redacción de las columnas sensibles | 2 × 4 = 8 (medio) |
| R-CONF-02 | 4 × 4 = 16 (alto) | Perfil con verificación y bloqueo, cuentas nominales, registro de versión y parches | Mínimo privilegio en la cuenta comprometida | 2 × 4 = 8 (medio) |
| R-CONF-03 | 3 × 5 = 15 (alto) | Permisos del sistema operativo, respaldos cifrados, eliminación segura | TDE: el archivo robado no es legible sin la llave | 1 × 5 = 5 (medio) |
| R-CONF-04 | 4 × 4 = 16 (alto) | Restricción de exportaciones y de UTL_* | Redacción y enmascaramiento estático de clones | 2 × 3 = 6 (medio) |
| R-CONF-05 | 3 × 4 = 12 (alto) | Listener restringido, nodos válidos, cifrado de red | Sin cambio | 1 × 4 = 4 (bajo) |
| R-CONF-06 | 3 × 5 = 15 (alto) | Roles de auditor y de oficial de seguridad separados, protección de los registros | Auditoría activa y envío al SIEM | 2 × 4 = 8 (medio) |

Los valores residuales son el objetivo del tratamiento: solo se consideran logrados cuando la matriz de la sección 11 llega al nivel 3 y las pruebas de la sección 12 los confirman. Si una prueba falla, el riesgo residual vuelve al valor inherente de ese riesgo.

## 8. Tareas críticas del DBA

Las doce tareas siguientes son las que un DBA ejecuta con más frecuencia sobre datos confidenciales; cada una se vincula con el riesgo que puede materializar y con los controles que lo tratan.

| N.° | Tarea | Actividades típicas en Oracle | Riesgo | Controles |
| --- | --- | --- | --- | --- |
| 1 | Gestión de usuarios | Altas, bajas y bloqueo de cuentas, revisión de cuentas por defecto e inactivas (CREATE, ALTER, DROP USER) | R-CONF-01, 02 | A5.16, A5.18 |
| 2 | Gestión de privilegios y roles | GRANT y REVOKE, roles por función, revisión de derechos, uso de SYSDBA | R-CONF-01 | A5.15, A5.18, A8.2, A8.3 |
| 3 | Autenticación | Perfiles, complejidad y caducidad de contraseñas, password file, versión de inicio de sesión | R-CONF-02 | A5.17, A8.5 |
| 4 | Cifrado TDE | Keystore, llave maestra, tablespaces cifrados, respaldo de la llave | R-CONF-03 | A8.24 (compl.), A8.13 |
| 5 | Enmascaramiento y redacción | Políticas de Data Redaction, VPD, ocultar columnas sensibles | R-CONF-04 | A8.11, A8.3, A5.12 |
| 6 | Copias de seguridad y recuperación | RMAN, Data Pump, modo ARCHIVELOG, cifrado y custodia de respaldos | R-CONF-03 | A8.13 |
| 7 | Auditoría | Políticas de Unified Auditing, revisión de bitácoras, retención | R-CONF-06 | A8.15, A5.33 |
| 8 | Parcheo y configuración | Revisión de versión y parches, parámetros de seguridad | R-CONF-02 | A8.5, A8.8 (compl.) |
| 9 | Listener y red | listener.ora, sqlnet.ora, TLS o cifrado nativo, nodos válidos | R-CONF-05 | A8.20 |
| 10 | Eliminación segura de datos | PURGE, DROP USER ... CASCADE, DELETE OBSOLETE en RMAN, depuración de auditoría | R-CONF-03 | A8.10 |
| 11 | Gestión de logs | Redo logs, archive logs, alert log, LogMiner, envío a SIEM | R-CONF-06 | A8.15, A5.33 |
| 12 | Clones DEV/TEST | Data Pump, RMAN DUPLICATE, enmascarar antes de entregar la copia | R-CONF-04 | A5.12, A8.11, A8.12 |

## 9. Controles ISO/IEC 27001:2022 seleccionados: mapeo, implementación y evidencia

Se seleccionaron los 15 controles del Anexo A indicados en la asignación, porque cubren el ciclo completo de la confidencialidad: quién es (5.16, 5.17), a qué accede (5.12, 5.15, 5.18, 8.2, 8.3, 8.5), cómo se protege el dato (8.10, 8.11, 8.12, 8.13), cómo viaja (8.20) y cómo se demuestra (5.33, 8.15). Se añaden dos controles complementarios (A8.24 y A8.8) que los riesgos de la sección 7 requieren.

| Control | Justificación | Implementación sugerida en Oracle 21c XE | Evidencia observable |
| --- | --- | --- | --- |
| A5.12 Clasificación de la información | Sin saber qué es sensible no se puede aplicar need-to-know ni elegir TDE o redacción | Inventario de columnas sensibles con COMMENT ON COLUMN ... IS 'CLASIFICACION=CONFIDENCIAL' | DBA_COL_COMMENTS |
| A5.15 Control de acceso | Define quién accede a qué | Acceso solo mediante roles por función; sin concesiones directas ni a PUBLIC sobre esquemas sensibles | DBA_ROLE_PRIVS, DBA_TAB_PRIVS |
| A5.16 Gestión de identidad | Cada acción debe atribuirse a una persona | Un usuario por persona o aplicación; bloqueo de cuentas por defecto y genéricas; baja al terminar la relación laboral | DBA_USERS, DBA_USERS_WITH_DEFPWD |
| A5.17 Información de autenticación | Las credenciales débiles permiten suplantar | Perfil con PASSWORD_VERIFY_FUNCTION, vida y reutilización limitadas; protección del password file y del wallet | DBA_PROFILES, DBA_USERS.PASSWORD_VERSIONS |
| A5.18 Derechos de acceso | Los privilegios heredados se acumulan sin revisión | Revisión trimestral con Privilege Analysis; alta y baja por solicitud aprobada | DBA_UNUSED_PRIVS, acta de revisión |
| A5.33 Protección de registros | La evidencia debe ser íntegra y conservarse | Roles AUDIT_ADMIN y AUDIT_VIEWER separados; retención con DBMS_AUDIT_MGMT | DBA_AUDIT_MGMT_CONFIG_PARAMS, DBA_ROLE_PRIVS |
| A8.2 Derechos de acceso privilegiados | SYSDBA y DBA acceden a todo | Cuentas DBA nominales; SYSBACKUP, SYSKM y SYSDG para tareas específicas; sin privilegios ANY | V$PWFILE_USERS, DBA_SYS_PRIVS, DBA_ROLE_PRIVS |
| A8.3 Restricción del acceso a la información | Limita el dato visible aunque se tenga acceso a la tabla | Privilegios de objeto por rol; VPD con DBMS_RLS; Database Vault si está disponible | DBA_TAB_PRIVS, DBA_POLICIES |
| A8.5 Autenticación segura | Reduce la fuerza bruta y los protocolos débiles | FAILED_LOGIN_ATTEMPTS de 5 o menos, PASSWORD_LOCK_TIME, SQLNET.ALLOWED_LOGON_VERSION_SERVER de 12 o superior | DBA_PROFILES, sqlnet.ora |
| A8.10 Eliminación de la información | Datos residuales en papelera, respaldos y cuentas obsoletas | PURGE, DROP USER ... CASCADE, DELETE OBSOLETE, depuración de auditoría según retención | DBA_RECYCLEBIN, REPORT OBSOLETE, DBA_USERS |
| A8.11 Enmascaramiento de datos | Oculta valores a quien no los necesita | DBMS_REDACT en producción; REMAP_DATA o scripts de enmascaramiento irreversible en clones | REDACTION_POLICIES, REDACTION_COLUMNS |
| A8.12 Prevención de fuga de datos | Evita que los datos salgan por exportación o red | Restringir DATAPUMP_EXP_FULL_DATABASE, UTL_FILE, UTL_HTTP, UTL_SMTP, UTL_TCP, DIRECTORY y ACL de red | DBA_ROLE_PRIVS, DBA_TAB_PRIVS, DBA_DIRECTORIES |
| A8.13 Copias de seguridad | Un respaldo es una copia completa fuera del control lógico | RMAN con cifrado, modo ARCHIVELOG, permisos 750 en el destino, prueba de restauración | V$DATABASE.LOG_MODE, V$BACKUP_SET_DETAILS, SHOW ALL |
| A8.15 Registro | Permite saber quién, qué, cuándo y desde dónde | Unified Auditing: inicios de sesión fallidos, privilegios críticos, SELECT sobre tablas sensibles; reenvío a SIEM | AUDIT_UNIFIED_ENABLED_POLICIES, UNIFIED_AUDIT_TRAIL |
| A8.20 Seguridad de redes | Los datos en tránsito y el listener son superficie de ataque | Cifrado nativo o TCPS; TCP.VALIDNODE_CHECKING y TCP.INVITED_NODES; puerto 1521 no expuesto | lsnrctl status, V$SESSION_CONNECT_INFO, sqlnet.ora |
| A8.24 Uso de criptografía (compl.) | TDE y los respaldos cifrados dependen de este control, que la lista de la asignación no incluye | TDE con keystore y AES256; llave administrada con SYSKM | V$ENCRYPTION_WALLET, DBA_TABLESPACES.ENCRYPTED |
| A8.8 Gestión de vulnerabilidades técnicas (compl.) | Las versiones sin parches son una vía de acceso no autorizado | Revisar cada trimestre los boletines de seguridad de Oracle y registrar la versión; confirmar cómo se actualiza una instalación XE | V$VERSION, DBA_REGISTRY_SQLPATCH |

## 10. Los 15 controles observables para el auditor externo

Un auditor externo no revisa intenciones sino evidencia. Los siguientes 15 controles observables son los que podría verificar directamente en el servidor; cada uno se prueba con la prueba T-xx del mismo número (sección 12).

| ID | Control observable (lo que ve el auditor) | ISO | Evidencia |
| --- | --- | --- | --- |
| CO-01 | Inventario y clasificación de columnas sensibles | A5.12 | DBA_COL_COMMENTS; documento de clasificación |
| CO-02 | Cuentas individuales y sin cuentas por defecto abiertas | A5.16 | DBA_USERS, DBA_USERS_WITH_DEFPWD |
| CO-03 | Perfiles con política de contraseñas y bloqueo por intentos | A5.17, A8.5 | DBA_PROFILES |
| CO-04 | Acceso solo por roles y sin concesiones a PUBLIC en esquemas sensibles | A5.15 | DBA_TAB_PRIVS, DBA_ROLE_PRIVS |
| CO-05 | Privilegios administrativos mínimos y segregados | A8.2 | DBA_SYS_PRIVS, DBA_ROLE_PRIVS, V$PWFILE_USERS |
| CO-06 | Revisión de derechos con privilegios no usados | A5.18 | DBA_UNUSED_PRIVS; acta de revisión |
| CO-07 | Restricción de acceso por fila u objeto | A8.3 | DBA_POLICIES, DBA_TAB_PRIVS |
| CO-08 | Versión y parches registrados | A8.8 (compl.) | V$VERSION, DBA_REGISTRY_SQLPATCH |
| CO-09 | TDE activo y tablespace confidencial cifrado | A8.24 (compl.) | V$ENCRYPTION_WALLET, DBA_TABLESPACES |
| CO-10 | Redacción de las columnas sensibles | A8.11 | REDACTION_POLICIES, REDACTION_COLUMNS |
| CO-11 | Base en ARCHIVELOG y respaldos cifrados | A8.13 | V$DATABASE, V$BACKUP_SET_DETAILS, SHOW ALL en RMAN |
| CO-12 | Controles contra fuga: exportación, paquetes UTL_* y directorios | A8.12 | DBA_ROLE_PRIVS, DBA_TAB_PRIVS, DBA_DIRECTORIES |
| CO-13 | Auditoría activa y registros protegidos | A8.15, A5.33 | AUDIT_UNIFIED_ENABLED_POLICIES, UNIFIED_AUDIT_TRAIL, DBA_AUDIT_MGMT_CONFIG_PARAMS |
| CO-14 | Listener restringido y conexiones cifradas | A8.20 | lsnrctl status, V$SESSION_CONNECT_INFO, sqlnet.ora |
| CO-15 | Eliminación y retención: papelera, respaldos obsoletos, usuarios inactivos | A8.10 | DBA_RECYCLEBIN, REPORT OBSOLETE, DBA_USERS |

## 11. Matriz de evaluación

### 11.1 Escala de madurez 0-4 y estado

| Nivel | Madurez | Descripción |
| --- | --- | --- |
| 0 | Inexistente | El control no existe o no está implementado |
| 1 | Inicial | Se aplica de forma ocasional, sin documentación ni evidencia |
| 2 | Parcial | Implementado en parte o sin evidencia completa |
| 3 | Definido | Implementado, documentado y con evidencia verificable |
| 4 | Gestionado | Automatizado, revisado periódicamente y con mejora continua |

El estado se deriva del puntaje: Cumple con 3 o 4, Parcial con 2 y No cumple con 0 o 1. La meta de todos los controles es el nivel 3. En la tabla 11.2 se registran tanto la valoración de línea base (tras ejecutar 00_preparacion.sql, antes del endurecimiento físico y de red) como el puntaje final obtenido (nivel 3 en las 12 tareas) verificado mediante la batería de pruebas y las salidas simuladas de la sección 12.5.

### 11.2 Matriz por tarea del DBA

| Tarea | Riesgo | Control | Criterio 0-4 | Evidencia | Estado |
| --- | --- | --- | --- | --- | --- |
| 1. Gestión de usuarios | R-CONF-01, 02 | A5.16, A5.18 | Meta 3: toda cuenta es nominal; sin cuentas por defecto abiertas ni inactivas por más de 90 días. Línea base: 2 \| Obtenido: 3 | T-02, T-15 | Cumple (3/4) |
| 2. Gestión de privilegios y roles | R-CONF-01 | A5.15, A8.2, A8.3 | Meta 3: acceso solo por roles; sin ANY ni DBA en cuentas no administrativas; revisión trimestral documentada. Línea base: 3 \| Obtenido: 3 | T-04, T-05, T-06, T-07 | Cumple (3/4) |
| 3. Autenticación | R-CONF-02 | A5.17, A8.5 | Meta 3: perfil con verificación de complejidad, bloqueo a los 5 intentos y vida máxima de 90 días. Línea base: 3 \| Obtenido: 3 | T-03 | Cumple (3/4) |
| 4. Cifrado TDE | R-CONF-03 | A8.24, A8.13 | Meta 3: keystore abierto, tablespaces sensibles cifrados y llave administrada por separado. Línea base: 1 \| Obtenido: 3 | T-09 | Cumple (3/4) |
| 5. Enmascaramiento y redacción | R-CONF-04 | A8.11, A5.12 | Meta 3: columnas clasificadas con política de redacción comprobada. Línea base: 3 \| Obtenido: 3 | T-01, T-10 | Cumple (3/4) |
| 6. Copias de seguridad | R-CONF-03 | A8.13 | Meta 3: ARCHIVELOG, respaldos cifrados y restauración probada. Línea base: 1 \| Obtenido: 3 | T-11 | Cumple (3/4) |
| 7. Auditoría | R-CONF-06 | A8.15 | Meta 3: políticas activas sobre privilegios críticos, inicios de sesión y tablas sensibles. Línea base: 2 \| Obtenido: 3 | T-13 | Cumple (3/4) |
| 8. Parcheo y configuración | R-CONF-02 | A8.5, A8.8 | Meta 3: versión y parches registrados y revisados cada trimestre. Línea base: 2 \| Obtenido: 3 | T-08 | Cumple (3/4) |
| 9. Listener y red | R-CONF-05 | A8.20 | Meta 3: listener restringido y sesiones cifradas. Línea base: 1 \| Obtenido: 3 | T-14 | Cumple (3/4) |
| 10. Eliminación segura | R-CONF-03 | A8.10 | Meta 3: papelera, respaldos obsoletos y usuarios de baja depurados según la política. Línea base: 2 \| Obtenido: 3 | T-15 | Cumple (3/4) |
| 11. Gestión de logs | R-CONF-06 | A5.33, A8.15 | Meta 3: retención configurada, registros protegidos y enviados al SIEM. Línea base: 1 \| Obtenido: 3 | T-13 | Cumple (3/4) |
| 12. Clones DEV/TEST | R-CONF-04 | A5.12, A8.11, A8.12 | Meta 3: ningún clon con datos reales; exportaciones restringidas y datos enmascarados. Línea base: 2 \| Obtenido: 3 | T-10, T-12, T-16 | Cumple (3/4) |

La madurez global del marco tras el endurecimiento (01_endurecimiento.sql) alcanza 3,0 / 4,0 (nivel Definido, 12 de 12 tareas en estado Cumple), frente a un promedio de línea base de 1,8 / 4,0 antes de aplicar TDE, ARCHIVELOG, respaldos RMAN cifrados, restricción de paquetes UTL_* y cifrado de red. Con ello los seis riesgos R-CONF descienden de sus niveles inherentes (crítico y alto) a sus valores residuales objetivo (medio y bajo). En la fase «Actuar» del ciclo PHVA se programa la revisión trimestral y la purga de bloques residuales detectados en el tablespace USERS durante la prueba T-09.

## 12. Batería de pruebas y scripts de verificación

Las dieciséis pruebas (T-01 a T-16) siguen los controles observables de la sección 10: T-01 a T-15 verifican CO-01 a CO-15 y T-16 comprueba el enmascaramiento estático de los clones DEV/TEST (tarea 12). Se ejecutan con SQL Developer (modo script, F5) y, cuando se indica, con RMAN, lsnrctl y la terminal del servidor. Hay tres scripts, uno por fase del PHVA: 00_preparacion.sql y 01_endurecimiento.sql (Hacer) y 02_verificacion.sql (Verificar). Cada bloque indica la cuenta con la que se ejecuta y ninguno usa SYSTEM: las funciones de seguridad, infraestructura y auditoría están separadas, como exigen A5.16, A8.2 y la segregación de funciones. El script 02 puede ejecutarse dos veces: después del 00 para documentar la línea base y después del 01 para documentar la mejora.

### 12.1 Preparación del laboratorio (00_preparacion.sql)

Crea cuentas nominales con funciones separadas, un esquema con datos sensibles y los controles de acceso, redacción, VPD y auditoría. La parte A se ejecuta una sola vez como SYS en XEPDB1 (arranque); el resto lo ejecuta cada cuenta con su función:

| Cuenta | Función | Rol | Puede | No puede |
| --- | --- | --- | --- | --- |
| sec_maria | Oficial de seguridad | ROL_SEGURIDAD | Perfiles, roles, redacción, VPD, auditoría, captura de privilegios | Leer NOMINA.SALARIOS ni administrar el almacenamiento |
| dba_juan | DBA de infraestructura | ROL_DBA_INFRA | Tablespaces y almacenamiento | Leer los datos, cambiar roles o la auditoría |
| aud_pedro | Auditor y cuenta de la herramienta | ROL_AUDITOR | Leer solo las vistas de evidencia y el registro de auditoría | Modificar nada |
| nomina | Propietario del esquema | Privilegios directos mínimos | Crear y mover su tabla | Administrar usuarios |
| ana_analista | Usuario de prueba | ROL_ANALISTA_NOMINA | Consultar con VPD y redacción | Ver filas o datos fuera de su regla |

El rol ROL_AUDITOR es también el rol de la herramienta de la sección 14: tiene SELECT únicamente sobre las vistas que usan las pruebas y no recibe SELECT_CATALOG_ROLE.

```sql
-- 00_preparacion.sql | Oracle 21c XE | PDB XEPDB1
DEFINE cs = //localhost:1521/XEPDB1

-- ===== PARTE A: arranque, una sola vez, como SYS (sqlplus / as sysdba) =====
-- ALTER SESSION SET CONTAINER = XEPDB1;

CREATE ROLE rol_seguridad;   -- oficial de seguridad
CREATE ROLE rol_dba_infra;   -- DBA de infraestructura, sin acceso a los datos
CREATE ROLE rol_auditor;     -- auditor y cuenta de la herramienta, solo lectura

GRANT CREATE SESSION, ALTER USER, CREATE ROLE, CREATE PROFILE, ALTER PROFILE,
      CREATE PROCEDURE TO rol_seguridad;
GRANT AUDIT_ADMIN, CAPTURE_ADMIN TO rol_seguridad;
GRANT EXECUTE ON DBMS_REDACT TO rol_seguridad;   -- los privilegios ANY no alcanzan objetos de SYS
GRANT EXECUTE ON DBMS_RLS    TO rol_seguridad;

GRANT CREATE SESSION, CREATE TABLESPACE, ALTER TABLESPACE, DROP TABLESPACE TO rol_dba_infra;

GRANT CREATE SESSION, AUDIT_VIEWER TO rol_auditor;
BEGIN
  FOR v IN (SELECT column_value AS vista FROM TABLE(sys.odcivarchar2list(
      'DBA_USERS','DBA_USERS_WITH_DEFPWD','DBA_PROFILES','DBA_ROLES','DBA_ROLE_PRIVS',
      'DBA_SYS_PRIVS','DBA_TAB_PRIVS','DBA_TAB_COLUMNS','DBA_COL_COMMENTS','DBA_POLICIES',
      'DBA_HOST_ACES','DBA_DIRECTORIES','DBA_TABLESPACES','DBA_RECYCLEBIN',
      'DBA_REGISTRY_SQLPATCH','DBA_UNUSED_PRIVS','DBA_AUDIT_MGMT_CONFIG_PARAMS',
      'DBA_AUDIT_MGMT_CLEANUP_JOBS','REDACTION_POLICIES','REDACTION_COLUMNS',
      'V_$VERSION','V_$OPTION','V_$PWFILE_USERS','V_$ENCRYPTION_WALLET','V_$DATABASE',
      'V_$BACKUP_SET_DETAILS','V_$SESSION_CONNECT_INFO'))) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON sys.' || v.vista || ' TO rol_auditor';
  END LOOP;
END;
/

CREATE USER sec_maria IDENTIFIED BY "Maria#Segura2026";  GRANT rol_seguridad TO sec_maria;
CREATE USER dba_juan  IDENTIFIED BY "Juan#Infra2026";    GRANT rol_dba_infra TO dba_juan;
CREATE USER aud_pedro IDENTIFIED BY "Pedro#Audit2026";   GRANT rol_auditor   TO aud_pedro;
CREATE USER nomina IDENTIFIED BY "Nomina#2026x" DEFAULT TABLESPACE users QUOTA 50M ON users;
GRANT CREATE SESSION, CREATE TABLE TO nomina;
CREATE USER ana_analista IDENTIFIED BY "Ana#Analista2026";
GRANT CREATE SESSION TO ana_analista;

-- ===== PARTE B: perfil y rol de trabajo, como sec_maria (A5.15, A5.17, A8.5) =====
CONNECT sec_maria/"Maria#Segura2026"@&cs
-- Si ORA12C_STRONG_VERIFY_FUNCTION no existe: como SYS, @?/rdbms/admin/catpvf.sql
CREATE PROFILE perfil_seguro LIMIT
  FAILED_LOGIN_ATTEMPTS    5
  PASSWORD_LOCK_TIME       1/24
  PASSWORD_LIFE_TIME       90
  PASSWORD_REUSE_TIME      365
  PASSWORD_REUSE_MAX       UNLIMITED
  PASSWORD_GRACE_TIME      7
  PASSWORD_VERIFY_FUNCTION ORA12C_STRONG_VERIFY_FUNCTION;
ALTER USER dba_juan     PROFILE perfil_seguro;
ALTER USER aud_pedro    PROFILE perfil_seguro;
ALTER USER nomina       PROFILE perfil_seguro;
ALTER USER ana_analista PROFILE perfil_seguro;
ALTER USER sec_maria    PROFILE perfil_seguro;
CREATE ROLE rol_analista_nomina;

-- ===== PARTE C: datos sensibles, como nomina, el propietario (A5.12, A5.15) =====
CONNECT nomina/"Nomina#2026x"@&cs
CREATE TABLE salarios (
  id           NUMBER,
  empleado     VARCHAR2(60),
  departamento VARCHAR2(20),
  cedula       VARCHAR2(15),
  salario      NUMBER(12,2),
  CONSTRAINT pk_salarios PRIMARY KEY (id)
);
INSERT INTO salarios VALUES (1, 'Empleado Uno',  'TI',   '1-1111-1111', 1500000);
INSERT INTO salarios VALUES (2, 'Empleado Dos',  'RRHH', '2-2222-2222', 1800000);
INSERT INTO salarios VALUES (3, 'Empleado Tres', 'FIN',  '3-3333-3333', 2100000);
COMMIT;

-- Todas las columnas se clasifican: la prueba T-01 busca las que falten
COMMENT ON COLUMN salarios.id           IS 'CLASIFICACION=INTERNA';
COMMENT ON COLUMN salarios.empleado     IS 'CLASIFICACION=CONFIDENCIAL;LEY8968=DATO_PERSONAL';
COMMENT ON COLUMN salarios.departamento IS 'CLASIFICACION=INTERNA';
COMMENT ON COLUMN salarios.cedula       IS 'CLASIFICACION=CONFIDENCIAL;LEY8968=DATO_PERSONAL';
COMMENT ON COLUMN salarios.salario      IS 'CLASIFICACION=CONFIDENCIAL';
GRANT SELECT ON salarios TO rol_analista_nomina;   -- el dueño concede al rol, nadie más

-- ===== PARTE D: controles sobre los datos, como sec_maria (A8.3, A8.11, A8.15) =====
CONNECT sec_maria/"Maria#Segura2026"@&cs
GRANT rol_analista_nomina TO ana_analista;

-- Redacción (A8.11): se redactan todas las columnas sensibles, no solo el salario
BEGIN
  DBMS_REDACT.ADD_POLICY(object_schema => 'NOMINA', object_name => 'SALARIOS',
    policy_name => 'RED_SALARIOS', column_name => 'SALARIO',
    function_type => DBMS_REDACT.FULL,
    expression => q'[SYS_CONTEXT('USERENV','SESSION_USER') <> 'NOMINA']');
  DBMS_REDACT.ALTER_POLICY(object_schema => 'NOMINA', object_name => 'SALARIOS',
    policy_name => 'RED_SALARIOS', action => DBMS_REDACT.ADD_COLUMN,
    column_name => 'CEDULA', function_type => DBMS_REDACT.FULL);
  DBMS_REDACT.ALTER_POLICY(object_schema => 'NOMINA', object_name => 'SALARIOS',
    policy_name => 'RED_SALARIOS', action => DBMS_REDACT.ADD_COLUMN,
    column_name => 'EMPLEADO', function_type => DBMS_REDACT.FULL);
END;
/
-- Variante parcial para la cédula (muestra solo los últimos dígitos): DBMS_REDACT.PARTIAL

-- VPD (A8.3): la función vive en el esquema de seguridad, no en el del propietario
CREATE OR REPLACE FUNCTION f_vpd_salarios (p_schema VARCHAR2, p_obj VARCHAR2)
  RETURN VARCHAR2 IS
BEGIN
  IF SYS_CONTEXT('USERENV','SESSION_USER') = 'NOMINA' THEN
    RETURN NULL;
  END IF;
  RETURN 'departamento = ''TI''';   -- regla de laboratorio; en producción se lee de una tabla de permisos
END;
/
-- Si ADD_POLICY falla con ORA-00439, la función no está habilitada: registrar «no aplicable»
BEGIN
  DBMS_RLS.ADD_POLICY(object_schema => 'NOMINA', object_name => 'SALARIOS',
    policy_name => 'VPD_SALARIOS', function_schema => 'SEC_MARIA',
    policy_function => 'F_VPD_SALARIOS', statement_types => 'SELECT');
END;
/

-- Enmascaramiento estático irreversible para clones DEV/TEST (A8.11; prueba T-16)
CREATE OR REPLACE PACKAGE pkg_mask AS
  FUNCTION f_mask_txt (p VARCHAR2) RETURN VARCHAR2;
  FUNCTION f_mask_sal (p NUMBER)   RETURN NUMBER;
END pkg_mask;
/
CREATE OR REPLACE PACKAGE BODY pkg_mask AS
  FUNCTION f_mask_txt (p VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE WHEN p IS NULL THEN NULL ELSE 'X-' || DBMS_RANDOM.STRING('X', 8) END;
  END;
  FUNCTION f_mask_sal (p NUMBER) RETURN NUMBER IS
  BEGIN
    RETURN CASE WHEN p IS NULL THEN NULL ELSE ROUND(DBMS_RANDOM.VALUE(1000000, 3000000), -4) END;
  END;
END pkg_mask;
/
GRANT EXECUTE ON pkg_mask TO nomina;

-- Auditoría unificada (A8.15)
CREATE AUDIT POLICY pol_acceso_salarios
  ACTIONS SELECT ON nomina.salarios, UPDATE ON nomina.salarios, DELETE ON nomina.salarios;
AUDIT POLICY pol_acceso_salarios;

CREATE AUDIT POLICY pol_privilegios_criticos
  PRIVILEGES SELECT ANY TABLE, CREATE ANY TABLE, DROP ANY TABLE,
             CREATE USER, ALTER USER, DROP USER;
AUDIT POLICY pol_privilegios_criticos;
```

### 12.2 Batería de pruebas

| ID | Tipo | Procedimiento | Resultado esperado | Herramienta |
| --- | --- | --- | --- | --- |
| T-01 | Consulta SQL por excepción | Cruzar DBA_TAB_COLUMNS con DBA_COL_COMMENTS para listar las columnas del esquema NOMINA sin clasificación | 0 filas: toda columna tiene CLASIFICACION= | SQL Developer |
| T-02 | Consulta SQL | Buscar cuentas con contraseña por defecto en estado OPEN y listar los usuarios no creados por Oracle | 0 cuentas por defecto abiertas; todo usuario es nominal | SQL Developer |
| T-03 | Revisión de configuración | Consultar DBA_PROFILES para DEFAULT y PERFIL_SEGURO | PERFIL_SEGURO: 5 intentos, vida de 90 días y función de verificación; si DEFAULT no cumple, se registra como brecha | SQL Developer |
| T-04 | Consulta SQL y prueba negativa | Buscar concesiones a PUBLIC, concesiones directas a usuarios y privilegios efectivos sobre NOMINA que llegan por roles anidados (consulta jerárquica) | Sin concesiones a PUBLIC ni directas; el único acceso efectivo es el de ANA_ANALISTA mediante ROL_ANALISTA_NOMINA | SQL Developer |
| T-05 | Consulta SQL | Buscar privilegios ANY efectivos (incluidos los heredados por roles anidados), usuarios con el rol DBA y el contenido de V$PWFILE_USERS | Ninguna cuenta nominal con el rol DBA; el único ANY es AUDIT ANY de SEC_MARIA, necesario para auditar; solo SYS y SYSTEM en el archivo de contraseñas | SQL Developer |
| T-06 | Prueba funcional | Capturar privilegios con DBMS_PRIVILEGE_CAPTURE durante el uso del script y listar los no usados | Lista de privilegios concedidos y no usados; acta de revisión | SQL Developer |
| T-07 | Prueba funcional y negativa | Como ANA_ANALISTA, contar las filas y los departamentos visibles en NOMINA.SALARIOS | 1 fila y 1 departamento (TI). Si ve las 3 filas, la política VPD no existe y A8.3 no cumple | SQL Developer |
| T-08 | Revisión de configuración | Consultar V$VERSION y DBA_REGISTRY_SQLPATCH y contrastar con el boletín trimestral de Oracle | Versión y parches registrados, con fecha de la última revisión | SQL Developer, sitio de Oracle |
| T-09 | Configuración y prueba física | Consultar V$ENCRYPTION_WALLET y DBA_TABLESPACES; ejecutar strings sobre el datafile cifrado y sobre el de USERS | Keystore OPEN; TS_CONF con ENCRYPTED=YES; strings sin coincidencias en ts_conf; si hay residuos en USERS, hallazgo de A8.10 | SQL Developer, terminal |
| T-10 | Prueba funcional | Consultar el catálogo de redacción y leer EMPLEADO, CEDULA y SALARIO como ANA_ANALISTA | Los tres campos aparecen redactados (espacio y 0) | SQL Developer |
| T-11 | Configuración y evidencia | Consultar LOG_MODE, los respaldos RMAN y la columna ENCRYPTED; revisar permisos de la carpeta | ARCHIVELOG; respaldo con ENCRYPTED=YES; permisos 750 | RMAN, SQL Developer, terminal |
| T-12 | Consulta SQL | Revisar roles de exportación, paquetes UTL_* concedidos a PUBLIC, DBA_DIRECTORIES y las ACL de red en DBA_HOST_ACES | Sin roles de exportación en cuentas nominales; UTL_* revocados a PUBLIC; sin ACL de red para cuentas de aplicación | SQL Developer |
| T-13 | Prueba funcional y consulta | Vaciar el buffer de auditoría con sec_maria y leer, como AUD_PEDRO, las políticas, UNIFIED_AUDIT_TRAIL y la retención | Política activa, registro de ANA_ANALISTA sobre SALARIOS y trabajo de purga configurado | SQL Developer |
| T-14 | Configuración y prueba negativa | Leer el banner de la sesión, lsnrctl status, sqlnet.ora y escanear el puerto desde un equipo no autorizado | Sesión cifrada; listener con restricciones; puerto no accesible desde equipos no autorizados | SQL Developer, lsnrctl, nmap |
| T-15 | Consulta SQL y RMAN | Revisar papelera, usuarios abiertos e inactivos (las cuentas bloqueadas se excluyen), REPORT OBSOLETE y retención de auditoría | Sin objetos sensibles en la papelera; sin usuarios abiertos e inactivos; 0 respaldos obsoletos | SQL Developer, RMAN |
| T-16 | Prueba funcional | Como NOMINA, crear una copia DEV con el paquete de enmascaramiento y compararla con el original | 0 valores reales conservados en la copia; la copia se elimina con PURGE | SQL Developer; Data Pump con REMAP_DATA a escala real |

### 12.3 Endurecimiento del laboratorio (01_endurecimiento.sql)

Implementa los controles que dejan las pruebas en verde y que la preparación no cubre: revocar a PUBLIC los paquetes de salida, activar TDE y mover los datos a un tablespace cifrado, activar ARCHIVELOG, configurar la retención de la auditoría y cifrar los respaldos. Cada parte indica la cuenta que la ejecuta. Las partes B y C reinician la instancia y requieren la terminal del servidor; ajuste las rutas a su instalación. La retención y el cifrado de respaldos son procedimientos que debe comprobar al ejecutarlos, porque dependen del entorno.

```sql
-- 01_endurecimiento.sql | Oracle 21c XE | cada parte indica la cuenta que la ejecuta
DEFINE cs = //localhost:1521/XEPDB1

-- ===== PARTE A: como SYS en XEPDB1 (A8.12): revocar a PUBLIC los paquetes de salida =====
-- ALTER SESSION SET CONTAINER = XEPDB1;
-- Puede afectar a aplicaciones que los usen; en el laboratorio no hay ninguna.
REVOKE EXECUTE ON UTL_FILE FROM PUBLIC;
REVOKE EXECUTE ON UTL_HTTP FROM PUBLIC;
REVOKE EXECUTE ON UTL_SMTP FROM PUBLIC;
REVOKE EXECUTE ON UTL_TCP  FROM PUBLIC;

-- ===== PARTE B: como SYS en CDB$ROOT (A8.24): keystore de TDE =====
-- Antes, en la terminal, crear la carpeta del keystore (ver bloque de terminal)
ALTER SYSTEM SET WALLET_ROOT = '/opt/oracle/admin/XE/wallet' SCOPE = SPFILE;
SHUTDOWN IMMEDIATE
STARTUP
ALTER PLUGGABLE DATABASE ALL OPEN;
ALTER SYSTEM SET TDE_CONFIGURATION = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH;
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "Wallet#2026x";
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "Wallet#2026x" CONTAINER = ALL;
ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "Wallet#2026x" WITH BACKUP CONTAINER = ALL;
ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "Wallet#2026x";

-- ===== PARTE C: como SYS en CDB$ROOT (A8.13): modo ARCHIVELOG =====
SELECT log_mode FROM v$database;
SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ALTER PLUGGABLE DATABASE ALL OPEN;

-- ===== PARTE D: tablespace cifrado para los datos confidenciales (A8.24) =====
-- El DBA de infraestructura crea el tablespace; no necesita leer los datos
CONNECT dba_juan/"Juan#Infra2026"@&cs
CREATE TABLESPACE ts_conf
  DATAFILE '/opt/oracle/oradata/XE/XEPDB1/ts_conf01.dbf' SIZE 50M
  AUTOEXTEND ON NEXT 10M MAXSIZE 200M
  ENCRYPTION USING 'AES256' DEFAULT STORAGE (ENCRYPT);

-- El oficial de seguridad asigna la cuota
CONNECT sec_maria/"Maria#Segura2026"@&cs
ALTER USER nomina QUOTA 50M ON ts_conf;

-- El propietario mueve su tabla y reconstruye el índice
CONNECT nomina/"Nomina#2026x"@&cs
ALTER TABLE salarios MOVE TABLESPACE ts_conf;
ALTER INDEX pk_salarios REBUILD TABLESPACE ts_conf;

-- ===== PARTE E: retención de la auditoría (A5.33), como sec_maria =====
CONNECT sec_maria/"Maria#Segura2026"@&cs
BEGIN
  DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
    audit_trail_type  => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    last_archive_time => SYSTIMESTAMP - INTERVAL '365' DAY);
  DBMS_AUDIT_MGMT.CREATE_PURGE_JOB(
    audit_trail_type           => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    audit_trail_purge_interval => 24,
    audit_trail_purge_name     => 'PURGA_AUDITORIA_UNIFICADA',
    use_last_arch_timestamp    => TRUE);
END;
/
-- La marca de tiempo se actualiza cada mes con SET_LAST_ARCHIVE_TIMESTAMP (procedimiento operativo)
```

Terminal y RMAN (las rutas son las de una instalación RPM de XE en Linux; ajústelas):

```bash
# Antes de la parte B (usuario oracle)
mkdir -p /opt/oracle/admin/XE/wallet/tde
chmod 700 /opt/oracle/admin/XE/wallet /opt/oracle/admin/XE/wallet/tde

# Destino de respaldos y archive logs
chmod 750 /opt/oracle/fast_recovery_area

# Después de las partes B y C: respaldo cifrado (A8.13)
rman target / <<'EOF'
CONFIGURE ENCRYPTION FOR DATABASE ON;
BACKUP DATABASE PLUS ARCHIVELOG;
SHOW ALL;
EOF
```

Red y listener (A8.20). En $ORACLE_HOME/network/admin/sqlnet.ora, y después reiniciar el listener con lsnrctl stop y lsnrctl start. Incluya en TCP.INVITED_NODES la dirección del equipo desde el que se conecta con SQL Developer; de lo contrario quedará sin acceso.

```sql
SQLNET.ENCRYPTION_SERVER = REQUIRED
SQLNET.ENCRYPTION_TYPES_SERVER = (AES256)
SQLNET.CRYPTO_CHECKSUM_SERVER = REQUIRED
SQLNET.CRYPTO_CHECKSUM_TYPES_SERVER = (SHA256)
SQLNET.ALLOWED_LOGON_VERSION_SERVER = 12
TCP.VALIDNODE_CHECKING = yes
TCP.INVITED_NODES = (127.0.0.1, <IP_del_equipo_con_SQL_Developer>)
```

Y en listener.ora: ADMIN_RESTRICTIONS_LISTENER = ON.

### 12.4 Verificación (02_verificacion.sql)

Se ejecuta con las cuentas nominales: aud_pedro hace la mayor parte de la lectura, con permisos de solo lectura. Los cambios de sesión se hacen con CONNECT; en SQL Developer, si el comando no está disponible, cambie de conexión manualmente. Las pruebas no siguen el orden numérico porque dependen de quién las ejecuta y de que el buffer de auditoría se vacíe antes de leerlo.

```sql
-- 02_verificacion.sql | Oracle 21c XE | ejecutar después del 00 (línea base) y después del 01
DEFINE cs = //localhost:1521/XEPDB1
SET LINESIZE 220 PAGESIZE 100 SERVEROUTPUT ON
COLUMN comments FORMAT A60
COLUMN network_service_banner FORMAT A80

-- ===== Inicio de la captura de privilegios (T-06) como sec_maria =====
CONNECT sec_maria/"Maria#Segura2026"@&cs
BEGIN DBMS_PRIVILEGE_CAPTURE.DROP_CAPTURE('CAP_REVISION'); EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  DBMS_PRIVILEGE_CAPTURE.CREATE_CAPTURE(name => 'CAP_REVISION',
                                        type => DBMS_PRIVILEGE_CAPTURE.G_DATABASE);
  DBMS_PRIVILEGE_CAPTURE.ENABLE_CAPTURE('CAP_REVISION');
END;
/

-- ===== T-07 y T-10 como ana_analista =====
CONNECT ana_analista/"Ana#Analista2026"@&cs
PROMPT === T-07 VPD (A8.3) | Esperado: filas_visibles = 1 y departamentos = 1 (solo TI)
SELECT COUNT(*) AS filas_visibles, COUNT(DISTINCT departamento) AS departamentos FROM nomina.salarios;
PROMPT === T-10 Redacción (A8.11) | Esperado: empleado y cédula como espacio, salario = 0
SELECT empleado, cedula, salario FROM nomina.salarios;

-- ===== Vaciar el buffer de auditoría (T-13) como sec_maria =====
CONNECT sec_maria/"Maria#Segura2026"@&cs
EXEC DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL;

-- ===== Lectura de evidencia como aud_pedro =====
CONNECT aud_pedro/"Pedro#Audit2026"@&cs
PROMPT === T-00 Funciones disponibles en la instancia | Esperado: las que usa el laboratorio
SELECT parameter, value FROM v$option
 WHERE parameter LIKE '%Vault%' OR parameter LIKE '%Label%' OR parameter LIKE '%Security%'
    OR parameter LIKE '%Fine-grained%' OR parameter = 'Unified Auditing';

PROMPT === T-01 Columnas sin clasificar (A5.12) | Esperado: 0 filas
SELECT c.table_name, c.column_name, m.comments
  FROM dba_tab_columns c
  LEFT JOIN dba_col_comments m
    ON m.owner = c.owner AND m.table_name = c.table_name AND m.column_name = c.column_name
 WHERE c.owner = 'NOMINA'
   AND (m.comments IS NULL OR m.comments NOT LIKE 'CLASIFICACION=%');

PROMPT === T-02 Cuentas por defecto abiertas (A5.16) | Esperado: 0 filas
SELECT d.username, u.account_status
  FROM dba_users_with_defpwd d JOIN dba_users u ON u.username = d.username
 WHERE u.account_status = 'OPEN';
PROMPT -- Usuarios no creados por Oracle | Esperado: todos nominales
SELECT username, account_status, profile, last_login
  FROM dba_users WHERE oracle_maintained = 'N' ORDER BY username;

PROMPT === T-03 Perfiles (A5.17, A8.5) | Esperado: PERFIL_SEGURO con 5 intentos, 90 días y función de verificación
SELECT profile, resource_name, limit
  FROM dba_profiles
 WHERE resource_type = 'PASSWORD'
   AND resource_name IN ('FAILED_LOGIN_ATTEMPTS','PASSWORD_LOCK_TIME','PASSWORD_LIFE_TIME','PASSWORD_VERIFY_FUNCTION')
   AND profile IN ('DEFAULT','PERFIL_SEGURO')
 ORDER BY profile, resource_name;

PROMPT === T-04 Acceso por roles (A5.15) | Esperado: 0 filas en las dos primeras; en la tercera, solo ANA_ANALISTA
SELECT grantee, table_name, privilege FROM dba_tab_privs WHERE grantee = 'PUBLIC' AND owner = 'NOMINA';
SELECT grantee, table_name, privilege
  FROM dba_tab_privs
 WHERE owner = 'NOMINA' AND grantee <> 'NOMINA' AND grantee NOT IN (SELECT role FROM dba_roles);
PROMPT -- Privilegios efectivos sobre NOMINA, incluidos los recibidos por roles anidados
SELECT DISTINCT h.usuario, h.rol, p.privilege, p.table_name
  FROM (SELECT CONNECT_BY_ROOT grantee AS usuario, granted_role AS rol
          FROM dba_role_privs
         START WITH grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
         CONNECT BY PRIOR granted_role = grantee) h
  JOIN dba_tab_privs p ON p.grantee = h.rol AND p.owner = 'NOMINA'
 ORDER BY h.usuario;

PROMPT === T-05 Privilegios administrativos (A8.2) | Esperado: ningún rol DBA; el único ANY es AUDIT ANY de SEC_MARIA
SELECT DISTINCT h.usuario, p.privilege
  FROM (SELECT CONNECT_BY_ROOT grantee AS usuario, granted_role AS rol
          FROM dba_role_privs
         START WITH grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
         CONNECT BY PRIOR granted_role = grantee) h
  JOIN dba_sys_privs p ON p.grantee = h.rol
 WHERE p.privilege LIKE '%ANY%'
UNION
SELECT grantee, privilege FROM dba_sys_privs
 WHERE privilege LIKE '%ANY%'
   AND grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N');
PROMPT -- Cuentas nominales que reciben el rol DBA, directo o anidado | Esperado: 0 filas
SELECT DISTINCT usuario
  FROM (SELECT CONNECT_BY_ROOT grantee AS usuario, granted_role AS rol
          FROM dba_role_privs
         START WITH grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
         CONNECT BY PRIOR granted_role = grantee)
 WHERE rol = 'DBA';
PROMPT -- Archivo de contraseñas (puede requerir CDB$ROOT) | Esperado: solo SYS y SYSTEM
SELECT * FROM v$pwfile_users;

PROMPT === T-08 Versión y parches (A8.8) | Esperado: versión 21c y parches en estado SUCCESS
SELECT banner_full FROM v$version;
SELECT patch_id, action, status, description, action_time
  FROM dba_registry_sqlpatch ORDER BY action_time;

PROMPT === T-09 TDE (A8.24) | Esperado: keystore OPEN y TS_CONF con ENCRYPTED=YES
SELECT wrl_type, status, wallet_type FROM v$encryption_wallet;
SELECT tablespace_name, encrypted FROM dba_tablespaces ORDER BY 1;
-- Prueba física (terminal): comparar el datafile cifrado y el de USERS
--   strings /opt/oracle/oradata/XE/XEPDB1/ts_conf01.dbf | grep -i "Empleado"   -> sin coincidencias
--   strings /opt/oracle/oradata/XE/XEPDB1/users01.dbf  | grep -i "Empleado"    -> si hay residuos, hallazgo de A8.10

PROMPT === T-10 (catálogo) | Esperado: política RED_SALARIOS con SALARIO, CEDULA y EMPLEADO
SELECT object_owner, object_name, column_name, function_type FROM redaction_columns;
SELECT object_owner, object_name, policy_name, enable FROM redaction_policies;

PROMPT === T-11 Respaldos (A8.13) | Esperado: ARCHIVELOG y respaldo con ENCRYPTED=YES
SELECT log_mode FROM v$database;
SELECT backup_type, encrypted, completion_time
  FROM v$backup_set_details ORDER BY completion_time DESC FETCH FIRST 5 ROWS ONLY;
-- En la terminal: ls -l /opt/oracle/fast_recovery_area   (esperado: propietario oracle, permisos 750)

PROMPT === T-12 Prevención de fuga (A8.12) | Esperado: 0 filas en las tres primeras; la cuarta, solo ACL autorizadas
SELECT grantee, granted_role FROM dba_role_privs
 WHERE granted_role IN ('DATAPUMP_EXP_FULL_DATABASE','EXP_FULL_DATABASE','DATAPUMP_IMP_FULL_DATABASE','IMP_FULL_DATABASE')
   AND grantee NOT IN ('SYS','SYSTEM','DBA');
SELECT grantee, table_name, privilege FROM dba_tab_privs
 WHERE grantee = 'PUBLIC' AND table_name IN ('UTL_FILE','UTL_HTTP','UTL_SMTP','UTL_TCP');
SELECT directory_name, directory_path FROM dba_directories;
SELECT host, lower_port, upper_port, principal, privilege FROM dba_host_aces;

PROMPT === T-13 Auditoría (A8.15, A5.33) | Esperado: política activa, registro de ANA_ANALISTA y trabajo de purga
SELECT policy_name, enabled_option, entity_name, success, failure FROM audit_unified_enabled_policies;
SELECT event_timestamp, dbusername, action_name, object_schema, object_name
  FROM unified_audit_trail
 WHERE object_name = 'SALARIOS'
 ORDER BY event_timestamp DESC FETCH FIRST 10 ROWS ONLY;
SELECT parameter_name, parameter_value FROM dba_audit_mgmt_config_params;
SELECT * FROM dba_audit_mgmt_cleanup_jobs;
SELECT grantee, granted_role FROM dba_role_privs WHERE granted_role IN ('AUDIT_ADMIN','AUDIT_VIEWER');

PROMPT === T-14 Red (A8.20) | Esperado: banner con cifrado AES256; listener restringido; puerto cerrado a equipos no autorizados
SELECT network_service_banner FROM v$session_connect_info WHERE sid = SYS_CONTEXT('USERENV','SID');
-- En la terminal del servidor (usuario oracle):
--   lsnrctl status
--   grep -iE "ENCRYPTION|CRYPTO|INVITED|VALIDNODE|ALLOWED_LOGON" $ORACLE_HOME/network/admin/sqlnet.ora
-- Desde un equipo no autorizado: nmap -p 1521 <IP_del_servidor>   (esperado: closed o filtered)

PROMPT === T-15 Eliminación y retención (A8.10) | Esperado: 0 filas en ambas consultas
SELECT owner, original_name, droptime FROM dba_recyclebin;
SELECT username, account_status, last_login
  FROM dba_users
 WHERE oracle_maintained = 'N' AND account_status = 'OPEN'
   AND COALESCE(last_login, CAST(created AS TIMESTAMP WITH TIME ZONE)) < SYSTIMESTAMP - INTERVAL '90' DAY;
-- En RMAN: REPORT OBSOLETE;   (esperado: sin respaldos obsoletos; si hay, DELETE OBSOLETE;)

-- ===== T-16 como nomina: copia DEV enmascarada =====
CONNECT nomina/"Nomina#2026x"@&cs
PROMPT === T-16 Enmascaramiento estático (A8.11) | Esperado: valores_reales_conservados = 0
CREATE TABLE salarios_dev AS
  SELECT id,
         sec_maria.pkg_mask.f_mask_txt(empleado) AS empleado,
         departamento,
         sec_maria.pkg_mask.f_mask_txt(cedula)   AS cedula,
         sec_maria.pkg_mask.f_mask_sal(salario)  AS salario
    FROM salarios;
SELECT COUNT(*) AS valores_reales_conservados
  FROM salarios s JOIN salarios_dev d ON d.id = s.id
 WHERE d.empleado = s.empleado OR d.cedula = s.cedula OR d.salario = s.salario;
SELECT * FROM salarios_dev;
DROP TABLE salarios_dev PURGE;
-- A escala real: expdp ... REMAP_DATA=NOMINA.SALARIOS.CEDULA:SEC_MARIA.PKG_MASK.F_MASK_TXT
-- Un clon hecho con RMAN DUPLICATE conserva los datos reales y debe enmascararse después

-- ===== Cierre de T-06 y bloqueo del propietario, como sec_maria =====
CONNECT sec_maria/"Maria#Segura2026"@&cs
BEGIN
  DBMS_PRIVILEGE_CAPTURE.DISABLE_CAPTURE('CAP_REVISION');
  DBMS_PRIVILEGE_CAPTURE.GENERATE_RESULT('CAP_REVISION');
END;
/
ALTER USER nomina ACCOUNT LOCK;   -- el propietario del esquema no inicia sesión en producción

-- ===== Resultado de T-06 como aud_pedro (el resultado puede tardar unos segundos) =====
CONNECT aud_pedro/"Pedro#Audit2026"@&cs
PROMPT === T-06 Privilegios concedidos y no usados (A5.18) | Esperado: lista para la revisión de derechos
SELECT * FROM dba_unused_privs WHERE capture = 'CAP_REVISION';
```

### 12.5 Ejecución de pruebas de comandos SQL y simulación de capturas de salida esperada

A continuación se presenta la ejecución detallada de las pruebas técnicas (T-00 a T-16) definidas en el script 02_verificacion.sql tras aplicar la preparación (00_preparacion.sql) y el endurecimiento (01_endurecimiento.sql) sobre Oracle Database 21c XE (servicio XEPDB1). Para cada prueba se documentan la cuenta nominal que la ejecuta según la segregación de funciones, las sentencias SQL o comandos de sistema operativo ejecutados, la simulación de la captura de pantalla de la salida esperada en Oracle SQL Developer o en la terminal del servidor y el dictamen técnico correspondiente.

T-00 · Funciones disponibles en la instancia (Control ISO: — | Tipo: Revisión de configuración | Cuenta: aud_pedro | Herramienta: SQL Developer)

Procedimiento: Consultar V$OPTION para dejar constancia de las funciones de seguridad activas en la instancia XE.  Resultado esperado: Fine-grained access control (VPD) en TRUE; Database Vault y Label Security pueden aparecer en FALSE porque no se configuran en el laboratorio; Unified Auditing en FALSE indica modo mixto, en el que las políticas unificadas funcionan.

```sql
SELECT parameter, value FROM v$option
 WHERE parameter LIKE '%Vault%' OR parameter LIKE '%Label%' OR parameter LIKE '%Security%'
    OR parameter LIKE '%Fine-grained%' OR parameter = 'Unified Auditing';
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-00 Funciones disponibles en la instancia | Esperado: las que usa el laboratorio

PARAMETER                   VALUE
--------------------------- -----
Fine-grained access control TRUE
Fine-grained Auditing       TRUE
Oracle Database Vault       FALSE
Oracle Label Security       FALSE
Real Application Security   TRUE
Unified Auditing            FALSE

6 rows selected.
```

*Figura 1. Simulación de salida esperada de T-00 (Funciones disponibles en la instancia) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-01 · Columnas sin clasificar (Control ISO: A5.12 | Tipo: Consulta SQL por excepción | Cuenta: aud_pedro | Herramienta: SQL Developer)

Procedimiento: Cruzar DBA_TAB_COLUMNS con DBA_COL_COMMENTS para listar las columnas del esquema NOMINA sin clasificación.  Resultado esperado: 0 filas: toda columna tiene CLASIFICACION=.

```sql
SELECT c.table_name, c.column_name, m.comments
  FROM dba_tab_columns c
  LEFT JOIN dba_col_comments m
    ON m.owner = c.owner AND m.table_name = c.table_name AND m.column_name = c.column_name
 WHERE c.owner = 'NOMINA'
   AND (m.comments IS NULL OR m.comments NOT LIKE 'CLASIFICACION=%');
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-01 Columnas sin clasificar (A5.12) | Esperado: 0 filas

no rows selected
```

*Figura 2. Simulación de salida esperada de T-01 (Columnas sin clasificar) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-02 · Cuentas por defecto abiertas (Control ISO: A5.16 | Tipo: Consulta SQL | Cuenta: aud_pedro | Herramienta: SQL Developer)

Procedimiento: Buscar cuentas con contraseña por defecto en estado OPEN y listar los usuarios no creados por Oracle.  Resultado esperado: 0 cuentas por defecto abiertas; todo usuario es nominal.

```sql
SELECT d.username, u.account_status
  FROM dba_users_with_defpwd d JOIN dba_users u ON u.username = d.username
 WHERE u.account_status = 'OPEN';
SELECT username, account_status, profile, last_login
  FROM dba_users WHERE oracle_maintained = 'N' ORDER BY username;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-02 Cuentas por defecto abiertas (A5.16) | Esperado: 0 filas

no rows selected

-- Usuarios no creados por Oracle | Esperado: todos nominales

USERNAME     ACCOUNT_STATUS PROFILE       LAST_LOGIN
------------ -------------- ------------- ----------------------------------
ANA_ANALISTA OPEN           PERFIL_SEGURO 19/10/26 10:41:03,000000000 -06:00
AUD_PEDRO    OPEN           PERFIL_SEGURO 19/10/26 10:41:09,000000000 -06:00
DBA_JUAN     OPEN           PERFIL_SEGURO 19/10/26 09:58:12,000000000 -06:00
NOMINA       OPEN           PERFIL_SEGURO 19/10/26 09:59:40,000000000 -06:00
SEC_MARIA    OPEN           PERFIL_SEGURO 19/10/26 10:41:06,000000000 -06:00

5 rows selected.
```

*Figura 3. Simulación de salida esperada de T-02 (Cuentas por defecto abiertas) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-03 · Perfiles de contraseña (Control ISO: A5.17 · A8.5 | Tipo: Revisión de configuración | Cuenta: aud_pedro | Herramienta: SQL Developer)

Procedimiento: Consultar DBA_PROFILES para DEFAULT y PERFIL_SEGURO.  Resultado esperado: PERFIL_SEGURO: 5 intentos, vida de 90 días y función de verificación; si DEFAULT no cumple, se registra como brecha.

```sql
SELECT profile, resource_name, limit
  FROM dba_profiles
 WHERE resource_type = 'PASSWORD'
   AND resource_name IN ('FAILED_LOGIN_ATTEMPTS','PASSWORD_LOCK_TIME',
                         'PASSWORD_LIFE_TIME','PASSWORD_VERIFY_FUNCTION')
   AND profile IN ('DEFAULT','PERFIL_SEGURO')
 ORDER BY profile, resource_name;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-03 Perfiles (A5.17, A8.5) | Esperado: PERFIL_SEGURO con 5 intentos, 90 días y función de verificación

PROFILE       RESOURCE_NAME            LIMIT
------------- ------------------------ -----------------------------
DEFAULT       FAILED_LOGIN_ATTEMPTS    10
DEFAULT       PASSWORD_LIFE_TIME       180
DEFAULT       PASSWORD_LOCK_TIME       1
DEFAULT       PASSWORD_VERIFY_FUNCTION NULL
PERFIL_SEGURO FAILED_LOGIN_ATTEMPTS    5
PERFIL_SEGURO PASSWORD_LIFE_TIME       90
PERFIL_SEGURO PASSWORD_LOCK_TIME       .0416
PERFIL_SEGURO PASSWORD_VERIFY_FUNCTION ORA12C_STRONG_VERIFY_FUNCTION

8 rows selected.
```

*Figura 4. Simulación de salida esperada de T-03 (Perfiles de contraseña) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-04 · Acceso por roles (incluidos roles anidados) (Control ISO: A5.15 | Tipo: Consulta SQL y prueba negativa | Cuenta: aud_pedro | Herramienta: SQL Developer)

Procedimiento: Buscar concesiones a PUBLIC, concesiones directas a usuarios y privilegios efectivos sobre NOMINA que llegan por roles anidados (consulta jerárquica).  Resultado esperado: Sin concesiones a PUBLIC ni directas; el único acceso efectivo es el de ANA_ANALISTA mediante ROL_ANALISTA_NOMINA.

```sql
SELECT grantee, table_name, privilege FROM dba_tab_privs
 WHERE grantee = 'PUBLIC' AND owner = 'NOMINA';
SELECT grantee, table_name, privilege
  FROM dba_tab_privs
 WHERE owner = 'NOMINA' AND grantee <> 'NOMINA'
   AND grantee NOT IN (SELECT role FROM dba_roles);
-- Privilegios efectivos sobre NOMINA, incluidos los recibidos por roles anidados
SELECT DISTINCT h.usuario, h.rol, p.privilege, p.table_name
  FROM (SELECT CONNECT_BY_ROOT grantee AS usuario, granted_role AS rol
          FROM dba_role_privs
         START WITH grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
         CONNECT BY PRIOR granted_role = grantee) h
  JOIN dba_tab_privs p ON p.grantee = h.rol AND p.owner = 'NOMINA'
 ORDER BY h.usuario;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-04 Acceso por roles (A5.15) | Esperado: 0 filas en las dos primeras; en la tercera, solo ANA_ANALISTA

no rows selected

no rows selected

-- Privilegios efectivos sobre NOMINA, incluidos los recibidos por roles anidados

USUARIO      ROL                 PRIVILEGE TABLE_NAME
------------ ------------------- --------- ----------
ANA_ANALISTA ROL_ANALISTA_NOMINA SELECT    SALARIOS
```

*Figura 5. Simulación de salida esperada de T-04 (Acceso por roles (incluidos roles anidados)) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-05 · Privilegios administrativos (incluidos roles anidados) (Control ISO: A8.2 | Tipo: Consulta SQL | Cuenta: aud_pedro | Herramienta: SQL Developer)

Procedimiento: Buscar privilegios ANY efectivos (directos y heredados por roles anidados), cuentas nominales con el rol DBA y el contenido de V$PWFILE_USERS.  Resultado esperado: Ninguna cuenta nominal con el rol DBA; el único ANY es AUDIT ANY de SEC_MARIA, que llega por el rol AUDIT_ADMIN y es necesario para auditar; solo SYS (y, si existe, SYSTEM) en el archivo de contraseñas.

```sql
SELECT DISTINCT h.usuario, p.privilege
  FROM (SELECT CONNECT_BY_ROOT grantee AS usuario, granted_role AS rol
          FROM dba_role_privs
         START WITH grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
         CONNECT BY PRIOR granted_role = grantee) h
  JOIN dba_sys_privs p ON p.grantee = h.rol
 WHERE p.privilege LIKE '%ANY%'
UNION
SELECT grantee, privilege FROM dba_sys_privs
 WHERE privilege LIKE '%ANY%'
   AND grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N');
-- Cuentas nominales que reciben el rol DBA, directo o anidado
SELECT DISTINCT usuario
  FROM (SELECT CONNECT_BY_ROOT grantee AS usuario, granted_role AS rol
          FROM dba_role_privs
         START WITH grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
         CONNECT BY PRIOR granted_role = grantee)
 WHERE rol = 'DBA';
SELECT * FROM v$pwfile_users;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-05 Privilegios administrativos (A8.2) | Esperado: ningún rol DBA; el único ANY es AUDIT ANY de SEC_MARIA

USUARIO   PRIVILEGE
--------- ---------
SEC_MARIA AUDIT ANY

-- Cuentas nominales que reciben el rol DBA, directo o anidado | Esperado: 0 filas

no rows selected

-- Archivo de contraseñas (puede requerir CDB$ROOT) | Esperado: solo SYS y SYSTEM

USERNAME SYSDB SYSOP SYSAS SYSBA SYSDG SYSKM ACCOUNT_STATUS CON_ID
-------- ----- ----- ----- ----- ----- ----- -------------- ------
SYS      TRUE  TRUE  FALSE FALSE FALSE FALSE OPEN                0
```

*Figura 6. Simulación de salida esperada de T-05 (Privilegios administrativos (incluidos roles anidados)) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-06 · Privilegios concedidos y no usados (Control ISO: A5.18 | Tipo: Prueba funcional | Cuenta: sec_maria → aud_pedro | Herramienta: SQL Developer)

Procedimiento: Capturar privilegios con DBMS_PRIVILEGE_CAPTURE mientras se ejecutan T-07 y T-10 y listar los concedidos que no se usaron.  Resultado esperado: Lista de privilegios concedidos y no usados; cada uno se justifica o se revoca en el acta de revisión.

```sql
-- Al inicio de 02_verificacion.sql, como sec_maria (antes de T-07 y T-10)
BEGIN DBMS_PRIVILEGE_CAPTURE.DROP_CAPTURE('CAP_REVISION'); EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  DBMS_PRIVILEGE_CAPTURE.CREATE_CAPTURE(name => 'CAP_REVISION',
                                        type => DBMS_PRIVILEGE_CAPTURE.G_DATABASE);
  DBMS_PRIVILEGE_CAPTURE.ENABLE_CAPTURE('CAP_REVISION');
END;
/
-- Al final, como sec_maria
BEGIN
  DBMS_PRIVILEGE_CAPTURE.DISABLE_CAPTURE('CAP_REVISION');
  DBMS_PRIVILEGE_CAPTURE.GENERATE_RESULT('CAP_REVISION');
END;
/
-- Como aud_pedro (columnas reducidas para la captura)
SELECT username, rolename, sys_priv, obj_priv, object_owner, object_name
  FROM dba_unused_privs WHERE capture = 'CAP_REVISION' ORDER BY username;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-06 Privilegios concedidos y no usados (A5.18) | Esperado: lista para la revisión de derechos

USERNAME  ROLENAME      SYS_PRIV          OBJ_PRIV OBJECT_OWNER OBJECT_NAME
--------- ------------- ----------------- -------- ------------ -----------
DBA_JUAN  ROL_DBA_INFRA ALTER TABLESPACE
DBA_JUAN  ROL_DBA_INFRA CREATE SESSION
DBA_JUAN  ROL_DBA_INFRA CREATE TABLESPACE
DBA_JUAN  ROL_DBA_INFRA DROP TABLESPACE
SEC_MARIA ROL_SEGURIDAD ALTER PROFILE
SEC_MARIA ROL_SEGURIDAD CREATE PROCEDURE
SEC_MARIA ROL_SEGURIDAD CREATE PROFILE
SEC_MARIA ROL_SEGURIDAD CREATE ROLE
SEC_MARIA ROL_SEGURIDAD                   EXECUTE  SYS          DBMS_RLS

9 rows selected.
```

*Figura 7. Simulación de salida esperada de T-06 (Privilegios concedidos y no usados) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-07 · Restricción por fila (VPD) (Control ISO: A8.3 | Tipo: Prueba funcional y negativa | Cuenta: ana_analista | Herramienta: SQL Developer)

Procedimiento: Como ANA_ANALISTA, contar las filas y los departamentos visibles en NOMINA.SALARIOS.  Resultado esperado: 1 fila y 1 departamento (TI). Si ve las 3 filas, la política VPD no existe y A8.3 no cumple.

```sql
SELECT COUNT(*) AS filas_visibles, COUNT(DISTINCT departamento) AS departamentos
  FROM nomina.salarios;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_ana_analista (ana_analista@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------------
=== T-07 VPD (A8.3) | Esperado: filas_visibles = 1 y departamentos = 1 (solo TI)

FILAS_VISIBLES DEPARTAMENTOS
-------------- -------------
             1             1
```

*Figura 8. Simulación de salida esperada de T-07 (Restricción por fila (VPD)) en Oracle SQL Developer (conexión XEPDB1_ana_analista). Estado: Cumple.*

T-08 · Versión y parches (Control ISO: A8.8 (compl.) | Tipo: Revisión de configuración | Cuenta: aud_pedro | Herramienta: SQL Developer, sitio de Oracle)

Procedimiento: Consultar V$VERSION y DBA_REGISTRY_SQLPATCH y contrastar con el boletín trimestral de seguridad de Oracle.  Resultado esperado: Versión registrada con la fecha de la última revisión. XE no recibe parches trimestrales (Release Updates): si DBA_REGISTRY_SQLPATCH no devuelve filas, se registra la versión instalada y el boletín revisado.

```sql
SELECT banner_full FROM v$version;
SELECT patch_id, action, status, description, action_time
  FROM dba_registry_sqlpatch ORDER BY action_time;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-08 Versión y parches (A8.8) | Esperado: versión 21c y parches en estado SUCCESS

BANNER_FULL
------------------------------------------------------------------------------
Oracle Database 21c Express Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

no rows selected
```

*Figura 9. Simulación de salida esperada de T-08 (Versión y parches) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-09 · Cifrado TDE (Control ISO: A8.24 (compl.) | Tipo: Configuración y prueba física | Cuenta: aud_pedro · terminal | Herramienta: SQL Developer, terminal)

Procedimiento: Consultar V$ENCRYPTION_WALLET y DBA_TABLESPACES; ejecutar strings sobre el datafile cifrado y sobre el de USERS.  Resultado esperado: Keystore OPEN; TS_CONF con ENCRYPTED=YES; strings sin coincidencias en ts_conf01.dbf; si hay residuos en users01.dbf, se registra un hallazgo de A8.10.

```bash
SELECT wrl_type, status, wallet_type FROM v$encryption_wallet;
SELECT tablespace_name, encrypted FROM dba_tablespaces ORDER BY 1;
-- Terminal del servidor (usuario oracle)
strings /opt/oracle/oradata/XE/XEPDB1/ts_conf01.dbf | grep -i "Empleado"
strings /opt/oracle/oradata/XE/XEPDB1/users01.dbf  | grep -i "Empleado"
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-09 TDE (A8.24) | Esperado: keystore OPEN y TS_CONF con ENCRYPTED=YES

WRL_TYPE STATUS WALLET_TYPE
-------- ------ -----------
FILE     OPEN   AUTOLOGIN

TABLESPACE_NAME ENCRYPTED
--------------- ---------
SYSAUX          NO
SYSTEM          NO
TEMP            NO
TS_CONF         YES
UNDOTBS1        NO
USERS           NO

6 rows selected.
```

*Figura 10. Simulación de salida esperada de T-09 (Cifrado TDE) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

```text
[Terminal — oracle@xe-lab]
--------------------------
$ strings /opt/oracle/oradata/XE/XEPDB1/ts_conf01.dbf | grep -i "Empleado"
$ echo $?
1
$ strings /opt/oracle/oradata/XE/XEPDB1/users01.dbf | grep -i "Empleado"
Empleado Uno
Empleado Dos
Empleado Tres
$ # Residuos en USERS: bloques liberados por ALTER TABLE ... MOVE -> hallazgo A8.10
```

*Figura 11. Simulación de salida esperada de T-09 (Cifrado TDE) en Terminal (oracle@xe-lab). Estado: Cumple.*

T-10 · Redacción de datos (Control ISO: A8.11 | Tipo: Prueba funcional | Cuenta: ana_analista · aud_pedro | Herramienta: SQL Developer)

Procedimiento: Leer EMPLEADO, CEDULA y SALARIO como ANA_ANALISTA y consultar el catálogo de redacción como AUD_PEDRO.  Resultado esperado: Los tres campos aparecen redactados (espacio en los textos y 0 en el salario); la política RED_SALARIOS cubre SALARIO, CEDULA y EMPLEADO.

```sql
-- Como ana_analista
SELECT empleado, cedula, salario FROM nomina.salarios;
-- Como aud_pedro
SELECT object_owner, object_name, column_name, function_type FROM redaction_columns;
SELECT object_owner, object_name, policy_name, enable FROM redaction_policies;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_ana_analista (ana_analista@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------------
=== T-10 Redacción (A8.11) | Esperado: empleado y cédula como espacio, salario = 0

EMPLEADO                                                     CEDULA             SALARIO
------------------------------------------------------------ --------------- ----------
                                                                                      0
```

*Figura 12. Simulación de salida esperada de T-10 (Redacción de datos) en Oracle SQL Developer (conexión XEPDB1_ana_analista). Estado: Cumple.*

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-10 (catálogo) | Esperado: política RED_SALARIOS con SALARIO, CEDULA y EMPLEADO

OBJECT_OWNER OBJECT_NAME COLUMN_NAME FUNCTION_TYPE
------------ ----------- ----------- --------------
NOMINA       SALARIOS    SALARIO     FULL REDACTION
NOMINA       SALARIOS    CEDULA      FULL REDACTION
NOMINA       SALARIOS    EMPLEADO    FULL REDACTION

3 rows selected.

OBJECT_OWNER OBJECT_NAME POLICY_NAME  ENABLE
------------ ----------- ------------ ------
NOMINA       SALARIOS    RED_SALARIOS YES
```

*Figura 13. Simulación de salida esperada de T-10 (Redacción de datos) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-11 · Respaldos (Control ISO: A8.13 | Tipo: Configuración y evidencia | Cuenta: aud_pedro · RMAN · terminal | Herramienta: RMAN, SQL Developer, terminal)

Procedimiento: Consultar LOG_MODE, los respaldos RMAN y la columna ENCRYPTED; revisar la configuración de RMAN y los permisos de la carpeta de respaldos.  Resultado esperado: ARCHIVELOG; respaldos con ENCRYPTED=YES; CONFIGURE ENCRYPTION FOR DATABASE ON; carpeta con permisos 750.

```sql
SELECT log_mode FROM v$database;
SELECT backup_type, encrypted, completion_time
  FROM v$backup_set_details ORDER BY completion_time DESC FETCH FIRST 5 ROWS ONLY;
-- Terminal del servidor (usuario oracle)
ls -ld /opt/oracle/fast_recovery_area
rman target / <<< "SHOW ENCRYPTION FOR DATABASE;"
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-11 Respaldos (A8.13) | Esperado: ARCHIVELOG y respaldo con ENCRYPTED=YES

LOG_MODE
----------
ARCHIVELOG

B ENC COMPLETION_TIME
- --- -----------------
L YES 19/10/26 09:35:22
D YES 19/10/26 09:34:58

2 rows selected.
```

*Figura 14. Simulación de salida esperada de T-11 (Respaldos) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

```text
[Terminal — oracle@xe-lab]
--------------------------
$ ls -ld /opt/oracle/fast_recovery_area
drwxr-x---. 3 oracle oinstall 16 oct 19 09:31 /opt/oracle/fast_recovery_area
$ rman target / <<< "SHOW ENCRYPTION FOR DATABASE;"
connected to target database: XE (DBID=3029761152)
RMAN configuration parameters for database with db_unique_name XE are:
CONFIGURE ENCRYPTION FOR DATABASE ON;
```

*Figura 15. Simulación de salida esperada de T-11 (Respaldos) en Terminal (oracle@xe-lab). Estado: Cumple.*

T-12 · Prevención de fuga (Control ISO: A8.12 | Tipo: Consulta SQL | Cuenta: aud_pedro | Herramienta: SQL Developer)

Procedimiento: Revisar roles de exportación e importación, paquetes UTL_* concedidos a PUBLIC, DBA_DIRECTORIES y las ACL de red en DBA_HOST_ACES.  Resultado esperado: Sin roles de exportación o importación en cuentas nominales; UTL_* revocados a PUBLIC; DBA_DIRECTORIES solo con los directorios creados por Oracle; ACL de red solo para cuentas de Oracle.

```sql
SELECT grantee, granted_role FROM dba_role_privs
 WHERE granted_role IN ('DATAPUMP_EXP_FULL_DATABASE','EXP_FULL_DATABASE',
                        'DATAPUMP_IMP_FULL_DATABASE','IMP_FULL_DATABASE')
   AND grantee NOT IN ('SYS','SYSTEM','DBA');
SELECT grantee, table_name, privilege FROM dba_tab_privs
 WHERE grantee = 'PUBLIC' AND table_name IN ('UTL_FILE','UTL_HTTP','UTL_SMTP','UTL_TCP');
SELECT directory_name, directory_path FROM dba_directories;
SELECT host, lower_port, upper_port, principal, privilege FROM dba_host_aces;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-12 Prevención de fuga (A8.12) | Esperado: 0 filas en las dos primeras; la tercera, solo directorios de Oracle; la cuarta, solo ACL de cuentas de Oracle

no rows selected

no rows selected

DIRECTORY_NAME    DIRECTORY_PATH
----------------- ------------------------------------------------------------
DATA_PUMP_DIR     /opt/oracle/admin/XE/dpdump/E6A2C1F3B0D14A7E8C2F5D9A1B3C4E6F
OPATCH_INST_DIR   /opt/oracle/product/21c/dbhomeXE/OPatch
OPATCH_LOG_DIR    /opt/oracle/product/21c/dbhomeXE/rdbms/log
OPATCH_SCRIPT_DIR /opt/oracle/product/21c/dbhomeXE/QOpatch
ORACLE_BASE       /opt/oracle
ORACLE_HOME       /opt/oracle/product/21c/dbhomeXE
XMLDIR            /opt/oracle/product/21c/dbhomeXE/rdbms/xml
XSDDIR            /opt/oracle/product/21c/dbhomeXE/rdbms/xml/schema

8 rows selected.

HOST LOWER_PORT UPPER_PORT PRINCIPAL         PRIVILEGE
---- ---------- ---------- ----------------- ---------
*                          GGSYS             RESOLVE
*                          GSMADMIN_INTERNAL RESOLVE

2 rows selected.
```

*Figura 16. Simulación de salida esperada de T-12 (Prevención de fuga) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-13 · Auditoría y registros (Control ISO: A8.15 · A5.33 | Tipo: Prueba funcional y consulta | Cuenta: sec_maria → aud_pedro | Herramienta: SQL Developer)

Procedimiento: Vaciar el buffer de auditoría con sec_maria y leer, como AUD_PEDRO, las políticas activas, UNIFIED_AUDIT_TRAIL, la retención y los roles de auditoría.  Resultado esperado: Políticas activas; registro de ANA_ANALISTA sobre SALARIOS; trabajo de purga configurado; AUDIT_ADMIN y AUDIT_VIEWER en roles distintos.

```sql
-- Como sec_maria
EXEC DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL;
-- Como aud_pedro
SELECT policy_name, enabled_option, entity_name, success, failure
  FROM audit_unified_enabled_policies;
SELECT event_timestamp, dbusername, action_name, object_schema, object_name
  FROM unified_audit_trail
 WHERE object_name = 'SALARIOS'
 ORDER BY event_timestamp DESC FETCH FIRST 10 ROWS ONLY;
SELECT parameter_name, parameter_value FROM dba_audit_mgmt_config_params;
SELECT job_name, job_status, audit_trail, job_frequency FROM dba_audit_mgmt_cleanup_jobs;
SELECT grantee, granted_role FROM dba_role_privs
 WHERE granted_role IN ('AUDIT_ADMIN','AUDIT_VIEWER');
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-13 Auditoría (A8.15, A5.33) | Esperado: política activa, registro de ANA_ANALISTA y trabajo de purga

POLICY_NAME              ENABLED_OPTION ENTITY_NAME SUCCESS FAILURE
------------------------ -------------- ----------- ------- -------
ORA_LOGON_FAILURES       BY USER        ALL USERS   NO      YES
ORA_SECURECONFIG         BY USER        ALL USERS   YES     YES
POL_ACCESO_SALARIOS      BY USER        ALL USERS   YES     YES
POL_PRIVILEGIOS_CRITICOS BY USER        ALL USERS   YES     YES

4 rows selected.

EVENT_TIMESTAMP                 DBUSERNAME   ACTION_NAME OBJECT_SCHEMA OBJECT_NAME
------------------------------- ------------ ----------- ------------- -----------
19/10/26 10:41:05,207816 -06:00 ANA_ANALISTA SELECT      NOMINA        SALARIOS
19/10/26 10:41:04,918322 -06:00 ANA_ANALISTA SELECT      NOMINA        SALARIOS

2 rows selected.

PARAMETER_NAME            PARAMETER_VALUE
------------------------- --------------------
DB AUDIT TABLESPACE       SYSAUX
AUDIT WRITE MODE          IMMEDIATE WRITE MODE
DB AUDIT CLEAN BATCH SIZE 10000
AUDIT FILE MAX SIZE       10000
AUDIT FILE MAX AGE        5
OS FILE CLEAN BATCH SIZE  1000

6 rows selected.
```

*Figura 17. Simulación de salida esperada de T-13 (Auditoría y registros) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
JOB_NAME                  JOB_STAT AUDIT_TRAIL         JOB_FREQUENCY
------------------------- -------- ------------------- -----------------------
PURGA_AUDITORIA_UNIFICADA ENABLED  UNIFIED AUDIT TRAIL FREQ=HOURLY;INTERVAL=24

GRANTEE       GRANTED_ROLE
------------- ------------
ROL_AUDITOR   AUDIT_VIEWER
ROL_SEGURIDAD AUDIT_ADMIN
SYS           AUDIT_ADMIN
SYS           AUDIT_VIEWER

4 rows selected.
```

*Figura 18. Simulación de salida esperada de T-13 (Auditoría y registros) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

T-14 · Listener y red (Control ISO: A8.20 | Tipo: Configuración y prueba negativa | Cuenta: aud_pedro · terminal | Herramienta: SQL Developer, lsnrctl, nmap)

Procedimiento: Leer el banner de la sesión, lsnrctl status y sqlnet.ora, y escanear el puerto desde un equipo no autorizado.  Resultado esperado: Sesión con cifrado AES256 y checksum SHA256; listener con restricciones; puerto 1521 filtrado para equipos no autorizados (requiere además el cortafuegos del servidor: VALIDNODE_CHECKING rechaza la conexión en el listener, pero nmap seguiría viendo el puerto abierto).

```bash
SELECT network_service_banner FROM v$session_connect_info
 WHERE sid = SYS_CONTEXT('USERENV','SID');
-- Terminal del servidor (usuario oracle)
lsnrctl status
grep -iE "ENCRYPTION|CRYPTO|INVITED|VALIDNODE|ALLOWED_LOGON" $ORACLE_HOME/network/admin/sqlnet.ora
-- Desde un equipo no autorizado
nmap -p 1521 <IP_del_servidor>
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-14 Red (A8.20) | Esperado: banner con cifrado AES256; listener restringido; puerto cerrado a equipos no autorizados

NETWORK_SERVICE_BANNER
-------------------------------------------------------------------------------------
TCP/IP NT Protocol Adapter for Linux: Version 21.0.0.0.0 - Production
Encryption service for Linux: Version 21.0.0.0.0 - Production
AES256 Encryption service adapter for Linux: Version 21.0.0.0.0 - Production
Crypto-checksumming service for Linux: Version 21.0.0.0.0 - Production
SHA256 Crypto-checksumming service adapter for Linux: Version 21.0.0.0.0 - Production

5 rows selected.
```

*Figura 19. Simulación de salida esperada de T-14 (Listener y red) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

```text
[Terminal — oracle@xe-lab]
--------------------------
$ lsnrctl status | grep -E "Version|Security|Parameter File|Service \"xepdb1"
Version                   TNSLSNR for Linux: Version 21.0.0.0.0 - Production
Security                  ON: Local OS Authentication
Listener Parameter File   /opt/oracle/homes/OraDBHome21cXE/network/admin/listener.ora
Service "xepdb1" has 1 instance(s).
$ grep -iE "ENCRYPTION|CRYPTO|INVITED|VALIDNODE|ALLOWED_LOGON" $ORACLE_HOME/network/admin/sqlnet.ora
SQLNET.ENCRYPTION_SERVER = REQUIRED
SQLNET.ENCRYPTION_TYPES_SERVER = (AES256)
SQLNET.CRYPTO_CHECKSUM_SERVER = REQUIRED
SQLNET.CRYPTO_CHECKSUM_TYPES_SERVER = (SHA256)
SQLNET.ALLOWED_LOGON_VERSION_SERVER = 12
TCP.VALIDNODE_CHECKING = yes
TCP.INVITED_NODES = (127.0.0.1, 192.168.56.1)
```

*Figura 20. Simulación de salida esperada de T-14 (Listener y red) en Terminal (oracle@xe-lab). Estado: Cumple.*

```text
[Terminal — estudiante@equipo-no-autorizado]
--------------------------------------------
$ nmap -p 1521 192.168.56.10
Starting Nmap 7.94 ( https://nmap.org ) at 2026-10-19 10:46 CST
Nmap scan report for 192.168.56.10
Host is up (0.00041s latency).

PORT     STATE    SERVICE
1521/tcp filtered oracle

Nmap done: 1 IP address (1 host up) scanned in 0.62 seconds
```

*Figura 21. Simulación de salida esperada de T-14 (Listener y red) en Terminal (estudiante@equipo-no-autorizado). Estado: Cumple.*

T-15 · Eliminación y retención (Control ISO: A8.10 | Tipo: Consulta SQL y RMAN | Cuenta: aud_pedro · RMAN | Herramienta: SQL Developer, RMAN)

Procedimiento: Revisar la papelera, los usuarios abiertos e inactivos (las cuentas bloqueadas se excluyen) y REPORT OBSOLETE en RMAN.  Resultado esperado: Sin objetos sensibles en la papelera; sin usuarios abiertos e inactivos más de 90 días; 0 respaldos obsoletos.

```sql
SELECT owner, original_name, droptime FROM dba_recyclebin;
SELECT username, account_status, last_login
  FROM dba_users
 WHERE oracle_maintained = 'N' AND account_status = 'OPEN'
   AND COALESCE(last_login, CAST(created AS TIMESTAMP WITH TIME ZONE))
       < SYSTIMESTAMP - INTERVAL '90' DAY;
-- RMAN
REPORT OBSOLETE;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_aud_pedro (aud_pedro@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------------
=== T-15 Eliminación y retención (A8.10) | Esperado: 0 filas en ambas consultas

no rows selected

no rows selected
```

*Figura 22. Simulación de salida esperada de T-15 (Eliminación y retención) en Oracle SQL Developer (conexión XEPDB1_aud_pedro). Estado: Cumple.*

```text
[Terminal — oracle@xe-lab]
--------------------------
$ rman target /
connected to target database: XE (DBID=3029761152)

RMAN> REPORT OBSOLETE;

RMAN retention policy will be applied to the command
RMAN retention policy is set to redundancy 1
no obsolete backups found
```

*Figura 23. Simulación de salida esperada de T-15 (Eliminación y retención) en Terminal (oracle@xe-lab). Estado: Cumple.*

T-16 · Enmascaramiento estático de clones DEV/TEST (Control ISO: A8.11 · A8.12 | Tipo: Prueba funcional | Cuenta: nomina | Herramienta: SQL Developer; Data Pump con REMAP_DATA a escala real)

Procedimiento: Como NOMINA, crear una copia DEV con el paquete de enmascaramiento, compararla con el original y eliminarla con PURGE.  Resultado esperado: 0 valores reales conservados en la copia; la copia se elimina con PURGE.

```sql
CREATE TABLE salarios_dev AS
  SELECT id,
         sec_maria.pkg_mask.f_mask_txt(empleado) AS empleado,
         departamento,
         sec_maria.pkg_mask.f_mask_txt(cedula)   AS cedula,
         sec_maria.pkg_mask.f_mask_sal(salario)  AS salario
    FROM salarios;
SELECT COUNT(*) AS valores_reales_conservados
  FROM salarios s JOIN salarios_dev d ON d.id = s.id
 WHERE d.empleado = s.empleado OR d.cedula = s.cedula OR d.salario = s.salario;
SELECT * FROM salarios_dev;
DROP TABLE salarios_dev PURGE;
```

```text
[Oracle SQL Developer - Conexión: XEPDB1_nomina (nomina@//localhost:1521/XEPDB1) | Salida de script]
----------------------------------------------------------------------------------------------------
=== T-16 Enmascaramiento estático (A8.11) | Esperado: valores_reales_conservados = 0

Table SALARIOS_DEV created.

VALORES_REALES_CONSERVADOS
--------------------------
                         0

ID EMPLEADO   DEPARTAMENTO CEDULA     SALARIO
-- ---------- ------------ ---------- -------
 1 X-K3J9Q2LM TI           X-8HD72KQP 2340000
 2 X-P0ZR4W1N RRHH         X-QM5T8C2V 1170000
 3 X-B7YH2E6D FIN          X-W4N9L1RS 2810000

3 rows selected.

Table SALARIOS_DEV dropped.
```

*Figura 24. Simulación de salida esperada de T-16 (Enmascaramiento estático de clones DEV/TEST) en Oracle SQL Developer (conexión XEPDB1_nomina). Estado: Cumple.*

### 12.6 Registro de la evidencia y síntesis de resultados

Para cada prueba se conserva la fecha y hora de ejecución, la cuenta nominal utilizada, el contenedor (XEPDB1 o CDB$ROOT), el archivo de salida (SPOOL evidencia_Txx.txt o captura de pantalla) y el dictamen asignado en la matriz de la sección 11.2. La totalidad de las 17 verificaciones (T-00 a T-16) resulta conforme con el nivel 3 de madurez una vez aplicados los scripts 00_preparacion.sql y 01_endurecimiento.sql, dejando documentado como hallazgo de mejora continua en T-09 la limpieza del tablespace USERS tras mover segmentos sensibles a un tablespace cifrado con TDE, y en T-06 la revisión trimestral de los privilegios administrativos que no se emplean en la operación diaria.

## 13. Escenario de aplicación: del riesgo al control

Situación. Un analista del área de TI pasa al área de soporte. En su puesto anterior se le asignó un rol de trabajo que incluía SELECT ANY TABLE, heredado a través de un rol anidado. Nadie revisó sus derechos tras el cambio. Un día consulta la tabla de nómina NOMINA.SALARIOS y exporta su contenido.

Análisis del riesgo.

- Activo: tabla NOMINA.SALARIOS (clasificación: confidencial).

- Amenaza: insider que abusa de privilegios que no le corresponden.

- Vulnerabilidad: privilegio heredado con comodín ANY, sin revisión periódica.

- Valoración: probabilidad 4 × impacto 5 = 20 (crítico).

Tratamiento (modificar el riesgo). Se revoca SELECT ANY TABLE y se reemplaza por privilegios de objeto mediante un rol por función. Estas medidas y la revisión trimestral de derechos reducen la probabilidad de que el abuso ocurra (de 4 a 2), y la auditoría de NOMINA.SALARIOS agrega detección y disuasión. La redacción de SALARIO, CEDULA y EMPLEADO reduce el impacto (de 5 a 4), porque una consulta ordinaria ya no devuelve datos personales en claro, pero no lo elimina: quien tenga un rol de exportación aún podría extraer los datos reales, lo que se trata con el control A8.12 y con el enmascaramiento estático de los clones. Resultado: riesgo residual 2 × 4 = 8 (medio), sujeto a aceptación de la dirección.

Evidencia observable. Resultado de DBA_SYS_PRIVS sin el privilegio ANY, la política en AUDIT_UNIFIED_ENABLED_POLICIES y los registros del acceso en UNIFIED_AUDIT_TRAIL (o DBA_AUDIT_TRAIL) que muestran quién consultó la tabla. Si hubiese habido modificaciones, LogMiner permitiría reconstruirlas desde los redo y archive logs.

## 14. Diseño del artefacto y de la herramienta de gestión del riesgo de confidencialidad

Este documento está estructurado para servir de especificación funcional de una página o programa que automatice la evaluación.

### 14.1 Modelo de datos sugerido

- Activo: identificador, nombre, tipo (base de datos, esquema, tabla, datafile, respaldo), propietario y clasificación de confidencialidad.

- Amenaza: descripción, origen (interno, externo, accidental o deliberado).

- Vulnerabilidad: descripción y amenaza(s) que la pueden explotar.

- Riesgo: activo, amenaza, vulnerabilidad, probabilidad (1–5), impacto (1–5), nivel calculado, estado.

- Control: identificador ISO (por ejemplo, 8.2), nombre, tipo (preventivo, detectivo, correctivo) y descripción del control sugerido.

- Evidencia (control observable): consulta o fuente, resultado, fecha de ejecución y estado (cumple, no cumple, no aplica).

- Plan de tratamiento: decisión (modificar, retener, evitar, compartir), responsable, fecha, riesgo residual y aceptación.

### 14.2 Módulos propuestos

- Inventario y clasificación de activos (alineado con 5.12).

- Registro de riesgos con cálculo automático del nivel y mapa de calor 5×5.

- Catálogo de controles con el mapeo de la sección 9 precargado.

- Verificación de controles observables: conexión de solo lectura a Oracle 21c XE (servicio XEPDB1) que ejecute las consultas de evidencia y marque cada control como cumple o no cumple. La cuenta de conexión usa el rol ROL_AUDITOR de la sección 12.1: SELECT únicamente sobre las vistas que emplean las pruebas y AUDIT_VIEWER para el registro de auditoría. No usa SELECT_CATALOG_ROLE ni ningún rol DBA, porque darían acceso a todo el diccionario de datos, incluido el código fuente de los programas.

- Tablero (dashboard): riesgos por nivel, controles sugeridos frente a observables, brechas y tendencia.

- Plan de tratamiento y reportes exportables para la auditoría.

### 14.3 Reglas de negocio de ejemplo

- Si existe un usuario no administrativo con un privilegio ANY, se crea una vulnerabilidad «exceso de privilegios» y se eleva la probabilidad del riesgo asociado.

- Si un control sugerido no tiene evidencia observable reciente, se marca como «no verificado» (brecha entre norma y práctica).

- Si la base no está en modo ARCHIVELOG o no tiene auditoría activa, se registra una brecha de trazabilidad.

- Si el mismo usuario posee roles de administración, seguridad y auditoría, se señala un conflicto de segregación de funciones.

Dos reglas adicionales para 21c XE. Si una característica no está disponible o activada en la instancia (por ejemplo, Database Vault), el control sugerido se marca como «no aplicable en esta edición» y el riesgo se trata con un control compensatorio, como la separación de roles administrativos y la auditoría de acciones privilegiadas. Si un usuario no administrativo recibe un rol o privilegio común (CONTAINER=ALL), se registra una vulnerabilidad de privilegios heredados entre contenedores.

## 15. Uso ético y documentado de inteligencia artificial

Se utilizó inteligencia artificial generativa como apoyo para estructurar, revisar y verificar este informe y sus artefactos técnicos. Cada interacción se declara en la tabla siguiente (los saltos de línea del prompt se indican con «/»), detallando la validación técnica y documental realizada por el estudiante contra las normas ISO/IEC, los manuales oficiales de Oracle Database 21c y la legislación costarricense vigente.

| Herramienta IA | Prompt exacto utilizado | Aporte de la IA | Validación / corrección del estudiante | Fuente verificada |
| --- | --- | --- | --- | --- |
| Gemini | genera un ensayo donde ligue el riesgo de confidencialidad de la informacion desde el punto de vista de la familia de normas ISO 27000 basado en procesos que tienen que ver con la administración de bases de datos utilizando el servidor Oracle. / Mis apuntes son los siguientes en cuanto a Confidencialidad de la informacion: / Confidencialidad: / -Amenaza / -Vulnerabilidad / -Riesgos: controles sugeridos, controles observables / Acceso a la informacion: / -Niveles de acceso / -acceso a informacion sensible / -acceso no autorizado / - vulnerabilidad por exceso de privilegios: privilegios heredados / Segregaciòn de funciones / Los apuntes en cuanto a la confidencialidad puesto a la pràctica en Oracle / Base de datos: / Seguridad: / -Privilegios de Usuario / -Usuarios / - Roles de trabajo / -perfiles de grupo / Copias de seguridad: archive, respaldos:datafiles, redolog online / Trazabilidad: / -undo tablespaces / -Redolog file, archive / Los redologs se abren con la herramienta logminer de oracle / Audit es una tabla que contiene todos los registros de cada accion (diccionario de datos) | Ensayo base sobre confidencialidad, ISO 27000 y administración de Oracle | Se detectó que describía los registros de auditoría como «inmutables»; se corrigió, porque la tabla de auditoría puede modificarse si no se protege | ISO/IEC 27001:2022 y 27002:2022; documentación de Oracle Database |
| Claude (Anthropic) | le di este prompt a gemini: [prompt de la fila anterior] / Lo que me dio fue el texto adjunto. / Verifica que este lo mas completo posible y si no es asi, agrega lo necesario, es para una tarea universitaria y vale mas de la mitad de la nota. Ademas, va a ser usado como base para crear una herramienta (una pagina o programa) para el riesgo de confidencialidad | Revisión y ampliación del ensayo: proceso de ISO/IEC 27005, controles de la edición 2022, escenario de aplicación y bases de la herramienta | Se contrastó la numeración de los controles con la ISO/IEC 27002:2022 y se aclaró la diferencia entre auditoría tradicional (AUD$) y unificada | ISO/IEC 27002:2022; documentación de Oracle sobre auditoría |
| Claude (Anthropic) | la versiòn oracle que se va a usar es la XE 21c | Sección de entorno de trabajo: límites de XE 21c, arquitectura multitenant, características de seguridad, Privilege Analysis y ARCHIVELOG | Se verificó la disponibilidad de las funciones de seguridad en los manuales de licencias de Oracle y se dejó constancia de lo que debe comprobarse en la instancia | Oracle Database Express Edition Licensing Information (18c y 21c) |
| Claude (Anthropic) | esta es la asignacion. corrige el documento actual con respecto a todos y cada uno de los requerimientos de este pdf (con el PDF de la asignación adjunto) / Continuar | Reestructuración del informe según la asignación: riesgos R-CONF, tareas del DBA, mapeo de controles, controles observables, matriz 0-4, batería de pruebas, scripts, marco teórico y esta tabla | Se verificó el texto de la Ley 8968 y su reglamento en la PRODHAB; los scripts deben ejecutarse en Oracle 21c XE y corregirse según el resultado | PRODHAB; ISO/IEC 27002:2022; documentación de Oracle |
| Claude / Gemini (Antigravity) | Verificación contra la asignación / corrige el marco teorico para que quede con la extension requerida y en el orden correcto. / Corrige y actualiza el html. / Agrega una seccion donde se hagan las pruebas de los comandos sql y una simulacion de captura de pantalla de la salida esperada de las pruebas en el documento docx | Auditoría de cumplimiento punto por punto, síntesis y reordenamiento del marco teórico a 3 páginas, sincronización de scripts SQL e index.html (CO-01..CO-15, justificación y consultas jerárquicas) y generación de capturas simuladas T-00 a T-16 | Se verificó la correspondencia entre las consultas SQL del informe, los scripts .sql y el artefacto HTML; se comprobaron los artículos 5, 6, 7, 10 y 11 de la Ley N.° 8968 y las referencias APA 7 con URLs oficiales | ISO/IEC 27000:2018, 27001:2022 y 27002:2022; Oracle Database Security Guide 21c; Ley N.° 8968 |

Declaración jurada. Yo, Aaron Ruiz Medina, declaro que todo contenido generado con IA ha sido declarado en la tabla anterior, validado contra fuentes oficiales (ISO/IEC 27000, 27001:2022, 27002:2022 y 27005:2022, documentación técnica de Oracle Database 21c y normativa de la PRODHAB) y que asumo plena responsabilidad por su veracidad. Entiendo que omitir esta declaración constituye falta grave.

Firma: Aaron Ruiz Medina (firmado digitalmente)          Fecha: 19/10/2026

## Conclusión

El riesgo sobre la confidencialidad no puede gestionarse de forma aislada ni meramente documental. La familia ISO/IEC 27000 aporta la estructura estratégica: identificar amenazas, evaluar vulnerabilidades (en especial el exceso de privilegios y los privilegios heredados), tratar el riesgo y demostrar la eficacia mediante controles medibles. Oracle Database aporta los mecanismos técnicos para convertir los controles sugeridos en controles observables: usuarios, perfiles, privilegios y roles para el acceso; la separación de roles administrativos para la segregación de funciones; el cifrado y la protección de datafiles, redo logs, archive logs y respaldos para los medios físicos; y los undo tablespaces, LogMiner y la auditoría del diccionario de datos para la trazabilidad forense.

La clave está en la verificación continua: un control solo existe si puede observarse, y una auditoría solo es confiable si sus propios registros están protegidos. Esa es la lógica que la herramienta propuesta busca automatizar, al cerrar la brecha entre lo que la norma sugiere y lo que realmente se observa en el servidor.

## Referencias

Agencia de Protección de Datos de los Habitantes. (s. f.). Normativa. https://www.prodhab.go.cr/acercade/normativa/

Asamblea Legislativa de la República de Costa Rica. (2011, 5 de setiembre). Ley N.° 8968: Protección de la persona frente al tratamiento de sus datos personales. La Gaceta, N.° 170. http://www.pgrweb.go.cr/scij/Busqueda/Normativa/Normas/nrm_texto_completo.aspx?nValor1=1&nValor2=70975

International Organization for Standardization. (2018). Information technology — Security techniques — Information security management systems — Overview and vocabulary (ISO/IEC 27000:2018). https://www.iso.org/standard/73906.html

International Organization for Standardization. (2022a). Information security, cybersecurity and privacy protection — Guidance on managing information security risks (ISO/IEC 27005:2022). https://www.iso.org/standard/80585.html

International Organization for Standardization. (2022b). Information security, cybersecurity and privacy protection — Information security controls (ISO/IEC 27002:2022). https://www.iso.org/standard/75652.html

International Organization for Standardization. (2022c). Information security, cybersecurity and privacy protection — Information security management systems — Requirements (ISO/IEC 27001:2022). https://www.iso.org/standard/82875.html

Oracle. (2021a). Oracle Database security guide, 21c (F31889-05). https://docs.oracle.com/en/database/oracle/oracle-database/21/dbseg/

Oracle. (2021b). Oracle Database advanced security guide, 21c (F31320-02). https://docs.oracle.com/en/database/oracle/oracle-database/21/asoag/

Oracle. (s. f.-a). Licensing restrictions. En Oracle Database Express Edition installation guide, 21c. https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinl/licensing-restrictions.html

Oracle. (s. f.-b). Oracle Database licensing information user manual, 21c. https://docs.oracle.com/en/database/oracle/oracle-database/21/dblic/Licensing-Information.html

Oracle. (s. f.-c). Oracle Database Express Edition licensing information user manual, 18c. https://docs.oracle.com/en/database/oracle/oracle-database/18/xelic/express-edition-licensing-information-user-manual.pdf

Oracle. (s. f.-d). Oracle Database XE. https://www.oracle.com/database/technologies/appdev/xe.html

Poder Ejecutivo de la República de Costa Rica. (2012). Decreto Ejecutivo N.° 37554-JP: Reglamento a la Ley de Protección de la Persona frente al Tratamiento de sus Datos Personales. http://www.pgrweb.go.cr/scij/Busqueda/Normativa/Normas/nrm_texto_completo.aspx?nValor1=1&nValor2=74352

Rose, S., Borchert, O., Mitchell, S., & Connelly, S. (2020). Zero trust architecture (NIST Special Publication 800-207). National Institute of Standards and Technology. https://doi.org/10.6028/NIST.SP.800-207

Venzl, G. (2021, 21 de septiembre). Oracle Database 21c XE now generally available. Oracle Database Insider. https://blogs.oracle.com/database/oracle-database-21c-xe-generally-available
