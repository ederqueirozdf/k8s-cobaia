{{/*===========================================================================
   * helm-lib.pvcStorage(claim:<CLAIM>, Release:Release, Template:Template, Values:Values)
   * This macro will expand a volume claim reference into the generated YAML at deploy time.
   * The macro takes the name of a claim, e.g. "dataVolumeClaim".
   *
   * If "global.persistence."<CLAIM> is defined, then that specific PVC will be used.
   * This enables the customer to inject a specific desired PVC, which must already exist 
   * or else the pods will be in "Pending" state waiting for this PVC.
   * 
   * Otherwise if "global.persistence.enabled==true", then it is expected that the PVC will
   * be created by the Composition chart, using the typical Release.Name prefix e.g.
   * "cold-fish-dataVolumeClaim".  It is expected that there are sufficient PVs available
   * so that all required PVCs can be created dynamically.
   * 
   * Otherwise, this macro will allow ephemeral storage ("emptyDir") if "global.isDemo==true".
   * The intention is to have the customer "opt in" to ephemeral storage, for POC.
   * 
   * If none of the above are true (claim not specified, auto-persistence not enabled, and
   * isDemo not true), then a chart-rendering error will result at deployment time, thus
   * preventing the customer from deploying the chart.
   *
   */}}
{{- define "helm-lib.pvcStorage" -}}
{{- $fullClaimName := cat ".Values.global.persistence." .claim | nospace -}}
{{- $claimRef := cat "{{ " $fullClaimName " }}" -}}
{{- if tpl $claimRef . -}}
persistentVolumeClaim:
  claimName: {{ tpl $claimRef . -}}
{{- else -}}
{{- if .Values.global.persistence.enabled }} 
persistentVolumeClaim:
  claimName: {{ include "helm-lib.pvcStorageName" ( dict "claim" .claim "Release" .Release "Values" .Values ) }}
{{- else -}}
{{- if not .Values.global.isDemo -}}
{{- cat "\nERROR: PVC storage (" $fullClaimName ") is not defined, and neither auto-PVC (global.persistence.enabled) nor demo mode (global.isDemo) is enabled" | fail -}}
{{- else -}}
emptyDir: {}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}



{{/*===========================================================================
   * helm-lib.pvcStorageName(claim:<CLAIM>, Release:Release, Values:Values)
   * This macro will expand to the name of an auto-generated PVC.  It is expected
   * to be called only from PVC YAMLs, found in composition charts.
   */}}
{{- define "helm-lib.pvcStorageName" -}}
{{- if not .Values.global.persistence.enabled -}}
{{- cat "\nERROR: pvcStorageName() should only be invoked if global.persistence.enabled==true" | fail -}}
{{- else -}}
{{ .Release.Name }}-{{ .claim | lower }}
{{- end -}}
{{- end -}}



{{/*===========================================================================
   * helm-lib.validateStorageClass(
   *   pvcName:<pvcName>                                                  Name of the PVC of this storage spec (used for the upgrade validation)
   *   storageClass:<storageClassName>                                    Name of the storageClass for the PVC
   *   storageClassKey:<keyName>                                          Name of the setting key in values.yaml that sets the storageClass
   *   Release:.Release, Values:.Values)                                  .Release and .Values must be passed for the processing
   *
   * Example:
   * {{- include "helm-lib.validateStorageClass" ( dict "pvcName" "fast-rwo-vol3" "storageClass" "fast-disk"
   *               "storageClassKey" ".global.persistence.storageClasses.fast-rwo" "Release" .Release "Values" .Values) }}
   * 
   */}}

{{- define "helm-lib.validateStorageClass" -}}
  {{- if .Release.IsUpgrade }}
    {{- $pvc :=  lookup "v1" "PersistentVolumeClaim" .Release.Namespace .pvcName }}
    {{- if  $pvc  }}
    {{- /* compare the storageClassName with the one in the existing PVC; fail if not the same, and let the customer change the setting or fix the deployed PV/PVC */ -}}
      {{- if ne ( .storageClass | default "" )  ( $pvc.spec.storageClassName | default "" ) -}}
        {{ printf "\n\nERROR: It is not possible to change the storageClassName for PVC \"%s\" to \"%s\", it is already set to \"%s\" in the existing PVC.\n       Set \"%s\" to \"%s\", or modify the existing PVC and PV to your desired storage class." .pvcName .storageClass $pvc.spec.storageClassName .storageClassKey $pvc.spec.storageClassName | fail }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}



