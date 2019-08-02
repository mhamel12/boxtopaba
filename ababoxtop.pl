# ===============================================================
# 
# ababoxtop.pl
#
# (c) 2010-2014 Michael Hamel
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of this license, visit # http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
#
# Version history
# 09/07/2011  1.0  MH  Initial version, based on boxtop.pl but optimized for 1973-74 stats
# 07/15/2014  1.0  MH  Optimize for ABA only, add league stats file support for coaches, arena/city/state, and menu-driven player selection
#
# ===============================================================


#! usr/bin/perl
use Getopt::Std;
use Time::Local;
use Date::Calc qw(:all);

use lib '../tools';
use Boxtop;

# ===============================================================

sub usage
{
    print "Quickly input multiple boxscores and save using the boxtop format (.csv)\n";
    print "Supports shortcuts for team names and common ABA player names.\n";
    print "Assumes basic box score information from TSN.\n";
    print "\n";
    print "\nUSAGE:\n ababoxtop.pl [-o outputfilename] -l leaguestatsfile\n";
    print " Default filename is output.csv unless specified.\n";

}
# end of sub usage()

# ===============================================================
# 
# parse_csv_line()
#
# Parses one line of a csv file and fills an array to return to caller.
#
# Input:
#
# Output:
#  Array that contains each element of the csv line.
#
# ===============================================================
sub parse_csv_line(@)
{
    ($line) = @_;

        # Note: If we don't declare this here, we end up re-using previously
    #       declared variable on our next trip through here!
        my @csv_elements;

        # trick - add a comma at the end of the line in place of the CR
        # makes searching easier...
        chomp($line);
        $line = join(",",$line,"");
    
        while ((my $next_comma = index($line,",")) >= 0)
        {
            # Grab next column header.
            push @csv_elements, substr($line,0,$next_comma);

            $line = substr($line,($next_comma+1),length($line));
        }
    
        return(@csv_elements);
}
# end of sub parse_csv_line()

# ===============================================================

sub getstring
{
    $string = <>;
    chomp($string); # strip off CR
    return $string;
}
# end of sub getstring()

# ===============================================================

# Team shortcuts - first three letters, except for "san" and "new" conflicts
%team_list =
(   
    "new" => "New Jersey Americans",
#    "new" => "New York Nets", # 1968-69 through 1975-76
    "ind" => "Indiana Pacers",
    "sds" => "San Diego Sails", # 1975-76
    "sdc" => "San Diego Conquistadors", # through 1974-75
    "sas" => "San Antonio Spurs",
    "mem" => "Memphis Pros", # 1971-72
#    "mem" => "Memphis Tams", # 1972-73 and 1973-74
#    "mem" => "Memphis Sounds", # 1974-75
    "den" => "Denver Rockets", # through 1973-74
#    "den" => "Denver Nuggets", # 1974-75 through 1975-76
    "ken" => "Kentucky Colonels",
    "vir" => "Virginia Squires",
    "car" => "Carolina Cougars",
    "uta" => "Utah Stars",
    "stl" => "Spirits of St. Louis",
    "dal" => "Dallas Chaparrals",
    "tex" => "Texas Chaparrals",
    "flo" => "The Floridians",
    "pit" => "Pittsburgh Condors", # 1970-71
    "pit" => "Pittsburgh Pipers", # 1967-68, 1969-70
#    "min" => "Minnesota Pipers", # 1968-69
    "min" => "Minnesota Muskies", # 1967-68
    "nob" => "New Orleans Buccaneers",
    "mia" => "Miami Floridians",
    "was" => "Washington Capitols",
    "los" => "Los Angeles Stars",
    "hou" => "Houston Mavericks",
    "oak" => "Oakland Oaks",
    "ana" => "Anaheim Amigos",
    
);

# ===============================================================

sub getteamstring
{
    $string = <>;
    chomp($string); # strip off CR
    if (exists($team_list{$string})) 
    {
        $string = $team_list{$string};
    }
    return $string;
}
# end of sub getteamstring()

# ===============================================================

# To keep this simple, we support automatic lookup only for teams who played
# in a single arena for their existence (1956-57 through 1968-69).
#
# Some teams moved during a season, which would make automating teams
# that played in multiple arenas non-trivial, and some teams such as
# the Warriors (Phila & SF) and 76ers played in multiple arenas during a
# single season, which makes automation impossible.

%arena_list; # now populated along with player and coaches hashes

