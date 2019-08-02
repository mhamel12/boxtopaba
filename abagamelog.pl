# ===============================================================
# 
# abagamelog.pl
#
# (c) 2010-2016 Michael Hamel
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of this license, visit # http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
#
# Version history
# 04/05/2011  1.0  MH  Initial version
# 08/07/2011  1.1  MH  Rework to support bgames database script
# 06/23/2014  1.2  MH  Add coaching record text to distinguish vs. players, new shading and text format for season totals
# 07/24/2014  1.3  MH  Rework for ABA with new table format without season totals
# 11/03/2016  1.4  MH  Support new multi-part, monthly, box score files
#
# ===============================================================


#! usr/bin/perl
use Getopt::Std;
use Date::Calc qw(:all);
use Boxtop;

# single game stats
my $fgm;
my $ftm;
my $fta;
my $pf;
my $pts;
my $min;
my $fga;
my $reb;
my $ast;

my $road_team_points;
my $road_team_name;
my $home_team_points;
my $home_team_name;
my $person_team;
my $game_date;
my $game_title;
my $game_number;
my $game_overtime;
my $game_neutral_site;

my $person_is_a;

# Use simple variables for totals
my $totals_games_played;
my $totals_fgm;
my $totals_ftm;
my $totals_fta;
my $totals_pf;
my $totals_pts;
my $totals_min;
my $totals_fga;
my $totals_reb;
my $totals_ast;

# These are counters to determine how complete the season is
# We increment these whenever the stat entry is NOT an empty string
my $totals_counter_fgm;
my $totals_counter_ftm;
my $totals_counter_fta;
my $totals_counter_pf;
my $totals_counter_pts;
my $totals_counter_min;
my $totals_counter_fga;
my $totals_counter_reb;
my $totals_counter_ast;


# Splits
my %splits;

my $output_filename;

# ===============================================================

