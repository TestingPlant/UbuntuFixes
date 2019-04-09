#A bunch of solutions I found which could fix bluetooth problems
echo "Running bluetooth fixes" 
/usr/sbin/rfkill unblock bluetooth 1> /dev/null
/usr/sbin/rfkill | /bin/grep bluetooth | /bin/grep -w blocked
/usr/bin/pactl load-module module-bluetooth-policy 1> /dev/null
/usr/bin/pactl load-module module-bluetooth-discover 1> /dev/null
/usr/bin/sudo /etc/init.d/bluetooth restart
/usr/bin/sudo /usr/bin/aptitude -y install bluetooth pulseaudio-module-bluetooth > /dev/null 2> /dev/null
