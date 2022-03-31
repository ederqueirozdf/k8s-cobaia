# Network Operations Management (NOM) 2021.11
### Ultimate Edition, Version: 1.5.0+20211100.162

Micro Focus Network Operations Management (NOM) Ultimate
delivers continual network discovery, topology, fault, availability, diagnostics and performance metrics, traffic
and quality assurance monitoring, configuration backups, device OS upgrades, change history, automated root-cause
analysis for dynamic network environments, executive dashboards, customized reporting along with network
orchestration, advanced networking services (IPT, MPLS, IP-MC) and integrated security and compliance.

## TL;DR;

```
helm install --namespace <NAMESPACE> nom-ultimate-1.5.0+20211100.162.tgz
```

> NOTE: There are 3 parameters which **must** be defined.  Deployment will abort if these are not defined.

    acceptEula: set to "true" to accept the Micro Focus EULA (see link at the end of this README).
    global.externalAccessHost: set to your <FQDN>.
    global.externalAccessPort: set to the desired HTTPS access <PORT>.

In addition, you must specify one of two different modes for persistent storage.  Either dynamic PVC-creation or
manual PVC-creation.  Chart deployment will fail unless you specify this.  See the "Persistence" section below for details.


## Introduction

NOM Ultimate delivers the following capabilities:

* **Network Executive Dashboards**:

  Network executive dashboards provide real-time views of the network infrastructure to understand operational performance and business impact by bringing business intelligence to IT data.  Executives can visualize status and statistics through business and IT KPIs to make informed decisions.

* **Collect Once Store Once (COSO)** _[Limited availability - intended for non-production use only]_:

  Collect Once Store Once (COSO) brings together data collection and storage to receive and process high volumes of data from independent data sources.  It provides a scalable data pipeline to ingest and store data optimally with a capacity to handle different data formats.

* **NOM UI and Collect Once Store Once (COSO)** _[Limited availability - intended for non-production use only]_:

  NOM UI is a next-generation customizable and persona-based user interface that unifies network data from monitoring, automation, compliance, and orchestration into actionable insights.  NOM UI provides a single-pane view to monitor & manage the health and compliance of network devices.  This selection also installs COSO, which brings together data collection and storage to receive and process high volume of data from independent data sources.

## Prerequisites

This Helm chart assumes that you have installed the Micro Focus Container Deployment Foundation (CDF).
And that during the CDF installation, you provided a "config.json" file which had specified "deploymentMode: helm".

At the time of CDF installation, you provided a Kubernetes namespace (using either "-n <NAMESPACE>" or "-d <DEPLOYMENT>" parameter).
You will be deploying NOM Ultimate into this namespace.

There are several password values that must be injected into the environment.  These passwords must be
entered using the "generate_secrets" tool, with this Helm chart as a parameter, e.g.:

```
/opt/kubernetes/scripts/generate_secrets --namespace <NAMESPACE> --chart nom-ultimate-1.5.0+20211100.162.tgz
```

This will query several passwords, which are converted to Kubernetes secrets and used at deployment time.

## Installing the Chart

To install the chart with release name `my-release`:

```
helm install --namespace <NAMESPACE> --name my-release nom-ultimate-1.5.0+20211100.162.tgz
```

