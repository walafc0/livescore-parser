#!/bin/sh

TEAM=CHANGE_ME
OUTPUT_FINAL=/tmp/dmenu_score

HOME=0
LIVE=0
TEAM_POS=-1
VS_POS=-1
URL=http://www.livescore.com/soccer/france/ligue-1/
OUTPUT=/tmp/livescore.txt
OUTPUT_MATCH=/tmp/livescore_match.txt
OUTPUT_TABLE=/tmp/livescore_table.txt
OUTPUT_DOM=/tmp/livescore_"$TEAM"_dom.txt
OUTPUT_EXT=/tmp/livescore_"$TEAM"_ext.txt


get_data()
{
    lynx -dump $URL > $OUTPUT 2> /dev/null
    egrep -A 100 -m 1  "France - Ligue 1" $OUTPUT > $OUTPUT_MATCH
    egrep -A 1000 -m 1 "France - Ligue 1 - Table" $OUTPUT > $OUTPUT_TABLE
    egrep -B 1 -A 2 $TEAM $OUTPUT_MATCH > $OUTPUT_DOM
    egrep -B 3 -A 0 $TEAM $OUTPUT_MATCH > $OUTPUT_EXT
}

get_status()
{
    # Get first word at line 1
    STATUS=$(sed '1,1!d' $OUTPUT_DOM | sed -e 's/^[ \t]*//' | awk '{print $1}')

    if [ $STATUS = "HT" ] || [ $STATUS = "live" ]; then
	# Match is not finished and $TEAM is playing at home
	HOME=1
	LIVE=1
    elif [ $STATUS = "FT" ]; then
	# Match is finished and $TEAM was at home
	HOME=1
    else
	STATUS=$(sed '1,1!d' $OUTPUT_EXT | sed -e 's/^[ \t]*//' | \
			awk '{print $1}')
	if [ $STATUS = "HT" ] || [ $STATUS = "live" ]; then
	    LIVE=1
	fi
	
    fi
    
    if [ $HOME -eq 0 ]; then 
	VS=$(sed '2,2!d' $OUTPUT_EXT | sed -e 's/^[ \t]*//')
    else
	VS=$(sed '4,4!d' $OUTPUT_DOM | sed -e 's/^[ \t]*//')
    fi

}

get_table()
{
    if [ $LIVE -eq 1 ]; then
	TEAM_POS=$(egrep -B 1 $TEAM $OUTPUT_TABLE | head -n 1 | \
			  awk '{print $2}' | sed -e 's/^[ \t]*//')
	VS_POS=$(egrep -B 1 "$VS" $OUTPUT_TABLE | head -n 1 | \
			  awk '{print $2}' | sed -e 's/^[ \t]*//')
    else
	TEAM_POS=$(egrep -B 1 $TEAM $OUTPUT_TABLE | head -n 1 | \
			  awk '{print $1}' | sed -e 's/^[ \t]*//')
	VS_POS=$(egrep -B 1 "$VS" $OUTPUT_TABLE | head -n 1 | \
			  awk '{print $1}' | sed -e 's/^[ \t]*//')
    fi
}

display()
{
    # $TEAM wasn't at home
    if [ $HOME -eq 0 ]; then
	TIME=$(sed '1,1!d' $OUTPUT_EXT | sed -e 's/^[ \t]*//')
	VS=$(sed '2,2!d' $OUTPUT_EXT | sed -e 's/^[ \t]*//')
	SCORE=$(sed '3,3!d' $OUTPUT_EXT | cut -d']' -f 2)
	TEAM=$(sed '4,4!d' $OUTPUT_EXT | sed -e 's/^[ \t]*//')
	echo "($TIME) ($VS_POS) $VS $SCORE $TEAM ($TEAM_POS)" > $OUTPUT_FINAL
    else
	TIME=$(sed '1,1!d' $OUTPUT_DOM | sed -e 's/^[ \t]*//')
	SCORE=$(sed '3,3!d' $OUTPUT_DOM | cut -d']' -f 2)
	TEAM=$(sed '2,2!d' $OUTPUT_DOM | sed -e 's/^[ \t]*//')
	VS=$(sed '4,4!d' $OUTPUT_DOM | sed -e 's/^[ \t]*//')
	echo "($TIME) ($TEAM_POS) $TEAM $SCORE $VS ($VS_POS)" > $OUTPUT_FINAL
    fi
}

get_data
get_status
get_table
display

exit
