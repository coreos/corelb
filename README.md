# corelb - a loadbalancer built on coreinit

This is a proof of concept using coreinit/etcd as a backing store for an
nginx loadbalancer.

### Running

```
ETCD_URL=http://192.168.240.151:4001 COREINIT_UNIT=simplehttp.service ./run
```
