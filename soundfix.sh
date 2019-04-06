#A bunch of solutions I found which could fix sound problems.
echo "Running sound fixes"
/usr/bin/pulseaudio -k 1> /dev/null
/usr/bin/sudo /sbin/alsa force-reload 1> /dev/null
/usr/bin/sudo /sbin/modprobe snd-hda-intel 1> /dev/null

