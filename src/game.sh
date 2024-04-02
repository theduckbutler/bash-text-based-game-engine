#!/bin/bash

### availability code abbreviated to AC

#'reads' in all of the arrays from the input file
if [[ -f "$PWD/input.txt" ]]; then
    readarray -t input < input.txt
    for array in "${input[@]}"; do
        declare -a "${array}"
    done
else
    echo "Error: input.txt has either been moved or is missing" && exit
fi

won=0
stty -echo

declare -A room="office"
declare -n actions="${room}_actions"
declare -n items="${room}_items"
declare -n people="${room}_people"
declare -n new_rooms="${room}_rooms"
declare -n descriptions="${room}_descriptions"
if [[ ${new_rooms[@]} == "" ]]; then
    echo "Error: the starting location array within input.txt is either missing, or incorrectly labeled" && exit
fi

list_options() {
    unset possible_actions
    unset possible_items
    unset possible_people
    unset possible_new_rooms
	unset possible_descriptions
    opt_num=1
	echo #
	###Description
	for i in $(seq $(( ${#descriptions[@]} - 1 )) ); do
		if [[ $(( i % 3 )) == 1 ]] && [[ ${descriptions[$((i))]} -ge ${descriptions[ $(( ${#descriptions[@]} - 1 )) ]} ]]; then
			for j in {-1..1}; do
				possible_descriptions+=( "${descriptions[$((i+j))]}" )
			done
			echo ${descriptions[i-1]}
			if [[ ${descriptions[i]} -gt ${descriptions[ $(( ${#descriptions[@]} - 1 )) ]} ]]; then
				descriptions[i]=0
			fi
		fi
	done
	echo #
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

### find functions return index of the value passed into it
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
### function to simulate typewriter
type() {
    text="$1"
    start="$2"
    for k in $(seq $start $(expr length "${text}")); do
        if [[ "${text:$k:1}" == "n" ]] && [[ "${text:$(($k-1)):1}" == "\\" ]]; then
            continue
        fi
        if [[ "${text:$k:1}" == "\\" ]] && [[ "${text:$(($k+1)):1}" == "n" ]]; then
            echo #
            continue
        fi
        echo -n "${text:$k:1}"
        delay=`shuf -i 1-10 -n 1`
        sleep `bc -l <<< "scale=2; $delay/100"`
    done
    echo #
}

ask() {
    stty echo  
    read -N 10000000 -t 0.01
    read -p "$1" && stty -echo
}

echo "Title"
echo -e "Introduction"

while [ $won == "0" ]; do
    while [[ true ]]; do
    	list_options
    	echo -e "\n"
    	ask "You decide to... "
    	echo -e "\n"
        if [[ "$REPLY" != *" "* ]]; then
            if [[ $REPLY -lt $opt_num ]] && [[ $REPLY -gt 0 ]]; then
                ###Actions
                if [[ $REPLY -le $(( ${#possible_actions[@]} / 3 )) ]]; then
                    clear
                    action_num=1
                    ###set the current dialogue array to lookup to the one of the selected person
                    if [[ $REPLY == 1 ]]; then    
                        declare -n current_action=${possible_actions[0]}
                        action_name=${possible_actions[1]}
                    else
                        declare -n current_action=${possible_actions[$(( $(( $REPLY * 3 )) - 3 ))]}
                        action_name=${possible_actions[$(( $(($REPLY * 3)) - 2 ))]}
                    fi
                    find_actions "$action_name"
                    ###set action_pos to correct associated AC value
                    if [[ ${actions[$(($? + 1))]} == ${actions[$((${#actions[@]} - 1))]} ]]; then
                        action_pos=1
                    else
                        action_pos="$((${actions[$(($? + 1))]} + 1))"
                    fi
                    ###whether or not to prepare array of indices for situational ifs
                    accessed_indices=()
                    if [[ "${current_action[*]}" =~ "?" ]]; then
                        accessed_indices[0]="${!current_action}"
                    fi
                    ##for every index from start to end that is accessed
                    for (( i=$action_pos; i<=${#current_action[@]}; i++ )); do
                        ###if current index is a #, jump to that index within the array
                        if [[ ${current_action[$((i-1))]} == ?(-)+([0-9]) ]]; then
                            i=${current_action[$((i-1))]}
                        elif [[ ${current_action[$((i-1))]} == ">" ]]; then
                            i=$(($i+2))
                        ###if current index isn't an end code or question, print out the text
                        elif [[ ${current_action[$(($i-1))]} != "!" ]] && [[ ${current_action[$(($i-1))]} != "?" ]]; then
                            type "${current_action[$(($i - 1))]}" 0
                        elif [[ ${current_action[$(($i-1))]} == "?" ]]; then
                            echo -e "\n"
                            question_num=1
                            unset question_choice
                            for j in $(seq ${current_action[$i]} ); do
                                if [[ ${current_action[$(( $(($i-1)) + $((3 * j)) ))]} != "^" ]]; then
                                    if ${current_action[$(( $i + $((3 * j)) ))]} == "#" ]] && [[ $action_num == 1 ]]; then
                                        break 2
                                    else
                                        echo -e "[$action_num] '${current_action[$(( $(($i-2)) + $((3 * j)) ))]}'"
                                        action_num=$(($action_num + 1))
                                        question_choice+=($question_num)
                                    fi
                                fi
                                question_num=$(($question_num + 1))
                            done
                            echo -e "\n"
                            ask "You pick... "
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
                            ###adds index of chosen answer to array, for situational ifs
                            accessed_indices+=($(( $(($i-2)) + $((3 * ${question_choice[$(($REPLY-1))]})) )))

                            ###VERY SPECIAL, VERY SPECIFICALLY TIME DEPENDENT SITUATIONAL IF

                            ###

                            ###jump to index of option chosen
                            echo -e -n "\n\nYou: "
                            type "'${current_action[$(( $(($i-2)) + $((3 * ${question_choice[$(($REPLY-1))]})) ))]}'\n\n" 0
                            if [[ ${current_action[$(( $i + $((3 * ${question_choice[$(($REPLY-1))]})) ))]} == "#" ]]; then
                                break
                            fi
                            type "${current_action[ ${current_action[$(( $i + $((3 * ${question_choice[$(($REPLY-1))]})) ))]} ]}" 0
                            ###check for * character, revert to ^ signifying not to use as option anymore
                            if [[ ${current_action[$(( $(( ${question_choice[$(($REPLY-1))]} * 3 )) + $(($i-1)) ))]} == "*" ]]; then
                                current_action[$(( $(( ${question_choice[$(($REPLY-1))]} * 3 )) + $(($i-1)) ))]="^"
                            fi
                            if [[ ${current_action[$(($i-1))]} != "#" ]]; then
                                backup_i=$i
                            else
                                unset backup_i
                                break
                            fi
                            ### person responds, i value adjusted accordingly
                            i=$(( ${current_action[$i + $((3 * ${question_choice[$(($REPLY-1))]} ))]} + 2 ))
                            ###whether or not an additional prompt is coming soon, may as well be sure the action_num is 1
                            action_num=1
                            ###quick check for any immediate ends
                            if [[ ${current_action[$(($i-1))]} == "!" ]]; then
                                echo -e "\n"
                                break
                            fi
                        elif [[ ${current_action[$(($i-1))]} != "#" ]]; then
                            ### must be set to backup minus one since it is about to loop back around, with i++ increasing it
                            i=$(($backup_i-1))
                        ###if received end code, exit action
                        elif [[ ${current_action[$(($i-1))]} == "!" ]]; then
                            echo -e "\n"
                            break
                        fi

                        ##Situational ifs

                        ###

                    done
                    ###where to point to based upon action's AC
                    if [[ ${current_action[$((${#current_action[@]} - 1))]} == ?(-)+([0-9]) ]]; then
                        ###if action's AC < 1, essentially disable action from being accessed
                        if [[ ${current_action[$((${#current_action[@]} - 1))]} == 0 ]]; then
                            new_rooms[$(($? + 2))]=0
                        ###if action's AC == 1, action starts as normal
                        elif [[ ${current_action[$((${#current_action[@]} - 1))]} == 1 ]]; then
                            continue
                        ###if action's AC > array AC, after initial text, redirect to index of array that is array AC
                        elif [[ ${current_action[$((${#current_action[@]} - 1))]} -gt 1 ]]; then
                            current_action[1]="${current_action[$((${#current_action[@]} - 1))]}"
                        fi
                    else
                        continue
                    fi
                ###Items
                elif [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) -le $(( ${#possible_items[@]} / 3 )) ]]; then
                    clear
                    ###all item info stored within one array/room, simpler info
                    ###just redirects where to read from based on item selected
                    if [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) == 1 ]]; then
                        type "${possible_items[1]}\n\n" 0
                        previous_item=${possible_items[0]}
                        if [[ ${possible_items[2]} == ${items[ $(( ${#items[@]} - 1 )) ]} ]]; then
                            find_items "${possible_items[0]}"
                            items[$(($? + 2))]=$((${items[$(($? + 2))]} - 1))
                        fi
                    else
                        type "${possible_items[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) * 3 )) - 2 ))]}\n\n" 0
                        previous_item=${possible_items[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) * 3 )) - 3 ))]}
                        if [[ ${possible_items[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) * 3 )) - 1 ))]} == ${items[ $(( ${#items[@]} - 1 )) ]} ]]; then
                            find_items "${possible_items[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) )) * 3 )) - 3 ))]}"
                            items[$(($? + 2))]=$((${items[$(($? + 2))]} - 1))
                        fi
                    fi
                    
                    ###Situational ifs

                    ###

                ###People
                elif [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) )) -le $(( ${#possible_people[@]} / 3 )) ]]; then
                    clear
                    speak_num=1
                    ###set the current dialogue array to lookup to the one of the selected person
                    if [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) )) == 1 ]]; then
                        declare -n current_person=${possible_people[0]}
                        name=${possible_people[1]}
                    else
                        declare -n current_person=${possible_people[$(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) )) + 1 ))]}
                        name=${possible_people[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) )) * 3 )) - 2 ))]}
                    fi
                    echo -e "Talk to $name\n"
                    find_people "$name"
                    ###if person's AC matches array's AC set dialogue_pos to 1, otherwise a new starting index has been set, saved as the array's AC
                    ###determine starting index within dialogue array (excluding default index 0 greeting that is always used)
                    if [[ ${people[$(($? + 1))]} == 1 ]]; then
                        dialogue_pos=1
                    else
                        dialogue_pos="$((${people[$(($? + 1))]} + 1))"
                    fi
                    ###whether or not to prepare array of indices for situational ifs
                    accessed_indices=()
                    if [[ "${current_person[*]}" =~ "?" ]]; then
                        accessed_indices[0]="${!current_person}"
                    fi
                    ##for every index from start to end that is accessed
                    for (( i=$dialogue_pos; i<=${#current_person[@]}; i++ )); do
                        ###if current index is a #, jump to that index within the array
                        if [[ ${current_person[$((i-1))]} == ?(-)+([0-9]) ]]; then
                            i=${current_person[$((i-1))]}
                        elif [[ ${current_person[$((i-1))]} == ">" ]]; then
                            i=$(($i+2))
                        ###if current index isn't an end code or question, print out the dialogue
                        elif [[ ${current_person[$(($i-1))]} != "!" ]] && [[ ${current_person[$(($i-1))]} != "?" ]]; then
                            echo -n "$name: "
                            type "'${current_person[$(($i - 1))]}'" 0
                            
                            ###Situational ifs

                            ###
                        
                        ###if current index is a question read out possible answers
                        elif [[ ${current_person[$(($i-1))]} == "?" ]]; then
                            echo -e "\n"
                            question_num=1
                            unset question_choice
                            for j in $(seq ${current_person[$i]} ); do
                                ### ^ following a question answer indicates it should not be displayed as an option
                                if [[ ${current_person[$(( $(($i-1)) + $((3 * j)) ))]} != "^" ]]; then
                                    if [[ ${current_person[$(( $i + $((3 * j)) ))]} == "#" ]] && [[ $speak_num == 1 ]] && [[ $i == $backup_i ]]; then
                                        unset backup_i
                                        break 2
                                    else
                                        echo -e "[$speak_num] '${current_person[$(( $(($i-2)) + $((3 * j)) ))]}'"
                                        speak_num=$(($speak_num + 1))
                                        question_choice+=($question_num)
                                    fi
                                fi
                                question_num=$(($question_num + 1))
                            done
                            echo -e "\n"
                            ask "You say... "
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
                            ###adds index of chosen answer to array, for situational ifs
                            accessed_indices+=($(( $(($i-2)) + $((3 * ${question_choice[$(($REPLY-1))]})) )))
                            ###jump to index of option chosen
                            echo -e -n "\n\nYou: "
                            type "'${current_person[$(( $(($i-2)) + $((3 * ${question_choice[$(($REPLY-1))]})) ))]}'\n\n" 0
                            if [[ ${current_person[$(( $i + $((3 * ${question_choice[$(($REPLY-1))]})) ))]} == "#" ]]; then
                                break
                            fi
                            echo -n "$name: "
                            type "'${current_person[ ${current_person[$(( $i + $((3 * ${question_choice[$(($REPLY-1))]})) ))]} ]}'" 0
                            ###check for * character, revert to ^ signifying not to use as option anymore
                            if [[ ${current_person[$(( $(( ${question_choice[$(($REPLY-1))]} * 3 )) + $(($i-1)) ))]} == "*" ]]; then
                                current_person[$(( $(( ${question_choice[$(($REPLY-1))]} * 3 )) + $(($i-1)) ))]="^"
                            fi
                            if [[ ${current_person[$(($i-1))]} != "#" ]]; then
                                backup_i=$i
                            else
                                unset backup_i
                                break
                            fi
                            i=$(( ${current_person[$i + $((3 * ${question_choice[$(($REPLY-1))]} ))]} + 2 ))
                            ###whether or not an additional prompt is coming soon, may as well be sure the speak_num is 1
                            speak_num=1
                            ###quick check for any immediate ends
                            if [[ ${current_person[$(($i-1))]} == "!" ]]; then
                                echo -e "\n"
                                break
                            fi
                        elif [[ ${current_person[$(($i-1))]} != "#" ]]; then
                            ### must be set to backup minus one since it is about to loop back around, with i++ increasing it
                            i=$(($backup_i-1))
                        ###if received end code, exit dialogue
                        elif [[ ${current_person[$(($i-1))]} == "!" ]]; then
                            echo -e "\n"
                            break
                        fi
                    done

                    ###Situational ifs

                    ###

                    ###where to point to based upon person's AC
                    if [[ ${current_person[$((${#current_person[@]} - 1))]} == ?(-)+([0-9]) ]]; then
                        ###if person's AC < 1, essentially disable character from being talked to
                        if [[ ${current_person[$((${#current_person[@]} - 1))]} == 0 ]]; then
                            people[$(($? + 2))]=0
                        ###if person's AC == 1, dialogue starts as normal
                        elif [[ ${current_person[$((${#current_person[@]} - 1))]} == 1 ]]; then
                            continue
                        ###if person AC > array AC, redirect to index of array that is array AC
                        elif [[ ${current_person[$((${#current_person[@]} - 1))]} -gt 1 ]]; then
                            current_person[1]="${current_person[$((${#current_person[@]} - 1))]}"
                        fi
                    else
                        continue
                    fi
                ###New rooms
                elif [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) - $(( ${#possible_people[@]} / 3 )) )) -le $(( ${#possible_new_rooms[@]} / 3 )) ]]; then
                    clear
                    if [[ $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) - $(( ${#possible_people[@]} / 3 )) )) == 1 ]]; then
                        echo -e "You move to ${possible_new_rooms[1]}"
                        declare -A room="${possible_new_rooms[0]}"
                    else
                        echo -e "You move to ${possible_new_rooms[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) - $(( ${#possible_people[@]} / 3 )) )) * 3 )) - 2 ))]}"
                        declare -A room="${possible_new_rooms[$(( $(( $(( $REPLY - $(( ${#possible_actions[@]} / 3 )) - $(( ${#possible_items[@]} / 3 )) - $(( ${#possible_people[@]} / 3 )) )) * 3 )) - 3 ))]}"
                    fi
                    ###reassign current array's for all associated objects
                    declare -n actions="${room}_actions"
                    declare -n items="${room}_items"
                    declare -n people="${room}_people"
                    declare -n new_rooms="${room}_rooms"
					declare -n descriptions="${room}_descriptions"
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