The above command will deploy NOM Ultimate into the Kubernetes cluster, using the default configuration.
The [configuration](#configuration) section lists the parameters that can be configured during installation.

> NOTE: As mentioned earlier, there are 4 parameters which **must** be defined.  Deployment will abort if these are not defined.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```
helm delete my-release
```

## Configuration

In this section there are several tables which list configuration parameters for NOM, and their default values.

The following parameters are required.  The installation will fail without these values being defined:

| Parameter                        | Description                                                   | Default value            |
| -------------------------------- | ------------------------------------------------------------- | ------------------------ |
| `acceptEula`                     | You must accept the Micro Focus EULA (see end of this README for the link) | false                    |
| `global.externalAccessHost`      | Externally accessible hostname/FQDN                           | not defined, but required to be defined at deployment time |
| `global.externalAccessPort`      | Externally accessible port                                    | not defined, but required to be defined at deployment time |

In addition to the above required parameters, there is another (optional) port-related parameter which is appropriate to mention now:

| Parameter                        | Description                                                   | Default value            |
| -------------------------------- | ------------------------------------------------------------- | ------------------------ |
| `global.nginx.httpsPort`         | Externally accessible port for NGINX ingress (see note)       |  equal to global.externalAccessPort defined above  |

> NOTE: As mentioned, the value of `global.externalAccessPort` will also be used as the default value of `global.nginx.httpsPort`.  However if you have a hardware load-balancer in front of your Kubernetes cluster, then these two values might be different.  The `global.externalAccessPort` would match the _external_ port visible to users accessing the load-balancer.  The `global.nginx.httpsPort` would match the ingress into the Kubernetes side of the load-balancer.  See the following diagram for clarification:

    +------+                              +---------------+                           +---------+
    | User | ---- externalAccessPort ---> | Load Balancer | ---- nginx.httpsPort ---> | Cluster |
    +------+                              +---------------+                           +---------+

The following parameters control whether certain features are selected, which also affects the sub-charts that are deployed:

| Parameter                                 | Description                                              | Default value            |
| ----------------------------------------- | -------------------------------------------------------- | ------------------------ |
| `global.coso.isSelected`                  | Enable/disable deployment of COSO feature                | true                     |
| `global.bvd.isSelected`                   | Enable/disable deployment of Executive Dashboard feature | true                     |
| `global.oo.isSelected`                    | Enable/disable deployment of OO central and OO designer  | false                    |
| `global.perfTroubleshooting.isSelected`   | Enable/disable Performance troubleshooting               | false                    |
| `global.vertica.embedded`                 | Enable/disable embedded Vertica (POC only)               | false                    |

As mentioned, `global.vertica.embedded` is for proof-of-concept (POC) only.  In production environments, the Vertica DB server
must be a highly-available, highly-performant system.  However for POC purposes, this Helm chart can deploy a containerized instance
of the Vertica DB within the cluster.  This containerized instance of Vertica is useful to demonstrate product features, etc.
but only a __very small__ scale.  If `global.vertica.embedded=false`, then you must configure parameters for connnecting to
your external Vertica DB server, details are found below.

You can define your local Kubernetes image registry:

| Parameter                        | Description                | Default value    |
| -------------------------------- | -------------------------- | ---------------- |
| `global.docker.registry`         | Docker registry            | "docker.registry.net" |
| `global.docker.orgName`          | Docker orgName             | "hpeswitom"      |
| `global.docker.imagePullPolicy`  | Docker image pull policy   | "IfNotPresent"   |
| `global.docker.imagePullSecret`  | Docker image pull secret   | ""               |

The following parameters control persistence of data.  For this release you must inject PVCs which have been previously created:

| Parameter                               | Description                         | Default value    |
| --------------------------------------- | ----------------------------------- | ---------------- |
| `global.persistence.enabled`            | Enables dynamic PVC creation        | false                                        |
| `global.persistence.configVolumeClaim`  | PVC for configuration files         | not defined, but required at deployment time |
| `global.persistence.dataVolumeClaim`    | PVC for data files                  | not defined, but required at deployment time |
| `global.persistence.dbVolumeClaim`      | PVC for database files, should be "fast" storage if available  | not defined, but required at deployment time |
| `global.persistence.logVolumeClaim`     | PVC for log files                   | not defined, but required at deployment time |
| `global.persistence.configVolumeSize`   | Size of PVC for configuration files | "1Gi" |
| `global.persistence.dataVolumeSize`     | Size of PVC for data files          | "1Gi" |
| `global.persistence.dbVolumeSize`       | Size of PVC for database files      | "5Gi" |
| `global.persistence.logVolumeSize`      | Size of PVC for log files           | "1Gi" |

The following parameters are used for the case where NPS is used as the data source:

| Parameter                               | Description                                 | Default value            |
| --------------------------------------- | ------------------------------------------- | ------------------------ |
| `global.perfTroubleshooting.isSelected` | Enable/disable Performance troubleshooting  | false                    |
| `itomnomcosodataaccess.sybase.host`     | Sybase hostname for NPS data source         | not defined, but required at deployment time |
| `itomnomcosodataaccess.sybase.port`     | Sybase port for NPS data source             | not defined, but required at deployment time |
| `itomnomcosodataaccess.sybase.user`     | Sybase username for NPS data source         | not defined, but required at deployment time |
| `itomnomcosodataaccess.sybase.db`       | Sybase database name for NPS data source    | not defined, but required at deployment time |

Other miscellaneous parameters:

| Parameter                        | Description             | Default value    |
| -------------------------------- | ----------------------- | ---------------- |
| `global.securityContext.user`    | user ID for deployment  | 1999             |
| `global.securityContext.fsGroup` | group ID for deployment | 1999             |

> NOTE: CDF by default uses UID:GID 1999:1999.  However you can change this by providing an alternate value during cluster creation as well as PV (Physical Volume) creation.

To define/inject any of the values listed above, you can do so directly on the command line, for example:

```
helm install --namespace <NAMESPACE> --name my-release \
  --set global.coso.isSelected=false --set global.persistence.enabled=true ... \
  nom-ultimate-1.5.0+20211100.162.tgz
```

Alternatively, the preferred method is to create a YAML file (e.g. "my-values.yaml") that specifies the values for the parameters and provide that while installing the chart. For example,

```
helm install --namespace <NAMESPACE> --name my-release -f my-values.yaml nom-ultimate-1.5.0+20211100.162.tgz
```

> **Tip**: You can examine/use the default [values.yaml](values.yaml)

#### NOM Mixed Mode vs. containerized Mode

The following parameters are used to configure "Mixed Mode" vs. "containerized Mode" deployments of NOM Ultimate.
In "containerized Mode" deployments, several NOM services,
(e.g Network Montitoring with NNMi and
Network Configuration with NA),
would be deployed into the Kubernetes cluster.
"Mixed Mode" is for customers who have existing instances of these services, and
enables connection of those existing services with the value added functionality of NOM (e.g.
Executive Dashboards and COSO).

However NOM Ultimate only supports "Mixed Mode", which requires that the external NNMi and NA
server parameters (host:port) must be defined, as seen in the following table:

| Parameter                 | Description                             | Default value                 |
| ------------------------- | --------------------------------------- | ----------------------------- |
| `global.nnmi.host`           | [Mixed mode only] NNMi server           | ""                            |
| `global.nnmi.failoverHost`   | [Mixed mode only] NNMi failover server  | "", optional                  |
| `global.nnmi.port`           | [Mixed mode only] NNMi port             | ""                            |
| `global.na.host`             | [Mixed mode only] NA server             | ""                            |
| `global.na.port`             | [Mixed mode only] NA port               | ""                            |
| `global.traffic.host`        | [Mixed mode only] Traffic server        | ""                            |
| `global.traffic.port`        | [Mixed mode only] Traffic port          | ""                            |
| `global.qos.host`            | [Mixed mode only] Network QoS server    | ""                            |
| `global.qos.port`            | [Mixed mode only] Network QoS port      | ""                            |

Either `global.nnmi.host` or `global.na.host` (or both) must be provided,
along with the corresponding ".port" values.  The Traffic and QoS parameters are optional.

#### Connecting to External Vertica Database


The following parameters are used to connect to a Vertica database:

| Parameter                    | Description                                  | Default value            |
| ---------------------------- | -------------------------------------------- | ------------------------ |
| `global.vertica.host`        | Hostname of Vertica DB server                | not defined, but required for external Vertica |
| `global.vertica.port`        | Port of Vertica DB                           | not defined, but required for external Vertica |
| `global.vertica.db`          | Database name within the Vertica DB          | not defined, but required for external Vertica |
| `global.vertica.rwuser`      | DB user which has Read/Write capabilities    | not defined, but required for external Vertica |
| `global.vertica.rouser`      | DB user which has Read-only capabilities     | not defined, but required for external Vertica |
| `global.vertica.tlsEnabled`  | Whether to use TLS or not for DB connections | false |

As mentioned earlier, there is a `global.vertica.embedded` flag, which is supported for proof-of-concept (POC) only.
This embedded Vertica instance is only useful for very small scale.  If embedded Vertica is selected, then none of the
above parameters for Vertica host:port, user, DB, etc. are required.
However, since the default value for `global.vertica.embedded=false`, then the above Vertica parameters **are** required.

> NOTE: To use TLS with Vertica, you will also need to inject the SSL certificate for the Vertica server at deployment time.  Details about injecting SSL ceritficates is described later in this README.

### Manage certificate secrets with helm

There are 3 ways to inject this certificate, each of which will be described in detail:

  1. On the command line, using "--set-file" parameter.
  2. In a YAML file (e.g. "my-values.yaml), as a single-line base64 encoded string.
  3. In a YAML file, as a multi-line PEM string.

**1. Using --set-file Parameter:**

For the first option, you would provide the full pathname to the file containing the Vertica certificate, along with the other parameters, e.g.:

```
helm install ... --set-file "global.vertica.cert.vertica-ca\.crt"=/path/to/vertica.crt ... nom-ultimate-1.5.0+20211100.162.tgz
```

Note that it is **very important** to escape the "." character between "vertica-ca" and "crt", resulting in "vertica-ca\.crt".
Also the entire string, i.e. `global.vertica.cert.vertica-ca\.crt` must be surrounded by double-quotes.
Both (the quotes and the backslash) are required because of how the Linux shell evaulates/expands the CLI before invoking
the "helm" command.  Failure to do either of these will result
in a slightly different string being injected into the Helm deployment and will likely fail.

**2. Single-line Base64 Encoded Value in a YAML File:**

For the second option, you would first get the base64 encoded value for your certificate, e.g.:

```
base64 -w 0 /path/to/vertica.crt > my-cert.yaml
```

This would result in a really long line being printed, resulting in a new file, called "my-cert.yaml".  The contents of this file would
look something like the following:

```
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tC0hkbVZ5ZEdsallUQ...(line-truncated)
```

You will need to edit this file, e.g. using "vi" editor, and convert it YAML syntax for injecting into Helm CLI.
The result would look like the following:

```
global:
  vertica:
    certEncoded:
      vertica-ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tC0hkbVZ5ZEdsallUQ...(line-truncated)
```

Note the indentation, the ":" characters, and having the line "client01.crt: <REALLY_LONG_STRING>".

By doing the above, you have just created a new YAML file, i.e. "my-cert.yaml".  The reason this was being demonstrated is because
you can pass multiple "-f" parameters to the "helm" command line, and thus you would inject this certifcate by adding this YAML, as follows:

```
helm install ... -f my-values.yaml -f my-cert.yaml ... nom-ultimate-1.5.0+20211100.162.tgz
```

Note the use of two "-f" parameters, the one which contains all the properties for your deployment, and a separate one for the certificate.
This is also useful for when your certificate expires (for example), and a new certificate must be injected.  You have separated 
the certificate from the other deployment-specific properties, and only need to provide a new certificate.

**3. Multi-line PEM Encoded Value in a YAML File:**

A PEM encoded string is the typical multi-line certificate, which looks looks like the following:

```
-----BEGIN CERTIFICATE-----
MIIDWDCCAkCgAwIBAgIUDv1FBwEnwDiZnVtn5A0VRLHcS1swDQYJKoZIhvcNAQEL
BQAwEjEQMA4GA1UEAwwHdmVydGljYTAeFw0xOTA4MDEwNTM3MDVaFw0yOTA3Mjkw
... (multiple lines)
-----END CERTIFICATE-----
```

This multi-line value can be injected as the certificate.  As in the example above, you could create a separate
YAML file which contains this certificate, and at Helm deployment time use two (or more) "-f" parameters.
First, copy the certificate file to be a YAML file, for example:

```
cp /path/to/vertica.crt my-cert.yaml
```

At this point, the two files are identical.  But now you will edit the my-cert.yaml to convert it to YAML syntax, as follows:

```
global:
  vertica:
    cert:
      vertica-ca.crt: |
        -----BEGIN CERTIFICATE-----
        MIIDWDCCAkCgAwIBAgIUDv1FBwEnwDiZnVtn5A0VRLHcS1swDQYJKoZIhvcNAQEL
        BQAwEjEQMA4GA1UEAwwHdmVydGljYTAeFw0xOTA4MDEwNTM3MDVaFw0yOTA3Mjkw
        ... (multiple lines)
        -----END CERTIFICATE-----
```

There are two important notes about the above example. 1) You must have the vertical bar (i.e. "|") at the end of the "```client01.crt: |```" entry.
And 2) the entire PEM string has been indented by 8 characters, so that it is indented by two spaces relative to the line above it.

