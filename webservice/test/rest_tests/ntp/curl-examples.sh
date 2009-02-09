curl -X POST -v -H "Content-Type: application/xml; charset=utf-8" -T login -c cookie http://0.0.0.0:3001/login.xml

curl -X GET -b cookie http://0.0.0.0:3001/services/ntp/config
curl -v -H "Content-Type: application/xml; charset=utf-8" -T peter -b cookie http://0.0.0.0:3001/services/ntp/config