sub getarenastring(@)
{
	$team_name = $_[0];	

    if (exists($arena_list{$team_name})) 
    {
        $string = $arena_list{$team_name};
    }
	else
	{
		# prompt for it
		print "Arena: ";
    	$string = <>;
    	chomp($string); # strip off CR
	}
        
    return $string;
}
# end of sub getarenastring()

# ===============================================================

%city_list; # now populated along with player and coaches hashes

sub getcitystring(@)
{
	$team_name = $_[0];	

    if (exists($city_list{$team_name})) 
    {
        $string = $city_list{$team_name};
    }
	else
	{
		# prompt for it
		print "City: ";
    	$string = <>;
    	chomp($string); # strip off CR
	}
        
    return $string;
}
# end of sub getcitystring()

# ===============================================================

%state_abbreviation_list =
(   
    "AL" => "Alabama",
    "AK" => "Alaska",
    "AZ" => "Arizona",
    "AR" => "Arkansas",
    "CA" => "California",
    "CO" => "Colorado",
    "CT" => "Connecticut",
    "DE" => "Delaware",
    "DC" => "Wash DC",
    "FL" => "Florida",
    "GA" => "Georgia",
    "HI" => "Hawaii",
    "ID" => "Idaho",
    "IL" => "Illinois",
    "IN" => "Indiana",
    "IA" => "Iowa",
    "KS" => "Kansas",
    "KY" => "Kentucky",
    "LA" => "Louisiana",
    "ME" => "Maine",
    "MD" => "Maryland",
    "MA" => "Massachusetts",
    "MI" => "Michigan",
    "MN" => "Minnesota",
    "MS" => "Mississippi",
    "MO" => "Missouri",
    "MT" => "Montana",
    "NE" => "Nebraska",
    "NV" => "Nevada",
    "NH" => "New Hampshire",
    "NJ" => "New Jersey",
    "NM" => "New Mexico",
    "NY" => "New York",
    "NC" => "North Carolina",
    "ND" => "North Dakota",
    "OH" => "Ohio",
    "OK" => "Oklahoma",
    "OR" => "Oregon",
    "PA" => "Pennsylvania",
    "RI" => "Rhode Island",
    "SC" => "South Carolina",
    "SD" => "South Dakota",
    "TN" => "Tennessee",
    "TX" => "Texas",
    "UT" => "Utah",
    "VT" => "Vermont",
    "VA" => "Virginia",
    "WA" => "Washington",
    "WV" => "West Virginia",
    "WI" => "Wisconsin",
    "WY" => "Wyoming",
);

# ===============================================================

# 1973-74 shortcuts
%state_list; # now populated along with player and coaches hashes

sub getstatestring(@)
{
	$team_name = $_[0];	

    if (exists($state_list{$team_name})) 
    {
        $string = $state_list{$team_name};
    }
	else
	{
		# prompt for it, and support abbreviations
		print "State: ";
    	$string = <>;
    	chomp($string); # strip off CR
	    if (exists($state_abbreviation_list{$string})) 
	    {
	        $string = $state_abbreviation_list{$string};
	    }
	}
        
    return $string;
}
# end of sub getstatestring()

# ===============================================================

%id_exception_hash =
(
# no longer used now that we put exceptions in the season stats file   
#    "Chuck Williams" => "02",
);

