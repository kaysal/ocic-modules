# Oracle Cloud Infrastructure Modules

These are custom modules used for demo of an example of a reference architecture.

The modules are configured specifically for the scenario illustrated in [OCIC Architecture] and are designed according to Infrastructure as Code (IAC) principles outlined in [Terraform: Up and Running].

The modules repository was uploaded initially and Git version set via tag to V1.0.0

```sh
git init
git add .
git commit -m "initial commit of modules repo"
git remote add origin https://github.com/kaysal/ocic-modules.git
git remote -v
git push origin master
git tag -a "v1.0.0" -m "First release of services modules for Bastion Server, Forward Proxy, and Reverse Proxy"
git push --tags
```


[OCIC Architecture]: <https://storage.googleapis.com/cloud-network-things/oracle/ocic_arch/image_8_1.png>
[Terraform: Up and Running]: <https://www.terraformupandrunning.com/>
