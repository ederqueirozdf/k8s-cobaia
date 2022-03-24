#===========================================================================
# generateLength()
# This function will generate an integer length between
# .L (DEFAULT 8, RANGE [4..32]) and .L2 (DEFAULT 32, RANGE [.L..64])
#
{{- define "helm-lib.generateLength" -}}
  {{- /* lower bound ($LB) is len L */ -}}
  {{- $LB:= .L | default ((eq (toString .L) "<nil>")| ternary 8 0) -}}
  {{- $LB:= max 4 $LB -}}              {{- /* $LB min is 4  */ -}}
  {{- $LB:= min 32 $LB -}}             {{- /* $LB max is 32 */ -}}

  {{- /* upper bound ($UB) is L2 or L or 32 or LB  */ -}}
  {{- $UB:= .L2 |default .L |default ((eq (toString .L) "<nil>")| ternary 32 $LB) -}}
  {{- $UB:= min 64 $UB -}}             {{- /* $UB max is 64     */ -}}
  {{- $UB:= max $UB $LB -}}            {{- /* $UB can't be < LB */ -}}

  {{- /* put bounds back in caller dict */ -}}
  {{- $_:= set . "LB" $LB -}}
  {{- $_:= set . "UB" $UB -}}

  {{- /* select random int between upper ($UB) and lower ($LB) bounds inclusive */ -}}
  {{- (int (add $LB (div (mul (randNumeric 2 |add1) (sub $UB $LB)) 100))) -}}
{{- end -}}

#===========================================================================
# randSpecial()
# This function will generate a string of random characters based on:
# Length: .L (DEFAULT 1, RANGE [0..maxint])
# Special Chars: .special (DEFAULT "-+\"'?/.,<>:;[]{}`~!@#%^&*()_=\\|$")
#
{{- define "helm-lib.randSpecial" -}}
  {{- $L:= .L | default ((eq (toString .L) "<nil>")| ternary 1 0) -}}
  {{- if gt $L 0 -}}
    {{- /* default to all ascii printable special chars (order matters) */ -}}
    {{- $special32:=  "-+\"'?/.,<>:;[]{}`~!@#%^&*()_=\\|$" -}}
    {{- $special:= .special | default $special32 -}}

    {{- /* put special back in caller dict */ -}}
    {{- $_:= set . "special" $special -}}

    {{- $slen:= len $special -}}
    {{- $val:= dict -}}
    {{- range $i,$e:= until $L -}}
      {{- /* choose a random index from 0...$slen */ -}}
      {{- $beg:= int ((mod (randNumeric 3) $slen)) -}}
      {{- $end:= int (add $beg 1) -}}

      {{- /* get the char from $special and add it to list */ -}}
      {{- $c:= substr $beg $end $special -}}
      {{- $_:= set $val (toString $i) $c -}}
    {{- end -}}

    {{- /* convert back to a string */ -}}
    {{- $str:= join "" (values $val) -}}
    {{- substr 0 $L $str -}}
  {{- end -}}
{{- end -}}

#===========================================================================
# getSecretsDefaultsDict()
# This adds a dict containing existing secrets to caller dict based on:
# .name      the name of the secret to find
# .namespace the namespace to search
# The added dict has key "existing" and will be the 1st valid one from:
#   1) the map comprising the "data" key in the secret specified by .name
#   2) the analogous map found using .name value with "-upgrade" appended
#   3) an empty map, (i.e. there are no existing values)
# The -upgrade case is used when the original secret was created externally
# e.g. via gen_secrets.sh
#
{{- define "helm-lib.getSecretsDefaultsDict" -}}
  {{- $secretName:= .name -}}
  {{- $secretNamespace:= .namespace -}}
  {{- $existing:= get (lookup "v1" "Secret" $secretNamespace $secretName) "data" | default (get (lookup "v1" "Secret" $secretNamespace (list $secretName "-upgrade" | join "")) "data") | default (dict) -}}
  {{- $_:= set . "existing" $existing -}}
{{- end -}}

