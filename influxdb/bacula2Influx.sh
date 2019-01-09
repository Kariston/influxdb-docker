#!/bin/bash

echo "Extraindo dados do Bacula"
echo ""
bash /opt/influxdb/getBaculaInfo.sh
echo ""
echo "Finalizado!"
echo "--------"

echo "Executando o import para o InfluxDB"
echo ""
influx -import -path=/tmp/file.out -precision=s
echo ""
echo "Finalizado"
echo "--------"
