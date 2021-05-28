#!/bin/sh

response=$(curl "https://cloud.feedly.com/v3/subscriptions" -H "Authorization: OAuth $1")
./scripts/feedly-following.rb "${response}"
