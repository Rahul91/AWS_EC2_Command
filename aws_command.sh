#!/bin/bash

export KEY_LOCATION="$HOME/.ssh/"
export USER="ubuntu"
export RESTART_DELAY_TIME=60

#declare -a INSTANCE_ARRAY=('Background processes-4' 'Background processes-3' 'Background processes-2' 'Background processes-1')

trap ctrl_c SIGINT

print_pre_configure_installation_requirement() {
  echo "Kindly check the availablilty of below packages before executing this script..\n"
  echo "1: python-pip \n"
  echo "2: awscli \n"
  echo "Also you need to have proper access permission to start/stop ec2 instances"
}

ctrl_c() {
  notify-send -i ~/jira_automation/error.ico 'Ctrl_c detected !!!' 'Aborting'
  echo
  exit
}

restart ()
{
	INSTANCE=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$SELECTED_NAME" | grep InstanceId | grep -E -o "i\-[0-9A-Za-z]+")
	aws ec2 stop-instances --instance-ids $INSTANCE
	echo "Delay for $RESTART_DELAY_TIME seconds"
	sleep $RESTART_DELAY_TIME
	aws ec2 start-instances --instance-ids $INSTANCE
	echo "AWS Instance $INSTANCE Restarted"
	unset SELECTED_NAME
}

action()
{
	if [ "$CRON" ];then
		read -p "Enter the Instance Name to Restart: " SELECTED_NAME
	else
		read -p "Enter the Instance Name to Restart: " SELECTED_NAME
	fi
	INSTANCE=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$SELECTED_NAME" | grep InstanceId | grep -E -o "i\-[0-9A-Za-z]+")
	echo "Action: $1"
	echo "Instace Name: $SELECTED_NAME"
	echo "Instace Id: $INSTANCE"
	aws ec2 $2 --instance-ids $INSTANCE
	echo "AWS Instance $INSTANCE: $1"
	unset SELECTED_NAME
}

getip ()
{
	sleep 30
	IP_ADDRESS=$(aws ec2 describe-instances --filters "Name=instance-id,Values=$1" | grep PublicIpAddress | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
}

show_filtered_instances()
{
	TEMP_FILE=$HOME/aws_temp.txt
	echo "List of $1 instances:"
	aws ec2 describe-instances --filters "Name=tag:Name,Values=*" --filters "Name=instance-state-name,Values=$1" | grep  "Value" | grep -E -o "[0-9A-Za-z]+\s\w.+[0-9A-Za-z]\)?"  > $TEMP_FILE
	COUNTER=1
	while IFS='' read -r line || [[ -n "$line" ]]; do    echo $COUNTER.$line ; ((COUNTER++)); done < "$TEMP_FILE"
	rm -rf "$TEMP_FILE"
}

status ()
{
	while [[ 1 ]]
	do
		read -p "Enter any other action {pending|running|stopped|stopping|terminated|exit}: " ACTION
		case "$ACTION" in
			pending)
			    show_filtered_instances "$ACTION"
			    ;;
			running)
			    show_filtered_instances "$ACTION"
			    ;;
			stopped)
				show_filtered_instances "$ACTION"
			    ;;
			terminated)
			    show_filtered_instances "$ACTION"
			    ;;
			stopping)
			    show_filtered_instances "$ACTION"
			    ;;
			exit)
			    echo "Exiting"
			    break
			    ;;
			*)
			    echo $"Action: {pending|running|stopped|stopping|terminated|exit}"
		esac
	done
}

while [[ 1 ]]
do
	read -p "Enter any option {start|stop|restart|status|exit|help}: " OPTION
	case "$OPTION" in
	        start)
				show_filtered_instances "stopped"
	            action "$OPTION" "start-instances"
	            getip $INSTANCE
				echo "Instance running on IP: $IP_ADDRESS"
				unset OPTION
				unset IP_ADDRESS
	            ;;
	         
	        stop)
				show_filtered_instances "running"
	            action "$OPTION" "stop-instances"
	            unset OPTION
	            ;;
	         
	        status)
				show_filtered_instances "running"
				show_filtered_instances "stopped"
				status
			    unset OPTION
	            ;;

	        restart)
				show_filtered_instances "running"
				echo
				restart
				getip $INSTANCE
				echo "Instance running on IP: $IP_ADDRESS"
				unset INSTANCE
				unset OPTION
				unset IP_ADDRESS
	            ;;
	        
	        exit)
				echo "Exiting"
				exit 1
				;;
	        help)
				print_pre_configure_installation_requirement
				echo $"Options: {start|stop|restart|status|exit|help}"
				;;
	        *)
	            echo $"Options: {start|stop|restart|status|exit|help}"
	esac
done
