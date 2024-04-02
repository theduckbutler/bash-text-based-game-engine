#!/bin/bash
types=( "_actions" "_items" "_people" "_rooms" )
title=( "action" "item" "person" "room" )
empty="X=( \"X_actions\" \"X_items\" \"X_people\" \"X_rooms\" )"
file="input.txt"

add_to_file() {
    #remove any \n's so sed doesn;t get angry
    sed -i 's/\\n/​/g' $file
    readarray -t input < $file
    for array in "${input[@]}"; do
        declare -a "${array}"
    done
    new_array=$1
    new_array_title=$2
    display_title=$3
    declare -n destination="$new_array"
    #determine whether there are 1 or 2 final indices in the array (array being added to)
    if [[ $((${#destination[@]} % 3)) == 1 ]]; then
        #only one final index
        last_index_offset=1
        final_index=${destination[-1]}
    elif [[ $((${#destination[@]} % 3)) == 2 ]]; then
        #two final indices
        last_index_offset=2
        final_index=2
        second_last_index=${destination[-2]}
    fi
    #create variable that is array for use with sed
    container_array="$new_array=( "
    for i in $(seq $((${#destination[@]} - $last_index_offset))); do
        i=$(($i-1))
        if [[ ${destination[$i]} == ?(-)+([0-9]) ]]; then
            container_array="$container_array${destination[$i]} "
        else
            container_array="$container_array\"${destination[$i]}\" "
        fi
    done
    #create frankenstein variable of the end of the array variables
    final_addon="\"$new_array_title\" \"$display_title\" $interactability "
    if [[ $second_last_index == "" ]]; then
        final_addon="$final_addon$final_index )"
    else
        final_addon="$final_addon$second_last_index $final_index )"
    fi
    #update array in input.txt file
    sed -i "s/\($container_array\).*/\1$final_addon/" $file
    #add the \n's back in after sed does its thing
    sed -i 's/​/\\n/g' $file
    readarray -t input < $file
    for array in "${input[@]}"; do
        declare -a "${array}"
    done
}

echo -e "Would you like to...\n\n[1] Start new 'input.sh' file\n\n          or\n\n[2] Continue a previous 'input.sh' file\n\n"
read -p "Choose... "

if [[ $REPLY == 1 ]]; then
    echo -e "\n\nStep 1: Creating the Initial Room\n\n"
    read -p "Choose an array name for the first room (no spaces): "
    echo ${empty//X/"$REPLY"} > $file
    for i in ${types[@]}; do
        printf "%s%s=( 1 )\n" "$REPLY" "$i" >> $file
    done
elif [[ $REPLY == 2 ]]; then
    echo #
    echo #
    read -p "Please input the directory which your 'input.txt' is located within (leave blank if you're within that directory): "
    file="$REPLY""input.txt"
else
    echo "\n\nThat is not a possible option" && exit
fi
echo #
while [[ pigs != flying_animal ]]; do
    if [[ -f "$PWD/input.txt" ]]; then
        readarray -t input < $file
        for array in "${input[@]}"; do
            declare -a "${array}"
        done
    else
        echo "Error: 'input.txt' has either been moved or is missing" && exit
    fi

    echo -e "\nPossible Editing Actions are...\n\n[1] List actions in current file\n[2] List items in current file\n[3] List people in current file\n[4] List rooms in currrent file\n[5] Add new action\n[6] Add new item\n[7] Add new person\n[8] Add new room\n[9] Finish building story\n"

    read -p "Choose..." add_choice
    echo #

    if [[ $add_choice == ?(-)+([0-9]) ]]; then
        #listing
        if [[ $add_choice -le 4 ]] && [[ $add_choice -gt 0 ]]; then
            for array in "${input[@]}"; do
                if [[ ! $array =~ [0-9] ]] && [[ ! $array ==  *"!"* ]]; then
                    removal=${array%%=*}
                    ###lookup is the name of the master room array that lists names of rooms items etc. (ie. office)
                    lookup="${array::${#removal}}"
                    final=$lookup[$(($add_choice-1))]
                    ###want is the array name of the thing looked for within the master room list (ie. office_actions)
                    want="${!final}"
                    declare -n destination=${want[*]}
                    ### the rest of the larger for loop prints out the information in a nice readable format
                    echo -n "--$want=( "
                    for i in $(seq ${#destination[@]}); do
                        i=$(($i-1))
                        if [[ ${destination[$i]} == ?(-)+([0-9]) ]]; then
                            echo -n "${destination[$i]} "
                        else echo -n "\"${destination[$i]}\" "
                        fi
                    done
                    echo -ne ")\n\n"
                    unset destination
                fi
            done
            continue
        fi
        #adding
        if [[ $add_choice -le 8 ]] && [[ $add_choice -gt 4 ]]; then
            echo -e "\nWhich room do you want to add to?\n"
            i=1
            for array in "${input[@]}"; do
                if [[ ! $array =~ [0-9] ]] && [[ ! $array == *"!"* ]]; then
                    removal=${array%%=*}
                    echo "[$i] $removal"
                    i=$(($i+1))
                fi
            done
            echo #
            read -p "Choose..." which_room
            if [[ $which_room == [0-9] ]] && [[ $which_room -gt 0 ]] && [[ $which_room -lt $i ]]; then
                i=0
                for array in "${input[@]}"; do
                    if [[ $which_room != $i ]] && [[ ! $array =~ [0-9] ]] && [[ ! $array == *"!"* ]]; then
                        removal=${array%%=*}
                        i=$(($i+1))
                    fi
                done
                echo #
                echo #
                new="${removal}${types[$(($add_choice-5))]}"
                #choose name for array of new thing
                if [[ $add_choice != 6 ]]; then
                    read -p "Array name for the ${title[$(($add_choice-5))]}: " new_array_name
                    if [[ $new_array_name != "" ]]; then
                        declare -n next=$new_array_name
                        if [[ "${next[0]}" == "" ]]; then
                            echo #
                            echo #
                            #choose display name
                            read -p "Name for the ${title[$(($add_choice-5))]} to display as: " display_name
                            echo $add_choice
                            if [[ $display_name != "" ]]; then
                                if [[ $add_choice != "8" ]]; then
                                    echo -e "\n\nAssign property to final item of array\n"
                                elif [[ $add_choice == "8" ]]; then
                                    echo -e "\n\nAssign ability to move into existing room\n"
                                fi
                                echo -e "[1] Make the ${title[$(($add_choice-5))]} interactable\n[2] Make the ${title[$(($add_choice-5))]} not currently interactable\n\n"
                                read -p "Choose..."
                                echo #
                                #determine interactability code
                                if [[ $REPLY == 1 ]]; then
                                    interactability=$REPLY
                                elif [[ $REPLY == 2 ]]; then
                                    interactability=$(($REPLY-2))
                                else
                                    echo -e "\n\nThat is not a possible option\n" && continue
                                fi 
                                #does thing show up? not show up? where?
                                if [[ $REPLY == [0-9] ]] && [[ $REPLY -gt 0 ]] && [[ $REPLY -lt 3 ]]; then
                                    if [[ $add_choice == 5 ]] || [[ $add_choice == 7 ]]; then
                                        echo "$new_array_name=( $(($REPLY-1)) )" >> $file
                                    #special extra steps if adding a room
                                    elif [[ $add_choice == 8 ]]; then
                                        echo ${empty//X/"$new_array_name"} >> $file
                                        for i in ${types[@]}; do
                                            printf "%s%s=( 1 )\n" "$new_array_name" "$i" >> $file
                                        done
                                        echo -e "\nDo you want to be able to move between both rooms, or just have a one way connection?\n\n[1] Two way connection (both '$new_array_name' to '$removal' and '$removal' to '$new_array_name')\n[2] One way connection (only '$removal' to '$new_array_name')\n[3] One way connection (only '$new_array_name' to '$removal')\n"
                                        read -p "Choose..." room_direction
                                        if [[ $room_direction == 1 ]] || [[ $room_direction == 3 ]]; then
                                            echo -e "\n\nDisplay name for the connecting room (from '$display_name' to ...) to display as\n"
                                            read -p "Choose..."
                                            echo #
                                            add_to_file "${new_array_name}_rooms" $removal "$REPLY"
                                            echo -e "\n\nAssign abilty to move into '$display_name'\n"
                                            echo -e "[1] Make the ${title[$(($add_choice-5))]} interactable\n[2] Make the ${title[$(($add_choice-5))]} not currently interactable\n\n"
                                            read -p "Choose..."
                                            echo #
                                            #determine interactability code
                                            if [[ $REPLY == 1 ]]; then
                                                interactability=$REPLY
                                            elif [[ $REPLY == 2 ]]; then
                                                interactability=$(($REPLY-2))
                                            else
                                                echo -e "\n\nThat is not a possible option\n" && continue
                                            fi 
                                        elif [[ $room_direction != 2 ]]; then
                                            echo -e "\n\nThat is not a possible option\n'$new_array_name' must be connected to seperare rooms manually now" && continue
                                        fi 
                                    fi
                                    if [[ $room_direction != 3 ]]; then
                                        add_to_file $new $new_array_name "$display_name"
                                        unset room_direction
                                    fi
                                else
                                    echo -e "\n\nThat is not a possible option\n" && continue
                                fi
                            else
                                echo -e "\n\nDisplay names cannot be blank, please choose a different name\n" && continue
                            fi
                        else
                            echo -e "\n\nArray '$REPLY' already exists, please choose a different name\n" && continue
                        fi
                    else
                        echo -e "\n\nArray names cannot be blank, please choose a different name\n" && continue
                    fi
                else
                    #silly funny different rules for adding an item
                    read -p "Prompt for the ${title[$(($add_choice-5))]} to display as: " display_name
                    if [[ $display_name != "" ]]; then
                        echo -e "\n\nAssign property to final item of array\n"
                        echo -e "[1] Make the ${title[$(($add_choice-5))]} disappear after one interaction\n[2] Make the ${title[$(($add_choice-5))]} remain available for interaction\n[3] Make the ${title[$(($add_choice-5))]} not currently interactable\n\n"
                        read -p "Choose..."
                        echo #
                        #determine interactability code
                        if [[ $REPLY == 1 ]] || [[ $REPLY == 2 ]]; then
                            interactability=$REPLY
                        elif [[ $REPLY == 3 ]]; then
                            interactability=$(($REPLY-3))
                        else
                            echo -e "\n\nThat is not a possible option\n" && continue
                        fi
                        add_to_file $new "$display_name" "This item doesn't have a description yet"
                    else
                        echo -e "\n\nDisplay names cannot be blank, please choose a different name\n" && continue
                    fi
                fi
            else
                echo -e "\n\nArray '$which_room' either does not exist or cannot be edited (make sure to input the associated number)\n" && continue
            fi
        elif [[ $add_choice == 9 ]]; then
            exit
        else
            echo -e "\nThat is not a possible option\n" && continue
        fi
    fi
done