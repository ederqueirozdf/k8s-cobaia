A Helm chart for BVD, expecting suite-related fields to be specified in values.yaml. 
This includes namespace, approle, approleid, database host and port

Credentials for DB are expected in Vault.

Redis is creating its own password if not present in Vault.
