# Google cloud platform (IaC)
**Used stack:**
- Google Cloud SDK:  245.0.0
- Terrafrom: 0.11.14
- Ansible: 2.8.1
- Packer: 1.4.1
- Bash: 3.2.57
- Gsutil: 4.38
------------
**General schema:**

This is the DEMO stand such demostrates how the **IAC** (infrastructure as code) feature can help you with provisioning of the cloud powers in mins.
Terraform/Packer/Ansible stack used for creation/provisioning of environment. Automation steps are metioned below:
1. Packer creates custom image **"gcp-centos7-apache"** which built with provisioner's script **install.sh ** and a direcory with public key, such baked inside the image. The base image is **centos-7**, ssh user is **gcp**, apache web-server is installed and enabled on this step. Healthchek point **/health** is configured by default in **"gcp-centos7-apache"** image.
2. Terraform creates a cluster of **3 instances**, including internal load balancer with  **health checks**. And many other entities (check the list after the "ansible" description part)
3. Ansible used to provision the simple php web-site such helps to observe the load-balancing process. The web site is working in HA mode, one-point access provided by internal load-balancer IP

The full list of GCP resources is placed below:
- `google_compute_health_check;`
- `google_compute_http_health_check;`
- `google_compute_firewall;`
- `google_compute_target_pool;`
- `google_compute_instance_template; `
- `google_compute_instance_group_manager;`
- `google_compute_autoscaler;`

------------
**Usage:**

`manage.sh` is a main entrypoint script. You can charge your cloud deployments with this script changing the input keys. 
`-d`- means **deploy**; 

```bash
./manage.sh -d
```
`-e` means **erase**;
```bash
./manage.sh -e
```
