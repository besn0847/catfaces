#!/bin/bash

export FLASK_APP=app.py

if [ ! -f /bootstrap/.bootstrapped_cats ]
then
        mv /bootstrap/* /conf/
        echo 1 > /bootstrap/.bootstrapped_cats
fi

cd /conf/
while(true)
do
        python app.py
        sleep 5
done
