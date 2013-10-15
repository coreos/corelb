# corelb - load balancer based on nginx and coreinit

This is a proof of concept using coreinit as a backing store for an
nginx loadbalancer.

### Running

```
ETCD_URL=http://192.168.240.151:4001 COREINIT_UNIT=simplehttp.service ./run
```
