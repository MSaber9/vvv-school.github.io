#!/bin/bash

# Copyright: (C) 2016 iCub Facility - Istituto Italiano di Tecnologia
# Authors: Ugo Pattacini <ugo.pattacini@iit.it>
# CopyPolicy: Released under the terms of the GNU GPL v3.0.
#
# Dependencies (through apt-get):
# - curl
# - jq
#
# The env variable GIT_TOKEN_ORG_READ should contain a valid GitHub
# token with "org:read" permission to retrieve organization data
#

if [ $# -lt 4 ]; then
    echo "Usage: $0 <organization> <team> <abspath-to-gradebook> <abspath-to-build>"
    exit 1
fi

if [ -z "$GIT_TOKEN_ORG_READ" ]; then
    echo -e "${red}env variable GIT_TOKEN_ORG_READ is not set${data}${nc}\n"
    exit 2
fi

org=$1
team=$2
path=$3

if [ ! -d "$4" ]; then
    mkdir $4
fi
cd "$4"

data=$path/data.json
README=$path/README.md
gradebook_cur=$path/gradebook.json
gradebook_new=gradebook-new.json
gradebook_tmp=gradebook-tmp.json

if [ ! -f "$data" ]; then
    echo -e "${red}Unable to find ${data}${nc}\n"
    exit 3
fi

# color codes
red='\033[1;31m'
green='\033[1;32m'
blue='\033[1;34m'
cyan='\033[1;36m'
nc='\033[0m'

# GitHub symbols
status_passed=":white_check_mark:"
status_failed=":x:"

# GitHub token for authorized access
token_header="-H \"Authorization: token $GIT_TOKEN_ORG_READ\""

# get students from $team
team_id=$(eval "curl -s $token_header -G https://api.github.com/orgs/vvv-school/teams | jq 'map(select(.name==\"$team\")) | .[0] | .id'")
students=$(eval "curl -s $token_header -G https://api.github.com/teams/$team_id/members | jq '.[] | .login' | sed 's/\"//g'")

tutorials=$(eval "cat $data | jq '.tutorials | .[] | .name' | sed 's/\\\"//g'")
assignments=$(eval "cat $data | jq '.assignments | .[] | .name' | sed 's/\\\"//g'")

# compute the student's score counting tutorials and assignments
function update_score {
    local stud=$1
    
    local stud_tutorials=$(eval "cat $gradebook_new | jq 'map(select(.username==\"$stud\")) | .[0] | .tutorials | .[] | .name' | sed 's/\\\"//g'")
    local stud_assignments=$(eval "cat $gradebook_new | jq 'map(select(.username==\"$stud\")) | .[0] | .assignments | .[] | .name' | sed 's/\\\"//g'")

    local score=0
    for tuto1 in $stud_tutorials; do
        for tuto2 in $tutorials; do
           if [ "${tuto1}" == "${tuto2}-${stud}" ]; then
              local tmp=$(eval "cat $data | jq '.tutorials | map(select(.name==\"$tuto2\")) | .[0] | .score'")
              let "score = $score + $tmp"
              break
           fi 
        done
    done
    
    for assi1 in $stud_assignments; do
        for assi2 in $assignments; do
           if [ "${assi1}" == "${assi2}-${stud}" ]; then
              local item=$(eval "cat $data | jq '.assignments | map(select(.name==\"$assi2\")) | .[0]'")
              local tmp=$(echo "$item" | jq '.status')
              if [ "${tmp}" == "${status_passed}" ]; then
                 tmp=$(echo "$item" | jq '.score')
                 let "score = $score + $tmp"
              fi
              break
           fi 
        done
    done
    
    echo -e "${green}${stud}${nc} has now score = ${cyan}${score}${nc}" > /dev/stderr
    local jq_path=$(eval "cat $gradebook_new | jq -c 'paths(.username?==\"$stud\")'") 
    jq_path=$(echo "$jq_path" | jq -c '.+["score"]')
    
    cp $gradebook_new $gradebook_tmp
    eval "cat $gradebook_tmp | jq 'setpath(${jq_path};${score})' > $gradebook_new"
    rm $gradebook_tmp
}

# push the new gradebook to GitHub
function publish_gradebook {
    cp $gradebook_new $gradebook_cur
    cur_dir=$(pwd)

    cd $path
    git diff --quiet
    if [ $? -ne 0 ]; then
        echo -e "${green}Publishing the gradebook${nc}\n" > /dev/stderr
        local keep_leading_lines=1
        cp $README $cur_dir/readme.tmp
        head -"${keep_leading_lines}" $cur_dir/readme.tmp > $README
        
        local num_students_1=$(eval "cat $gradebook_cur | jq 'length-1'")
        for i in `seq 0 $num_students_1`; do
            eval "cat $gradebook_cur | jq '.[$i]'" > $cur_dir/student_data.tmp
            local username=$(eval "cat $cur_dir/student_data.tmp | jq '.username' | sed 's/\\\"//g'")            
            echo "" >> $README
            echo -e "### [**$username**](https://github.com/$username) grade\n" >> $README            
            echo -e "| assignment | status | score |" >> $README
            echo -e "|    :--:    |  :--:  | :--:  |" >> $README
            local empty=true;
            
            eval "cat $cur_dir/student_data.tmp | jq '.tutorials'" > $cur_dir/tutorials_data.tmp
            local num_tutorials_1=$(eval "cat $cur_dir/tutorials_data.tmp | jq 'length-1'")
            for t in `seq 0 $num_tutorials_1`; do
                local name=$(eval "cat $cur_dir/tutorials_data.tmp | jq '.[$t] | .name' | sed 's/\\\"//g'")
                local status=$(eval "cat $cur_dir/tutorials_data.tmp | jq '.[$t] | .status' | sed 's/\\\"//g'")
                local score=$(eval "cat $cur_dir/tutorials_data.tmp | jq '.[$t] | .score'")
                if [ "$status" != "$status_passed" ]; then
                    score=0
                fi
                echo -e "| [$name](https://github.com/$org/$name) | $status | $score |" >> $README
                empty=false;
            done
        
            eval "cat $cur_dir/student_data.tmp | jq '.assignments'" > $cur_dir/assignments_data.tmp
            local num_assignments_1=$(eval "cat $cur_dir/assignments_data.tmp | jq 'length-1'")
            for a in `seq 0 $num_assignments_1`; do
                local name=$(eval "cat $cur_dir/assignments_data.tmp | jq '.[$a] | .name' | sed 's/\\\"//g'")
                local status=$(eval "cat $cur_dir/assignments_data.tmp | jq '.[$a] | .status' | sed 's/\\\"//g'")
                local score=$(eval "cat $cur_dir/assignments_data.tmp | jq '.[$a] | .score'")
                if [ "$status" != "$status_passed" ]; then
                    score=0
                fi                
                echo -e "| [$name](https://github.com/$org/$name) | $status | $score |" >> $README
                empty=false;
            done
            
            if [ "${empty}" == "true" ]; then
                # remove the table
                cp $README $cur_dir/readme.tmp
                head -n -2 $cur_dir/readme.tmp > $README
            else
                echo "" >> $README
            fi
            
            local totscore=$(eval "cat $cur_dir/student_data.tmp | jq '.score'")
            local color="brightgreen"
            local style="flat-square"
            if [ $totscore -eq 0 ]; then
                color="orange"
            fi
            echo -e "![total score](https://img.shields.io/badge/total_score-${totscore}-${color}.svg?style=${style})\n" >> $README
            echo -e "---\n" >> $README
        done
        
        if [ -f $cur_dir/readme.tmp ]; then
            rm $cur_dir/readme.tmp
        fi
        if [ -f $cur_dir/student_data.tmp ]; then
            rm $cur_dir/student_data.tmp
        fi
        if [ -f $cur_dir/tutorials_data.tmp ]; then
            rm $cur_dir/tutorials_data.tmp
        fi
        if [ -f $cur_dir/assignments_data.tmp ]; then
            rm $cur_dir/assignments_data.tmp
        fi

        git add $gradebook_cur $README
        git commit --quiet -m "updated by automatic grading script"
        git push --quiet origin master
        if [ $? -ne 0 ]; then
            echo -e "${red}Problems detected while pushing to GitHub${nc}" > /dev/stderr
        fi
    fi
    
    cd $cur_dir
}

function smoke_test() {
    local repo=$1
    local url=$2
    if [ -d "$repo" ]; then
        rm $repo -rf
    fi
 
    local ret="error"
    git clone $url
    if [ $? -eq 0 ]; then
        if [ -d "$repo/smoke-test" ]; then
            cd $repo/smoke-test
            ./test.sh
            ret=$?
        else
            echo -e "${red}${repo} does not contain smoke-test${nc}" > /dev/stderr
        fi
    else
        echo -e "${red}GitHub seems unreachable${nc}" > /dev/stderr
    fi

    echo $ret
}

# update tutorial in the new gradebook
function update_tutorial {
    local stud=$1
    local tuto=$2
    local repo="${tuto}-${stud}"
    
    echo -e "${cyan}${repo} is a tutorial${nc} => given for granted ;)" > /dev/stderr

    local jq_path=$(eval "cat $gradebook_new | jq -c 'paths(.name?==\"$repo\")'")
    if [ ! -z "$jq_path" ]; then
        jq_path=$(echo "$jq_path" | jq -c '.+["status"]')
        
        cp $gradebook_new $gradebook_tmp
        eval "cat $gradebook_tmp | jq 'setpath(${jq_path};\"${status_passed}\")' > $gradebook_new"
        rm $gradebook_tmp
    else
        local jq_path_student=$(eval "cat $gradebook_new | jq -c 'paths(.username?==\"$stud\")'")
        local jq_path_tutorial=0
        if [ ! -z "$jq_path_student" ]; then
            jq_path_tutorial=$(eval "cat $gradebook_new | jq '.[] | select(.username==\"$stud\") | .tutorials | length'")
        else
            jq_path_student=$(eval "cat $gradebook_new | jq 'length'")
        fi

        local tutorial_score=$(eval "cat $data | jq '.tutorials | map(select(.name==\"$tuto\")) | .[0].score'")

        echo "$jq_path_student" > $gradebook_tmp        
        local jq_path_name=$(eval "cat $gradebook_tmp | jq -c '.+[\"tutorials\",$jq_path_tutorial,\"name\"]'")
        local jq_path_status=$(eval "cat $gradebook_tmp | jq -c '.+[\"tutorials\",$jq_path_tutorial,\"status\"]'")
        local jq_path_score=$(eval "cat $gradebook_tmp | jq -c '.+[\"tutorials\",$jq_path_tutorial,\"score\"]'")
                
        cp $gradebook_new $gradebook_tmp
        eval "cat $gradebook_tmp | jq 'setpath(${jq_path_name};\"${repo}\")' > $gradebook_new"
        
        cp $gradebook_new $gradebook_tmp
        eval "cat $gradebook_tmp | jq 'setpath(${jq_path_status};\"${status_passed}\")' > $gradebook_new"
        
        cp $gradebook_new $gradebook_tmp
        eval "cat $gradebook_tmp | jq 'setpath(${jq_path_score};${tutorial_score})' > $gradebook_new"
        rm $gradebook_tmp
    fi

    update_score ${stud}
    publish_gradebook
}

function update_assignment {
    local stud=$1
    local assi=$2
    local repo="${assi}-${stud}"

    echo -e "${cyan}${repo} is an assignment${nc}" > /dev/stderr
    
    local last_commit_date=$(eval "cat $gradebook_new | jq 'map(select(.username == \"$stud\")) | .[0].assignments | map(select(.name=="$repo")) | .[0].last_commit_date'")
    local repo_commit_date=$(eval "curl -s $token_header -G https://api.github.com/repos/vvv-school/$repo/commits | jq '.[0].commit.committer.date'")
    if [ "${last_commit_date}" != "${repo_commit_date}" ]; then
        echo -e "detected new activity on ${cyan}${repo}${nc} => start off testing" > /dev/stderr
        local result=$(smoke_test $repo https://github.com/${org}/${repo}.git)
        local status=$status_failed
        if [ $result -eq 0 ]; then
            status=$status_passed
        fi

        local jq_path=$(eval "cat $gradebook_new | jq -c 'paths(.name?==\"$repo\")'")
        if [ ! -z "$jq_path" ]; then
            local jq_path_status=$(echo "$jq_path" | jq -c '.+["status"]')
            local jq_path_date=$(echo "$jq_path" | jq -c '.+["last_commit_date"]')
            
            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq 'setpath(${jq_path_status};\"${status}\")' > $gradebook_new"
            eval "cat $gradebook_tmp | jq 'setpath(${jq_path_date};\"${repo_commit_date}\")' > $gradebook_new"
            rm $gradebook_tmp
        else
            local jq_path_student=$(eval "cat $gradebook_new | jq -c 'paths(.username?==\"$stud\")'")
            local jq_path_assignment=0
            if [ ! -z "$jq_path_student" ]; then
                jq_path_assignment=$(eval "cat $gradebook_new | jq '.[] | select(.username==\"$stud\") | .tutorials | length'")
            else
                jq_path_student=$(eval "cat $gradebook_new | jq 'length'")
            fi

            local assignment_score=$(eval "cat $data | jq '.assignments | map(select(.name==\"$assi\")) | .[0].score'")

            echo "$jq_path_student" > $gradebook_tmp        
            local jq_path_name=$(eval "cat $gradebook_tmp | jq -c '.+[\"assignments\",$jq_path_assignment,\"name\"]'")
            local jq_path_status=$(eval "cat $gradebook_tmp | jq -c '.+[\"assignments\",$jq_path_assignment,\"status\"]'")
            local jq_path_score=$(eval "cat $gradebook_tmp | jq -c '.+[\"assignments\",$jq_path_assignment,\"score\"]'")
            local jq_path_date=$(eval "cat $gradebook_tmp | jq -c '.+[\"assignments\",$jq_path_assignment,\"last_commit_date\"]'")
                    
            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq 'setpath(${jq_path_name};\"${repo}\")' > $gradebook_new"
            
            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq 'setpath(${jq_path_status};\"${status}\")' > $gradebook_new"
            
            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq 'setpath(${jq_path_score};${assignment_score})' > $gradebook_new"

            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq 'setpath(${jq_path_score};\"${repo_commit_date}\")' > $gradebook_new"
            rm $gradebook_tmp
        fi
    fi

    update_score ${stud}
    publish_gradebook
}

# remove usernames not in ${team}
function gc_usernames_no_students {
    local usernames=$(eval "cat $gradebook_new | jq 'map(.username) | .[]' | sed 's/\\\"//g'")
    local newline=false
    
    for user in $usernames; do
        local isin=false
        for stud in $students; do
            if [ "${user}" == "${stud}" ]; then
                isin=true
                break;
            fi
        done
        
        if [ "${isin}" == "false" ]; then
            echo "Removing ${user} from gradebook; he's not in ${team}" > /dev/stderr
            newline=true
            
            local jq_path_user=$(eval "cat $gradebook_new | jq -c 'paths(.username?==\"$user\") | .[0]'")
            
            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq 'del(.[${jq_path_user}])' > $gradebook_new"
            rm $gradebook_tmp            
        fi
    done
    
    if [ "$newline" == "true" ]; then
        echo ""
    fi
}

# add missing students as empty items
function add_missing_students {  
    local newline=false
    
    for stud in $students; do
        local isin=$(eval "cat $gradebook_new | jq 'map(select(.username==\"${stud}\")) | .[0] | .username'")
        if [ "$isin" == "null" ]; then
            echo "Adding ${stud} to gradebook" > /dev/stderr
            newline=true
            
            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq '.+ [{\"username\": \"${stud}\", \"tutorials\": [], \"assignments\": [], score: 0}]' > $gradebook_new"
            rm $gradebook_tmp
        fi
    done
    
    if [ "$newline" == "true" ]; then
        echo ""
    fi
}

# remove student's unavailable repositories
function gc_student_repositories {
    local stud=$1
    shift
    local repositories=${@}

    local jq_path_stud=$(eval "cat $gradebook_new | jq -c 'paths(.username?==\"$stud\") | .[0]'")
    
    local stud_tutorials=$(eval "cat $gradebook_new | jq 'map(select(.username==\"$stud\")) | .[0] | .tutorials'")
    local stud_tutorials_name=$(echo "$stud_tutorials" | jq '.[] | .name' | sed 's/\"//g')
    for tuto in $stud_tutorials_name; do        
        local isin=false
        for repo in $repositories; do
            if [ "${tuto}" == "${repo}" ]; then
                isin=true
                break
            fi
        done
        
        if [ "${isin}" == "false" ]; then
            echo "Removing ${tuto} from gradebook; it's not in ${org}"  > /dev/stderr
            echo "$stud_tutorials" > $gradebook_tmp
            local jq_path_tuto=$(eval "cat $gradebook_tmp | jq -c 'paths(.name?==\"$tuto\") | .[0]'")
                        
            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq 'del(.[${jq_path_stud}].tutorials[${jq_path_tuto}])' > $gradebook_new"
            rm $gradebook_tmp
            
            # recompute data
            local stud_tutorials=$(eval "cat $gradebook_new | jq 'map(select(.username==\"$stud\")) | .[0] | .tutorials'")
        fi
    done
    
    local stud_assignments=$(eval "cat $gradebook_new | jq 'map(select(.username==\"$stud\")) | .[0] | .assignments'")
    local stud_assignments_name=$(echo "$stud_assignments" | jq '.[] | .name' | sed 's/\"//g')
    for assi in $stud_assignments_name; do
        local isin=false
        for repo in $repositories; do
            if [ "${assi}" == "${repo}" ]; then
                isin=true
                break
            fi
        done

        if [ "${isin}" == "false" ]; then
            echo "Removing ${assi} from gradebook; it's not in ${org}" > /dev/stderr
            echo "$stud_assignments" > $gradebook_tmp
            local jq_path_assi=$(eval "cat $gradebook_tmp | jq -c 'paths(.name?==\"$assi\") | .[0]'")

            cp $gradebook_new $gradebook_tmp
            eval "cat $gradebook_tmp | jq 'del(.[${jq_path_stud}].assignments[${jq_path_assi}])' > $gradebook_new"
            rm $gradebook_tmp
            
            # recompute data
            local stud_assignments=$(eval "cat $gradebook_new | jq 'map(select(.username==\"$stud\")) | .[0] | .assignments'")
        fi
    done
    
    update_score ${stud}
    publish_gradebook
}

# try to shut down gracefully
function ctrl_c() {
    echo -e "\n${red}Trapped CTRL-C, shutting down...${nc}\n" > /dev/stderr
    exit 0
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c SIGINT

while true; do
    # generate new gradebook from old one, if exists
    if [ -f $gradebook_new ]; then
        rm $gradebook_new
    fi
    if [ -f $gradebook_cur ]; then
        cp $gradebook_cur $gradebook_new
    # otherwise produce an empy gradebook
    else    
        echo "[]" > $gradebook_new
    fi
    
    # retrieve names of public repositories in $org
    repositories=$(eval "curl -s $token_header -G https://api.github.com/orgs/$org/repos?type=public | jq '.[] | .name' | sed 's/\\\"//g'")
        
    echo ""
    echo -e "${cyan}============================================================================${nc}"
    echo -e "Working out the students:\n${green}${students}${nc}\n"
    echo -e "Against repositories in ${cyan}https://github.com/${org}:\n${blue}${repositories}${nc}\n"
    
    # remove from the gradebook users who are not students,
    # since they can be potentially in the original gradebook
    gc_usernames_no_students
    
    # add up missing students to the current gradebook
    add_missing_students

    # publish if a change has occurred
    publish_gradebook

    # for each student in the list
    for stud in $students; do
        echo -e "${cyan}==== Grading ${green}${stud}${nc}"
        
        # remove student's repositories that are not in $org
        gc_student_repositories $stud ${repositories[@]}

        # for each repository found in $org
        for repo in $repositories; do            

            # for tutorials, simply give them for granted
            proceed=false;
            for tuto in $tutorials; do
                if [ "${repo}" == "${tuto}-${stud}" ]; then                    
                    update_tutorial ${stud} ${tuto}
                    proceed=true
                    break
                fi
            done
            
            # we've detected $repo as a tutorial
            # hence skip the following cycle
            if [ "$proceed" == true ]; then
                continue
            fi
            
            # for assignments, run the smoke test
            for assi in $assignments; do
                if [ "${repo}" == "${assi}-${stud}" ]; then
                    update_assignment ${stud} ${assi}
                    break
                fi
            done
        done
        
        # newline
        echo ""
    done
done
