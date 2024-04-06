# 监控方案
> 运维监控部分，使用主流的方案，prometheus+grafana+alertmanager，进行采集、监控、展示、告警

## install
> 操作系统 CentOS 7.9

修改所有配置文件中的IP地址，改为服务器本地IP

## start
```bash
systemctl start docker
systemctl enable docker

cat <<EOF > /etc/docker/daemon.json
{
    "registry-mirrors": [
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ]
}
EOF

systemctl daemon-reload
systemctl restart docker
```

```bash
cd /opt && git clone https://github.com/xiaoyunjie/monitor

```
> 部署前，需要将所有配置文件中的IP地址进行修改，建议使用grep匹配
## auto install
```bash
# 填入主机本地ip地址，默认地址是 192.168.1.1
/bin/bash install.sh [ip]
```

## 手动安装
## prometheus
```bash
mkdir -p /opt/monitor/prometheus/data && chmod 777 /opt/monitor/prometheus/data

docker run -d \
--name=prometheus \
--privileged=true \
--restart=always \
-p 9090:9090 \
-v /opt/monitor/prometheus:/etc/prometheus \
prom/prometheus \
--storage.tsdb.path=/etc/prometheus/data \
--storage.tsdb.retention.time=180d \
--config.file=/etc/prometheus/prometheus.yml \
--web.enable-lifecycle \
--web.external-url=http://192.168.1.1:9090
```
> curl -X POST "http://192.168.1.1:9090/-/reload"  调整yml配置有软加载

## grafana
```bash
mkdir -p /opt/monitor/grafana-storage &&  chmod 777 -R  /opt/monitor/grafana-storage

docker run -itd \
--name=grafana \
--restart=always \
--privileged=true \
-p 3000:3000 \
-v /opt/monitor/grafana-storage:/var/lib/grafana \
grafana/grafana:10.0.3
```
> 模板文件，从grafana目录中获取后导入

## node_exporter
- 二进制文件部署 node_exporter
```bash
cd node_exporter
tar zxvf install_linux_node_export_1.6.1_amd64.tar.gz
cd linux_node_export && ./install
```

## alertmanager
```bash
docker run -d --name=alertmanager \
--privileged=true \
--restart=always \
-p 9093:9093 \
-v /opt/monitor/alertmanager:/etc/alertmanager \
prom/alertmanager \
--config.file=/etc/alertmanager/alertmanager.yml \
--web.external-url=http://192.168.1.1:9093
```

## dingtalk
- .config.yml 中 webhook 需要填入新建的机器人
```bash
docker run -d --name=dingtalk \
--restart=always \
--privileged=true \
-p 8060:8060 \
-v /opt/monitor/dingtalk:/opt/dingtalk \
timonwong/prometheus-webhook-dingtalk:v2.1.0 \
--config.file=/opt/dingtalk/config.yml \
--web.enable-ui \
--web.enable-lifecycle \
--log.level=error
```

- 如果在内网部署，则需要走代理，例如nginx正向代理
```bash
docker run -d --name=dingtalk \
--restart=always \
--privileged=true \
-p 8060:8060 \
-e https_proxy="192.168.1.1:8000" \
-v /opt/monitor/dingtalk:/opt/dingtalk \
timonwong/prometheus-webhook-dingtalk:v2.1.0 \
--config.file=/opt/dingtalk/config.yml \
--web.enable-ui \
--web.enable-lifecycle \
--log.level=error
```

> curl -XPOST http://192.168.1.1:8060/-/reload   调整模板后，软加载配置

## blackbox_exporter
```bash
docker run  -d --name=blackbox_exporter \
--restart=always \
--privileged=true \
-p 9115:9115 \
-v /opt/monitor/blackbox_exporter:/config \
prom/blackbox-exporter:master \
--config.file=/config/blackbox.yml
```
