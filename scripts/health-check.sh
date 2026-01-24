#!/bin/bash
# Simple script to check if the backend is responding
URL="http://localhost:8080/health"

if curl -s --head  --request GET "$URL" | grep "200 OK" > /dev/null
then 
    echo "Backend is HEALTHY"
else
    echo "Backend is DOWN"
    exit 1
fi