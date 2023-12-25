#!/bin/bash

INPUT_1=$1
IPADDR=${INPUT_1:=192.168.1.1}

## install

yum -y install epel-release
yum -y install yum-utils device-mapper-persistent-data lvm2 tmux iftop htop vim tcpdump net-tools git wget
yum-config-manager --add-repo https://mirrors.ustc.edu.cn/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce-17.12.1.ce

## start
systemctl start docker
systemctl enable docker

cat <<EOF > /etc/docker/daemon.json
{
    "registry-mirrors": [
        "https://l136ubp3.mirror.aliyuncs.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ]
}
EOF

systemctl daemon-reload
systemctl restart docker

## prometheus
mkdir -p /opt/monitor/prometheus/data && chmod 777 /opt/monitor/prometheus/data

docker run -d \
--name=prometheus \
--restart=always \
-p 9090:9090 \
-v /opt/monitor/prometheus:/etc/prometheus \
prom/prometheus \
--storage.tsdb.path=/etc/prometheus/data \
--storage.tsdb.retention.time=180d \
--config.file=/etc/prometheus/prometheus.yml \
--web.enable-lifecycle \
--web.external-url=http://$IPADDR:9090

## grafana
mkdir -p /opt/monitor/grafana-storage &&  chmod 777 -R  /opt/monitor/grafana-storage

docker run -itd \
--name=grafana \
--restart=always \
-p 3000:3000 \
-v /opt/monitor/grafana-storage:/var/lib/grafana \
grafana/grafana:10.0.3

## node_exporter
cd node_exporter
tar zxvf install_linux_node_export_1.6.1_amd64.tar.gz
cd linux_node_export && /bin/bash install.sh && cd ../../

## alertmanager
docker run -d --name=alertmanager \
--restart=always \
-p 9093:9093 \
-v /opt/monitor/alertmanager:/etc/alertmanager \
prom/alertmanager \
--config.file=/etc/alertmanager/alertmanager.yml \
--web.external-url=http://$IPADDR:9093

## dingtalk
docker run -d --name=dingtalk \
--restart=always \
-p 8060:8060 \
-v /opt/monitor/dingtalk:/opt/dingtalk \
timonwong/prometheus-webhook-dingtalk:v2.1.0 \
--config.file=/opt/dingtalk/config.yml \
--web.enable-ui \
--web.enable-lifecycle \
--log.level=error

## blackbox_exporter
docker run  -d --name=blackbox_exporter \
--restart=always \
-p 9115:9115 \
-v /opt/monitor/blackbox_exporter:/config \
prom/blackbox-exporter:master \
--config.file=/config/blackbox.yml
