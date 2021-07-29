yum -y install PyYAML
service docker start
cd /opt/metersphere
case $1 in
server)
    echo
    export MS_INSTALL_MODE=server
    sed -i "s/MS_EXTERNAL_KAFKA=false/MS_EXTERNAL_KAFKA=true/g" install.conf
    sed -i "s/MS_INSTALL_MODE=allinone/MS_INSTALL_MODE=server/g" install.conf
    sed -i "s/MS_EXTERNAL_PROMETHEUS=false/MS_EXTERNAL_PROMETHEUS=true/g" install.conf
    sed -i "s/#kafka.bootstrap-servers=.*/kafka.bootstrap-servers=${2}:9092/g" conf/metersphere.properties
    sed -i "/KAFKA_BOOTSTRAP-SERVERS.*/d" docker-compose-server.yml
python - <<EOF
import yaml
with open("docker-compose-server.yml", 'r') as file:
    try:
        compose=yaml.safe_load(file)
        del compose["services"]["ms-data-streaming"] 
    except yaml.YAMLError as exc:
        print(exc)
with open("docker-compose-server.yml", 'w') as file:
    try:
        file.write(yaml.dump(compose, default_flow_style=False))
    except yaml.YAMLError as exc:
        print(exc)
EOF
    ;;
node-controller)
    echo
    sed -i "s/MS_EXTERNAL_KAFKA=false/MS_EXTERNAL_KAFKA=true/g" install.conf
    sed -i "s/MS_EXTERNAL_MYSQL=false/MS_EXTERNAL_MYSQL=true/g" install.conf
    sed -i "s/MS_EXTERNAL_PROMETHEUS=false/MS_EXTERNAL_PROMETHEUS=true/g" install.conf
    sed -i "s/MS_INSTALL_MODE=allinone/MS_INSTALL_MODE=node-controller/g" install.conf
    sed -i "s/#kafka.bootstrap-servers=.*/kafka.bootstrap-servers=${2}:9092/g" conf/metersphere.properties
    sed -i "/KAFKA_BOOTSTRAP-SERVERS.*/d" docker-compose-node-controller.yml    
    ;;
data-streaming)
    echo
    sed -i "s/MS_EXTERNAL_KAFKA=false/MS_EXTERNAL_KAFKA=true/g" install.conf
    sed -i "s/MS_EXTERNAL_MYSQL=false/MS_EXTERNAL_MYSQL=true/g" install.conf
    sed -i "s/MS_MYSQL_HOST=mysql/MS_MYSQL_HOST=${3}/g" install.conf
    sed -i "s/MS_MYSQL_PORT=3306/MS_MYSQL_PORT=3307/g" install.conf
    sed -i "s/MS_EXTERNAL_PROMETHEUS=false/MS_EXTERNAL_PROMETHEUS=true/g" install.conf
    sed -i "s/MS_INSTALL_MODE=allinone/MS_INSTALL_MODE=server/g" install.conf
    sed -i "/KAFKA_BOOTSTRAP-SERVERS.*/d" docker-compose-server.yml
    sed -i "s/#kafka.bootstrap-servers=.*/kafka.bootstrap-servers=${2}:9092/g" conf/metersphere.properties
python - <<EOF
import yaml
with open("docker-compose-server.yml", 'r') as file:
    try:
        compose=yaml.safe_load(file)
        del compose["services"]["ms-server"]
    except yaml.YAMLError as exc:
        print(exc)
with open("docker-compose-server.yml", 'w') as file:
    try:
        file.write(yaml.dump(compose, default_flow_style=False))
    except yaml.YAMLError as exc:
        print(exc)
EOF
    ;;
esac
sleep 5
msctl reload
msctl reload