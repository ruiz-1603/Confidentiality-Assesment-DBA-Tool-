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

-- ===== Comandos de terminal y RMAN complementarios (usuario oracle) =====
-- # Antes de la parte B (usuario oracle)
-- mkdir -p /opt/oracle/admin/XE/wallet/tde
-- chmod 700 /opt/oracle/admin/XE/wallet /opt/oracle/admin/XE/wallet/tde
-- 
-- # Destino de respaldos y archive logs
-- chmod 750 /opt/oracle/fast_recovery_area
-- 
-- # Después de las partes B y C: respaldo cifrado (A8.13)
-- rman target / <<'EOF'
-- CONFIGURE ENCRYPTION FOR DATABASE ON;
-- BACKUP DATABASE PLUS ARCHIVELOG;
-- SHOW ALL;
-- EOF

-- ===== Red y listener (/network/admin/sqlnet.ora y listener.ora) =====
-- SQLNET.ENCRYPTION_SERVER = REQUIRED
-- SQLNET.ENCRYPTION_TYPES_SERVER = (AES256)
-- SQLNET.CRYPTO_CHECKSUM_SERVER = REQUIRED
-- SQLNET.CRYPTO_CHECKSUM_TYPES_SERVER = (SHA256)
-- SQLNET.ALLOWED_LOGON_VERSION_SERVER = 12
-- TCP.VALIDNODE_CHECKING = yes
-- TCP.INVITED_NODES = (127.0.0.1, <IP_del_equipo_con_SQL_Developer>)
-- listener.ora: ADMIN_RESTRICTIONS_LISTENER = ON