> NOTE: If you have another value immediately following the "--END CERTIFICATE--" line, it is recommended to put a blank line between, just for readability.

Again, to use this file you would pass two -f parameters the "helm" command line, e.g.:

```
helm install ... -f my-values.yaml -f my-cert.yaml ... nom-ultimate-1.5.0+20211100.162.tgz
```

**Injecting Other Certificates:**

The injection of the certificate for the external Vertica database server is shown above.
For injecting other certificates, e.g. external NNMi server, external NA server, or external
Postgres database server, you would do similar to above, but instead of creating
the YAML property `global.vertica.cert.vertica-ca.crt`, you are creating multiple properties
that start with "caCertificates.*".  For example, using --set-file parameter:

```
helm install ... --set-file "caCertificates.nnmi\.crt"=/path/to/nnmi.crt ... nom-ultimate-1.5.0+20211100.162.tgz
```

Or base64 string converted to YAML property:

```
caCertificates:
  postgres.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tC0hkbVZ5ZEdsallUQ...(long base64 encoded line truncated)

```

or multi-line PEM-encoded string converted to YAML property:

```
caCertificates:
  nnmi.crt: |
    -----BEGIN CERTIFICATE-----
    MIIDWDCCAkCgAwIBAgIUDv1FBwEnwDiZnVtn5A0VRLHcS1swDQYJKoZIhvcNAQEL
    BQAwEjEQMA4GA1UEAwwHdmVydGljYTAeFw0xOTA4MDEwNTM3MDVaFw0yOTA3Mjkw
    ... (multiple lines)
    -----END CERTIFICATE-----
```