#===========================================================================
# generatePassword()
# This function will generate a password matching complexity specified by:
# MinLength:   .L  (DEFAULT random in range [8..32], RANGE [4..32])
# MaxLength:   .L2 (DEFAULT .L, RANGE [.L..64])
# USE_SPECIAL: .S  (DEFAULT true) password includes special chars from .special
# USE_ALPHA:   .A  (DEFAULT true) password includes upper and lower case chars
# USE_NUMERIC: .N  (DEFAULT true) password includes digits [0-9]
# Special Chars: .special (DEFAULT "-+\"'?/.,<>:;[]{}`~!@#%^&*()_=\\|$")
#
{{- define "helm-lib.generatePassword" -}}
  {{- $L:= include "helm-lib.generateLength" . -}}
  {{- $A:= .A | default (eq (toString .A) "<nil>") -}}
  {{- $N:= .N | default (eq (toString .N) "<nil>") -}}
  {{- $S:= .S | default (eq (toString .S) "<nil>") -}}

  {{- /* get single random special */ -}}
  {{- $mydict:= dict "L" 1 "special" .special -}}
  {{- $spec:= include "helm-lib.randSpecial" $mydict -}}

  {{- /* conditionally put special back in caller dict */ -}}
  {{- $special:= get $mydict "special" -}}
  {{- if not .special -}}
    {{- $_:= set . "special" $special -}}
  {{- end -}}

  {{- /* Generate prefix (one of each required char type) */ -}}
  {{- $digit:= randNumeric 1 -}}
  {{- $upper:= randAlpha 1 | upper -}}
  {{- $lower:= randAlpha 1 | lower -}}
  {{- $prefix:= list ($A | ternary $upper "") ($A | ternary $lower "") ($N | ternary $digit "") ($S | ternary $spec "") | join "" -}}

  {{- /* determine remaining length ($rLen) based on $L */ -}}
  {{- $rLen:= sub $L (len $prefix) | int -}}

  {{- /* special case for no additional chars */ -}}
  {{- if le $rLen 0 -}}
    {{- shuffle $prefix -}}

  {{- /* additional chars contain all */ -}}
  {{- else if and $A $N $S -}}
    {{- $sLen:= int (div $rLen 4) -}} {{- /* ~ 1/4 of remaining chars... */ -}} 
    {{- $spec:= include "helm-lib.randSpecial" (dict "L" $sLen "special" $special) -}}
    {{- $rLen:= int (sub $rLen $sLen) -}} {{- /* leftover non-special chars... */ -}}
    {{- list $prefix $spec (randAlphaNum $rLen) | join "" | shuffle -}}

  {{- /* additional chars are alpha-numeric */ -}}
  {{- else if and $A $N -}}
    {{- list $prefix (randAlphaNum $rLen) | join "" | shuffle -}}

  {{- /* additional chars are numeric (possibly with special, but allow/ignore that) */ -}}
  {{- else if $N -}}
    {{- list $prefix (randNumeric $rLen) | join "" | shuffle -}}

  {{- /* additional chars are alpha (possibly with special, but allow/ignore that) */ -}}
  {{- else if $A -}}
    {{- list $prefix (randAlpha $rLen) | join "" | shuffle -}}

  {{- /* otherwise bad state... e.g. don't allow only special, etc */ -}}
  {{- else -}}
    {{- fail "helm-lib.generatePassword: Invalid combination of Alpha/Numeric/Special" -}}

  {{- end -}}
{{- end -}}

