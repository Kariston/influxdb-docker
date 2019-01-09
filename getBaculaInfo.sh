#!/bin/bash

TMPFILE="/tmp/output.out"
FILE="/tmp/file.out"

DBUSER='bcm_user'
DBPASS='bcm@mp_92'
DBHOST='10.209.8.251'

DATABASE="bacula"
DBTABLE="Job"
#QUERY="SELECT * FROM $DBTABLE LIMIT 1"
#  END AS JobStatus, UNIX_TIMESTAMP(j.StartTime) * 1000000000, j.EndTime

QUERY="
SELECT CONVERT(c.Name using utf8) AS Client, j.JobId,
  CASE WHEN j.Type = 'B' THEN 'Back' WHEN j.Type = 'R' THEN 'Rest' END AS Type,
  CASE WHEN j.Level = 'F' THEN 'Full' WHEN j.Level = 'D'
  THEN 'Diff' WHEN j.Level = 'I' THEN 'Incr' END AS Level,
  CONVERT(p.Name using utf8) AS Pool,
  CONVERT(m.VolumeName using utf8) AS Volume, (TRUNCATE(j.JobBytes DIV 1024 DIV 1024 / 1024,2)) AS Size,
  CASE WHEN j.JobStatus = 'A' THEN 'Cancelado' WHEN j.JobStatus = 'T' THEN 'Finalizado'
  WHEN j.JobStatus = 'f' THEN 'Erro' WHEN j.JobStatus = 'R' THEN 'Executando'
  END AS JobStatus, UNIX_TIMESTAMP(j.StartTime) + 7200, j.EndTime
  FROM Job j
  LEFT JOIN JobMedia jm
  ON j.JobId = jm.JobId
  LEFT JOIN Media m
  ON jm.MediaId = m.MediaId
  LEFT JOIN Client c
  ON j.ClientId = c.ClientId
  LEFT JOIN Pool p
  ON j.PoolId = p.PoolId
  WHERE c.Name not like 'bmaster-fd'
  GROUP BY j.JobId;"

mysql -h $DBHOST -u $DBUSER -p$DBPASS -D $DATABASE -e "$QUERY" > $TMPFILE

rm -f $FILE

echo "# DDL" >> $FILE
echo "DROP DATABASE bacula_jobs" >> $FILE
echo "CREATE DATABASE bacula_jobs" >> $FILE

echo "# DML" >> $FILE
echo "# CONTEXT-DATABASE: bacula_jobs" >> $FILE
# echo "# CONTEXT-RETENTION-POLICY: oneday" >> $FILE
echo "" >> $FILE

while read job
do
	#awk '{ print "jobs,client=" $1 ",pool=" $5 " jobid=\"" $2 "\",type=\"" $3 "\",level=\"" $4 "\",status=\"" $8 "\",size=\"" $7 "\" " $9}' >> $FILE
	awk '{ print "jobs,client=" $1 " jobid=\"" $2 "\",type=\"" $3 "\",level=\"" $4 "\",pool=\"" $5 "\",status=\"" $8 "\",size=\"" $7 "\" " $9}' >> $FILE
	#awk '{ print "jobs,client=" $1 " jobid=\"" $2 "\",type=\"" $3 "\",level=\"" $4 "\",pool=" $5 ",status=\"" $8 "\",size=\"" $7 "\" " $9}' >> $FILE
	#awk '{ print $1 " jobid=\"" $2 "\",type=\"" $3 "\",level=\"" $4 "\",pool=\"" $5 "\",status=\"" $8 "\",size=\"" $7 "\" " $9}' >> $FILE
done < $TMPFILE