For either of the latter two methods you would pass the certificates into the Helm CLI:

```
helm install ... -f my-values.yaml -f my-cert.yaml ... nom-ultimate-1.5.0+20211100.162.tgz
```

## Replication

> NOTE: NOM does not support scale out at this time.

## Persistence

NOM requires 4 Persistent Volume Claims (PVCs):

  1. Configuration Volume
  2. Data Volume, i.e. data files
  3. Database Volume, i.e. for Postgres/Vertica database.  It is recommended that this be "fast" storage.  Also typical backup tools would not be appropriate for these files.
  4. Log Files Volume

There are two differnt modes for persistent storage:

  1. Dynamic PVC creation.  Helm will auto-create PVCs during deploy, and release these PVCs during undeploy.
  2. Manual PVC creation.  You must create the 4 PVCs manually, and inject the names of these claims into the chart at deployment time.

For Dynamic PVC creation, simply define "global.persistence.enabled=true" parameter during your deployment, e.g.:

```
global:
  persistence:
    enabled: true
```

For Manual PVC creation, you must first manually create the 4 PVCs as specified above (refer to Micro Focus or Kubernetes
documentation) and inject the names of each volume claim into the chart at deployment time (e.g. inside "my-values.yaml"), as follows:

```
global:
  persistence:
    configVolumeClaim: <NAME_OF_PVC_FOR_CONFIGURATION>
    dataVolumeClaim: <NAME_OF_PVC_FOR_DATA_FILES>
    dbVolumeClaim: <NAME_OF_PVC_FOR_DATABASE>
    logVolumeClaim: <NAME_OF_PVC_FOR_LOG_FILES>
```

