# Kubelet CGroups memory fix

Minimal loop to reconcile `kubepods.slice` memory limits against an expected value.
The expected limit is calculated using the formula `SYS_TOTAL_MEMORY - RESERVED_MEMORY`.

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

## Verify update
To verify the updated memory limits:
```
$ sudo systemctl status kubepods.slice
```
