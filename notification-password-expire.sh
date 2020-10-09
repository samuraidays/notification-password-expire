#!/bin/bash

## Populate below variable before running command
JCAPIKey='XXXXXXXXXXXXXXXXXXXXXXXXXXX'

## alertDaysThreshold set to '7' by default.
## Users whose passwords will expire in 7 days or less will receive a prompt to update.
## Update the value of the variable alertDaysThreshold=''to modify the threshold.
alertDaysThreshold='7'

#------- Do not modify below this line ------
user=$(ls -la /dev/console | cut -d " " -f 4)
echo ${user}
user='takashi'
passwordExpirationDate=$(
    curl -s \
        -X 'POST' \
        -d '{"filter":[{"username":"'${user}'"}],"fields" : "password_expiration_date"}' \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -H 'x-api-key: '${JCAPIKey}'' \
        "https://console.jumpcloud.com/api/search/systemusers"
)

regex=':".*T'
if [[ $passwordExpirationDate =~ $regex ]]; then
    unformattedDate1="${BASH_REMATCH[@]}"
    unformattedDate2=$(echo "${unformattedDate1:2}")
    expirationDay=${unformattedDate2%?}
    echo "${user} password_expiration_date: ${expirationDay}"
else
    echo "Could not locate the password expiration date for user ${user}."
    echo "Is ${user} enabled for password_never_expires?"
    echo "If so users enabled with password_never_expires have no password expiration date."
    exit 1
fi

Today="$(echo $(date -u +%Y-%m-%d))"

daysToExpiration=$(echo $((($(date -jf %Y-%m-%d $expirationDay +%s) - $(date -jf %Y-%m-%d $Today +%s)) / 86400)))
echo "${user} password will expire in ${daysToExpiration} days"

if [ "$daysToExpiration" -le "$alertDaysThreshold" ]; then
    echo "${daysToExpiration} within alertDaysThreshold of ${alertDaysThreshold} prompting user"

    userPrompt=$(sudo -u hasegawa osascript -e '
        display dialog "パスワードの期限が残り'"${daysToExpiration}"'日で切れます。\n OKをクリックし表示された手順に従いパスワードを更新してください。" buttons {"OK","Cancel"} default button 1 with title "パスワード有効期限通知" with icon file "Applications:Jumpcloud.app:Contents:Resources:AppIcon.icns"
        set tmp to result
        set btn to button returned of tmp
    ')
    echo "$userPrompt"

    if [ $userPrompt = "OK" ]; then
        echo "OPEN"
        `sudo -u hasegawa /usr/bin/open -a '/Applications/Google Chrome.app' "https://www.yahoo.co.jp"`
        echo "OPEN-END"
    fi


else
    echo "${daysToExpiration} NOT within alertDaysThreshold of ${alertDaysThreshold} NOT prompting user"

fi

exit 0