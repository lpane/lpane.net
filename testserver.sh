#!/bin/bash
echo "morbo listening on port 9001";
nohup morbo --listen http://*:9001 /home/nina/src/mhlan.com/mhlan.pl > /home/nina/src/mhlan.com/testserver.log 2>&1 &
