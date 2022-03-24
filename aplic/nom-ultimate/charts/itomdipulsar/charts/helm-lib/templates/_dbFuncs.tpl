#===========================================================================
# All of the functions in this file are used for injection of DB parameters.
# An ITOM-wide group had discussed various scenarios for DB parameter injection
# to handle internal (Postgres) DB as well as external (Postgres or Oracle)
# DB.  And ability for global settings which affect all subcharts vs. chart
# specific overrides which would take precedence over global parameters.
#
# The macros in this file handle the various parameters, incluing chart
# specific overrides, etc.
#

#===========================================================================
# dbInternal()
# This function will look for service chart specific "deployment.database.internal"
# value, or default to "global.database.internal".
#
{{- define "helm-lib.dbInternal" -}}
{{- if kindIs "bool" .Values.deployment.database.internal -}}
{{- printf "%t" .Values.deployment.database.internal -}}
{{- else -}}
{{- if kindIs "bool" .Values.global.database.internal -}}
{{- printf "%t" .Values.global.database.internal -}}
{{- end -}}
{{- end -}}
{{- end -}}

#===========================================================================
# dbHost()
# This function will look for service chart specific "deployment.database.host"
# value, or default to "global.database.host".  However, if DB settings are
# "internal" Postgres database, then it will return the internal Postgres instance,
# which might have chart-specific namePrefix.
#
{{- define "helm-lib.dbHost" -}}
{{- if eq "true" (include "helm-lib.dbInternal" .) -}}
{{- printf "%s-postgresql" (default "itom" .Values.namePrefix | lower) -}}
{{- else -}}
{{- if (include "helm-lib.dbUrl" .) -}}
{{- include "helm-lib.getDbHostFromDbUrl" . }}
{{- else if .Values.deployment.database.host -}}
{{- printf "%s" .Values.deployment.database.host -}}
{{- else if .Values.global.database.host -}}
{{- printf "%s" .Values.global.database.host -}}
{{- else -}}
{{- fail "ERROR: Must define database host or database url" -}}
{{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# dbPort()
# This function will look for service chart specific "deployment.database.port"
# value, or default to "global.database.port".  However, if DB settings are
# "internal" Postgres database, then it will return the internal Postgres port.
#
{{- define "helm-lib.dbPort" -}}
{{- if eq "true" (include "helm-lib.dbInternal" .) -}}
{{- printf "%d" (int64 5432) -}}
{{- else -}}
{{- if (include "helm-lib.dbUrl" .) -}}
{{- include "helm-lib.getDbPortFromDbUrl" . }}
{{- else if .Values.deployment.database.port -}}
{{ printf "%d" (int64 .Values.deployment.database.port) -}}
{{- else if .Values.global.database.port -}}
{{- printf "%d" (int64 .Values.global.database.port) -}}
{{- else -}}
{{- fail "ERROR: Must define database port or database url" -}}
{{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# dbName()
# This function will look for service chart specific "deployment.database.name"
# value, or default to "global.database.name".  If neither is defined, and
# database is internal, then "postgres" is returned.  This allows for DB name
# to be injected, even for internal PG (which should be the common scenario),
# but to have a reasonable default value for internal PG, e.g. for CI/CD.
#
{{- define "helm-lib.dbName" -}}
{{- if (include "helm-lib.dbUrl" .) -}}
  {{- include "helm-lib.getDbNameFromDbUrl" . }}
{{- else -}}
  {{- if .Values.deployment.database.dbName -}}
    {{- printf "%s" .Values.deployment.database.dbName -}}
  {{- else -}}
    {{- if .Values.global.database.dbName -}}
      {{- printf "%s" .Values.global.database.dbName -}}
    {{- else -}}
      {{- if eq "true" (include "helm-lib.dbInternal" .) -}}
      {{- printf "postgres" -}}
    {{- else -}}
      {{- $dbType := (include "helm-lib.dbType" .) -}}
        {{- if (eq $dbType "postgresql") -}}
          {{- fail "ERROR: Must define database dbName" -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# getDbNameFromDbUrl()
# Extract the database name from jdbc url.
# For postgresql, if dbUrl should be jdbc:postgresql://host:port/dbName[?param1=v1]. if dbName is empty, database name will be empty
# For postgresql, if dbUrl should be jdbc:oracle:thin:@host:port:sid, jdbc:oracle:thin:@//host:port/serviceName.  database name will be sid or serviceName
#
{{- define "helm-lib.getDbNameFromDbUrl" -}}
{{- if include "helm-lib.dbUrl" . -}}
  {{- if contains "postgresql" (include "helm-lib.dbUrl" .) -}}
    {{- include "helm-lib.trimDbNameFromUrl" ( dict "dbUrl" (trimPrefix "jdbc:postgresql://" (include "helm-lib.dbUrl" .)) "dbType" "postgresql") }}
  {{- else -}}
    {{- if contains "oracle" (include "helm-lib.dbUrl" .) -}}
      {{- include "helm-lib.trimDbNameFromUrl" (dict "dbUrl" (trimPrefix "jdbc:oracle:thin:@" (include "helm-lib.dbUrl" .)) "dbType" "oracle") }}
    {{- else -}}
      {{- fail "ERROR: Not define database url" -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{- fail "ERROR: Not define database url" -}}
{{- end -}}
{{- end -}}


{{- define "helm-lib.trimDbNameFromUrl" -}}
{{- $dbUrl := .dbUrl | lower -}}
{{- $dbType := .dbType | lower -}}
{{- if eq "oracle" $dbType -}}
  {{- if contains "description=" ($dbUrl | lower) -}}
    {{- range $item :=splitList "(" $dbUrl -}}
      {{- if hasPrefix "sid" $item}}
        {{- $tmpArr := split "=" $item }}
        {{- printf "%s"  ($tmpArr._1 | replace ")" "") -}}
      {{- else if hasPrefix "service_name" $item}}
        {{- $tmpArr := split "=" $item }}
        {{- printf "%s" ($tmpArr._1 | replace ")" "") -}}
      {{- end }}
    {{- end }}
  {{- else -}}
    {{- if hasPrefix  "//" $dbUrl -}}
      {{- $tmpArr := split "/" $dbUrl -}}
      {{- printf "%s" $tmpArr._3 -}}
    {{- else -}}
      {{- $tmpArr := split ":" $dbUrl -}}
      {{- printf "%s" $tmpArr._2 -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{- $tmpArr := split "/" $dbUrl -}}
  {{- $tmpArr2 := split "?" $tmpArr._1 -}}
  {{- printf "%s" $tmpArr2._0 -}}
{{- end -}}
{{- end -}}


#===========================================================================
# dbUser()
# This function will look for service chart specific "deployment.database.user"
# value, or default to "global.database.user".  However, if DB settings are
# "internal" Postgres database, then it will return the "postgres" user.
#
{{- define "helm-lib.dbUser" -}}
{{- if .Values.deployment.database.user -}}
{{- printf "%s" .Values.deployment.database.user -}}
{{- else -}}
{{- if .Values.global.database.user -}}
{{- printf "%s" .Values.global.database.user -}}
{{- else -}}
{{- if eq "true" (include "helm-lib.dbInternal" .) -}}
{{- printf "postgres" -}}
{{- else -}}
{{- fail "ERROR: Must define database user" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# dbUserKey()
# This function will look for service chart specific "deployment.database.userPasswordKey"
# value, or default to "global.database.userPasswordKey".  However, if DB settings are
# "internal" Postgres database, then it will return the "ITOM_DB_PASSWD_KEY".
#
{{- define "helm-lib.dbUserKey" -}}
{{- if .Values.deployment.database.userPasswordKey -}}
{{ printf "%s" .Values.deployment.database.userPasswordKey -}}
{{- else -}}
{{- if .Values.global.database.userPasswordKey -}}
{{- printf "%s" .Values.global.database.userPasswordKey -}}
{{- else -}}
{{- if eq "true" (include "helm-lib.dbInternal" .) -}}
{{- printf "ITOM_DB_PASSWD_KEY" -}}
{{- else -}}
{{- fail "ERROR: Must define database userPasswordKey" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# dbAdmin()
# This function will look for service chart specific "deployment.database.admin"
# value, or default to "global.database.admin".  However, if DB settings are
# "internal" Postgres database, then it will return the "postgres" user.
# Note that if createDB==false, then there is no need for dbAdmin user to be
# injected, so empty string ("") is returned.
#
{{- define "helm-lib.dbAdmin" -}}
{{- if (and (not .Values.global.database.createDb) (not .Values.deployment.database.createDb)) -}}
{{- printf "" -}}
{{- else -}}
{{- if eq "true" (include "helm-lib.dbInternal" .) -}}
{{- printf "postgres" -}}
{{- else -}}
{{- if .Values.deployment.database.admin -}}
{{ printf "%s" .Values.deployment.database.admin -}}
{{- else -}}
{{- if (not .Values.global.database.admin) -}}
{{- fail "ERROR: Must define database admin user" -}}
{{- end -}}
{{- printf "%s" .Values.global.database.admin -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# dbAdminKey()
# This function will look for service chart specific "deployment.database.adminPasswordKey"
# value, or default to "global.database.adminPasswordKey".  However, if DB settings are
# "internal" Postgres database, then it will return the "ITOM_DB_PASSWD_KEY".
# Note that if createDB==false, then there is no need for dbAdminKey to be
# injected, so empty string ("") is returned.
#
{{- define "helm-lib.dbAdminKey" -}}
{{- if (and (not .Values.global.database.createDb) (not .Values.deployment.database.createDb)) -}}
{{- printf "" -}}
{{- else -}}
{{- if .Values.deployment.database.adminPasswordKey -}}
{{ printf "%s" .Values.deployment.database.adminPasswordKey -}}
{{- else -}}
{{- if (not .Values.global.database.adminPasswordKey) -}}
{{- if eq "true" (include "helm-lib.dbInternal" .) -}}
{{- printf "ITOM_DB_PASSWD_KEY" -}}
{{- else -}}
{{- fail "ERROR: Must define database adminPasswordKey" -}}
{{- end -}}
{{- else -}}
{{- printf "%s" .Values.global.database.adminPasswordKey -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

#===========================================================================
# dbCreateDb()
# This function will look for service chart specific "deployment.database.createDb"
# value (if true), or default to "global.database.createDb".  
#
{{- define "helm-lib.dbCreateDb" -}}
{{- if (kindIs "bool" .Values.deployment.database.createDb) -}}
{{- if .Values.deployment.database.createDb -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "false" -}}
{{- end -}}
{{- else -}}
{{- if (kindIs "bool" .Values.global.database.createDb) -}}
{{- if .Values.global.database.createDb -}}
{{- printf "true" -}}
{{- else -}}
{{- printf "false" -}}
{{- end -}}
{{-  else -}}
{{- printf "false" -}}
{{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# A previous version of helm-lib functions had "createDb" instead of
# "dbCreateDb", to align with all the other "db*" functions.  This macro
# is here just for backwards-compatibility.
#
{{- define "helm-lib.createDb" -}}
{{- include "helm-lib.dbCreateDb" . -}}
{{- end -}}


#===========================================================================
# dbTlsEnabled()
# This function will look for service chart specific "deployment.database.tlsEnabled"
# value (if true), or default to "global.database.tlsEnabled".  
#
{{- define "helm-lib.dbTlsEnabled" -}}
{{ if kindIs "bool" .Values.deployment.database.tlsEnabled -}}
{{- printf "%t" .Values.deployment.database.tlsEnabled -}}
{{- else -}}
{{- if kindIs "bool" .Values.global.database.tlsEnabled -}}
{{- printf "%t" .Values.global.database.tlsEnabled -}}
{{- else -}}
{{- printf "true" -}}
{{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# dbType()
# This function will look for service chart specific "deployment.database.type"
# value, or default to "global.database.type".  However, if DB settings are
# "internal" Postgres database, then it will return "postgresql".
# Also, the injected value is valdiated to be either "postgresql" or "oracle",
# anything else is an error.
#
{{- define "helm-lib.dbType" -}}
{{- if eq "true" (include "helm-lib.dbInternal" .) -}}
{{- printf "postgresql" -}}
{{- else -}}
{{ $dbType := (coalesce .Values.deployment.database.type .Values.global.database.type) -}}
{{- if eq ($dbType | toString) "<nil>" -}}
{{- if not (coalesce .Values.deployment.database.dbUrl .Values.global.database.dbUrl) -}}
{{- printf "postgresql" -}}
{{- else -}}
{{- if hasPrefix "jdbc:postgresql://" (include "helm-lib.dbUrl" .) -}}
{{- printf "postgresql" -}}
{{- else -}}
{{- if hasPrefix "jdbc:oracle:thin:@" (include "helm-lib.dbUrl" .) -}}
{{- printf "oracle" -}}
{{- else -}}
{{- fail "ERROR: Unrecognized value for dbType, must be 'postgresql' or 'oracle'" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- if (or (eq $dbType "postgresql") (eq $dbType "oracle")) -}}
{{- printf "%s" $dbType -}}
{{- else -}}
{{- fail "ERROR: Unrecognized value for dbType, must be 'postgresql' or 'oracle'" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

#===========================================================================
# dbOracleSid()
# This function will look for service chart specific "deployment.database.oracleSid"
# value, or default to "global.database.oracleSid".  However, if DB type 
# is "postgresql" database, then it will return empty string ("").
#
{{- define "helm-lib.dbOracleSid" -}}
{{- $dbType := (include "helm-lib.dbType" .) -}}
{{- if (eq $dbType "oracle") -}}
{{- if .Values.deployment.database.oracleSid -}}
{{- printf "%s" .Values.deployment.database.oracleSid -}}
{{- else -}}
{{- if .Values.global.database.oracleSid -}}
{{- printf "%s" .Values.global.database.oracleSid -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}


#===========================================================================
# dbOracleConnectionString()
# This function will look for service chart specific "deployment.database.oracleConnectionString"
# value, or default to "global.database.oracleConnectionString".  However, if DB type 
# is "postgresql" database, then it will return empty string ("").
#
{{- define "helm-lib.dbOracleConnectionString" -}}
{{- $dbType := (include "helm-lib.dbType" .) -}}
{{- if (eq $dbType "oracle") -}}
{{- if .Values.deployment.database.oracleConnectionString -}}
{{- printf "%s" .Values.deployment.database.oracleConnectionString -}}
{{- else -}}
{{- if .Values.global.database.oracleConnectionString -}}
{{- printf "%s" .Values.global.database.oracleConnectionString -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

#===========================================================================
# dbOracleServiceName()
# This function will look for service chart specific "deployment.database.oracleServiceName"
# value, or default to "global.database.oracleServiceName".  However, if DB type 
# is "postgresql" database, then it will return empty string ("").
#
{{- define "helm-lib.dbOracleServiceName" -}}
{{- $dbType := (include "helm-lib.dbType" .) -}}
{{- if (eq $dbType "oracle") -}}
{{- if .Values.deployment.database.oracleServiceName -}}
{{- printf "%s" .Values.deployment.database.oracleServiceName -}}
{{- else -}}
{{- if .Values.global.database.oracleServiceName -}}
{{- printf "%s" .Values.global.database.oracleServiceName -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

#===========================================================================
# dbSchema()
# This function will look for the schema name from service chart specific "deployment.database.schema"
# value, or "global.database.schema" value or default to value "public".  However, if DB type
# is not "postgresql" database, then it will return empty string ("") as Oracle have the different mean on schema.
#
{{- define "helm-lib.dbSchema" -}}
{{- $dbType := (include "helm-lib.dbType" .) -}}
{{- if (eq $dbType "postgresql") -}}
{{- if .Values.deployment.database.schema -}}
{{- printf "%s" .Values.deployment.database.schema -}}
{{- else -}}
{{- if .Values.global.database.schema -}}
{{- printf "%s" .Values.global.database.schema -}}
{{- else -}}
{{- printf "public" -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

#===========================================================================
# adminDbName()
# This function will look for database name for admin from service chart specific "deployment.database.dbName"
# value, or "global.database.dbName" value or default to value "postgres".
#
{{- define "helm-lib.adminDbName" -}}
{{- $dbType := (include "helm-lib.dbType" .) -}}
{{- if (eq $dbType "postgresql") -}}
{{- if .Values.deployment.database.adminDbName -}}
{{- printf "%s" .Values.deployment.database.adminDbName -}}
{{- else -}}
{{- if .Values.global.database.adminDbName -}}
{{- printf "%s" .Values.global.database.adminDbName -}}
{{- else -}}
{{- printf "postgres" -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- printf "" -}}
{{- end -}}
{{- end -}}

#===========================================================================
# dbUrl()
# This function will look for service chart specific "deployment.database.dbUrl"
# value, or default to "global.database.dbUrl".
#
{{- define "helm-lib.dbUrl" -}}
{{- if .Values.deployment.database.dbUrl -}}
{{- printf "%s" .Values.deployment.database.dbUrl -}}
{{- else -}}
{{- if .Values.global.database.dbUrl -}}
{{- printf "%s" .Values.global.database.dbUrl -}}
{{- else -}}
{{- if eq (include "helm-lib.dbType" .) "oracle" -}}
{{- $dbOracleConnectionString := (include "helm-lib.dbOracleConnectionString" .) -}}
{{- if $dbOracleConnectionString -}}
{{- printf "jdbc:oracle:thin:@%s" $dbOracleConnectionString -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "helm-lib.getDbHostFromDbUrl" -}}
{{- if include "helm-lib.dbUrl" . -}}
{{- if contains "postgresql" (include "helm-lib.dbUrl" .) -}}
{{- include "helm-lib.trimHostFromUrl" ( dict "dbUrl" (trimPrefix "jdbc:postgresql://" (include "helm-lib.dbUrl" .)) "dbType" "postgresql") }}
{{- else -}}
{{- if contains "oracle" (include "helm-lib.dbUrl" .) -}}
{{- include "helm-lib.trimHostFromUrl" (dict "dbUrl" (trimPrefix "jdbc:oracle:thin:@" (include "helm-lib.dbUrl" .)) "dbType" "oracle") }}
{{- else -}}
{{- fail "ERROR: Not define database url" -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- fail "ERROR: Not define database url" -}}
{{- end -}}
{{- end -}}

{{- define "helm-lib.trimHostFromUrl" -}}
{{- $dbUrl := .dbUrl | lower -}}
{{- $dbType := .dbType | lower -}}
{{- if eq "oracle" $dbType -}}
{{- if contains "description=" ($dbUrl | lower) -}}
{{- range $item :=splitList "(" $dbUrl -}}
{{- if hasPrefix "host" $item}}
{{- $tmpArr := split "=" $item }}
{{- printf "%s" $tmpArr._1 | replace ")" "" -}}
{{- end }}
{{- end }}
{{- else -}}
{{- $tmpArr := split ":" $dbUrl -}}
{{- printf "%s" $tmpArr._0 -}}
{{- end -}}
{{- else -}}
{{- $tmpArr := split ":" $dbUrl -}}
{{- printf "%s" $tmpArr._0 -}}
{{- end -}}
{{- end -}}

{{- define "helm-lib.getDbPortFromDbUrl" -}}
{{- if include "helm-lib.dbUrl" . -}}
{{- if contains "postgresql" (include "helm-lib.dbUrl" .) -}}
{{- include "helm-lib.trimPortFromUrl" ( dict "dbUrl" (trimPrefix "jdbc:postgresql://" (include "helm-lib.dbUrl" .)) "dbType" "postgresql") }}
{{- else -}}
{{- if contains "oracle" (include "helm-lib.dbUrl" .) -}}
{{- include "helm-lib.trimPortFromUrl" (dict "dbUrl" (trimPrefix "jdbc:oracle:thin:@" (include "helm-lib.dbUrl" .)) "dbType" "oracle") }}
{{- else -}}
{{- fail "ERROR: Not define database url" -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- fail "ERROR: Not define database url" -}}
{{- end -}}
{{- end -}}

{{- define "helm-lib.trimPortFromUrl" -}}
{{- $dbUrl := .dbUrl | lower -}}
{{- $dbType := .dbType | lower -}}
{{- if eq "oracle" $dbType -}}
{{- if contains "description=" ($dbUrl | lower) -}}
{{- range $item :=splitList "(" $dbUrl -}}
{{- if hasPrefix "port" $item}}
{{- $tmpArr := split "=" $item }}
{{- printf "%d" (int64 ($tmpArr._1 | replace ")" "")) -}}
{{- end }}
{{- end }}
{{- else -}}
{{- $tmpArr := split ":" $dbUrl -}}
{{- printf "%d" (int64 $tmpArr._1) -}}
{{- end -}}
{{- else -}}
{{- $tmpArr := split ":" $dbUrl -}}
{{- $tmpArr2 := split "/" $tmpArr._1 -}}
{{- printf "%d" (int64 $tmpArr2._0) -}}
{{- end -}}
{{- end -}}
