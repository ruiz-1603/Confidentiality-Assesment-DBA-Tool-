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
