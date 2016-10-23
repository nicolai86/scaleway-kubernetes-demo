# Kubernetes on Scaleway

**warning**  
this is just an example on how to setup a K8s cluster on @Scaleway via terraform.
It's not secured in any way and shouldn't been used in production! 

**inspiration**  
Joe Beda outlined this approach in a [PR](https://github.com/upmc-enterprises/kubeadm-aws/issues/1).
I stumbled over this on twitter by a tweet from [Steve Sloka](https://twitter.com/stevesloka/status/780936473725972481)

## Setup

Setting up the K8s cluster requires a recent version of terraform (0.7.7 +)
Besides terraform you need a Scaleway account and export `SCALEWAY_ACCESS_KEY` and `SCALEWAY_ORGANIZATION` to your ENV.

```
$ k8stoken=$(python -c 'import random; print "%0x.%0x" % (random.SystemRandom().getrandbits(3*8), random.SystemRandom().getrandbits(8*8))')
$ terraform plan -var 'k8stoken=$k8stoken'
$ terraform apply -var 'k8stoken=$k8stoken'
```

Terraform will take ~10 minutes to finish. The setup includes the kubernetes-dashboard.
You can access it like this:

```
$ ssh -L 8080:localhost:8080 root@<master_ip>
$ kubectl proxy
```

Now open `http://localhost:8001/ui` inside your browser.

## Details

Terraform will setup a three node kubernetes cluster, consisting of one master and
two workers. All nodes will be `VC1S` instance types, without additional storage.

## TODOs

- [ ] firewall rules to somehow secure this setup
- [ ] mixed setup of public & private nodes
- [ ] logging
- [ ] metric aggregation
