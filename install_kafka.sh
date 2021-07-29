mkdir -p /usr/local/zookeeper-cluster
cd ~
tar zxvf apache-zookeeper-3.7.0-bin.tar.gz
mv apache-zookeeper-3.7.0-bin/* /usr/local/zookeeper-cluster/
cd /usr/local/zookeeper-cluster
mkdir data logs
cd conf
mv zoo_sample.cfg zoo.cfg
sed -i 's#^dataDir=.*#dataDir=/usr/local/zookeeper-cluster/data#g' zoo.cfg
sed -i '/dataDir=.*/a\dataLogDir=\/usr\/local\/zookeeper-cluster\/logs' zoo.cfg
count=${1}
num=0
OIFS=$IFS
IFS=,
for i in $2;do
    num=$((num+1))
    echo server.${num}=${i%:2181}:2888:3888 >> zoo.cfg
done
IFS=${OIFS}

echo $((count+1)) >/usr/local/zookeeper-cluster/data/myid

/usr/local/zookeeper-cluster/bin/zkServer.sh start

cd ~
tar zxvf kafka_2.12-2.8.0.tgz
mkdir -p /usr/local/kafka-cluster
mv kafka_2.12-2.8.0/* /usr/local/kafka-cluster/
cd /usr/local/kafka-cluster/config/
LOCAL_IP=$(hostname -I | awk '{print $1}')
sed -i "s#^broker\.id=.*#broker\.id=$((count+1))#g" server.properties
sed -i "s#listeners=.*#listeners=PLAINTEXT://${LOCAL_IP}:9092#g" server.properties

sed -i "s#^zookeeper\.connect=.*#zookeeper.connect=${2}:2181#g" server.properties

/usr/local/kafka-cluster/bin/kafka-server-start.sh  -daemon /usr/local/kafka-cluster/config/server.properties