Note you also can **mix** the two methods, e.g. manually create 2 of the 4 PVCs in inject the names of those volume claims, and the
**also** specify global.persistence.enabled=true.  If a PVC claim name is injected, it will take precedence over dynamic PVC creation,
for that specific claim.  Here is an example where dbVolumeClaim PVC is injected, and the other 3 PVCs would be dynamically created/released:

```
global:
  persistence:
    enabled: true
    dbVolumeClaim: <NAME_OF_PVC_FOR_DATABASE>
```

Since dbVolumeClaim is specified, that manually-created PVC is used for database files.  And the other 3 PVCs would be created

## Upgrading

With Helm, an "upgrade" is any change to a running deployment.  This _can be_ an actual upgrade, i.e. upgrading from an
older version of the chart to a newer version of the chart.  But it might also be the _same_ chart version, but with different
configuration parameters injected into the deployment.  Just like at install time, you can use the "--set" CLI parameter
or edit the YAML file (e.g. my-values.yaml) and change properties in that file.

```
helm upgrade my-release -f my-values.yaml nom-ultimate-1.5.0+20211100.162.tgz
```

## Rollback

With Helm, a "rollback" is a way to go back to a specific deployed "revision" of the chart.  That is, the initial "helm install" is
revision "1", and then subsequent "upgrade" or "rollback" operations will generate a new revision ("2", "3", "4", etc.).
You first look at the history of the deployment (e.g. "my-release" as used above) and then choose the desired revision,
and then rollback to that point in time.  For example:  

```
helm history my-release
helm rollback my-release 3
```

Note: Unlike the "upgrade" command, the "rollback" command does **NOT** allow you to inject different configuration parameters.
It will rollback to the _exact_ configuration which was deployed at revision "3".  You could then use the "upgrade"
command to change configuration parameters, after having rolled back to a previous revision. 

## Links

- Read product documentation - <https://docs.microfocus.com/itom/Network_Operations_Management:2021.02Home>
- Read product brief - <https://docs.microfocus.com/itom/ITOM:Network_Operations_Management/Home>
- Meet your peers - <https://community.microfocus.com/t5/Network-Operations-Management/ct-p/NOM>
- Contact Support - <https://softwaresupport.softwaregrp.com/>
- Looking for more information - <https://www.microfocus.com/en-us/products/network-operations-management-suite/overview>

### (c) Copyright 2019-2020 Micro Focus

- Software License Agreement - <https://www.microfocus.com/en-us/legal/software-licensing>
