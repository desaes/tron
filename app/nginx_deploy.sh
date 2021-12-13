#!/bin/bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt update
sudo apt install -y apt-transport-https
echo "deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install -y nginx nfs-common filebeat
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl enable filebeat
sudo update-rc.d filebeat defaults 95 10
sudo filebeat modules enable nginx
sudo cp /var/www/html/index.nginx-debian.html /var/tmp/index.nginx-debian.html
sudo cat <<EOF > /var/www/html/index.nginx-debian.html
<!DOCTYPE html>
<html lang="en">
<head>
    <style>
        body {
            font-family: "Roboto", sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            background-color: #151b29;
            color: white;
            font-size: 100px;
        }
    </style>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <link
      href="https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@300&display=swap"
    />
    <title>Hello Kroton</title>
</head>
<body>
<p>Hello Kroton</p>
</body>
</html>
EOF
sudo mkdir -p /export/logs
sudo mount -t nfs ${logs_nfs_endpoint}:/ /export/logs
sudo chmod 1777 /export/logs

cp /etc/filebeat/modules.d/nginx.yml /etc/filebeat/modules.d/nginx.yml.orig
sed -i '/access/a\ \ \ \ var.paths: ["/var/log/nginx/access.log*"]' /etc/filebeat/modules.d/nginx.yml
mkdir -p /export/logs/filebeat-$HOSTNAME
cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.orig
sed -i 's/^output.elasticsearch:/#output.elasticsearch/' /etc/filebeat/filebeat.yml
sed -i 's/hosts: \[\"localhost\:9200\"\]/#hosts: ["localhost:9200"]/' /etc/filebeat/filebeat.yml
sed -i "/Processors/i output.file:\n\ \ enable: true\n\ \ path: /export/logs/filebeat-$HOSTNAME\n\ \ filename: filebeat" /etc/filebeat/filebeat.yml
sudo systemctl start filebeat
