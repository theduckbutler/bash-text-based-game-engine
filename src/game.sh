#!/bin/bash
won=0

echo "Title"
echo -e "Introduction\n\n"

#'reads' in all of the arrays from the input file
readarray -t input < input.txt
for array in "${input[@]}"; do
    declare -a "${array}"
done

find_items(){
    value=$1
    for i in "${!items[@]}"; do
        if [[ "${items[$i]}" = "${value}" ]]; then
            return "${i}";
        fi
    done
}
find_people(){
    value=$1
    for i in "${!people[@]}"; do
        if [[ "${people[$i]}" = "${value}" ]]; then
            return "${i}";
        fi
    done
}
find_actions(){
    value=$1
    for i in "${!actions[@]}"; do
        if [[ "${actions[$i]}" = "${value}" ]]; then
            return "${i}";
        fi
    done
}

declare -n room="office"
declare -n actions=${room[0]}
declare -n items=${room[1]}
declare -n people=${room[2]}
declare -n new_rooms=${room[3]}

while [ $won == "0" ]; do
    list_options() {
        unset possible_actions
        unset possible_items
        unset possible_people
        unset possible_new_rooms
        opt_num=1
        ###Actions
        for i in $(seq $(( ${#actions[@]} - 1 )) ); do
            ### if i is an action - based on position in list - and has the correct associated unlocked code at end of list
            if [[ $(( i % 3 )) == 1 ]] && [[ ${actions[$((i+1))]} -ge ${actions[ $(( ${#actions[@]} - 1 )) ]} ]]; then
                ### Adds info from (room)_actions into possible_actions in case that action needs to be accessed
                for j in {-1..1}; do
                    possible_actions+=( "${actions[$((i+j))]}" )
                done
                ### Prints the options and their associated #
                echo "[$opt_num] ${actions[i]}"
                opt_num=$(($opt_num+1))
            fi
            ###!!! NEED TO ADD IN QUESTION SUPPORT FOR ACTIONS!!!###
        done
        ###Items
        for i in $(seq $(( ${#items[@]} - 1 )) ); do
            if [[ $(( i % 3 )) == 1 ]] && [[ ${items[$((i+1))]} -ge ${items[ $(( ${#items[@]} - 1 )) ]} ]]; then
                for j in {-1..1}; do
                    possible_items+=( "${items[$((i+j))]}" )
                done
                echo "[$opt_num] ${items[$((i-1))]}"
                opt_num=$(($opt_num+1))
            fi
        done
        ###People
        for i in $(seq $(( ${#people[@]} - 1 )) ); do
            if [[ $(( i % 3 )) == 1 ]] && [[ ${people[$((i+1))]} -ge ${people[ $(( ${#people[@]} - 1 )) ]} ]]; then
                for j in {-1..1}; do
                    possible_people+=( "${people[$((i+j))]}" )
                done
                echo "[$opt_num] Speak to ${people[$i]}"
                opt_num=$(($opt_num+1))
            fi
        done
        ###Rooms
        for i in $(seq $(( ${#new_rooms[@]} - 1 )) ); do
            if [[ $(( i % 3 )) == 1 ]] && [[ ${new_rooms[$((i+1))]} -ge ${new_rooms[ $(( ${#new_rooms[@]} - 1 )) ]} ]]; then
                for j in {-1..1}; do
                    possible_new_rooms+=( "${new_rooms[$((i+j))]}" )
                done
                echo "[$opt_num] Move to ${new_rooms[$i]}"
                opt_num=$(($opt_num+1))
            fi
        done
    }

    while [[ true ]]; do
    list_options
    echo -e "\n"
    read -p "You decide to... "
    echo -e "\n"
        if [[ "$REPLY" != *" "* ]]; then
            if [[ $REPLY -lt $opt_num ]] && [[ $REPLY -gt 0 ]]; then
                if [[ $REPLY -le $(( ${#possible_actions[@]} / 3 )) ]]; then
                    clear
                    action_num=1
                    if [[ $REPLY == 1 ]]; then    
                        declare -n current_action=${possible_actions[0]}
                        action_name=${possible_actions[1]}
                    else
                        declare -n current_action=${possible_actions[$(( $(( $REPLY * 3 )) - 3 ))]}
                        action_name=${possible_actions[$(( $(($REPLY * 3)) - 2 ))]}
                    fi
                    find_actions "$action_name"
                    if [[ ${actions[$(($? + 1))]} == ${actions[$((${#actions[@]} - 1))]} ]]; then
                        action_pos=1
                    else
                        action_pos="$((${actions[$(($? + 1))]} + 1))"
                    fi
                    for (( i=$action_pos; x<=${#current_action[@]}; i++ )); do
                        if [[ ${current_action[$((i-1))]} == ?(-)+([0-9]) ]]; then
                            i=${current_action[$((i-1))]}
                        elif [[ ${current_action[$(($i-1))]} != "!" ]] && [[ ${current_action[$(($i-1))]} != "?" ]]; then
                            echo -e "${current_action[$(($i - 1))]}" | randtype -t 15,7500
                        elif [[ ${current_action[$(($i-1))]} == "?" ]]; then
                            echo -e "\n"
                            for j in $(seq ${current_action[$i]} ); do
                                echo -e "[$action_num] '${current_action[$(( $(($i-1)) + $((2 * j)) ))]}'"
                                action_num=$(($action_num + 1))
                            done
                            echo -e "\n\n"
                            read -p "You pick... "
                            if [[ "$REPLY" != *" "* ]]; then
                                if [[ $REPLY -le 0 ]] || [[ $REPLY -gt $(($action_num - 1)) ]]; then
                                    echo -e "\n\nThat is not a possible option, please choose an option from the list shown"
                                    action_num=1
                                    continue
                                fi
                            else
                                echo -e "\n\nThat is not a possible option, please choose an option from the list shown"
                                action_num=1
                                continue
                            fi
                            echo -e -n "\n\nYou: "
                            echo -e "'${current_action[$(( $(($i-1)) + $((2 * $REPLY)) ))]}'\n\n" | randtype -t 15,7500
                            echo -e "${current_action[ ${current_action[$(( $i + $((2 * $REPLY)) ))]} ]}" | randtype -t 15,7500
                            action_num=1
                            i=$(( ${current_action[$(( $i + $((2 * $REPLY)) ))]} + 1 ))
                            if [[ ${current_action[$(($i-1))]} == "!" ]]; then
                                echo -e "\n"
                                break
                            fi
                        elif [[ ${current_action[$(($i-1))]} == "!" ]]; then
                            echo -e "\n"
                            break
                        fi

                        ##Situational ifs

                        ###

                    done
                    if [[ ${current_action[$((${#current_action[@]} - 1))]} == ?(-)+([0-9]) ]]; then
                        if [[ ${current_action[$((${#current_action[@]} - 1))]} == 0 ]]; then
                            new_rooms[$(($? + 2))]=0
                        elif [[ ${current_action[$((${#current_action[@]} - 1))]} == 1 ]]; then
                            continue
                        elif [[ ${current_action[$((${#current_action[@]} - 1))]} -gt 1 ]]; then
                            current_action[1]="${current_action[$((${#current_action[@]} - 1))]}"
                        fi
                    else
                        continue
                    fi
                elif [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) -le $(( ${#possible_items[@]} / 3 )) ]]; then
                    clear
                    if [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) == 1 ]]; then
                        echo -e "${possible_items[1]}\n\n" | randtype -t 15,7500
                        previous_item=${possible_items[0]}
                        if [[ ${possible_items[2]} == ${items[ $(( ${#items[@]} - 1 )) ]} ]]; then
                            find_items "${possible_items[0]}"
                            items[$(($? + 2))]=$((${items[$(($? + 2))]} - 1))
                        fi
                    else
                        echo -e "${possible_items[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) * 3 )) - 2 ))]}\n\n" | randtype -t 15,7500
                        previous_item=${possible_items[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) * 3 )) - 3 ))]}
                        if [[ ${possible_items[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) * 3 )) - 1 ))]} == ${items[ $(( ${#items[@]} - 1 )) ]} ]]; then
                            find_items "${possible_items[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) * 3 )) - 3 ))]}"
                            items[$(($? + 2))]=$((${items[$(($? + 2))]} - 1))
                        fi
                    fi
                    
                    ###Situational ifs

                    ###

                elif [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) )) -le $(( ${#possible_people[@]} / 3 )) ]]; then
                    clear
                    speak_num=1
                    if [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) )) == 1 ]]; then
                        declare -n current_person=${possible_people[0]}
                        name=${possible_people[1]}
                    else
                        declare -n current_person=${possible_people[$(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) )) + 1 ))]}
                        name=${possible_people[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) )) * 3 )) - 2 ))]}
                    fi
                    echo -e "Talk to $name\n"
                    find_people "$name"
                    if [[ ${people[$(($? + 1))]} == ${people[$((${#people[@]} - 1))]} ]]; then
                        dialogue_pos=1
                    else
                        dialogue_pos="$((${people[$(($? + 1))]} + 1))"
                    fi
                    for (( i=$dialogue_pos; x<=${#current_person[@]}; i++ )); do
                        if [[ ${current_person[$((i-1))]} == ?(-)+([0-9]) ]]; then
                            i=${current_person[$((i-1))]}
                        elif [[ ${current_person[$(($i-1))]} != "!" ]] && [[ ${current_person[$(($i-1))]} != "?" ]]; then
                            echo -n "$name: "
                            echo -e "'${current_person[$(($i - 1))]}'" | randtype -t 15,7500
                            
                            ###Situational ifs

                            ###

                        elif [[ ${current_person[$(($i-1))]} == "?" ]]; then
                            echo -e "\n"
                            for j in $(seq ${current_person[$i]} ); do
                                echo -e "[$speak_num] '${current_person[$(( $(($i-1)) + $((2 * j)) ))]}'"
                                speak_num=$(($speak_num + 1))
                            done
                            echo -e "\n\n"
                            read -p "You say... "
                            if [[ "$REPLY" != *" "* ]]; then
                                if [[ $REPLY -le 0 ]] || [[ $REPLY -gt $(($speak_num - 1)) ]]; then
                                    echo -e "\n\nThat is not a possible option, please choose an option from the list shown"
                                    speak_num=1
                                    continue
                                fi
                            else
                                echo -e "\n\nThat is not a possible option, please choose an option from the list shown"
                                speak_num=1
                                continue
                            fi
                            echo -e -n "\n\nYou: "
                            echo -e "'${current_person[$(( $(($i-1)) + $((2 * $REPLY)) ))]}'\n\n" | randtype -t 15,7500
                            echo -n "$name: "
                            if [[ ${current_person[$(( $(( 2 * ${current_person[$i]} )) + $i ))]} == "*" ]] && [[ $REPLY == $(($speak_num - 1)) ]]; then
                                echo -e "'${current_person[ ${current_person[$(( $(($i + 1)) + $((2 * $REPLY)) ))]} ]}'" | randtype -t 15,7500
                                current_person[$i]=$(( ${current_person[$i]} - 1 ))
                                i=$(( ${current_person[$(( $(($i + 1)) + $((2 * $REPLY)) ))]} + 2 ))
                            else
                                echo -e "'${current_person[ ${current_person[$(( $i + $((2 * $REPLY)) ))]} ]}'" | randtype -t 15,7500
                                i=$(( ${current_person[$(( $i + $((2 * $REPLY)) ))]} + 2 ))
                            fi
                            if [[ ${current_person[$i+1]} == "?" ]]; then
                                speak_num=1
                                continue
                            fi
                            if [[ ${current_person[$(($i-1))]} == "!" ]]; then
                                echo -e "\n"
                                break
                            fi
                        elif [[ ${current_person[$(($i-1))]} == "!" ]]; then
                            echo -e "\n"
                            break
                        fi
                    done

                    ###Situational ifs

                    ###

                    if [[ ${current_person[$((${#current_person[@]} - 1))]} == ?(-)+([0-9]) ]]; then
                        if [[ ${current_person[$((${#current_person[@]} - 1))]} == 0 ]]; then
                            people[$(($? + 2))]=0
                        elif [[ ${current_person[$((${#current_person[@]} - 1))]} == 1 ]]; then
                            continue
                        elif [[ ${current_person[$((${#current_person[@]} - 1))]} -gt 1 ]]; then
                            current_person[1]="${current_person[$((${#current_person[@]} - 1))]}"
                        fi
                    else
                        continue
                    fi
                elif [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) - $(( ${#possible_people[@]} / 3 )) )) -le $(( ${#possible_new_rooms[@]} / 3 )) ]]; then
                    clear
                    if [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) - $(( ${#possible_people[@]} / 3 )) )) == 1 ]]; then
                        echo -e "You move to ${possible_new_rooms[1]}\n\n"
                        declare -n room="${possible_new_rooms[0]}"
                    else
                        echo -e "You move to ${possible_new_rooms[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) - $(( ${#possible_people[@]} / 3 )) )) * 3 )) - 2 ))]}\n\n"
                        declare -n room="${possible_new_rooms[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) - $(( ${#possible_people[@]} / 3 )) )) * 3 )) - 3 ))]}"
                    fi
                    declare -n actions=${room[0]}
                    declare -n items=${room[1]}
                    declare -n people=${room[2]}
                    declare -n new_rooms=${room[3]}
                    continue
                fi
            else
                clear
                echo -e "That is not a possible option, please choose an option from the list shown\n\n"
                continue
            fi
        else
            clear
            echo -e "That is not a possible option, please choose an option from the list shown\n\n"
            continue
        fi
    done
    exit
done
