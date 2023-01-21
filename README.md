# Kubelet CGroups memory fix

Minimal loop to reconcile `kubepods.slice` memory limits against an expected value.
The expected limit is calculated using the formula `SYS_TOTAL_MEMORY - RESERVED_MEMORY`.
