# Kubelet CGroups memory fix

Minimal loop to reconcile `kubepods.slice` memory limits against an expected value.
This script is implemented and tested for OpenShift 3.11 and RHEL 7 only.

The expected limit is calculated using the formula `SYS_TOTAL_MEMORY - RESERVED_MEMORY`.

## Background
This is a mitigation script for the issue described in Bugzilla [1814804](https://bugzilla.redhat.com/show_bug.cgi?id=1814804) and fixed with 
Red Hat OpenShift Container Platform release **3.11.219**. The update includes the PR [24568](https://github.com/openshift/origin/pull/24568) to 
fix Bug 1802687.

Users who haven't already applied the suggested latest release of OCP 3.11 can use it to mitigate
the bug before patching. **It is strongly advised to patch at the latest release ASAP**.

## Install
To install as a systemd unit on the host run
```
$ git clone https://github.com/giannisalinetti/kubelet-cg-fix.git
$ cd kubelet-cg-fix
$ sudo ./install.sh
```

## Monitor status
The scripts tracks and logs the changes on the memory limit of kubepods.slice. To view the status:
```
$ sudo systemctl status kubelet-cg-fix.service
```

## Verify updated status
To verify the updated memory limits:
```
$ sudo systemctl status kubepods.slice
```

## Test memory hog
The file `test/kill-node.yaml` runs a hog pod that quickly saturates the memory of the node, causing
the kubelet to become unreachable for > 10m.
To test the behavior of the fix:
```
$ oc create ns kill-node
$ oc create -f test/kill-node.yaml -n kill-node
```

Watch for the `kubepods.slice` resources and verify that the hog pod is evicted or OOMKilled when the CGroups `memory.limits_in_bytes` value is reached.
The test manifest was provided on Bugzilla [1800319](https://bugzilla.redhat.com/show_bug.cgi?id=1800319).

## Legal disclaimer
This software is release under the Apache License 2.0 and provided "as is", without any commitments regarding quality and performance or that the OSS does not infringe any third party rights. 
Any use is therefore at the user’s own risk.

