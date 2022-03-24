This is Micro Focus Postgres Database.

By default a single instance is created, and injected into other Helm charts as
the "global.postgres.instance".

However, a Helm chart which requires Postgres can also create their own dedicated
instance of Postgres, by declaring the "postgres.serviceName" they want to use,
in addition to "postgres.consumerName". 
