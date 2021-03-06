[ -d /data/kafka-logs ] || mkdir -p /data/kafka-logs
[ -d /opt/kafka ] || (mkdir -p /opt/kafka &&
  cd /opt/kafka &&
  curl -s -O http://apache.mirrors.spacedump.net/kafka/2.4.0/kafka_2.12-2.4.0.tgz &&
  tar xf kafka_2.12-2.4.0.tgz &&
  ln -s kafka_2.12-2.4.0 home &&
  rm -f kafka_2.12-2.4.0.tgz)
export KAFKA_HOME=/opt/kafka/home
[ -d /opt/kafka/home/logs ] || mkdir /opt/kafka/home/logs
[ -h /var/log/kafka ] || ln -s /opt/kafka/home/logs /var/log/kafka
[ -z "$INSTANCE_NUMBER" ] || (
  ZOOKEEPER_CONNECT_LIST="zookeeper${INSTANCE_NUMBER}:2181"
  for ((i = 1; i <= TOTAL_INSTANCES; i++)); do
    [[ ${i} -eq ${INSTANCE_NUMBER} ]] && continue
    ZOOKEEPER_CONNECT_LIST="${ZOOKEEPER_CONNECT_LIST},zookeeper${i}:2181"
  done
  sed 's/@INSTANCE_NUMBER@/'"${INSTANCE_NUMBER}"'/g;s/@ZOOKEEPER_CONNECT_LIST@/'"${ZOOKEEPER_CONNECT_LIST}"'/g' ./packages/kafka/config/server.properties >/opt/kafka/home/config/server.properties

  sed 's/@TOTAL_INSTANCES@/'"${TOTAL_INSTANCES}"'/g' ./packages/scripts/opt/bookit/bin/create-topics-after-startup.sh >/opt/bookit/bin/create-topics-after-startup.sh
  chmod 744 /opt/bookit/bin/create-topics-after-startup.sh

  cp ./packages/cron/etc/cron.d/1create-topics /etc/cron.d/1create-topics
  chmod 644 /etc/cron.d/1create-topics
)
id -u kafka > /dev/null 2>&1 || adduser -r kafka
chown -R kafka:kafka /opt/kafka
chown -R kafka:kafka /data/kafka-logs

cp ./packages/kafka/service/etc/systemd/system/kafka.service /etc/systemd/system/kafka.service
chmod 644 /etc/systemd/system/kafka.service
systemctl daemon-reload
