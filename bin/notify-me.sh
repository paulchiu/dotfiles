#!/bin/sh

CMD="$0"
USAGE="Usage: $CMD <message>"

if [ $# == 0 ] ; then
    echo $USAGE
    exit 1;
fi

MESSAGE="$1"

curl -s -o /dev/null -X POST -H 'Content-type: application/json' --data "{\"text\":\"$MESSAGE\"}" https://hooks.slack.com/services/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
echo "💬 Message \"$MESSAGE\" sent to Slack"
