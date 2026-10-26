-- DBA Confidentiality Assessment · Scripts de verificación (Oracle 21c XE, PDB XEPDB1)
-- Archivo sincronizado con 02_verificacion.sql y el informe técnico (Sección 12.4 y 12.5).
-- Ejecutar en SQL Developer, modo script (F5), después de 00_preparacion.sql y 01_endurecimiento.sql.

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
