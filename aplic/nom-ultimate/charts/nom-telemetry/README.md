# Telemetry Image Chart
(c) Copyright 2018-2021 Micro Focus or one of its affiliates.

This is Micro Focus Network Operations Management Content for Telemetry Collector. The chart in this project 
is used to deploy the telemetry component into a kubernetes environment. 

## Standard Features Observed

### UID/GID of the process
The UID and the GID of the installation can be controlled through the 

### Logging Volume


## Telemetry Features
### NodePorts 
Node ports are used to connect the outside kubernetes world to the server. Nodeports are established on each 
node in the cluster and will forward traffic into the Telemetry service. NodePorts are exposed for grpc, and grpcs 
traffic. The default node ports are (grpc 35500, grpcs 35543).

### Feature Flags
Feature flags have been defined to allow control over what ports on the system are open for communications. If tls
is disabled, then the grpcs nodeport on internal ports will not be open for communications. 

#### TLS Enabled
To enable or disable TLS you can add the following entry to your values.yaml file or provide the equivalent dotted 
notation property configuration.  To disable:
```
helm upgrade .... --set telemetry.tls.enabled=false
```
or to enable:
```
helm upgrade .... --set telemetry.tls.enabled=true
```

#### NON-TLS Enabled
To enable or disable TLS you can add the following entry to your values.yaml file or provide the equivalent dotted
notation property configuration.  To disable:
```
helm upgrade .... --set telemetry.nontls.enabled=false
```
or to enable:
```
helm upgrade .... --set telemetry.nontls.enabled=true
```

# Composite Chart Usage
If this chart is included as a composite chart, then the entries for the values and properties will need to be 
prefixed with the chart name within the composit chart. This would typically be nom-telemetry.

Hence to set values in a composite environment for the following property:
```
--set telemetry.nodeport.grpcs=36543
```
would become:
```
--set nom-telemetry.telemetry.nodeport.grpcs=36543
```

Similarly if the value were specified in the values.yaml file, it would change from:

```
telemetry:
  nodeport:
    grpcs: 36543
```

would become:

```
nom-telemetry:
  telemetry:
    nodeport:
      grpcs: 36543
```