{{/*===========================================================================
   * helm-lib.pvcStorageSpec(
   *   globalStorageClass:<global.persistence.storageClasses.<alias>>     Name of the setting under .global.persistence.storageClasses - must be passed as a string literal!
   *   volumeStorageClass:<volumeStorageClass>                            Name of the volume-specific setting of the service - must be passed as a string literal!
   *   accessMode:<accessMode>                                            AcccessMode (ReadWriteOnce, ReadWriteMany) to use for the PVC
   *   pvcName:<pvcName>                                                  Name of the PVC of this storage spec (used for the upgrade validation)
   *   Release:.Release, Values:.Values, Template:.Template)              .Release, .Values, and .Template must be passed for the processing
   *
   * This macro will expand to an (optional) .spec.storageClassName and a .spec.accessModes for a PVC.  It is expected to be called only from PVC YAML templates.
   *
   * The macro allows to combine a small number of well-known global storageClass alias settings (e.g. "fast-rwx") with per-volume override storageClass settings.
   * The global aliases allow the user to define a general mapping for the standard cases – these settings are exposed in the application composition chart,
   * as well as in the AppHub UI, and are used in the PVC templates.  In addition, the PVC templates allow an override at the individual volume level 
   * (settings of the chart that has the PVC template itself) – these settings would usually not be visualized in the AppHub UI as a setting (to reduce 
   * the number of settings exposed to the user), but could be used as an “advanced setting” in a particular customer situation.  
   * 
   * If volume-storageclass is set (for a particular volume of a particular service / application), set storageClassName: <volume-storageclass>
   * Else if global-storageclass is set, set storageClassName: <global-storageclass>
   * Else, don’t set storageClassName in the PVC (i.e. use the default storage class that is defined for the cluster).
   * Volume-storageclass setting should NOT be set in the service values.yaml to some default value, in order to allow the global setting to take effect!!
   * 
   * Change of the storageClassName is not possible after the PVC is created and bound in Kubernetes - the macro checks and alerts on changes during upgrades.
   *
   * Given that the storageClass selection usually goes along with the accessMode (readWriteOnce, readWriteMany) for the volume that is provisioned, and 
   * to allow for an accessMode=RWO override for single-node clusters, the accessmode is also a parameter in the helm-lib macro.
   * 
   * If global.persistence.accessMode is set, then set the PVC’s accessModes accordingly (note: accessModes is a list in a PVC, but we set a SINGLE value in the
   * macro at this time)
   * Else, use the literal accessMode that the PVC template specifies in the macro
   *
   * Example:
   * {{- include "helm-lib.pvcStorageSpec" ( dict "globalStorageClass" "fastRWO" "volumeStorageClass" ".Values.myService.persistence.volume3.storageClass"
   *               "accessMode" "ReadWriteMany" "pvcName" "fast-rwo-vol3" "Release" .Release "Values" .Values "Template" .Template ) }}
   *
   */}}

{{- define "helm-lib.pvcStorageSpec" -}}
{{- $vsc := "" -}}
{{- if .volumeStorageClass }}
  {{- $vsc = tpl (cat "{{ " .volumeStorageClass  " }}") . -}}
{{- end -}}
{{- if $vsc }}
  {{- include "helm-lib.validateStorageClass" ( dict "pvcName" .pvcName "storageClass" $vsc "storageClassKey" .volumeStorageClass "Release" .Release "Values" .Values) }}
  storageClassName: {{ $vsc }}
{{- else -}}
  {{- if .globalStorageClass }}
    {{- $gscKey := cat ".Values.global.persistence.storageClasses." .globalStorageClass | nospace  -}}
    {{- $gsc := get .Values.global.persistence.storageClasses .globalStorageClass -}}
    {{- include "helm-lib.validateStorageClass" ( dict "pvcName" .pvcName "storageClass" $gsc "storageClassKey" $gscKey "Release" .Release "Values" .Values) }}
    {{- if $gsc }}
  storageClassName: {{ $gsc -}}
    {{- end -}}
  {{- else -}}
    {{- include "helm-lib.validateStorageClass" ( dict "pvcName" .pvcName "storageClass" "" "Release" .Release "Values" .Values) }}
  {{- end -}}
{{- end -}}
{{- if .Values.global.persistence.accessMode }}
  accessModes:
  - {{ .Values.global.persistence.accessMode -}}
{{- else }}
  {{- if .accessMode }}
  accessModes:
  - {{ .accessMode -}}
  {{- else }}
    {{- cat "\nERROR: parameter accessMode is not set in the call to pvcStorageSpec()" | fail -}}
  {{- end -}}
{{- end -}}
{{- end -}}