sub getid($$$$)
{
    $first = $_[0];
    $last = $_[1];
    $coach = $_[2];
    $id_hint = $_[3]; # ignored for non-coaches, and ignored if zero

    if ($coach eq "coach")
    {	
	    # prompt for id (equal to player id if they ever played, 99 if they did not - always ends in 'c')
	    if ($id_hint == 0)
	    {
    	    print "Two-digit id number: ";
	        $id = getstring();
        }
        else
        {
            $id = $id_hint;
        }
	}
	else # this is a player, so just look it up	in our exception hash   
  	{
	  	$full_name = join(" ",$first,$last);
  		if (exists ($id_exception_hash{$full_name}))
  		{
		  	$id = $id_exception_hash{$full_name};
		}  
		else
		{
			$id = "01";
		}
	}

    # remove spaces from last name to handle cases like 'Van Arsdale' which gets translated to vanar<first>01
    # remove "." to handle K.C. Jones
    # remove "'" and "`" to handle O'Brien and O`Brien
    $first =~ s/[\.'` ]//g;
    $last =~ s/[\.'` ]//g;
	 
    if (length($last) > 5)
    {
        $last = substr($last,0,5);
    }

    if (length($first) > 2)
    {
# We now cover K.C. Jones case above	    
#	    if (substr($first,1,1) eq ".") # cover K.C. Jones case
#	    {
#		    $first = substr($first,0,1) . substr($first,2,1);
#		}
#		else
#       {
	        $first = substr($first,0,2);
#     	}
    }

    $myid = $last . $first . $id;

    # Note that for coaches who did not play in NBA, basketball reference uses 99 as default id, not 01
    if ($coach eq "coach")
    {
        $myid = $myid . "c";
    }

    # convert to all lower-case
    return lc($myid);

}
# end of sub getid()

# ===============================================================

my %player_hash;
my %coaches_hash;

sub create_player_hash()
{
    # We need a hash of hashes. Indexed first by team, and then, one entry per player that maps BR.com id to their full player name
    while ($line = <leaguestats_filehandle>)
    {
        # we only care about the playertotal rows for players
        if ($line =~ /^playertotal/)
        {
            @this_line_array = parse_csv_line($line);    
            
            # column 1 contains an override BR.com id or just a number 
            #          (this can include an id ending in 01 if we have both an 01 and an 02 or 03 in the same season - see Roger Brown, 1973-74)
            # column 2 contains full player name
            # column 5 contains team name - drop TOT on the floor
            
            if ($this_line_array[5] ne "TOT")
            {
                if ($this_line_array[1] =~ /[^0-9]/)
                {
                    $his_id = $this_line_array[1];
                }
                else
                {
                    # We're cheating here and assuming that any player with a space in their name has a space in their LAST name.
                    # May require some overrides, But 1973-74 is clean.
                    my($first, $last) = split(/\s/, $this_line_array[2],2);
                    $his_id = getid($first,$last,"player",0); # not a coach by definition
                }
                                
                $player_hash{$this_line_array[5]}{$his_id} = $this_line_array[2];
            }
        }
        elsif ($line =~ /^coach/)
        {
            @this_line_array = parse_csv_line($line);    
            
            # column 1 contains first name
            # column 2 contains last name
            # column 3 contains team abbrev
            # column 4 contains id number only (01, 99, etc.)
            # column 5 is blank if they coached the entire season, else includes a number indicating order of coaches
            # column 6 is blank if they coached the entire season, else contains date of first game (for coaches #2 and onward)

            # supply id info as a "hint"            
            $his_id = getid($this_line_array[1],$this_line_array[2],"coach",$this_line_array[4]);
            
            $coaches_hash{$this_line_array[3]}{$his_id}{first} = $this_line_array[1];
            $coaches_hash{$this_line_array[3]}{$his_id}{last} = $this_line_array[2];
            $coaches_hash{$this_line_array[3]}{$his_id}{order} = $this_line_array[5];
            $coaches_hash{$this_line_array[3]}{$his_id}{debut} = $this_line_array[6];
        }
        elsif ($line =~ /^arena/)
        {
            @this_line_array = parse_csv_line($line);    
            
            # column 1 contains team name (spelled out)
            # column 2 contains arena name
            # column 3 contains city
            # column 4 contains state
            
            $state_list{$this_line_array[1]} = $this_line_array[4];
            $city_list{$this_line_array[1]} = $this_line_array[3];
            $arena_list{$this_line_array[1]} = $this_line_array[2];
        }
    }
}

# ===============================================================


sub get_day_of_week($)
{
	$date = $_[0];
	
   	my ($mon,$mday,$year) = split(/\//, $date);
 
	$wday = Day_of_Week($year,$mon,$mday);
	$the_day = Day_of_Week_to_Text($wday);
 
   	return($the_day);
}

# ===============================================================

sub display_boxscore_menu()
{
	print "Enter type of boxscore -\n";
	print " [a]ba TSN  FGM/FTM/FTA/PTS/3FGM\n";
	print " [b]asic    FGM/FTM/FTA/PF/PTS\n";
	print " [c]omplete MIN/FGM/FGA/FTM/FTA/REB/AST/PF/PTS\n";
	print " [n]ba TSN  FGM/FTM/FTA/PTS\n";
	print " [s]imple   FGM/FTM/PTS\n";
	print " [w]ebuns   complete ABA\n";
	print " [d]one\n";
	print " : ";
}

# ===============================================================

# Support shortcuts for common names
# Must have an entry in both hashes for each name, or the script will break.
# No longer used in ABA version
%celtics_first_names =
(
    ".drj" => "Julius",
    ".wilt" => "Wilt",
);

%celtics_last_names =
(
    ".drj" => "Erving",
    ".wilt" => "Chamberlain",
);


$output_filename = "output.csv";

getopts('o:h:l:',\%cli_opt);

if (exists ($cli_opt{"o"}))
{
    $output_filename = $cli_opt{"o"};
}

if (exists ($cli_opt{"l"}))
{
    $leaguestats_filename = $cli_opt{"l"};
}
else
{
	usage();
	exit;
}

if (exists ($cli_opt{"h"}))
{
	usage();
	exit;
}

$done = "no";

# open for reading
if (!open(leaguestats_filehandle, "$leaguestats_filename")) 
{
    die "Can't open input file $leaguestats_filename\n";
}
# Open output file, appending or creating as necessary
if (!open(output_filehandle, ">>$output_filename")) 
{
    close(leaguestats_filehandle);
    die "Can't open output file $output_filename\n";
}

# First step is to read in the leaguestats file and get our player and coaches hashes set up.
create_player_hash();

close(leaguestats_filehandle);

%info;
%person;
%stats;

my @player_id_list;

display_boxscore_menu();
$boxscore_type = getstring();

$previous_date = "MON/DAY/YEAR";

while ($done eq "no")
{

    # put the preamble first
    print output_filehandle "\ngamebxt\nversion,1\n";
    
    # get the common data first
    print "Date ($previous_date): ";
    $temp = getstring();
    if (length($temp) == 0)
    {
        $info{date} = $previous_date;
    }
    else    
    {
        $info{date} = $temp;
        $previous_date = $temp;
    }

#    print "Day of week: ";
    $info{dayofweek} = get_day_of_week($info{date}); # getstring();
#    print "$info{dayofweek}\n";

    print "Game description (playoffs): ";
    $info{title} = getstring();

    print "Neutral site game? [y/n]";
    $neutral_site = getstring();

    if ( $neutral_site eq "y" ) # This should be "y" only if the game is NOT held at a home-away-from-home, but at a truly neutral site like Toronto.
    {
        $arena_exception = "y";
    }
    else
    {
        print "Special arena? [y/n]";
        $arena_exception = getstring();
    }
    
    if ($arena_exception eq "y")
    {
	    print "Team1 (Road): ";
	    $info{rteam} = getteamstring();
	
	    print "Team2 (Home): ";
	    $info{hteam} = getteamstring();
	    
	    print "Arena: ";
	    $info{arena} = getstring();
	    
	    print "City: ";
	    $info{city} = getstring();
	    
	    print "State: ";
	    $info{state} = getstring();
	}
	else
	{	     
	    print "Road Team: ";
	    $info{rteam} = getteamstring();
	
	    print "Home Team: ";
	    $info{hteam} = getteamstring();
	
	    # Attempt to derive arena, city, state information from the home team name
	  	$info{arena} = getarenastring($info{hteam});
	   	$info{city} = getcitystring($info{hteam});
	   	$info{state} = getstatestring($info{hteam});
	}

    # All Celtics games during this era were in the United States
    $info{country} = "USA";

    print "Attendance: ";
    $info{attendance} = getstring();

    if (($boxscore_type eq "a") || ($boxscore_type eq "n") || ($boxscore_type eq "w"))
	{
		# TSN doesn't list refeeres, start time, or radio/tv
		$info{ref1} = "";
		$info{ref2} = "";
    	$info{starttime} = "";
    	$info{timezone} = "";
	    $info{radio} = "";
	    $info{tv} = "";
	}    
    else
    {
    	# Only two refs during this era
	    print "Ref1: ";
    	$info{ref1} = getstring();
	
    	print "Ref2: ";
    	$info{ref2} = getstring();

    	print "Start Time: ";
    	$info{starttime} = getstring();

    	$info{timezone} = "ET";

	    print "Radio: ";
	    $info{radio} = getstring();

	    print "Television: ";
	    $info{tv} = getstring();
	}
	
#   print(%info);

    # Add general info to .csv
    print output_filehandle "info,date,$info{date}\n";
    print output_filehandle "info,dayofweek,$info{dayofweek}\n";
    if ($neutral_site eq "y")
    {
        print output_filehandle "info,neutral\n";
    }    
    print output_filehandle "info,rteam,$info{rteam}\n";
    print output_filehandle "info,hteam,$info{hteam}\n";
    print output_filehandle "info,title,$info{title}\n";
    print output_filehandle "info,arena,$info{arena}\n";
    print output_filehandle "info,city,$info{city}\n";
    print output_filehandle "info,state,$info{state}\n";
    print output_filehandle "info,country,$info{country}\n";
    print output_filehandle "info,attendance,$info{attendance}\n";
    print output_filehandle "info,ref,$info{ref1}\n";
    print output_filehandle "info,ref,$info{ref2}\n";
    print output_filehandle "info,starttime,$info{starttime}\n";
    print output_filehandle "info,timezone,$info{timezone}\n";
    print output_filehandle "info,radio,$info{radio}\n";
    print output_filehandle "info,tv,$info{tv}\n";

    # Visitors first
    $team_preamble = $info{rteam};
    $team_forfile = "rteam";
    for ($a=0; $a<2; $a++)
    {
        print "\n\nEnter info for $team_preamble\n\n";

        $tm_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($team_preamble);
        
        @coach_id_array = ();
        if (exists($coaches_hash{$tm_abbrev}))
        {
            $coach_count = 0;
            foreach $c_id (keys %{$coaches_hash{$tm_abbrev}}) # we'll only find one entry in this hash - unless they had more than one coach that year
            {
                $coach_count++;
                
                if ($coaches_hash{$tm_abbrev}{$c_id}{order} ne "")
                {
                    # We need a menu
                    # TBD - could use date of first game for coaches #2 and onward to fully automate this
                    # zero'th entry should always be empty
                    $coach_id_array[$coaches_hash{$tm_abbrev}{$c_id}{order}] = $c_id;
                }
                else
                {
                    # this is the only coach they had this season
                    $person{id} = $c_id;
                    $person{first} = $coaches_hash{$tm_abbrev}{$person{id}}{first};
                    $person{last} = $coaches_hash{$tm_abbrev}{$person{id}}{last};
                }
            }
            if ($coach_count > 1)
            {
                for ($coach_index=1; $coach_index<=$coach_count; $coach_index++)
                {
                    print "$coach_index. $coaches_hash{$tm_abbrev}{$coach_id_array[$coach_index]}{first} $coaches_hash{$tm_abbrev}{$coach_id_array[$coach_index]}{last}";
                    if ($coaches_hash{$tm_abbrev}{$coach_id_array[$coach_index]}{debut} ne "")
                    {
                        print " (first game $coaches_hash{$tm_abbrev}{$coach_id_array[$coach_index]}{debut})";
                    }
                    print "\n";
                }

                print "\nCoach number: ";
                $coach_number_temp = ucfirst(getstring());
                
                if ($coach_number_temp > $coach_count)
                {
                    # just force it to the first coach
                    $coach_number_temp = 1;
                }
                
                $person{id} = $coach_id_array[$coach_number_temp];
                $person{first} = $coaches_hash{$tm_abbrev}{$person{id}}{first};
                $person{last} = $coaches_hash{$tm_abbrev}{$person{id}}{last};                
            }
            
            print "Coach: $person{first} $person{last} ($person{id})\n";
        }
        else
        {                
            print "Coach ($team_preamble) first name: ";
            $first_name_temp = ucfirst(getstring());
            
            # Check for a shortcut name first - could include any player or coach in these hashes, not just Celtics
            if ($first_name_temp =~ /^\./)
            {
                if (exists($celtics_first_names{$first_name_temp}))
                {
                    $person{first} = $celtics_first_names{$first_name_temp};
                    $person{last} = $celtics_last_names{$first_name_temp};
                }
            }
            else
            {
    	        # user entered first name, so prompt for last name
    	        $person{first} = $first_name_temp;
    
    	        print "Coach ($team_preamble) last name: ";
            	$person{last} = ucfirst(getstring());
    		}
    
            $person{id} = getid($person{first},$person{last},"coach",0);
        }
    
        $coach_technicals = "";

#       print(%person);
        print output_filehandle "coach,$team_forfile,$person{id},$person{first},$person{last},$coach_technicals\n";

        # Build the list of possible players for this team
        
        print "\n";
        
        # first, clear it
        %player_id_hash = ();
        $player_id_hash_count = 0;
        
        # now, look up in hash
        foreach $tm (keys %player_hash)
        {
            if ($tm eq $tm_abbrev)
            {
                foreach $playerid (sort keys %{$player_hash{$tm}})
                {
                    $player_id_hash{$playerid} = $player_hash{$tm}{$playerid};
                    $player_id_hash_count++;
                    
                    print "$player_id_hash_count. $playerid  $player_id_hash{$playerid}\n";
                }
            }
        }

        # Allow user to enter a numeric value that uses player_id_list to fetch the name and id (must split the name as shown below)
        
        print "\nPlayer number ($player_id_hash_count), first name, or s to stop: ";
        $first_name_temp = ucfirst(getstring());
        
        while ($first_name_temp ne "S") # note that we use ucfirst() on name string, so s or S becomes S
        {
            if (($first_name_temp =~ /[^0-9]/) || ($first_name_temp > $player_id_hash_count)) # no numbers, only alphanumerics, or input is an out of bounds number
            {                
                if ($first_name_temp =~ /[^a-zA-Z]/) # no letters
                {
                    print "\nINVALID NUMBER\n";
                    print "Player first name: ";
                    $first_name_temp = ucfirst(getstring());
                }
                
                if ($first_name_temp =~ /^\./)
                {
                    if (exists($celtics_first_names{$first_name_temp}))
                    {
                        $person{first} = $celtics_first_names{$first_name_temp};
                        $person{last} = $celtics_last_names{$first_name_temp};
                    }
                    else
                    {
                        print "NOT FOUND\n";
                        print "Player first name: ";
                        $person{first} = ucfirst(getstring());
                        print "Player last name: ";
                        $person{last} = ucfirst(getstring());
                    }
                }
                else
                {
                    $person{first} = $first_name_temp;
                    print "Player last name: ";
                    $person{last} = ucfirst(getstring());
                }
        
                $person{id} = getid($person{first},$person{last},"player",0);
            }
            else
            {
                # get the name and id info from the player_id_hash
                # $first_name_temp is the index into this hash

                $player_id_hash_count = 1;                
                foreach $playerid (sort keys %player_id_hash)
                {
                    if ($player_id_hash_count eq $first_name_temp)
                    {
                        # we found our guy
                        $person{id} = $playerid;
                        ($person{first}, $person{last}) = split(/\s/, $player_id_hash{$playerid}, 2); # split on first space only, so Jan Van Breda Kolff gets correct last name
                        
                        print "$person{first} $person{last} ($person{id})\n";
                        
                        # now mark the player as having been entered in this boxscore
                        $player_id_hash{$playerid} = "DONE" . $player_id_hash{$playerid};
                    }

                    $player_id_hash_count++;
                }
            }
            
            # fill in defaults
            $stats{MIN} = "";
            $stats{FGM} = "";
            $stats{FGA} = "";
            $stats{FTM} = "";
            $stats{FTA} = "";
            $stats{FG3M} = "";
            $stats{FG3A} = "";
            $stats{PF} = "";
            $stats{PTS} = "";
            $stats{OREB} = "";
            $stats{BLOCKS} = "";
            $stats{TURNOVERS} = "";
            $stats{STEALS} = "";
            $stats{TECHNICALFOUL} = "";
            $stats{REB} = "";
            $stats{AST} = "";
            
            if ($boxscore_type eq "a")
            {
                # basic input only, TSN/NYT style for ABA
                print "FGM: ";
                $stats{FGM} = getstring();
                
                # special exception character - an minus sign means fill in the rest with zeroes
                if ($stats{FGM} eq "-") # upper-right key on number pad, easiest to find while typing
                {
                    $stats{FGM} = 0;
                    $stats{FTM} = 0;
                    $stats{FTA} = 0;
                    $stats{PTS} = 0;
                    $stats{FG3M} = 0;
                }
                else
                {
                    print "FTM: ";
                    $stats{FTM} = getstring();
                    print "FTA: ";
                    $stats{FTA} = getstring();
                    print "PTS: ";
                    $stats{PTS} = getstring();
                    print "3FGM: ";
                    $stats{FG3M} = getstring();
                }
            }
            elsif ($boxscore_type eq "w")
            {
                # complete input for ABA
#                print "MIN: ";
#                $stats{MIN} = getstring();

                print "FGM: ";
                $stats{FGM} = getstring();
            	print "FGA: ";
                $stats{FGA} = getstring();
                print "FTM: ";
                $stats{FTM} = getstring();
                print "FTA: ";
                $stats{FTA} = getstring();

#        	    print "OREB: ";
#            	$stats{OREB} = getstring();
        	    print "REB: ";
            	$stats{REB} = getstring();
#                print "AST: ";
#                $stats{AST} = getstring();
#                print "TURNOVERS: ";
#                $stats{TURNOVERS} = getstring();
	            print "PF: ";
    	        $stats{PF} = getstring();
                print "PTS: ";
                $stats{PTS} = getstring();
                
                print "3FGM: ";
                $stats{FG3M} = getstring();
#                print "3FGA: ";
#                $stats{FG3A} = getstring();
                
#                print "BLOCKS: ";
#                $stats{BLOCKS} = getstring();
#                print "STEALS: ";
#                $stats{STEALS} = getstring();
                
            }
            elsif ($boxscore_type eq "n")
            {
                # basic input only, TSN/NYT style late 1960s
                print "FGM: ";
                $stats{FGM} = getstring();
                print "FTM: ";
                $stats{FTM} = getstring();
                print "FTA: ";
                $stats{FTA} = getstring();
                print "PTS: ";
                $stats{PTS} = getstring();
            }
            elsif ($boxscore_type eq "b")
            {
                # basic input only
                print "FGM: ";
                $stats{FGM} = getstring();
                print "FTM: ";
                $stats{FTM} = getstring();
                print "FTA: ";
                $stats{FTA} = getstring();
                print "PF: ";
                $stats{PF} = getstring();
                print "PTS: ";
                $stats{PTS} = getstring();
            }
            elsif ($boxscore_type eq "s")
            {
                # very basic input only
                print "FGM: ";
                $stats{FGM} = getstring();
                print "FTM: ";
                $stats{FTM} = getstring();
                print "PTS: ";
                $stats{PTS} = getstring();
            }
            else
            {
                # complete input
                print "MIN: ";
                $stats{MIN} = getstring();

                print "FGM: ";
                $stats{FGM} = getstring();
            	print "FGA: ";
                $stats{FGA} = getstring();
                print "FTM: ";
                $stats{FTM} = getstring();
                print "FTA: ";
                $stats{FTA} = getstring();

        	    print "REB: ";
            	$stats{REB} = getstring();
                print "AST: ";
                $stats{AST} = getstring();
	            print "PF: ";
    	        $stats{PF} = getstring();
                print "PTS: ";
                $stats{PTS} = getstring();
            }


            # stat,player,ID,FIRSTNAME,LASTNAME,MIN,FGM,FGA,FTM,FTA,3FGM,3FGA,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS
            print output_filehandle "stat,$team_forfile,player,$person{id},$person{first},$person{last},$stats{MIN},$stats{FGM},$stats{FGA},$stats{FTM},$stats{FTA},$stats{FG3M},$stats{FG3A},$stats{PTS},$stats{OREB},$stats{REB},$stats{AST},$stats{PF},$stats{BLOCKS},$stats{TURNOVERS},$stats{STEALS},$stats{TECHNICALFOUL}\n";


            print ("\n");
            # display list of players again
            $player_id_hash_count = 1;
            foreach $playerid (sort keys %player_id_hash)
            {
                print "$player_id_hash_count. $playerid  $player_id_hash{$playerid}\n";

                $player_id_hash_count++;
            }
            
            print "\nPlayer number, first name, or s to stop: ";
    	    $first_name_temp = ucfirst(getstring());

        } # end of player entry loop

        # Team stats

        # Now get team stat line - yes, this is inefficient cut-and-pasting of code; minutes omitted.
        print "Enter TEAM stats for $team_preamble\n";

        # fill in defaults
        $stats{MIN} = "";
        $stats{FGM} = "";
        $stats{FGA} = "";
        $stats{FTM} = "";
        $stats{FTA} = "";
        $stats{FG3M} = "";
        $stats{FG3A} = "";
        $stats{PF} = "";
        $stats{PTS} = "";
        $stats{OREB} = "";
        $stats{BLOCKS} = "";
        $stats{TURNOVERS} = "";
        $stats{STEALS} = "";
        $stats{TECHNICALFOUL} = "";
        $stats{REB} = "";
        $stats{AST} = "";
        $stats{TEAMREB} = "";
            
        if ($boxscore_type eq "a")
        {
            # very basic input only
            print "FGM: ";
            $stats{FGM} = getstring();
            print "FTM: ";
            $stats{FTM} = getstring();
            print "FTA: ";
            $stats{FTA} = getstring();
            print "PTS: ";
            $stats{PTS} = getstring();
            print "3FGM: ";
            $stats{FG3M} = getstring();
            print "PF: ";
	        $stats{PF} = getstring();
        }
        elsif ($boxscore_type eq "w")
        {
#            print "MIN: ";
#            $stats{MIN} = getstring();

            print "FGM: ";
            $stats{FGM} = getstring();
        	print "FGA: ";
            $stats{FGA} = getstring();
            print "FTM: ";
            $stats{FTM} = getstring();
            print "FTA: ";
            $stats{FTA} = getstring();

#    	    print "OREB: ";
#        	$stats{OREB} = getstring();
    	    print "REB: ";
        	$stats{REB} = getstring();
#            print "AST: ";
#            $stats{AST} = getstring();
#            print "TURNOVERS: ";
#            $stats{TURNOVERS} = getstring();
            print "PF: ";
	        $stats{PF} = getstring();
            print "PTS: ";
            $stats{PTS} = getstring();
            
            print "3FGM: ";
            $stats{FG3M} = getstring();
#            print "3FGA: ";
#            $stats{FG3A} = getstring();
            
#            print "BLOCKS: ";
#            $stats{BLOCKS} = getstring();
#            print "STEALS: ";
#            $stats{STEALS} = getstring();
        }
        elsif ($boxscore_type eq "n")
        {
            # very basic input only
            print "FGM: ";
            $stats{FGM} = getstring();
            print "FTM: ";
            $stats{FTM} = getstring();
            print "FTA: ";
            $stats{FTA} = getstring();
            print "PTS: ";
            $stats{PTS} = getstring();
        }
        elsif ($boxscore_type eq "b")
        {
            # basic input only
            print "FGM: ";
            $stats{FGM} = getstring();
            print "FTM: ";
            $stats{FTM} = getstring();
            print "FTA: ";
            $stats{FTA} = getstring();
            print "PF: ";
            $stats{PF} = getstring();
            print "PTS: ";
            $stats{PTS} = getstring();
        }
        elsif ($boxscore_type eq "s")
        {
            # very basic input only
            print "FGM: ";
            $stats{FGM} = getstring();
            print "FTM: ";
            $stats{FTM} = getstring();
            print "PTS: ";
            $stats{PTS} = getstring();
        }
        else
        {
            # complete input
            print "MIN: ";
            $stats{MIN} = getstring();

            print "FGM: ";
            $stats{FGM} = getstring();
        	print "FGA: ";
            $stats{FGA} = getstring();
            print "FTM: ";
            $stats{FTM} = getstring();
            print "FTA: ";
            $stats{FTA} = getstring();

    	    print "REB: ";
        	$stats{REB} = getstring();
            print "AST: ";
            $stats{AST} = getstring();
            print "PF: ";
	        $stats{PF} = getstring();
            print "PTS: ";
            $stats{PTS} = getstring();
            
            print "TEAMREB: ";
            $stats{TEAMREB} = getstring();
        }

        # stat,rteam|hteam,CITY,NICKNAME,FGM,FGA,FTM,FTA,FG3M,FG3A,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS
        print output_filehandle "tstat,$team_forfile,$stats{MIN},$stats{FGM},$stats{FGA},$stats{FTM},$stats{FTA},$stats{FG3M},$stats{FG3A},$stats{PTS},$stats{OREB},$stats{REB},$stats{AST},$stats{PF},$stats{BLOCKS},$stats{TURNOVERS},$stats{STEALS},$stats{TEAMREB},$stats{TECHNICALFOUL}\n";

        # Linescore
        print "$team_preamble linescore (comma delimited): ";
        $linescore = getstring();
        print output_filehandle "linescore,$team_forfile,$linescore\n";
        
        # Setup for entry of home team stats    
        $team_preamble = $info{hteam};
        $team_forfile = "hteam";

    }

	print "Technical Fouls: ";
	$techs = getstring();
	if (length($techs) > 0) # ignore blank lines
	{
	    print output_filehandle "info,techs,$techs\n";
    }
	
	print "Game notes: ";
	$game_notes = getstring();
	if (length($game_notes) > 0) # ignore blank lines
	{
	    print output_filehandle "info,note,$game_notes\n";
    }

# For 1967-68, no scores in TSN, so need to enter this info    	
#	if (($boxscore_type eq "a") || ($boxscore_type eq "n"))
#    {
#	    $sources_list = "TSN";
#	}
#	else
	{
	    print "\nSources for this boxscore: ";
    	$sources_list = getstring();
	}
	
	print output_filehandle "sources,$sources_list\n\n";

    # Save current file so we don't lose this boxscore if we crash
	close(output_filehandle);
	
	# Open output file, appending or creating as necessary
	if (!open(output_filehandle, ">>$output_filename")) 
	{
        die "Can't re-open output file $output_filename\n";
	}
    
	print "\n\n";    
	
    display_boxscore_menu();
    $boxscore_type = getstring();

    if ($boxscore_type eq "d")
    {
        $done = "yes";
    }

} # end of main while loop

close (output_filenandle);

print "File $output_filename created.\n";

