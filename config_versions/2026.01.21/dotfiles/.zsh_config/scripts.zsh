alias local-docker="docker-compose -f $SCRIPTS_DIR/docker-compose-local.yml up --remove-orphans --build -d"

for filename in $SCRIPTS_DIR/bin/*.sh; do
  name=${$(basename $filename)%".sh"}
  alias ${name}=$filename
done

function purgeq(){
  awslocal sqs purge-queue --queue-url http://localhost:4566/000000000000/$1
}