#===========================================================================
# validatePassword()
# This function will validate a password matching complexity specified by:
# MinLength:   .L  (DEFAULT random in range [8..32], RANGE [4..32])
# MaxLength:   .L2 (DEFAULT .L, RANGE [.L..64])
# USE_SPECIAL: .S  (DEFAULT true) password includes special chars from .special
# USE_ALPHA:   .A  (DEFAULT true) password includes upper and lower case chars
# USE_NUMERIC: .N  (DEFAULT true) password includes digits [0-9]
# Special Chars: .special (DEFAULT "-+\"'?/.,<>:;[]{}`~!@#%^&*()_=\\|$")
# VALIDATE:    .V  (DEFAULT true) skip validation by setting to false
#                  Note that validation only occurs for new values
#                  i.e. specified in values.yaml or via --set
# GENERATE:    .G  (DEFAULT true) generate random password if none found
#
# The invoking dictionary can also contain:
# a map of values from values.yaml: .map
#  NOTE: these secrets values are
#  assumed to be base64 encoded
#  unless prefixed with "clear="
# a map of existing values:         .existing
# the password name to validate:    .key
# the password value to validate:   .secret
#
# These values are best created by using the getSecretsDefaultsDict() 
# tpl function (defined above) and then merging additional desired 
# values for validation when including this function in a secrets template.
# For examples of this, see the README.md file.
# 
# In cases where the password value is not provided, not contained in
# either the .map or .existing maps and .G(enerate) is true, the value is generated
# by calling the generatePassword() tpl function defined above.
#
{{- define "helm-lib.validatePassword" -}}
  {{- $tplName:= "helm-lib.validatePassword::" -}}
  {{- if .key -}}
   {{- $pfx:= "clear=" -}}
   {{- $mVal:= get .map .key -}}
   {{- if $mVal -}}
     {{- $clearText:= $mVal | hasPrefix $pfx -}}
     {{- $mVal:= ternary ($mVal | trimPrefix $pfx ) ($mVal | b64dec) $clearText -}}
     {{- $_:= set . "yamlValue" $mVal -}}
   {{- end -}}
   {{- $kVal:= .yamlValue | default (get (.existing | default (dict)) .key | b64dec) -}}
   {{- $_:= set . "secret" $kVal -}}
  {{- end -}}

  {{- /* Generate a password if not existing/specified */ -}}
  {{- $G:= .G | default (eq (toString .G) "<nil>") -}}
  {{- $P:= ternary (ternary (include "helm-lib.generatePassword" .) "" $G) .secret (.secret | empty) -}}

  {{- /* if we have a yamlValue, the password was specified, so we should validate... */ -}}
  {{- if .yamlValue -}}
    {{- $V:= .V | default (eq (toString .V) "<nil>") -}}
    {{- /* ...unless validation is specifically set to false via .V */ -}}
    {{- if $V -}}
      {{- /* use specified validation parameters */ -}}
      {{- $A:= .A | default (eq (toString .A) "<nil>") -}}
      {{- $N:= .N | default (eq (toString .N) "<nil>") -}}
      {{- $S:= .S | default (eq (toString .S) "<nil>") -}}
      {{- $_:= include "helm-lib.generateLength" . -}}
      {{- $special:= .special -}}
  
      {{- /* Validate Length */ -}}
      {{- if or (lt (len $P) .LB) (gt (len $P) .UB) -}}
        {{- if ne .LB .UB -}}
           {{- fail (cat $tplName .key "length must be between" .LB "and" .UB "( but is" (len $P) ")" ) -}}
        {{- end -}}
        {{- fail (cat $tplName .key "length must be:" .LB "( but is" (len $P) ")") -}}
      {{- end -}}
  
      {{- /* Validate Upper */ -}}
      {{- if $A -}}
        {{- if not (regexMatch "[A-Z]" $P) -}}
        {{- fail (cat $tplName .key "must contain at least 1 upper case") -}}
        {{- end -}}
      {{- else -}}
        {{- if regexMatch "[A-Z]" $P -}}
        {{- fail (cat $tplName .key "cannot contain upper case") -}}
        {{- end -}}
      {{- end -}}
  
      {{- /* Validate Lower */ -}}
      {{- if $A -}}
        {{- if not (regexMatch "[a-z]" $P) -}}
        {{- fail (cat $tplName .key "must contain at least 1 lower case") -}}
        {{- end -}}
      {{- else -}}
        {{- if regexMatch "[a-z]" $P -}}
        {{- fail (cat $tplName .key "cannot contain lower case") -}}
        {{- end -}}
      {{- end -}}
  
      {{- /* Validate Digit */ -}}
      {{- if $N -}}
        {{- if not (regexMatch "[0-9]" $P) -}}
        {{- fail (cat $tplName .key "must contain at least 1 digit") -}}
        {{- end -}}
      {{- else -}}
        {{- if regexMatch "[0-9]" $P -}}
        {{- fail (cat $tplName .key "cannot contain a digit") -}}
        {{- end -}}
      {{- end -}}
  
      {{- /* Validate Special */ -}}
      {{- $regex:= (list "[" ($special | replace "\\" "\\\\" | replace "]" "\\]") "]") | join "" -}}
      {{- if $S -}}
        {{- if not (mustRegexMatch $regex $P) -}}
        {{- fail (cat $tplName .key "must contain at least 1 special char in:" $special "( regex=" $regex ")" ) -}}
        {{- end -}}
      {{- else -}}
        {{- if mustRegexMatch $regex $P -}}
        {{- /* fail (cat $tplName .key "cannot contain any special characters") */ -}}
        {{- end -}}
      {{- end -}}
  
      {{- /* Validate Other */ -}}
      {{- $regex:= (list "[^A-Za-z0-9" ($special | replace "\\" "\\\\" | replace "]" "\\]") "]") | join "" -}}
      {{- if mustRegexMatch $regex $P -}}
        {{- fail (cat $tplName .key "cannot contain any special characters not in:" $special ) -}}
      {{- end -}}

    {{- else -}}
      {{- /* $V is specified as false, validation skipped... */ -}}
    {{- end -}}
  {{- else -}}
    {{- /* $P is defaulted, generated or existing; no validation required... */ -}}
    {{- if and (empty $P) (not $G) -}}
    {{- /* handle validateOnly, when generation disabled and no value */ -}}
    {{- fail (cat $tplName .key "cannot be undefined or the empty string") -}}
    {{- end -}}
  {{- end -}}

  {{- /* $P is acceptable, return it... */ -}}
  {{- $P -}}
{{- end -}}