sub usage
{
    print "Create game log for a specific player or coach based on boxtop file(s).\n";
    print "\n";
    print "Output is written to either an html file or a text file in .csv format\n";
    
    print "\n";
    print "\nUSAGE:";
    print "\n abagamelog.pl -p playerid or coachid [-o HTMLoutputfilename]";
    print "\n            ( [-i inputfilename] [-l link to HTML filename]";
    print "\n            OR [-f configuration file] )";
    print "\n            [-v opponent filter] [-c CSVoutputfilename]";
    print "\n            [-a append mode] [-t output title]";
    print "\n            [-j java sorting on|off]";
    print "\n\n";
    print " If linking to an HTML filename, must be in same folder as the gamelog\n";
    print " Append mode appends raw html with no header or footer to the output file\n";
    print "\n";
    print " Enclose opponent filter in quotes for best results\n";
    print " Note that -o takes precedence over -c\n";
    print " Default filenames are input.csv and <id>_log.htm unless specified.\n";
   
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

$br_player_link = "http:\/\/www.basketball-reference.com\/players";
$br_coach_link = "http:\/\/www.basketball-reference.com\/coaches";

sub add_html_header($$$)
{
	$name = $_[0];
	$id = $_[1];	
	$lastname = $_[2];

	$ch = substr($id,0,1);
	$index_link = "aba_" . $ch . "_log_index.html";
	print output_filehandle "<h5><a href=\"$index_link\">Game Log Index</a></h5>\n";
	
	# Add a link point so we can provide direct links to a particular player if desired.
	# For now, we are not creating a formal index	
	print output_filehandle "<a id=$id><\/a>\n";
	print output_filehandle "<h1>";

    $personid = $cli_opt{"p"};
    if ($id =~ /c$/) # this is a coach
	{
		print output_filehandle "<a href=\"$br_coach_link\/$id.html\">$name<\/a><\/h1>\n";
		print output_filehandle "<h2>Coaching Record</h2>\n";
	}
	else
	{
	    $ch = substr($id,0,1);
	    $start_of_lastname = substr($lastname,0,1);
	    if ($ch ne $start_of_lastname)
	    {
    	    # need to look for exceptions
    	    if ($id eq "abdulma01")
    	    {
    		    print output_filehandle "<a href=\"$br_player_link\/$ch\/$id.html\">$name<\/a> (Mahdi Abdul-Rahman)<\/h1>\n";
    	    }
    	    elsif ($id eq "abdulza01")
    	    {
    		    print output_filehandle "<a href=\"$br_player_link\/$ch\/$id.html\">$name<\/a> (Zaid Abdul-Aziz)<\/h1>\n";
    	    }
    	    else # we're looking for more exceptions, so just print to stdout and use normal header
    	    {
        	    print "WARNING: $id not a match for $name ($lastname) - need to edit gamelog.pl\n";
    		    print output_filehandle "<a href=\"$br_player_link\/$ch\/$id.html\">$name<\/a><\/h1>\n";
    	    }
	    }
	    else
	    {
		    print output_filehandle "<a href=\"$br_player_link\/$ch\/$id.html\">$name<\/a><\/h1>\n";
	    }
	}		
	print output_filehandle "<\/h1>\n";
	if ($opponent_filter ne " ")
	{
		print output_filehandle "<h4>filtered for $opponent_filter<\/h4>\n";
	}
}
# end of add_html_header

# ===============================================================

sub add_csv_header($)
{
	$page_title = $_[0];	
	
	print output_filehandle "$page_title vs. $opponent_filter\n";

}
# end of add_csv_header

# ===============================================================

sub add_html_footer()
{
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

	print output_filehandle "<p>This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.<br>To view a copy of this license, visit <a href=\"http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/\">http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/<\/a>\n";
	printf output_filehandle "<p>Web page created at %02d:%02d:%02d on %02s\/%02d\/%4d using abagamelog.pl based on boxtop format data, (c) 2010-2014 Michael Hamel.\n",$hour,$min,$sec,$mon+1,$mday,$year+1900;
}
# end of sub add_html_footer()

# ===============================================================

sub add_csv_footer()
{
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

	print output_filehandle "This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.\n";
	print output_filehandle "To view a copy of this license visit http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/\n";
	printf output_filehandle ".CSV file created at %02d:%02d:%02d on %02s\/%02d\/%4d using abagamelog.pl based on boxtop format data (c) 2010-2014 Michael Hamel.\n",$hour,$min,$sec,$mon+1,$mday,$year+1900;
}
# end of sub add_csv_footer()

# ===============================================================

sub get_season_string($)
{
    $game_date = $_[0];
    
	# determine which season this is by looking at the final game date
    @final_game_date = split(/\//,$game_date);
    if ($final_game_date[0] < 8) # January-July
    {
		$year = $final_game_date[2];
	}
	else
	{
		$year = $final_game_date[2] + 1;
	}
	
	# now that we have the year (e.g. 1969) we create a string to represent the season (e.g. 1968-69)
	$season = ($year - 1) . "-" . substr($year,2,2);
	
	return($season);    
}
# end of get_season_string()

# ===============================================================

# Black on gray for sections, with reduced font size
my $table_section_header = "<thead><tr bgcolor=dddddd style = \"font-size:80%\;\"><th align = \"left\">Date<\/th><th align = \"left\">Team<\/th><th align = \"right\">PTS<\/th><th align = \"left\">@<\/th><th align = \"left\">Opp<\/th><th align = \"right\">PTS<\/th><th align = \"left\">OT<\/th><th align = \"right\">MIN<\/th><th align = \"right\">FGM<\/th><th align = \"right\">FGA<\/th><th align = \"right\">FTM<\/th><th align = \"right\">FTA<\/th><th align = \"right\">3FG<\/th><th align = \"right\">3FA<\/th><th align = \"right\">PTS<\/th><th align = \"right\">ORB<\/th><th align = \"right\">REB<\/th><th align = \"right\">AST<\/th><th align = \"right\">PF<\/th><th align = \"right\">TO<\/th><th align = \"right\">BL<\/th><th align = \"right\">ST<\/th><th align = \"left\">W-L<\/th><th align = \"left\">NOTES<\/th><\/tr></thead>\n";
my $table_coach_section_header = "<thead><tr bgcolor=dddddd style = \"font-size:80%\;\"><th align = \"left\">Date<\/th><th align = \"left\">Team<\/th><th align = \"right\">PTS<\/th><th align = \"left\">@<\/th><th align = \"left\">Opp<\/th><th align = \"right\">PTS<\/th><th align = \"left\">OT<\/th><th align = \"left\">W-L<\/th><th align = \"left\">NOTES<\/th><\/tr></thead>\n";

# White on black for season totals
# my $totals_section_header = "<tr bgcolor=black style = \"color:white\;\"><td align = \"left\">Season<\/td><td align = \"left\"><\/td><td align = \"left\"><\/td><td align = \"right\">Games<\/td><td align = \"right\">MIN<\/td><td align = \"right\">FGM<\/td><td align = \"right\">FGA<\/td><td align = \"right\">FTM<\/td><td align = \"right\">FTA<\/td><td align = \"right\">REB<\/td><td align = \"right\">AST<\/td><td align = \"right\">PF<\/td><td align = \"right\">PTS<\/td><td align = \"left\">W-L<\/td><td align = \"left\"><\/td><\/tr>\n";
# my $totals_coach_section_header = "<tr bgcolor=black style = \"color:white\;\"><td align = \"left\">Season<\/td><td align = \"left\"><\/td><td align = \"left\"><\/td><td align = \"right\">Games<\/td><td align = \"left\">W-L<\/td><td align = \"left\"><\/td><\/tr>\n";


my $csv_section_header = "Date,Team,Road,Home,MIN,FGM,FGA,FTM,FTA,REB,AST,PF,PTS,RECORD,NOTES\n";
my $csv_coach_section_header = "Date,Team,Road,Home,RECORD,NOTES\n";
my $mywins;
my $mylosses;
my $gamenumber_today  = ""; # usually a blank, but if two games between the same two teams on the same day, can be a 2 (see 1/24/1976, Nets vs. Squires)

my $season_year;

sub dump_to_file()
{
	if ($person_team eq 'rteam')
	{
		$myteam = $road_team_name;
		$myteam_pts = $road_team_points;
		$oppteam = $home_team_name;
		$oppteam_pts = $home_team_points;
		if ($game_neutral_site eq "yes")
		{
    		$gamesite = "N";
        }
        else
		{
    		$gamesite = "@";
        }
	}
	else
	{
		$myteam = $home_team_name;
		$myteam_pts = $home_team_points;
		$oppteam = $road_team_name;
		$oppteam_pts = $road_team_points;
		if ($game_neutral_site eq "yes")
		{
    		$gamesite = "N";
        }
        else
		{
    		$gamesite = " ";
        }
	}
	
	if ($myteam_pts > $oppteam_pts)
	{
		$mywins++;
	}
	else
	{
		$mylosses++;
	}	

#    ($mon1,$day1,$year1) = split('/',$game_date);
#    $padded_mon = sprintf("%02d",$mon1);
#    $game_date_link = $html_link_filename . "_" . $padded_mon . ".htm#" . Boxtop_GetGameLinkText($game_date,$home_team_name,$road_team_name,$gamenumber_today);
    $game_date_link = Boxtop_GetFullGameLinkText($game_date,$home_team_name,$road_team_name,$gamenumber_today,$html_link_filename);
	if ($person_is_a eq "player")
    {
	    if ($output_type eq "html")
	    {
		    print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
		    if (length($html_link_filename) > 0)
		    {
			    print output_filehandle "<td align = \"left\"><a href=\"$game_date_link\">$game_date<\/a><\/td>";
		   	}
		   	else
		   	{
			    print output_filehandle "<td align = \"left\">$game_date<\/td>";
			}
		    print output_filehandle "<td align = \"left\">$myteam<\/td><td align = \"right\">$myteam_pts</td><td align = \"left\">$gamesite<\/td><td align = \"left\">$oppteam<\/td><td align = \"right\">$oppteam_pts</td><td align = \"left\">$game_overtime<\/td><td align = \"right\">$min<\/td>";
		    print output_filehandle "<td align = \"right\">$fgm<\/td><td align = \"right\">$fga<\/td><td align = \"right\">$ftm<\/td><td align = \"right\">$fta<\/td><td align = \"right\">$fg3m<\/td><td align = \"right\">$fg3a<\/td><td align = \"right\">$pts<\/td>\n";
		    print output_filehandle "<td align = \"right\">$oreb<\/td><td align = \"right\">$reb<\/td><td align = \"right\">$ast<\/td><td align = \"right\">$pf<\/td><td align = \"right\">$turnovers<\/td><td align = \"right\">$blocks<\/td><td align = \"right\">$steals<\/td><td align = \"center\">$mywins-$mylosses<\/td><td align = \"left\">$game_title<\/td><\/tr>\n";
		}		    
		else
	    {
		    print output_filehandle "$game_date,$myteam,$myteam_pts,$gamesite,$oppteam,$oppteam_pts,$min,$fgm,$fga,$ftm,$fta,$reb,$ast,$pf,$pts,$mywins-$mylosses,$game_title\n";
		}		    
	}
	else
	{
		if ($output_type eq "html")
	    {
		    print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
		    if (length($html_link_filename) > 0)
		    {
			    print output_filehandle "<td align = \"left\"><a href=\"$game_date_link\">$game_date<\/a><\/td>";
		   	}
		   	else
		   	{
			    print output_filehandle "<td align = \"left\">$game_date<\/td>";
			}
		    print output_filehandle "<td align = \"left\">$myteam<\/td><td align = \"right\">$myteam_pts</td><td align = \"left\">$gamesite<\/td><td align = \"left\">$oppteam<\/td><td align = \"right\">$oppteam_pts</td><td align = \"left\">$game_overtime<\/td><td align = \"center\">$mywins-$mylosses<\/td><td align = \"left\">$game_title<\/td><\/tr>\n";
		}
		else
	    {
		    print output_filehandle "$game_date,$myteam,$road_team_name $road_team_points,$home_team_name $home_team_points,$mywins-$mylosses,$game_title\n";
		}
	}
}
# end of sub dump_to_file()

# ===============================================================

my $splits_section_header = "<tr style = \"font-weight:bold;\" style = \"font-size:80%\;\"><td align = \"left\">Split<\/td><td align = \"left\">Value<\/td><td align = \"right\">Games<\/td><td align = \"right\">FGM<\/td><td align = \"right\">FTM<\/td><td align = \"right\">FTA<\/td><td align = \"right\">3FG<\/td><td align = \"right\">PTS<\/td><td align = \"right\">PPG<\/td><\/tr>\n";
my $splits_blank_row = "<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>\n";

@months_list = ( "September", "October", "November", "December", "January", "February", "March", "April", "May", "June", "July", "August" );
@days_list = ( "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" );

sub dump_splits_to_file($$)
{
    $season = $_[0];
	$type = $_[1];
	
    if ($person_is_a ne "player")
    {
        return;
    }
    
    # If an element does not exist (such as $splits{Wins} if the player never played in a winning game), fill in the hash with zeroes so the tables look better.
    # Do NOT do this for opponents. If they didn't play against an opponent, do not list them at all.
    # Doing this manually is the best approach... Home, Road, Wins, Losses... and eventually, month and day_of_week
    # Could do this here or when we clear the %splits hash.
    if (!exists $splits{Home})
    {
    	$splits{Home}{Games} = 0;
    	$splits{Home}{FGM} = 0;
    	$splits{Home}{FTM} = 0;
    	$splits{Home}{FTA} = 0;
    	$splits{Home}{F3GM} = 0;
    	$splits{Home}{PTS} = 0;
    }
    
    if (!exists $splits{Road})
    {
    	$splits{Road}{Games} = 0;
    	$splits{Road}{FGM} = 0;
    	$splits{Road}{FTM} = 0;
    	$splits{Road}{FTA} = 0;
    	$splits{Road}{F3GM} = 0;
    	$splits{Road}{PTS} = 0;
    }

    if (!exists $splits{Neutral})
    {
    	$splits{Neutral}{Games} = 0;
    	$splits{Neutral}{FGM} = 0;
    	$splits{Neutral}{FTM} = 0;
    	$splits{Neutral}{FTA} = 0;
    	$splits{Neutral}{F3GM} = 0;
    	$splits{Neutral}{PTS} = 0;
    }

    if (!exists $splits{Wins})
    {
    	$splits{Wins}{Games} = 0;
    	$splits{Wins}{FGM} = 0;
    	$splits{Wins}{FTM} = 0;
    	$splits{Wins}{FTA} = 0;
    	$splits{Wins}{F3GM} = 0;
    	$splits{Wins}{PTS} = 0;
    }

    if (!exists $splits{Losses})
    {
    	$splits{Losses}{Games} = 0;
    	$splits{Losses}{FGM} = 0;
    	$splits{Losses}{FTM} = 0;
    	$splits{Losses}{FTA} = 0;
    	$splits{Losses}{F3GM} = 0;
    	$splits{Losses}{PTS} = 0;
    }

    # compute points per game    
    foreach $vsopp (keys %splits)
    {
        if ($splits{$vsopp}{Games} > 0)
        {
            $temp = ($splits{$vsopp}{PTS} * 1.0) / $splits{$vsopp}{Games};
            $splits{$vsopp}{PPG} = sprintf("%.1f",$temp); # rounds up or down appropriately to one decimal place
        }
        else
        {
            $splits{$vsopp}{PPG} = 0.0;
        }
    }    
    
    print output_filehandle "<h3>$season $type Splits</h3>\n";
    print output_filehandle "<table>\n";
    print output_filehandle $splits_section_header;
#    print output_filehandle "<tbody>\n";
    
    
    print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
    print output_filehandle "<td align = \"left\"></td><td align = \"left\">Totals</td><td align = \"right\">$splits{Totals}{Games}<\/td><td align = \"right\">$splits{Totals}{FGM}<\/td><td align = \"right\">$splits{Totals}{FTM}<\/td><td align = \"right\">$splits{Totals}{FTA}<\/td><td align = \"right\">$splits{Totals}{F3GM}<\/td><td align = \"right\">$splits{Totals}{PTS}<\/td><td align = \"right\">$splits{Totals}{PPG}<\/td></tr>\n";
    print output_filehandle $splits_blank_row;
    print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
    print output_filehandle "<td align = \"left\">H/R</td><td align = \"left\">Home</td><td align = \"right\">$splits{Home}{Games}<\/td><td align = \"right\">$splits{Home}{FGM}<\/td><td align = \"right\">$splits{Home}{FTM}<\/td><td align = \"right\">$splits{Home}{FTA}<\/td><td align = \"right\">$splits{Home}{F3GM}<\/td><td align = \"right\">$splits{Home}{PTS}<\/td><td align = \"right\">$splits{Home}{PPG}<\/td></tr>\n";
    print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
    print output_filehandle "<td align = \"left\"></td><td align = \"left\">Road</td><td align = \"right\">$splits{Road}{Games}<\/td><td align = \"right\">$splits{Road}{FGM}<\/td><td align = \"right\">$splits{Road}{FTM}<\/td><td align = \"right\">$splits{Road}{FTA}<\/td><td align = \"right\">$splits{Road}{F3GM}<\/td><td align = \"right\">$splits{Road}{PTS}<\/td><td align = \"right\">$splits{Road}{PPG}<\/td></tr>\n";
    
    # omit neutral line if they did not play in any neutral site games
    if ($splits{Neutral}{Games} > 0)
    {
        print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
        print output_filehandle "<td align = \"left\"></td><td align = \"left\">Neutral</td><td align = \"right\">$splits{Neutral}{Games}<\/td><td align = \"right\">$splits{Neutral}{FGM}<\/td><td align = \"right\">$splits{Neutral}{FTM}<\/td><td align = \"right\">$splits{Neutral}{FTA}<\/td><td align = \"right\">$splits{Neutral}{F3GM}<\/td><td align = \"right\">$splits{Neutral}{PTS}<\/td><td align = \"right\">$splits{Neutral}{PPG}<\/td></tr>\n";
    }
    
    print output_filehandle $splits_blank_row;
    
    print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
    print output_filehandle "<td align = \"left\">Result</td><td align = \"left\">Wins</td><td align = \"right\">$splits{Wins}{Games}<\/td><td align = \"right\">$splits{Wins}{FGM}<\/td><td align = \"right\">$splits{Wins}{FTM}<\/td><td align = \"right\">$splits{Wins}{FTA}<\/td><td align = \"right\">$splits{Wins}{F3GM}<\/td><td align = \"right\">$splits{Wins}{PTS}<\/td><td align = \"right\">$splits{Wins}{PPG}<\/td></tr>\n";
    print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
    print output_filehandle "<td align = \"left\"></td><td align = \"left\">Losses</td><td align = \"right\">$splits{Losses}{Games}<\/td><td align = \"right\">$splits{Losses}{FGM}<\/td><td align = \"right\">$splits{Losses}{FTM}<\/td><td align = \"right\">$splits{Losses}{FTA}<\/td><td align = \"right\">$splits{Losses}{F3GM}<\/td><td align = \"right\">$splits{Losses}{PTS}<\/td><td align = \"right\">$splits{Losses}{PPG}<\/td></tr>\n";

    if ($type eq "Regular Season")
    {
        print output_filehandle $splits_blank_row;
        $months_printed = 0;    
        
        foreach (@months_list)
        {
            if (exists($splits{$_}))
            {
                $mon = $_;
                print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
                if ($months_printed == 0)
                {
                    print output_filehandle "<td align = \"left\">Month</td>";
                    $months_printed++;
                }      
                else
                {
                    print output_filehandle "<td align = \"left\"></td>";
                }
                print output_filehandle "<td align = \"left\">$mon</td><td align = \"right\">$splits{$mon}{Games}<\/td><td align = \"right\">$splits{$mon}{FGM}<\/td><td align = \"right\">$splits{$mon}{FTM}<\/td><td align = \"right\">$splits{$mon}{FTA}<\/td><td align = \"right\">$splits{$mon}{F3GM}<\/td><td align = \"right\">$splits{$mon}{PTS}<\/td><td align = \"right\">$splits{$mon}{PPG}<\/td></tr>\n";
            }   
        }
        
        print output_filehandle $splits_blank_row;
        $days_printed = 0;   
        
        foreach (@days_list)
        {
            if (exists($splits{$_}))
            {
                $dow = $_;
                print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
                if ($days_printed == 0)
                {
                    print output_filehandle "<td align = \"left\">Day of Week</td>";
                    $days_printed++;
                }      
                else
                {
                    print output_filehandle "<td align = \"left\"></td>";
                }
                print output_filehandle "<td align = \"left\">$dow</td><td align = \"right\">$splits{$dow}{Games}<\/td><td align = \"right\">$splits{$dow}{FGM}<\/td><td align = \"right\">$splits{$dow}{FTM}<\/td><td align = \"right\">$splits{$dow}{FTA}<\/td><td align = \"right\">$splits{$dow}{F3GM}<\/td><td align = \"right\">$splits{$dow}{PTS}<\/td><td align = \"right\">$splits{$dow}{PPG}<\/td></tr>\n";
            }   
        }         
    }
        
    print output_filehandle $splits_blank_row;
    $dumb_counter = 0;
    foreach $vsopp (sort keys %splits)
    {
        if ($vsopp =~ /^vs/)
        {
            # print "Opponent" in first column for first opponent only.
            print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
            if ($dumb_counter == 0)
            {
                print output_filehandle "<td align = \"left\">Opponent</td>";
                $dumb_counter++;
            }      
            else
            {
                print output_filehandle "<td align = \"left\"></td>";
            }
            print output_filehandle "<td align = \"left\">$vsopp</td><td align = \"right\">$splits{$vsopp}{Games}<\/td><td align = \"right\">$splits{$vsopp}{FGM}<\/td><td align = \"right\">$splits{$vsopp}{FTM}<\/td><td align = \"right\">$splits{$vsopp}{FTA}<\/td><td align = \"right\">$splits{$vsopp}{F3GM}<\/td><td align = \"right\">$splits{$vsopp}{PTS}<\/td><td align = \"right\">$splits{$vsopp}{PPG}<\/td></tr>\n";
        }
    }    
    
#    print output_filehandle "</tbody>\n";
    print output_filehandle "</table>\n";
}

# ===============================================================

# Note: most of these totals are not used any more... but the splits hashes ARE used.
sub increment_totals()
{
	$totals_games_played++;
	
	if ($person_is_a eq "player")
	{
		$totals_min += $min;
		$totals_fgm += $fgm;
		$totals_fga += $fga;
		$totals_ftm += $ftm;
		$totals_fta += $fta;
		$totals_pts += $pts;
		$totals_reb += $reb;
		$totals_ast += $ast;
		$totals_pf += $pf;
					
		if ($min ne "")
		{
			$totals_counter_min++;
		}
		if ($fgm ne "")
		{
			$totals_counter_fgm++;
		}
		if ($fga ne "")
		{
			$totals_counter_fga++;
		}
		if ($ftm ne "")
		{
			$totals_counter_ftm++;
		}
		if ($fta ne "")
		{
			$totals_counter_fta++;
		}
		if ($pts ne "")
		{
			$totals_counter_pts++;
		}
		if ($reb ne "")
		{
			$totals_counter_reb++;
		}
		if ($ast ne "")
		{
			$totals_counter_ast++;
		}
		if ($pf ne "")
		{
			$totals_counter_pf++;
		}
	}
	
	# For splits, we're using a hash and only collecting the basic stats. 
	# In fact, the totals above aren't even being printed in the ABA version.
	$splits{Totals}{Games}++;
	$splits{Totals}{FGM}+=$fgm;
	$splits{Totals}{FTM}+=$ftm;
	$splits{Totals}{FTA}+=$fta;
	$splits{Totals}{F3GM}+=$fg3m;
	$splits{Totals}{PTS}+=$pts;
	
	if ($person_team eq "rteam")
	{
    	if ($game_neutral_site eq "yes")
    	{
        	$splits{Neutral}{Games}++;
        	$splits{Neutral}{FGM}+=$fgm;
        	$splits{Neutral}{FTM}+=$ftm;
        	$splits{Neutral}{FTA}+=$fta;
        	$splits{Neutral}{F3GM}+=$fg3m;
        	$splits{Neutral}{PTS}+=$pts;
        }
        else
        {
        	$splits{Road}{Games}++;
        	$splits{Road}{FGM}+=$fgm;
        	$splits{Road}{FTM}+=$ftm;
        	$splits{Road}{FTA}+=$fta;
        	$splits{Road}{F3GM}+=$fg3m;
        	$splits{Road}{PTS}+=$pts;
        }
        	
    	$opponent_team_string = "vs " . $home_team_name;
    }
    else
	{
    	if ($game_neutral_site eq "yes")
    	{
        	$splits{Neutral}{Games}++;
        	$splits{Neutral}{FGM}+=$fgm;
        	$splits{Neutral}{FTM}+=$ftm;
        	$splits{Neutral}{FTA}+=$fta;
        	$splits{Neutral}{F3GM}+=$fg3m;
        	$splits{Neutral}{PTS}+=$pts;
        }
        else
        {
        	$splits{Home}{Games}++;
        	$splits{Home}{FGM}+=$fgm;
        	$splits{Home}{FTM}+=$ftm;
        	$splits{Home}{FTA}+=$fta;
        	$splits{Home}{F3GM}+=$fg3m;
        	$splits{Home}{PTS}+=$pts;
        }
    
    	$opponent_team_string = "vs " . $road_team_name;
    }
    
	$splits{$opponent_team_string}{Games}++;
	$splits{$opponent_team_string}{FGM}+=$fgm;
	$splits{$opponent_team_string}{FTM}+=$ftm;
	$splits{$opponent_team_string}{FTA}+=$fta;
	$splits{$opponent_team_string}{F3GM}+=$fg3m;
	$splits{$opponent_team_string}{PTS}+=$pts;    
    
    if ((($person_team eq "rteam") && ($road_team_points > $home_team_points)) ||
        (($person_team eq "hteam") && ($home_team_points > $road_team_points)))
    {
    	$splits{Wins}{Games}++;
    	$splits{Wins}{FGM}+=$fgm;
    	$splits{Wins}{FTM}+=$ftm;
    	$splits{Wins}{FTA}+=$fta;
    	$splits{Wins}{F3GM}+=$fg3m;
    	$splits{Wins}{PTS}+=$pts;
    }
    else
    {
    	$splits{Losses}{Games}++;
    	$splits{Losses}{FGM}+=$fgm;
    	$splits{Losses}{FTM}+=$ftm;
    	$splits{Losses}{FTA}+=$fta;
    	$splits{Losses}{F3GM}+=$fg3m;
    	$splits{Losses}{PTS}+=$pts;
    }
    	
    my ($month,$day,$year) = split ('/',$game_date);
   	$wday = Day_of_Week($year,$month,$day);
	$the_day = Day_of_Week_to_Text($wday);
	$the_month = Month_to_Text($month);
	
	$splits{$the_day}{Games}++;
	$splits{$the_day}{FGM}+=$fgm;
	$splits{$the_day}{FTM}+=$ftm;
	$splits{$the_day}{FTA}+=$fta;
	$splits{$the_day}{F3GM}+=$fg3m;
	$splits{$the_day}{PTS}+=$pts;
    
	$splits{$the_month}{Games}++;
	$splits{$the_month}{FGM}+=$fgm;
	$splits{$the_month}{FTM}+=$ftm;
	$splits{$the_month}{FTA}+=$fta;
	$splits{$the_month}{F3GM}+=$fg3m;
	$splits{$the_month}{PTS}+=$pts;
    
} # end of sub increment_totals()

# ===============================================================

##########################################################################
#
# Parse command line arguments
#
##########################################################################


$start_of_boxscore = "gamebxt";

# default filenames
@input_filename_array;
@html_link_filename_array;
@regular_season_game_array;

my $java_sorting = "off";

getopts('p:i:o:h:c:v:l:f:a:t:j:',\%cli_opt);

if (exists ($cli_opt{"p"}))
{
    $personid = $cli_opt{"p"};
    if ($personid =~ /c$/)
    {
	    $person_is_a = "coach";
	}
	else
	{
		$person_is_a = "player";
	}
}
else # this is a required argument
{
	usage();
	exit;
}

if (exists ($cli_opt{"a"}))
{
	$append_mode = "yes";
}
else
{
	$append_mode = "no";
}

if (exists ($cli_opt{"j"}))
{
	$java_sorting = lc($cli_opt{"j"});
}

if (exists ($cli_opt{"o"}))
{
    $output_filename = $cli_opt{"o"};
    $output_type = "html";
}
elsif (exists ($cli_opt{"c"}))
{
    $output_filename = $cli_opt{"c"};
    $output_type = "csv";
}
else # use default name and format for output file
{
	$output_filename = $personid."_log.htm";
	$output_type = "html";
}

if (exists ($cli_opt{"t"}))
{
	$page_title = $cli_opt{"t"};
}
else
{
	$page_title = $output_filename;
}

if (exists ($cli_opt{"v"}))
{
    $opponent_filter = $cli_opt{"v"};
}
else
{
	$opponent_filter = " ";
}

if (exists ($cli_opt{"f"}))
{
	$config_file = $cli_opt{"f"};
	
	if (!open(config_filehandle, "$config_file"))
	{
		die "Can't open config file $config_file\n";
	}
	
	while ($line = <config_filehandle>)
	{
		@this_line_array = parse_csv_line($line);
		push(@input_filename_array,$this_line_array[0]);
		push(@html_link_filename_array,$this_line_array[1]);
#		push(@regular_season_games_array,$this_line_array[2]);
	}

	close(config_filehandle);
}
else # look for -i and -l options
{
	# set defaults
	$input_filename_array[0] = "input.csv";
	$html_link_filename_array[0] = "";

	if (exists ($cli_opt{"i"}))
	{
    	$input_filename_array[0] = $cli_opt{"i"};
	}

	if (exists ($cli_opt{"l"}))
	{
		$html_link_filename_array[0] = $cli_opt{"l"};
	}
}

if (exists ($cli_opt{"h"}))
{
	usage();
	exit;
}

##########################################################################
#
# Finished with argument parsing, let's get to work
#
##########################################################################

# open for writing, creating or appending depending on flag
if ($append_mode eq "yes")
{
	if (!open(output_filehandle, ">>$output_filename")) 
	{
        close(input_filehandle);
        die "Can't open output file $output_filename\n";
	}
}	
else
{
	if (!open(output_filehandle, ">$output_filename")) 
	{
        close(input_filehandle);
        die "Can't open output file $output_filename\n";
	}
}

if ($append_mode eq "no")
{
	# Output the document header
	if ($output_type eq "html")
	{
        print output_filehandle Boxtop_HtmlHeader($page_title, $java_sorting);
	}
}

# We haven't put a player/coach header in the file yet, so set this so we do it later
$player_header_missing = "yes";

# my $seasons_read_in = 0; # used to index into regular_season_games_array[]
my $regular_season_games_this_season;

%splits = ();

# Main loop starts here
foreach $element (@input_filename_array)
{
	$input_filename = $element;
	$html_link_filename = shift @html_link_filename_array;
	
	# open for reading
	if (!open(input_filehandle, "$input_filename")) 
	{
	        die "Can't open input file $input_filename\n";
	}
	
	my $lines_read_from_input_file = 0;
	my $first_gamebxt_read = "no";
	my $current_game_number = 0;
	
#	$regular_season_games_this_season = $regular_season_games_array[$seasons_read_in];
	
	$totals_games_played = 0;
	$totals_fgm = 0;
	$totals_ftm = 0;
	$totals_fta = 0;
	$totals_pf = 0;
	$totals_pts = 0;
	$totals_min = 0;
	$totals_fga = 0;
	$totals_reb = 0;
	$totals_ast = 0;
	$totals_team_reb = 0;
	
	$totals_counter_fgm = 0;
	$totals_counter_ftm = 0;
	$totals_counter_fta = 0;
	$totals_counter_pf = 0;
	$totals_counter_pts = 0;
	$totals_counter_min = 0;
	$totals_counter_fga = 0;
	$totals_counter_reb = 0;
	$totals_counter_ast = 0;
	$totals_counter_team_reb = 0;
	
	$mywins = 0;
	$mylosses = 0;

	my $firstname;
	my $lastname;
	
	my $person_found = "false"; # this tracks whether THIS person was found in the current .csv file
	my $next_game_is_playoffs = "false"; # this is used to determine whether to turn on the $playoffs_have_started flag
	my $playoffs_have_started = "false"; # this tracks whether we've found a playoff game in the current .csv file
	my $found_playoff_game = "false"; # this tracks whether a playoff game was found containing THIS person
	
	# start of loop for a single input file
	
	while ($line = <input_filehandle>)
	{
		$lines_read_from_input_file++;
		
	    # read until we read a "gamebxt" which tells us to loop back around to the next boxscore
	    # but skip everything until after we read the first one
	    if ($first_gamebxt_read eq "no")
	    {
		    if ($line =~ /^$start_of_boxscore/)
		    {
			    # flip the flag, but ignore this line
			    $first_gamebxt_read = "yes";
			    $current_game_number++;
			    $game_neutral_site = "no";
			}
			# else just skip the line
		}			  
	    elsif ($line =~ /^$start_of_boxscore/)
	    {
		    $current_game_number++;
		    
		    if ($person_found eq "true")
		    {
			    # only dump data if we've actually found the person in this game
			    if (($person_team eq "rteam" && $home_team_name=~/$opponent_filter/) ||
			        ($person_team eq "hteam" && $road_team_name=~/$opponent_filter/))
			    {
				    increment_totals();

					if ($player_header_missing eq "yes")
					{
						# now add the player header
						if ($output_type eq "html")
						{
							if ($person_is_a eq "player")
							{
								$name = "$firstname $lastname";
							}
							else
							{
								$name = "$firstname $lastname";
							}
							
							add_html_header($name,$personid,$lastname);
							
						}
						else
						{
							add_csv_header($title);
							
                			# print header
                			if ($person_is_a eq "player")
                		    {
                			    print output_filehandle $csv_section_header;
                			}
                			else
                		    {
                			    print output_filehandle $csv_coach_section_header;
                			}
						}			
						
						$player_header_missing = "no";
					}	    

					if ($totals_games_played == 1) # print this header only at start of each season
					{
    					$season_string = get_season_string($game_date);
    					if ( $found_playoff_game eq "true")
    					{
        				    print output_filehandle "<h3>$season_string Playoffs</h3>\n";
    				    }
    				    else
    					{
        				    print output_filehandle "<h3>$season_string Regular Season</h3>\n";
    				    }
    				    
    				    if ($java_sorting eq "on")
        				{
#                            print output_filehandle "<p style = \"font-size:90%\;\">Click on any column header to sort</p>\n";
                            print output_filehandle "<h5><span style=\"color:gray\">Click on any column header to sort</span></h5>\n";
                            print output_filehandle "<table class=\"tablesorter\">\n";
        		        }
        		        else
        		        {
            				print output_filehandle "<table>\n";
        		        }
        		        
            			if ($person_is_a eq "player")
            		    {
            			    print output_filehandle $table_section_header;
            			}
            			else
            		    {
            			    print output_filehandle $table_coach_section_header;
            			}
            			print output_filehandle "<tbody>\n"
			        }   
													    				
				    dump_to_file();
				    $gamenumber_today = "";
				}
			    
				
			    $person_found = "false";
			}

       	    $game_neutral_site = "no";
			
			# If we've just found the playoffs sentinel, complete this table and get ready for the playoff table
		    if ($next_game_is_playoffs eq "true")
            {
                $next_game_is_playoffs = "false";
                			    
                if ($totals_games_played > 0)
                {
                    # Complete the table
                    print output_filehandle "</tbody>\n";
                    print output_filehandle "</table>\n";
        
        #    			dump_totals_to_file($season_string,"Regular Season");
                    dump_splits_to_file($season_string,"Regular Season");
                    print output_filehandle "<hr>\n";
                
                    # clear splits
                    %splits = ();
                    
        			# reset all totals
                   	$totals_games_played = 0;
                	$totals_fgm = 0;
                	$totals_ftm = 0;
                	$totals_fta = 0;
                	$totals_pf = 0;
                	$totals_pts = 0;
                	$totals_min = 0;
                	$totals_fga = 0;
                	$totals_reb = 0;
                	$totals_ast = 0;
                	$totals_team_reb = 0;
                	
                	$totals_counter_fgm = 0;
                	$totals_counter_ftm = 0;
                	$totals_counter_fta = 0;
                	$totals_counter_pf = 0;
                	$totals_counter_pts = 0;
                	$totals_counter_min = 0;
                	$totals_counter_fga = 0;
                	$totals_counter_reb = 0;
                	$totals_counter_ast = 0;
                	$totals_counter_team_reb = 0;
        
                	$mywins = 0;
                	$mylosses = 0;
                }    			    
		    }				
					    
#			print output_filehandle "Games $current_game_number [Regular=$regular_season_games_this_season]\n";
			
		}	
        elsif ($line =~ /^playoffsstarthere/)
        {
            # regular season is over!
            $next_game_is_playoffs = "true";
            $playoffs_have_started = "true";
        }
	    elsif ($line =~ /^version/)
	    {
	        # ignore
	    }
	    elsif ($line =~ /^info/)
	    {
	        # split the line
	        @this_line_array = parse_csv_line($line);
	        
			if ($this_line_array[1] eq "rteam")
	        {
	            $road_team_name = $this_line_array[2];
	        }
	        elsif ($this_line_array[1] eq "hteam")
	        {
		        $home_team_name = $this_line_array[2];
	        }
	        elsif ($this_line_array[1] eq "neutral")
	        {
    	        $game_neutral_site = "yes";
	        }
	        elsif ($this_line_array[1] eq "date")
	        {
		        $game_date = $this_line_array[2];
		        $game_number = $current_game_number; # This is relative to this particular input file
	    	}
	    	elsif ($this_line_array[1] eq "title")
	    	{
		    	$game_title = $this_line_array[2];
	    	}
	    	elsif ($this_line_array[1] eq "gamenumber")
	    	{
		    	$gamenumber_today = $this_line_array[2];
	    	}
	    }
	    elsif (($line =~ /^coach/) && ($person_is_a eq "coach"))
	    {
	        # split the line and add to hash
	        @this_line_array = parse_csv_line($line);
	        if ($this_line_array[2] eq $personid)
	        {
	        	# if $personid ends in a "c" we need to match against id in THIS ENTRY
	# coach,rteam|hteam,ID,FIRSTNAME,LASTNAME,TECHNICALFOUL
	# 0     1           2  3         4        5
				$person_found = "true";
    		    $found_playoff_game = $playoffs_have_started;
				$person_team = $this_line_array[1];
				$firstname = $this_line_array[3];
				$lastname = $this_line_array[4];
			}
	    }
	    elsif (($line =~ /^stat/) && ($person_is_a eq "player"))
	    {
	        # split the line and add to hash
	        @this_line_array = parse_csv_line($line);
	        
	        if ($this_line_array[3] eq $personid)
	        {
		        # This is the player we care about. Grab the stats.
				# stat,rteam,player,ramsefr01,Frank,Ramsey,,3,,5,6,,,11,,,,5,,,,
	# stat,rteam|hteam,player,ID,FIRSTNAME,LASTNAME,MIN,FGM,FGA,FTM,FTA,3FGM,3FGA,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS,TECHNICALFOUL
	# 0    1           2      3  4         5        6   7   8   9   10  11   12   13  14   15  16  17 18     19        20     21		
	
				$person_found = "true";
    		    $found_playoff_game = $playoffs_have_started;
				$person_team = $this_line_array[1];
				$firstname = $this_line_array[4];
				$lastname = $this_line_array[5];
	
				$min = $this_line_array[6];
				$fgm = $this_line_array[7];
				$fga = $this_line_array[8];
				$ftm = $this_line_array[9];
				$fta = $this_line_array[10];
				$fg3m = $this_line_array[11];
				$fg3a = $this_line_array[12];
				$pts = $this_line_array[13];
				$oreb = $this_line_array[14];
				$reb = $this_line_array[15];
				$ast = $this_line_array[16];
				$pf = $this_line_array[17];
				$blocks = $this_line_array[18];
				$turnovers = $this_line_array[19];
				$steals = $this_line_array[20];
	        }
	    }
	    elsif ($line =~ /^tstat/)
	    {
	        # split the line and add to hash
	        @this_line_array = parse_csv_line($line);
	     
	        if ($this_line_array[1] eq "rteam")
	        {
	# tstat,rteam|hteam,MIN,FGM,FGA,FTM,FTA,FG3M,FG3A,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS,TEAMREBOUNDS,TECHNICALFOUL
	# 0     1           2   3   4   5   6   7    8    9   10   11  12  13 14     15        16     17           18
		        $road_team_points = $this_line_array[9];
	        }
	        elsif ($this_line_array[1] eq "hteam")
	        {
		        $home_team_points = $this_line_array[9];
	    	}
	        
	    }
	    elsif ($line =~ /^linescore/)
	    {
    	    # figure out if this game is an overtime game
	        @this_line_array = parse_csv_line($line);
	        $counter = 0;
	        $found_colon = 0;
	        $game_overtime = "";
	        foreach (@this_line_array)
	        {
    	        if ($_ eq ":")
    	        {
        	        $found_colon = $counter;
    	        }
    	        $counter++;
	        }
	        
	        if ($found_colon == 7)
	        {
    	        $game_overtime = "OT";
	        }
	        elsif ($found_colon > 7)
	        {
            $number_of_ot = $found_colon-6;
	        $game_overtime = $number_of_ot . "OT";
	        }
	    }   
	
	
	} # end of loop for each input file
	
	close(input_filehandle);

	# Need to dump the last game here, if needed
	if ($person_found eq "true")
	{
	    if (($person_team eq "rteam" && $home_team_name=~/$opponent_filter/) ||
	        ($person_team eq "hteam" && $road_team_name=~/$opponent_filter/))
	    {		    
		    increment_totals();

			if ($totals_games_played == 1) # print this header only at start of each season
			{
				$season_string = get_season_string($game_date);
				if ( $found_playoff_game eq "true")
				{
				    print output_filehandle "<h3>$season_string Playoffs</h3>\n";
			    }
			    else
				{
				    print output_filehandle "<h3>$season_string Regular Season</h3>\n";
			    }
			    
			    if ($java_sorting eq "on")
				{
#                            print output_filehandle "<p style = \"font-size:90%\;\">Click on any column header to sort</p>\n";
                    print output_filehandle "<h5><span style=\"color:gray\">Click on any column header to sort</span></h5>\n";
                    print output_filehandle "<table class=\"tablesorter\">\n";
		        }
		        else
		        {
    				print output_filehandle "<table>\n";
		        }
		        
    			if ($person_is_a eq "player")
    		    {
    			    print output_filehandle $table_section_header;
    			}
    			else
    		    {
    			    print output_filehandle $table_coach_section_header;
    			}
    			print output_filehandle "<tbody>\n"
 	        }   		    		    
 	        
            dump_to_file();
		}
	}			
	
	# NO LONGER DOING THIS FOR ABA format - so just close the table.
	
	# Then dump the totals; special case with no date or team info
	# TBD Consider dumping totals BY team (would require storing totals in a hash)
	if ($totals_games_played > 0)
	{
    	print output_filehandle "</tbody>\n";
	    print output_filehandle "</table>\n";

    	if ($found_playoff_game eq "true")
    	{
            dump_splits_to_file($season_string,"Playoffs");	    
#    		dump_totals_to_file($season_string,"Playoffs");
        }
        else
    	{
            dump_splits_to_file($season_string,"Regular Season");	    
#    		dump_totals_to_file($season_string,"Regular Season");
        }
        
        
        # clear splits
        %splits = ();
        
		# reset all totals
       	$totals_games_played = 0;
    	$totals_fgm = 0;
    	$totals_ftm = 0;
    	$totals_fta = 0;
    	$totals_pf = 0;
    	$totals_pts = 0;
    	$totals_min = 0;
    	$totals_fga = 0;
    	$totals_reb = 0;
    	$totals_ast = 0;
    	$totals_team_reb = 0;
    	
    	$totals_counter_fgm = 0;
    	$totals_counter_ftm = 0;
    	$totals_counter_fta = 0;
    	$totals_counter_pf = 0;
    	$totals_counter_pts = 0;
    	$totals_counter_min = 0;
    	$totals_counter_fga = 0;
    	$totals_counter_reb = 0;
    	$totals_counter_ast = 0;
    	$totals_counter_team_reb = 0;

    	$mywins = 0;
    	$mylosses = 0;        

        print output_filehandle "<hr>\n";
        
   	}

	$seasons_read_in++;
    $found_playoff_game = "false";
    
    print "Found ($person_found)\n";
    
} # end of Main loop

# Complete the last table
if ($output_type eq "html")
{
	print output_filehandle "</tbody>\n";
	print output_filehandle "</table>\n";
}

if ($append_mode eq "no")
{
	if ($output_type eq "html")
	{
        print output_filehandle Boxtop_HtmlFooter("abagamelog.pl");
	}
	else
	{
		add_csv_footer();
	}
}

close (output_filenandle);

print "File $output_filename created.\n";
