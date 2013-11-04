#!/bin/bash


block_user()
{	echo $1
	$(su - zimbra -c "zmprov sp $1 FOTTUTOSPAMMER")
	$(su - zimbra -c "zmprov ma $1 zimbraAccountStatus closed")	
	send_mail $1	
	block_ip $1
}

send_mail()
{
SUBJECT="Customer blocked for spam"
EMAIL="mail@mail.mm" #Insert here the mail to send notification
CC="cc@mail.mm" #Insert here the mail to send in cc
SENDER="sender@mail.mm" #Enter here the sender email

echo "Customer $1 was blocked for spam. This is an automatic mail, please do not reply" | /bin/mail -s "$SUBJECT" "$EMAIL" -- -f "$SENDER" -c "$CC" 
}

check()
{
echo $1
status=$(su - zimbra -c "zmaccts" | grep  | awk '{print $2}')
if [ "$status" != "closed" ];then
	block_user $1
fi
}

block_ip()
{
ip=$(grep "$1" /var/log/maillog | grep sasl | sed -e 's/\[/ /g' -e 's/\]/ /g' | awk '{print "ALL: " $10}' | sort | uniq >> /etc/hosts.deny)


}

MAILLOG=/var/log/maillog
MINUTES=30
MAIL_NUMBER=50

NOW=$(date +"%b %d %H:%M:%S")
START=$(date -d "-$MINUTES minutes" +"%b %e %H:%M")


ln=$(grep -nr "$START" /var/log/maillog | cut -f"1" -d":" | head -n1)
users=$(tail -n +"$ln" "$MAILLOG" | grep sasl_username | awk 'BEGIN { FS = "=" }; {print $4}' | sort | uniq)
for i in $users; do
	counter=$(tail -n +"$ln" "$MAILLOG" | grep -c $i)
	if [ $counter -ge $MAIL_NUMBER ]; then
		check $i
	fi
done
