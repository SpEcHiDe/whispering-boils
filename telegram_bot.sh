#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# get telegram bot token from @BotFather
tg_bot_token=$(echo $TG_BOT_TOKEN)
# sets the base API url
tg_api_url=$(echo "https://api.telegram.org")
# set the base request url
tg_base_request_url="${tg_api_url}/bot${tg_bot_token}"
# calculate offset needed for getUpdates
[[ -z "${TG_LAST_UPDATE_ID}" ]] && tg_last_update_id="0" || tg_last_update_id="${TG_LAST_UPDATE_ID}"

function moin_function() {
    result=$(curl -s "${tg_base_request_url}/getMe")
    bot_user_name=$(echo $result | jq -r ".result.username")
    echo -n "${bot_user_name} Started"
    while true; do 
        proc_bot_messages
        # sleep one second between updates
        sleep 1
    done
}


function proc_bot_messages() {
    local i update message_id chat_id text

	local updates=$(curl -s "${tg_base_request_url}/getUpdates?offset=$tg_last_update_id")
	local count_update=$(echo $updates | jq -r ".result | length")

    [[ $count_update -eq 0 ]] && echo -n "."

    for ((i=0; i<$count_update; i++)); do
        update=$(echo $updates | jq -r ".result[$i]")   
    	tg_last_update_id=$(echo $update | jq -r ".update_id")

        chat_join_request=$(echo $update | jq -r ".chat_join_request")
        join_chat_reqed=$(echo $chat_join_request | jq -r ".chat.id")
        join_user_reqed=$(echo $chat_join_request | jq -r ".from.id")

        result=$(curl -s "${tg_base_request_url}/approveChatJoinRequest" \
                -d chat_id="${join_chat_reqed}" \
                -d user_id="${join_user_reqed}"
        )


    	message_id=$(echo $update | jq -r ".message.message_id")
    	chat_id=$(echo $update | jq -r ".message.chat.id")
        chat_type=$(echo $update | jq -r ".message.chat.type")
        text=$(echo $update | jq -r ".message.text")

        if [ "${chat_type}" == "private" ]; then
            msg="${text}: https://github.com/SpEcHiDe/whispering-boils"
            result=$(curl -s "${tg_base_request_url}/sendMessage" \
                    -d chat_id="${chat_id}" \
                    -d text="${msg}" \
                    -d parse_mode="HTML" \
                    -d reply_to_message_id="${chat_id}"
                )
        fi

        tg_last_update_id=$(($tg_last_update_id + 1))
        # store the correct offset
        # for the next iteration
		TG_LAST_UPDATE_ID="${tg_last_update_id}"
		echo $TG_LAST_UPDATE_ID
    done
}

# call the main function,
# to process updates
moin_function
