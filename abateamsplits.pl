# ===============================================================
# 
# abateamsplits.pl
#
# (c) 2010-2016 Michael Hamel
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of this license, visit # http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
#
# Version history
# 11/14/2014  1.0  MH  Initial version, based on abacrosscheck.pl and other scripts
# 11/03/2016  1.1  MH  Add support for printing splits in blue if the statistics are incomplete
#
# ===============================================================

#! usr/bin/perl
use Getopt::Std;
use lib '../tools';
use Boxtop;
use Date::Calc qw(:all);

# Overall count of games, regular season + playoffs
my $game_count = 0;

my $java_sorting = "off";

# Set to "yes" to print games where a stat is missing; especially useful for cases like FGM, 
# FTM, PTS where we should have these stats for EVERY game but can be useful for any stat.
# BE SURE TO TURN ON THE ONES YOU WANT TO USE by searching the code
my $verbose_print = "yes";


# Splits
#
# $the_splits{teamid}{playerid}{statistic} = player total for this statistic, vs teamid
# $the_team_splits{teamid}{statistic} = team total for this statistic, vs teamid
#
# We scan input file for each team, since if player plays for more than one team we need to 
# how they played against each team WHILE PLAYING FOR THIS specific team.
# If folks want to know overall splits for a PLAYER, they can look at the gamelog for that player.
#
# TBD - Therefore, we can cheat and use the teamid slot in the hash for the COMPLETE season stats for this player.
# But for this first pass we're leaving the old hashes alone since that is well-tested code, borrowed
# from abacrosscheck.pl

my %the_splits;
my %the_team_splits;


# Use hashes for players - one entry per player
my %player_games_played;
my %player_fgm;
my %player_ftm;
my %player_fta;
my %player_fgm3;
my %player_fga3;
my %player_pf;
my %player_pts;
my %player_first_names;
my %player_last_names;
my %player_min;
my %player_fga;
my %player_reb;
my %player_ast;
my %player_oreb;
my %player_blocks;
my %player_turnovers;
my %player_steals;

my %current_game_counters = (minutes => 0, fgm => 0, fga => 0, ftm => 0, fta => 0, fgm3 => 0, fga3 => 0, pf => 0, pts => 0, min => 0, reb => 0, ast => 0, team_reb => 0, games => 0, oreb => 0, turnovers => 0, steals => 0, blocks => 0);


my %season_team_games_played;
my %season_team_fgm;
my %season_team_ftm;
my %season_team_fta;
my %season_team_fgm3;
my %season_team_fga3;
my %season_team_pf;
my %season_team_pts;
my %season_team_first_names;
my %season_team_last_names;
my %season_team_min;
my %season_team_fga;
my %season_team_oreb;
my %season_team_reb;
my %season_team_team_reb;
my %season_team_ast;
my %season_team_turnovers;
my %season_team_blocks;
my %season_team_steals;

my %season_stat_counters_games_played;
my %season_stat_counters_fgm;
my %season_stat_counters_ftm;
my %season_stat_counters_fta;
my %season_stat_counters_fgm3;
my %season_stat_counters_fga3;
my %season_stat_counters_pf;
my %season_stat_counters_pts;
my %season_stat_counters_min;
my %season_stat_counters_fga;
my %season_stat_counters_oreb;
my %season_stat_counters_reb;
my %season_stat_counters_team_reb;
my %season_stat_counters_ast;
my %season_stat_counters_turnovers;
my %season_stat_counters_blocks;
my %season_stat_counters_steals;

my %splits_stat_counters_games_played;
my %splits_stat_counters_fgm;
my %splits_stat_counters_ftm;
my %splits_stat_counters_fta;
my %splits_stat_counters_fgm3;
my %splits_stat_counters_fga3;
my %splits_stat_counters_pf;
my %splits_stat_counters_pts;
my %splits_stat_counters_min;
my %splits_stat_counters_fga;
my %splits_stat_counters_oreb;
my %splits_stat_counters_reb;
my %splits_stat_counters_team_reb;
my %splits_stat_counters_ast;
my %splits_stat_counters_turnovers;
my %splits_stat_counters_blocks;
my %splits_stat_counters_steals;

# added for crosscheck version
my %team_full_names;
my %cc_BR_regular_season_teams;
my %cc_BR_playoff_teams;
my %cc_BR_regular_season_players;
my %cc_BR_playoff_players;

my %found_playoffs = ();

my $regular_season_issue = "";
my $playoff_issue = "";

my $page_title_preamble;

my $season_stats_filename;

my $number_of_regular_season_games = 0;
my $team_full_name = "";
my $date_of_first_game = "NONE";

# init to defaults
my %config_options = (
	seasonstats => off,
	threeptfg => off,
	check_through_date => "all",
);

my $check_through_mon;
my $check_through_day;
my $check_through_year;

my $next_game_would_be_playoffs = "no";

# ===============================================================


sub usage
{
    print "Create team statistics report based on a boxtop file.\n";
    print "1. Tabulates season totals for each player\n";
    print "2. Calculates splits against each oppponent\n";
    print "\n";
    print "Output is written in .htm format\n";
   
    print "\n";
    print "\nUSAGE:\n";
    print "abateamsplits.pl [-i inputfilename] [-o outputfilename preamble] [-t page title preamble]\n";
    print "               -s season stats file [-j on|off java sorting ]\n";
    print "               [-g on|off check 3 point FG]\n";
    print "               [-d yes|no display BR stats for debug]\n";
    print "               [-p mm/dd/yyyy check stats up through this date\n";
    print "\n";
    print " Defaults:\n";
    print "  Input file: input.csv   Output file: seasonsplits.htm\n";
    print "  Team name is appended to outputfilename _team.htm\n";
    print "  Page title: 'inputfilename', 3PT FG OFF, Java sorting OFF\n";
    print "\n";
   
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


# =====================================================================

sub clear_team_stats(\%)
{
    my %stats = ${shift()};

	print "Here @{[%stats]}\n";
    
	foreach (keys %stats)
 	{
	 	$aa{$_} = 0;
	}

	print "Here2 @{[%stats]}\n";
	
}
# end of sub clear_team_stats()

# =====================================================================

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


# =====================================================================

# helper function for dump_stats_summary_to_file()
sub check_and_print_stat_summary($$$$)
{
	$our_stat = $_[0];
	$official_stat = $_[1]; # or "splits" in the splits case
	$number_of_games = $_[2];
	$number_of_games_where_this_stat_is_available = $_[3];
	
	if ($our_stat eq $official_stat)
	{
		print output_filehandle "<td style=\"text-align:right\">$our_stat<\/td>";
	}
	elsif ($official_stat eq "splits")
	{
    	if ($our_stat eq "")
    	{
            $our_stat = 0; # make ouput prettier
        }
        
    	if ($number_of_games eq $number_of_games_where_this_stat_is_available)
    	{
    		print output_filehandle "<td style=\"text-align:right\">$our_stat<\/td>";
        }
        else
    	{
    		# Just print the data in blue because we have incomplete data
    		print output_filehandle "<td style=\"text-align:right\" ><font color=blue>$our_stat<\/font><\/td>";
    	}        
    }
	elsif ($number_of_games eq $number_of_games_where_this_stat_is_available)
	{
		# This statistic SHOULD be correct since we have full season data for this statistic.
		# Highlight the error in red and print the good data.
		if ($print_debug_info eq "yes")
		{
    		print output_filehandle "<td style=\"text-align:right\" ><font color=red>$our_stat<\/font> ($official_stat)<\/td>";
        }
        else
        {
    		print output_filehandle "<td style=\"text-align:right\" ><font color=red>$our_stat<\/font><\/td>";
        }
	}
	else
	{
		# Just print the data in blue because we have incomplete data
		if ($our_stat eq "")
		{
            $our_stat = 0; # make ouput prettier
        }
		print output_filehandle "<td style=\"text-align:right\" ><font color=blue>$our_stat<\/font><\/td>";
	}
}	

# =====================================================================

# Current assumption is that this only gets called for playoffs if a team played in the playoffs
sub dump_stats_to_file($$)
{
    $preamble = $_[0];
    $teamid = $_[1]; # abbreviation
    
	# get data from appropriate BR hash - we do this first so we can grab the team's full name
    # 0      1    2 3  4  5   6   7  8   9   10 11  12  13 14  15  16  17  18  19  20  21  22  23 24  25
	# ignore,Team,G,MP,FG,FGA,FG%,3P,3PA,3P%,2P,2PA,2P%,FT,FTA,FT%,ORB,DRB,TRB,AST,STL,BLK,TOV,PF,PTS,PTS/G,,,,
    if ($preamble eq "Regular Season")
    {
        $BR_stats = $cc_BR_regular_season_teams{$teamid};
    }
    else
    {
        $BR_stats = $cc_BR_playoff_teams{$teamid};
    }
   
    @this_line_array = parse_csv_line($BR_stats);    
    
    $team_full_name = $this_line_array[1];
	$tm_fgm = $this_line_array[4];
	$tm_fga = $this_line_array[5];
	$tm_ftm = $this_line_array[13];
	$tm_fta = $this_line_array[14];
	$tm_fgm3 = $this_line_array[7];
	$tm_fga3 = $this_line_array[8];
	$tm_pf = $this_line_array[23];
	$tm_pts = $this_line_array[24];
	$tm_min = $this_line_array[3];
	$tm_oreb = $this_line_array[16];
	$tm_reb = $this_line_array[18];
	$tm_ast = $this_line_array[19];
	$tm_steals = $this_line_array[20];
	$tm_blocks = $this_line_array[21];
	$tm_turnovers = $this_line_array[22];
    
    if ($preamble eq "Regular Season")	
    {
        # We only want to print the team name and the link once for regular season, not again for playoffs
        $team_link = Boxtop_GetBRTeamPageLink($team_full_name,$date_of_first_game);
		print output_filehandle "<p><h3>" . $team_link . "$team_full_name</a><\/h3>\n";
    }
    else
    {
        print output_filehandle "<hr>\n";
    }
	print output_filehandle "<h4>$preamble statistics<\/h4>\n";
	
    $backlink = $output_filename_preamble . ".htm";
        
    if ($java_sorting eq "on")
    {
        print output_filehandle "<h5><span style=\"color:gray\">Click on any column header to sort \| <a href=#Glossary>Glossary</a> \| <a href=\"$backlink\">League statistics</a></span></h5>\n";
        print output_filehandle "<table class=\"tablesorter\">\n";
    }
    else
    {
        print output_filehandle "<h5><span style=\"color:gray\"><a href=#Glossary>Glossary</a> \| <a href=\"$backlink\">League statistics</a></span></h5>\n";
	    print output_filehandle "<table>\n";
    }
	
    $counter = 1;
    
	print output_filehandle "<thead><tr>";
	print output_filehandle "<th style=\"text-align:right\">#<\/th>"; # dummy column simply for sorting purposes
	print output_filehandle "<th>Name<\/th>";
#	print output_filehandle "<th align = \"left\">PlayerId<\/th>";
	print output_filehandle "<th style=\"text-align:center\">G<\/th>";
	print output_filehandle "<th style=\"text-align:center\">MIN<\/th>";
	print output_filehandle "<th style=\"text-align:center\">FGM<\/th>";
	print output_filehandle "<th style=\"text-align:center\">FGA<\/th>";
	print output_filehandle "<th style=\"text-align:center\">FTM<\/th>";
	print output_filehandle "<th style=\"text-align:center\">FTA<\/th>";
	if ($config_options{threeptfg} eq "on")
	{
		print output_filehandle "<th style=\"text-align:center\">3FG<\/th>";
		print output_filehandle "<th style=\"text-align:center\">3FA<\/th>";
	}
	print output_filehandle "<th style=\"text-align:center\">PTS<\/th>"; # TBD - I moved this for cross-check
	print output_filehandle "<th style=\"text-align:center\">ORB<\/th>";
	print output_filehandle "<th style=\"text-align:center\">REB<\/th>";
	print output_filehandle "<th style=\"text-align:center\">AST<\/th>";
	print output_filehandle "<th style=\"text-align:center\">PF<\/th>";
	print output_filehandle "<th style=\"text-align:center\">TO<\/th>";
	print output_filehandle "<th style=\"text-align:center\">BL<\/th>";
	print output_filehandle "<th style=\"text-align:center\">ST<\/th>";
	print output_filehandle "</tr></thead><tbody>\n";	
	
	foreach $value (sort keys %player_fgm)
	{
		@id_info = split(/-/,$value);
		$my_id = $id_info[0];
		$my_team_id = $id_info[1];
		
		$BR_player_link = Boxtop_GetBRPlayerPageLink($my_id);
		
		# get data from appropriate BR hash
        # 0     1 2      3   4   5  6 7  8  9  10  11  12 13  14  15 16  17  18 19  20  21  22  23  24  25  26  27  28 29
        # ignore,,Player,Pos,Age,Tm,G,GS,MP,FG,FGA,FG%,3P,3PA,3P%,2P,2PA,2P%,FT,FTA,FT%,ORB,DRB,TRB,AST,STL,BLK,TOV,PF,PTS
    	if ($preamble eq "Regular Season")
        {
            $BR_stats = $cc_BR_regular_season_players{$my_id};
        }
        else
        {
            $BR_stats = $cc_BR_playoff_players{$my_id};
        }

        @this_line_array = parse_csv_line($BR_stats);
        $BR_games = $this_line_array[6];
        $BR_min = $this_line_array[8];
        $BR_fgm = $this_line_array[9];
        $BR_fga = $this_line_array[10];
        $BR_3fgm = $this_line_array[12];
        $BR_3fga = $this_line_array[13];
        $BR_ftm = $this_line_array[18];
        $BR_fta = $this_line_array[19];
        $BR_oreb = $this_line_array[21];
        $BR_reb = $this_line_array[23];
        $BR_ast = $this_line_array[24];
        $BR_steals = $this_line_array[25];
        $BR_blocks = $this_line_array[26];
        $BR_turnovers = $this_line_array[27];
        $BR_pf = $this_line_array[28];
        $BR_pts = $this_line_array[29];
		
		print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
		print output_filehandle "<td style=\"text-align:right\">$counter<\/td>";
		$counter++;
		print output_filehandle "<td>$BR_player_link$player_first_names{$value} $player_last_names{$value}</a><\/td>";
#			print output_filehandle "<td align = \"left\">$my_id<\/td>"; # DEBUG: can print $value here to see team name too
		
		check_and_print_stat_summary($player_games_played{$value},$BR_games,0,0); # we always have the right number of games
		check_and_print_stat_summary($player_min{$value},$BR_min,$season_team_games_played{$teamid},$season_stat_counters_min{$teamid});
		check_and_print_stat_summary($player_fgm{$value},$BR_fgm,$season_team_games_played{$teamid},$season_stat_counters_fgm{$teamid});
		check_and_print_stat_summary($player_fga{$value},$BR_fga,$season_team_games_played{$teamid},$season_stat_counters_fga{$teamid});
		check_and_print_stat_summary($player_ftm{$value},$BR_ftm,$season_team_games_played{$teamid},$season_stat_counters_ftm{$teamid});
		check_and_print_stat_summary($player_fta{$value},$BR_fta,$season_team_games_played{$teamid},$season_stat_counters_fta{$teamid});
		if ($config_options{threeptfg} eq "on")
		{	
			check_and_print_stat_summary($player_fgm3{$value},$BR_3fgm,$season_team_games_played{$teamid},$season_stat_counters_fgm3{$teamid});
			check_and_print_stat_summary($player_fga3{$value},$BR_3fga,$season_team_games_played{$teamid},$season_stat_counters_fga3{$teamid});
		}
		check_and_print_stat_summary($player_pts{$value},$BR_pts,$season_team_games_played{$teamid},$season_stat_counters_pts{$teamid});
		check_and_print_stat_summary($player_oreb{$value},$BR_oreb,$season_team_games_played{$teamid},$season_stat_counters_oreb{$teamid});
		check_and_print_stat_summary($player_reb{$value},$BR_reb,$season_team_games_played{$teamid},$season_stat_counters_reb{$teamid});
		check_and_print_stat_summary($player_ast{$value},$BR_ast,$season_team_games_played{$teamid},$season_stat_counters_ast{$teamid});
		check_and_print_stat_summary($player_pf{$value},$BR_pf,$season_team_games_played{$teamid},$season_stat_counters_pf{$teamid});
		check_and_print_stat_summary($player_turnovers{$value},$BR_turnovers,$season_team_games_played{$teamid},$season_stat_counters_turnovers{$teamid});
		check_and_print_stat_summary($player_steals{$value},$BR_steals,$season_team_games_played{$teamid},$season_stat_counters_steals{$teamid});
		check_and_print_stat_summary($player_blocks{$value},$BR_blocks,$season_team_games_played{$teamid},$season_stat_counters_blocks{$teamid});
		
		print output_filehandle "</tr>\n";
	
	}

	# Placing this tag BEFORE the team totals causes Table Sorter to exclude the totals from sorting, which is a cleaner experience
	print output_filehandle "</tbody>\n";	
	
# my %season_stat_counters = (minutes => 0, fgm => 0, fga => 0, ftm => 0, fta => 0, pf => 0, pts => 0, min => 0, reb => 0, ast => 0, team_reb => 0, games => 0);
# my %season_team_stats = (minutes => 0, fgm => 0, fga => 0, ftm => 0, fta => 0, pf => 0, pts => 0, min => 0, reb => 0, ast => 0, team_reb => 0, games => 0);

	print output_filehandle "<tr>";
	print output_filehandle "<td><\/td>";
	print output_filehandle "<td><strong>TEAM</strong><\/td>";
	check_and_print_stat_summary($season_team_games_played{$teamid},$season_team_games_played{$teamid},0,0); # we always have the right number of games
	check_and_print_stat_summary($season_team_min{$teamid},$tm_min,$season_team_games_played{$teamid},$season_stat_counters_min{$teamid});
	check_and_print_stat_summary($season_team_fgm{$teamid},$tm_fgm,$season_team_games_played{$teamid},$season_stat_counters_fgm{$teamid});
	check_and_print_stat_summary($season_team_fga{$teamid},$tm_fga,$season_team_games_played{$teamid},$season_stat_counters_fga{$teamid});
	check_and_print_stat_summary($season_team_ftm{$teamid},$tm_ftm,$season_team_games_played{$teamid},$season_stat_counters_ftm{$teamid});
	check_and_print_stat_summary($season_team_fta{$teamid},$tm_fta,$season_team_games_played{$teamid},$season_stat_counters_fta{$teamid});
	if ($config_options{threeptfg} eq "on")	
	{
		check_and_print_stat_summary($season_team_fgm3{$teamid},$tm_fgm3,$season_team_games_played{$teamid},$season_stat_counters_fgm3{$teamid});
		check_and_print_stat_summary($season_team_fga3{$teamid},$tm_fga3,$season_team_games_played{$teamid},$season_stat_counters_fga3{$teamid});
	}
	check_and_print_stat_summary($season_team_pts{$teamid},$tm_pts,$season_team_games_played{$teamid},$season_stat_counters_pts{$teamid});
	check_and_print_stat_summary($season_team_oreb{$teamid},$tm_oreb,$season_team_games_played{$teamid},$season_stat_counters_oreb{$teamid});
	check_and_print_stat_summary($season_team_reb{$teamid},$tm_reb,$season_team_games_played{$teamid},$season_stat_counters_reb{$teamid});
	check_and_print_stat_summary($season_team_ast{$teamid},$tm_ast,$season_team_games_played{$teamid},$season_stat_counters_ast{$teamid});
	check_and_print_stat_summary($season_team_pf{$teamid},$tm_pf,$season_team_games_played{$teamid},$season_stat_counters_pf{$teamid});
	check_and_print_stat_summary($season_team_turnovers{$teamid},$tm_turnovers,$season_team_games_played{$teamid},$season_stat_counters_turnovers{$teamid});
	check_and_print_stat_summary($season_team_steals{$teamid},$tm_steals,$season_team_games_played{$teamid},$season_stat_counters_steals{$teamid});
	check_and_print_stat_summary($season_team_blocks{$teamid},$tm_blocks,$season_team_games_played{$teamid},$season_stat_counters_blocks{$teamid});
#	print output_filehandle "<td align = \"right\">$season_team_team_reb{$teamid}<\/td>"; # exception case for now
	print output_filehandle "</tr>\n";

    # I'm pretty sure I want to skip this row in the production version.	
    
    if ($print_debug_info eq "yes")
    {
    	print output_filehandle "<tr>";
    	print output_filehandle "<td><\/td>";
    	print output_filehandle "<td style = \"font-size:70%\;\"><strong>Games Available</strong><\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_team_games_played{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_min{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_fgm{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_fga{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_ftm{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_fta{$teamid}<\/td>";
    	if ($config_options{threeptfg} eq "on")
    	{
    		print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_fgm3{$teamid}<\/td>";
    		print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_fga3{$teamid}<\/td>";
    	}
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_pts{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_oreb{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_reb{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_ast{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_pf{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_turnovers{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_steals{$teamid}<\/td>";
    	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_blocks{$teamid}<\/td>";
    #	print output_filehandle "<td style=\"text-align:right\">$season_stat_counters_team_reb{$teamid}<\/td>";
    	print output_filehandle "</tr>\n";
    }

#    print output_filehandle "<\/table>\n";

    if ($preamble eq "Regular Season")
    {
        if (length($regular_season_issue) > 0)
        {
            print output_filehandle "<p>Note: $regular_season_issue\n";
        }
    }
    else
    {
        if (length($playoff_issue) > 0)
        {
            print output_filehandle "<p>Note: $playoff_issue\n";
        }
    }
        
#	print output_filehandle "</tbody>\n";	
    print output_filehandle "</table>\n";


    # Now we dump the per opponent hashes
    foreach $opp (sort keys %the_splits)
    {
        if ($preamble eq "Regular Season")
        {
            print output_filehandle "<h4><i>vs. $opp</i><\/h4>\n";        
        }
        else
        {
            print output_filehandle "<h4><i>Playoffs vs. $opp</i><\/h4>\n";        
        }
        
        $backlink = $output_filename_preamble . ".htm";
        
        if ($java_sorting eq "on")
        {
            print output_filehandle "<h5><span style=\"color:gray\">Click on any column header to sort \| <a href=#Glossary>Glossary</a> \| <a href=\"$backlink\">League statistics</a><span></h5>\n";
            print output_filehandle "<table class=\"tablesorter\">\n";
        }
        else
        {
            print output_filehandle "<h5><span style=\"color:gray\"><a href=#Glossary>Glossary</a> \| <a href=\"$backlink\">League statistics</a></span></h5>\n";
    	    print output_filehandle "<table>\n";
        }
    	
        $counter = 1;
        
    	print output_filehandle "<thead><tr>";
    	print output_filehandle "<th style=\"text-align:right\">#<\/th>"; # dummy column simply for sorting purposes
    	print output_filehandle "<th>Name<\/th>";
    #	print output_filehandle "<th align = \"left\">PlayerId<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">G<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">MIN<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">FGM<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">FGA<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">FTM<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">FTA<\/th>";
    	if ($config_options{threeptfg} eq "on")
    	{
    		print output_filehandle "<th style=\"text-align:center\">3FG<\/th>";
    		print output_filehandle "<th style=\"text-align:center\">3FA<\/th>";
    	}
    	print output_filehandle "<th style=\"text-align:center\">PTS<\/th>"; # TBD - I moved this for cross-check
    	print output_filehandle "<th style=\"text-align:center\">ORB<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">REB<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">AST<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">PF<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">TO<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">BL<\/th>";
    	print output_filehandle "<th style=\"text-align:center\">ST<\/th>";
    	print output_filehandle "</tr></thead><tbody>\n";	
    	
    	# actually add the stats, do not check against season totals since we're only printing against one opponent

    	foreach $value (sort keys %{$the_splits{$opp}})
    	{
    		@id_info = split(/-/,$value);
    		$my_id = $id_info[0];
    		$my_team_id = $id_info[1];
    		
    		$BR_player_link = Boxtop_GetBRPlayerPageLink($my_id);
    		
    		print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">";
    		print output_filehandle "<td style=\"text-align:right\">$counter<\/td>";
    		$counter++;
    		print output_filehandle "<td>$BR_player_link$player_first_names{$value} $player_last_names{$value}</a><\/td>";
    #			print output_filehandle "<td align = \"left\">$my_id<\/td>"; # DEBUG: can print $value here to see team name too
    		
    		check_and_print_stat_summary($the_splits{$opp}{$value}{games_played},$the_splits{$opp}{$value}{games_played},0,0); # we always have the right number of games
    		$games_to_compare = $the_team_splits{$opp}{games_played};
#    		print "$teamid : $opp : $games_to_compare (FGM count = $splits_stat_counters_fgm{$teamid}{$opp}) (FGA count = $splits_stat_counters_fga{$teamid}{$opp})\n";
    		
    		# The key here is to remember that the second arg is supposed to be the official total from BR.com, 
    		# but for splits there are no official totals. So fake it out with "splits" so the function will 
    		# just check games played and print in blue if incomplete.
    		
    		check_and_print_stat_summary($the_splits{$opp}{$value}{min},"splits",$games_to_compare,$splits_stat_counters_min{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{fgm},"splits",$games_to_compare,$splits_stat_counters_fgm{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{fga},"splits",$games_to_compare,$splits_stat_counters_fga{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{ftm},"splits",$games_to_compare,$splits_stat_counters_ftm{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{fta},"splits",$games_to_compare,$splits_stat_counters_fta{$teamid}{$opp});
    		if ($config_options{threeptfg} eq "on")
    		{	
    			check_and_print_stat_summary($the_splits{$opp}{$value}{fgm3},"splits",$games_to_compare,$splits_stat_counters_fgm3{$teamid}{$opp});
    			check_and_print_stat_summary($the_splits{$opp}{$value}{fga3},"splits",$games_to_compare,$splits_stat_counters_fga3{$teamid}{$opp});
    		}
    		check_and_print_stat_summary($the_splits{$opp}{$value}{pts},"splits",$games_to_compare,$splits_stat_counters_pts{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{oreb},"splits",$games_to_compare,$splits_stat_counters_oreb{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{reb},"splits",$games_to_compare,$splits_stat_counters_reb{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{ast},"splits",$games_to_compare,$splits_stat_counters_ast{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{pf},"splits",$games_to_compare,$splits_stat_counters_pf{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{turnovers},"splits",$games_to_compare,$splits_stat_counters_turnovers{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{steals},"splits",$games_to_compare,$splits_stat_counters_steals{$teamid}{$opp});
    		check_and_print_stat_summary($the_splits{$opp}{$value}{blocks},"splits",$games_to_compare,$splits_stat_counters_blocks{$teamid}{$opp});
    		
    		print output_filehandle "</tr>\n";
    	
    	}
    
    	# Placing this tag BEFORE the team totals causes Table Sorter to exclude the totals from sorting, which is a cleaner experience
    	print output_filehandle "</tbody>\n";	
    	
    	# TBD - add the team totals
    	print output_filehandle "<tr>";
    	print output_filehandle "<td><\/td>";
    	print output_filehandle "<td><strong>TEAM</strong><\/td>";

		check_and_print_stat_summary($the_team_splits{$opp}{games_played},$the_team_splits{$opp}{games_played},0,0); # we always have the right number of games
   		$games_to_compare = $the_team_splits{$opp}{games_played};

		check_and_print_stat_summary($the_team_splits{$opp}{min},"splits",$games_to_compare,$splits_stat_counters_min{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{fgm},"splits",$games_to_compare,$splits_stat_counters_fgm{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{fga},"splits",$games_to_compare,$splits_stat_counters_fga{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{ftm},"splits",$games_to_compare,$splits_stat_counters_ftm{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{fta},"splits",$games_to_compare,$splits_stat_counters_fta{$teamid}{$opp});
		if ($config_options{threeptfg} eq "on")
		{	
			check_and_print_stat_summary($the_team_splits{$opp}{fgm3},"splits",$games_to_compare,$splits_stat_counters_fgm3{$teamid}{$opp});
			check_and_print_stat_summary($the_team_splits{$opp}{fga3},"splits",$games_to_compare,$splits_stat_counters_fga3{$teamid}{$opp});
		}
		check_and_print_stat_summary($the_team_splits{$opp}{pts},"splits",$games_to_compare,$splits_stat_counters_pts{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{oreb},"splits",$games_to_compare,$splits_stat_counters_oreb{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{reb},"splits",$games_to_compare,$splits_stat_counters_reb{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{ast},"splits",$games_to_compare,$splits_stat_counters_ast{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{pf},"splits",$games_to_compare,$splits_stat_counters_pf{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{turnovers},"splits",$games_to_compare,$splits_stat_counters_turnovers{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{steals},"splits",$games_to_compare,$splits_stat_counters_steals{$teamid}{$opp});
		check_and_print_stat_summary($the_team_splits{$opp}{blocks},"splits",$games_to_compare,$splits_stat_counters_blocks{$teamid}{$opp});
    	
    	print output_filehandle "</tr>\n";    	
    	
    	print output_filehandle "</table>\n";
    }
    
} # end of dump_stats_to_file()

# ===============================================================

# This used to be gamelog_to_file(), which created game inventory AND incremented stat counters.
# Now it just does the counters.
#
# TBD - For now, the current_game_counters are for both teams in a given game, so we either declare
#       a stat complete for both teams or neither. It would be better to do the home and road teams
#       separately, so we can declare one team complete and the other not complete, as required.
sub update_stat_counters($$)
{
    $the_team = $_[0]; # abbreviation, not full name
    $the_opponent = $_[1]; # full name
    
#    print "Stats: $the_team vs. $the_opponent\n";
    
    # If the counters are all at zero, this game probably does not have any stats at all, so skip the analysis
    
    if (($current_game_counters{minutes} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_min{$the_team}++;
	    $splits_stat_counters_min{$the_team}{$the_opponent}++;
	}

	if (($current_game_counters{fgm} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_fgm{$the_team}++;
	    $splits_stat_counters_fgm{$the_team}{$the_opponent}++;
#	    print "Got here ($current_game_counters{fgm} : $current_game_counters{games})\n";
	}
	else
	{
		if ($verbose_print eq "yes")
		{
    		print "FGM missing from $the_team game on $game_date\n";
		}
	}
	
    if (($current_game_counters{fga} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_fga{$the_team}++;
	    $splits_stat_counters_fga{$the_team}{$the_opponent}++;
	}
	
    if (($current_game_counters{ftm} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_ftm{$the_team}++;
	    $splits_stat_counters_ftm{$the_team}{$the_opponent}++;
	}
	else
	{
	    if ($verbose_print eq "yes")
    	{
	    	print "FTM missing from $the_team game on $game_date\n";
    	}
	}
    	
    if (($current_game_counters{fta} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_fta{$the_team}++;
	    $splits_stat_counters_fta{$the_team}{$the_opponent}++;
	}
	else
	{
	    if ($verbose_print eq "yes")
    	{
	    	print "FTA missing from $the_team game on $game_date\n";
    	}
	}

	if ($config_options{threeptfg} eq "on")	
    {
	    if (($current_game_counters{fgm3} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
	    {
		    $season_stat_counters_fgm3{$the_team}++;
    	    $splits_stat_counters_fgm3{$the_team}{$the_opponent}++;
		}
		else
		{
		    if ($verbose_print eq "yes")
	    	{
		    	print "3FGM missing from $the_team game on $game_date\n";
	    	}
		}
	    	
	    if (($current_game_counters{fga3} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
	    {
		    $season_stat_counters_fga3{$the_team}++;
    	    $splits_stat_counters_fga3{$the_team}{$the_opponent}++;
		}
	}
		
    if (($current_game_counters{pf} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_pf{$the_team}++;
	    $splits_stat_counters_pf{$the_team}{$the_opponent}++;
	}

	if (($current_game_counters{pts} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_pts{$the_team}++;
	    $splits_stat_counters_pts{$the_team}{$the_opponent}++;
	}
	else
	{
		if ($verbose_print eq "yes")
		{
	    	print "PTS missing from $the_team game on $game_date\n";
		}
	}
	
    if (($current_game_counters{oreb} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_oreb{$the_team}++;
	    $splits_stat_counters_oreb{$the_team}{$the_opponent}++;
	}
	
    if (($current_game_counters{reb} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_reb{$the_team}++;
	    $splits_stat_counters_reb{$the_team}{$the_opponent}++;
	}

	if (($current_game_counters{ast} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_ast{$the_team}++;
	    $splits_stat_counters_ast{$the_team}{$the_opponent}++;
	}

    if (($current_game_counters{turnovers} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_turnovers{$the_team}++;
	    $splits_stat_counters_turnovers{$the_team}{$the_opponent}++;
	}
	
    if (($current_game_counters{blocks} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_blocks{$the_team}++;
	    $splits_stat_counters_blocks{$the_team}{$the_opponent}++;
	}
	
    if (($current_game_counters{steals} == $current_game_counters{games}) && ($current_game_counters{games} > 0))
    {
	    $season_stat_counters_steals{$the_team}++;
	    $splits_stat_counters_steals{$the_team}{$the_opponent}++;
	}
	
}

# end of sub update_stat_counters()

# ===========================================================

sub clear_player_hashes()
{
    %player_fgm = ();
    %player_ftm = ();
    %player_fta = ();
    %player_fgm3 = ();
    %player_fga3 = ();
    %player_pf = ();
    %player_pts = ();
    %player_games_played = ();
    %player_first_names = ();
    %player_last_names = ();
    %player_min = ();
    %player_fga = ();
    %player_oreb = ();
    %player_reb = ();
    %player_ast = ();
    %player_blocks = ();
    %player_turnovers = ();
    %player_steals = ();
}

sub clear_season_team_hashes() 
{       			        						
	%season_team_fgm = ();
	%season_team_ftm = ();
	%season_team_fta = ();
	%season_team_fgm3 = ();
	%season_team_fga3 = ();
	%season_team_pf = ();
	%season_team_pts = ();
	%season_team_games_played = ();
	%season_team_min = ();
	%season_team_fga = ();
	%season_team_oreb = ();
	%season_team_reb = ();
	%season_team_team_reb = ();
	%season_team_ast = ();
	%season_team_blocks = ();
	%season_team_turnovers = ();
	%season_team_steals = ();
}	

sub clear_season_stat_counters_hashes()
{
	%season_stat_counters_fgm = ();
	%season_stat_counters_ftm = ();
	%season_stat_counters_fta = ();
	%season_stat_counters_fgm3 = ();
	%season_stat_counters_fga3 = ();
	%season_stat_counters_pf = ();
	%season_stat_counters_pts = ();
	%season_stat_counters_games_played = ();
	%season_stat_counters_min = ();
	%season_stat_counters_fga = ();
	%season_stat_counters_oreb = ();
	%season_stat_counters_reb = ();
	%season_stat_counters_team_reb = ();
	%season_stat_counters_ast = ();
	%season_stat_counters_blocks = ();
	%season_stat_counters_turnovers = ();
	%season_stat_counters_steals = ();
	
	
	%splits_stat_counters_fgm = ();
	%splits_stat_counters_ftm = ();
	%splits_stat_counters_fta = ();
	%splits_stat_counters_fgm3 = ();
	%splits_stat_counters_fga3 = ();
	%splits_stat_counters_pf = ();
	%splits_stat_counters_pts = ();
	%splits_stat_counters_games_played = ();
	%splits_stat_counters_min = ();
	%splits_stat_counters_fga = ();
	%splits_stat_counters_oreb = ();
	%splits_stat_counters_reb = ();
	%splits_stat_counters_team_reb = ();
	%splits_stat_counters_ast = ();
	%splits_stat_counters_blocks = ();
	%splits_stat_counters_turnovers = ();
	%splits_stat_counters_steals = ();	
}

# ===========================================================

$start_of_boxscore = "gamebxt";

# default filenames
$input_filename = "input.csv";
$output_filename = "seasonsplits.htm";
$skip_season_checks = "no";

getopts('i:o:h:t:s:g:j:d:p:',\%cli_opt);


if (exists ($cli_opt{"i"}))
{
    $input_filename = $cli_opt{"i"};
}

if (exists ($cli_opt{"o"}))
{
    $output_filename_preamble = $cli_opt{"o"};
}

if (exists ($cli_opt{"t"}))
{
	$page_title_preamble = $cli_opt{"t"};
}
else
{
	$page_title_preamble = "empty"; # will default to input filename
}

if (exists ($cli_opt{"s"}))
{
	$config_options{seasonstats} = "yes";
	$season_stats_filename = $cli_opt{"s"};
}

if (exists ($cli_opt{"g"}))
{
	$config_options{threeptfg} = lc($cli_opt{"g"});
}

if (exists ($cli_opt{"p"}))
{
	$config_options{check_through_date} = $cli_opt{"p"};
	($check_through_mon, $check_through_day, $check_through_year) = split("\/",$config_options{check_through_date});
}

if (exists ($cli_opt{"j"}))
{
	$java_sorting = lc($cli_opt{"j"});
}

$print_debug_info = "no";
if (exists ($cli_opt{"d"}))
{
	$print_debug_info = lc($cli_opt{"d"});
}

if (exists ($cli_opt{"h"}))
{
	usage();
	exit;
}


print "Checking $input_filename...\n\n";


if ($config_options{seasonstats} eq "yes")
{
    #
    # 1. Create hash of all teams who played in regular season or playoffs, and their statistics
    #
	if (!open(season_input_filehandle, "$season_stats_filename"))
	{
		print "Unable to open $season_stats_filename\n";
		exit;
	}

    %cc_BR_regular_season_teams = ();
    %cc_BR_playoff_teams = ();
    while ($line = <season_input_filehandle>)
    {
        if ($line =~ /^teamtotal/)
        {
            $stats = $line;
                
            @this_line_array = parse_csv_line($line);
            $tm_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($this_line_array[1]);
            
            $cc_BR_regular_season_teams{$tm_abbrev} = $stats;
            $team_full_names{$tm_abbrev} = $this_line_array[1]; # assume no team plays ONLY in playoffs
        }
        elsif ($line =~ /^teamplayofftotal/)
        {
            $stats = $line;
                
            @this_line_array = parse_csv_line($line);
            $tm_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($this_line_array[1]);
            
            $cc_BR_playoff_teams{$tm_abbrev} = $stats;
        }
    }
 
    close(season_input_filehandle);
 
    # 
    # 2. Now loop through each regular season team and grab regular season and playoff stats
    #    Assumption is that a playoff team must have played in regular season
    #
    foreach $team (sort keys %cc_BR_regular_season_teams)
    {
	    if (!open(season_input_filehandle, "$season_stats_filename"))
	    {
		    print "Unable to open $season_stats_filename while processing $team\n";
		    exit;
	    }

	    # clear hashes	    
	    %cc_BR_regular_season_players = ();
        %cc_BR_playoff_players = ();
        %the_splits = ();
        %the_team_splits = ();

        # open output file for writing, creating if needed
        $teamwithoutspaces = $team_full_names{$team};
        $teamwithoutspaces =~ s/ //g;
        $output_filename = $output_filename_preamble . "_" . $teamwithoutspaces . ".htm";
        if (!open(output_filehandle, ">$output_filename")) 
        {
                close(input_filehandle);
                die "Can't open output file $output_filename\n";
        }
        
        if ($page_title_preamble eq "empty")
        {
        	$page_title = $team_full_names{$team};
        }
        else
        {
            $page_title = $page_title_preamble . " " . $team_full_names{$team};
        }
        
        print output_filehandle Boxtop_HtmlHeader("$page_title Statistics",$java_sorting); # page-title must be set before making this call

        
        while ($line = <season_input_filehandle>)
        {
            if ($line =~ /^playertotal/)
            {
                $stats = $line;
                    
                @this_line_array = parse_csv_line($line);
                if ($this_line_array[5] eq $team)
                {
                    # found a player on this team
                    
                    # column 1 contains an override BR.com id or just a number 
                    #          (this can include an id ending in 01 if we have both an 01 and an 02 or 03 in the same season - see Roger Brown, 1973-74)
                    # column 2 contains full player name
                    # column 5 contains team name - drop TOT on the floor
                    
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
                                    
                    $cc_BR_regular_season_players{$his_id} = $stats;
                }
            }
            elsif ($line =~ /^playerplayofftotal/)
            {
                $stats = $line;
                    
                @this_line_array = parse_csv_line($line);
                if ($this_line_array[5] eq $team)
                {
                    # found a player on this team
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
                                    
                    $cc_BR_playoff_players{$his_id} = $stats;
                }
            }
        }
        
        close(season_input_filehandle);
    
        
        # 
        # 3. Now loop through all games played by this team, and grab all stats from BOXTOP's perspective
        #
        
        # open for reading
        if (!open(input_filehandle, "$input_filename")) 
        {
                die "Can't open input file $input_filename\n";
        }
      
        my $lines_read_from_input_file = 0;
        my $first_gamebxt_read = "no";

        $found_playoffs{$team} = "no";
        $next_game_would_be_playoffs = "no";
        
        # clear all hashes
        %the_splits = ();
        %the_team_splits = ();
        clear_player_hashes();
        clear_season_team_hashes();
        clear_season_stat_counters_hashes();

	    foreach (keys %current_game_counters)
	 	{
		 	$current_game_counters{$_} = 0;
		}
        	
		$stop_checking = "no";		
        while (($line = <input_filehandle>) && ($stop_checking eq "no"))
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
        		    $game_count++;
        		}
        		# else just skip the line
        	}			  
            elsif ($line =~ /^$start_of_boxscore/)
            {
        	    # We're finished with the previous box score, so determine if we need to increment our team stat counters
        	    # Note that the "games" field is set equal to the number of players in this game; the other values
        	    # will be <= that number.
        	    if ($current_game_counters{games} > 0)
                {
                    # the last box score we processed included the team we care about, so update the counters
                    update_stat_counters($team,$opponent);        
                }
        				
            	# The current game counters are no longer needed, so clear them to get ready for the next game
        		foreach (keys %current_game_counters)
        	 	{
        		 	$current_game_counters{$_} = 0;
        		}
        		$game_date = "";
        		$game_title = "";
        		$game_arena = "";
        		$game_attendance = "";
        		$game_sources = "";
        		$game_starttime = "";
        		$game_ref_count = 0;
        
        		
        		$game_count++;

        	}	
        	elsif ($line =~ /^abatiebreaker/)
        	{
            	# drop this game on the floor and do not add to player/team totals
#            	print "Tie-breaker\n";
                $first_gamebxt_read = "no"; # sleazy, but effective - drop everything on the floor until the next "gamebxt" is read from the file                 	
            }
        	elsif ($line =~ /^playoffsstarthere/)
        	{
            	$next_game_would_be_playoffs = "yes"; # this tells the script to set $found_playoffs to "yes" when the next gamebxt is read
            	
                # We're finished with the LAST box score, so determine if we need to increment our team stat counters
        	    if ($current_game_counters{games} > 0)
                {
                    # the last box score we processed included the team we care about, so update the counters
                    update_stat_counters($team,$opponent);
                }
                
            	# The current game counters are no longer needed, so clear them to get ready for the next game
        		foreach (keys %current_game_counters)
        	 	{
        		 	$current_game_counters{$_} = 0;
        		}                
            	
    		    # We're done with the regular season stats, so save stats to file
#    		    print output_filehandle "<\/table>\n";
                print output_filehandle "<a id=$team><\/a>\n";		    
                dump_stats_to_file("Regular Season",$team);
# was    		    	dump_stats_summary_to_file("regular season",$_);
    		    
    		    # clear all hashes
                %the_splits = ();
                %the_team_splits = ();
                clear_player_hashes();
                clear_season_team_hashes();
                clear_season_stat_counters_hashes();
            }
            elsif ($line =~ /^version/)
            {
                # ignore
            }
            elsif ($line =~ /^issue/)
            {
                #ignore
            }
            elsif ($line =~ /^sources/)
            {
                # ignore
        	}	
            elsif ($line =~ /^info/)
            {
                # split the line
                @this_line_array = parse_csv_line($line);
                
                # IMPORTANT
                # We make the assumption that the rteam/hteam is declared in the boxtop file first.
                
        		if ($this_line_array[1] eq "rteam")
                {
                    $road_team_name = $this_line_array[2];
        	        $team_string = $this_line_array[2];
            
            		# This could be made more efficient by only setting $found_playoffs once, but the approach
            		# below allows us to use $next_game_would_be_playoffs to tell the script to dump the playoff stats table.
            		if ($next_game_would_be_playoffs eq "yes")
            		{
                        $found_playoffs{Boxtop_GetBRAbbreviationFromTeamName($team_string)} = "yes";
                    }
        	    }
                elsif ($this_line_array[1] eq "hteam")
                {
        	        $home_team_name = $this_line_array[2];
        	        $team_string = $this_line_array[2];

            		# This could be made more efficient by only setting $found_playoffs once, but the approach
            		# below allows us to use $next_game_would_be_playoffs to tell the script to dump the playoff stats table.
            		if ($next_game_would_be_playoffs eq "yes")
            		{
                        $found_playoffs{Boxtop_GetBRAbbreviationFromTeamName($team_string)} = "yes";
                    }
                }
                # Also grab some game info so we can track what we are missing
                elsif ($this_line_array[1] eq "date")
        		{
        	        $game_date = $this_line_array[2];
        	        
    	            if ($date_of_first_game eq "NONE")
    	            {
        	            # grab this for use in linking to BR team pages
        	            $date_of_first_game = $game_date; 
    	            }
    	            
    	            # if desired, determine if this date is beyond the range we want to check
    	            if ($config_options{check_through_date} ne "all")
    	            {
        	            my ($c_mon, $c_day, $c_year) = split("\/",$game_date);
                        if (Date_to_Days($c_year,$c_mon,$c_day) >
                            Date_to_Days($check_through_year,$check_through_mon,$check_through_day))        	            
    	                {
        	                $stop_checking = "yes";
        	            }   
    	            }
        		}        
        		elsif ($this_line_array[1] eq "title")
        		{
        	        $game_title = $this_line_array[2];
        		}        
        		elsif ($this_line_array[1] eq "arena")
        		{
        	        $game_arena = $this_line_array[2];
        		}        
        		elsif ($this_line_array[1] eq "attendance")
        		{
        	        $game_attendance = $this_line_array[2];
        		}        
        		elsif ($this_line_array[1] eq "starttime")
        		{
        	        $game_starttime = $this_line_array[2];
        		}        
        		elsif ($this_line_array[1] eq "ref")
        		{
        			if ($this_line_array[2] ne "")
        	        {
        		        $game_ref_count++;
        	    	}
        		}        
                
            }
            elsif ($line =~ /^coach/)
            {
                # ignore
            }
            elsif ($line =~ /^stat/)
            {
                # split the line and add to hash
                @this_line_array = parse_csv_line($line);
                
                if ($this_line_array[1] eq "rteam")
                {
                	$tm_str = $road_team_name;
            	}
            	else
                {
                	$tm_str = $home_team_name;
            	}
                
                # Check if this team is included in the list of teams we want to collect stats for
                $tm_str_abbrev = Boxtop_GetBRAbbreviationFromTeamName($tm_str);
                if ($team eq $tm_str_abbrev)
                {
        	        # This player plays for the team we care about. Grab the stats.
        	        
                    if ($tm_str eq $road_team_name)
                    {
                        $opponent = $home_team_name;
                    }
                    else
                    {
                        $opponent = $road_team_name;
                    }
        	        
        			# stat,rteam,player,ramsefr01,Frank,Ramsey,,3,,5,6,,,11,,,,5,,,,
        # stat,rteam|hteam,player,ID,FIRSTNAME,LASTNAME,MIN,FGM,FGA,FTM,FTA,3FGM,3FGA,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS,TECHNICALFOUL
        # 0    1           2      3  4         5        6   7   8   9   10  11   12   13  14   15  16  17 18     19        20     21		
        			$player_id = $this_line_array[3] . "-" . $tm_str;
        			
        			if (($this_line_array[6] eq "") || ($this_line_array[6] > 0)) # cover cases where player minutes are explictly listed as "zero"
                    {
        	            if (!(exists($player_games_played{$player_id})))
        	            {
        		        	# Only grab name one time
        		        	$player_first_names{$player_id} = $this_line_array[4];
        		        	$player_last_names{$player_id} = $this_line_array[5];
        	            }
            	            
    		            $player_games_played{$player_id}++;
    		            $player_fgm{$player_id} += $this_line_array[7];
    		            $player_ftm{$player_id} += $this_line_array[9];
    		            $player_fta{$player_id} += $this_line_array[10];
    		            $player_fgm3{$player_id} += $this_line_array[11];
    		            $player_fga3{$player_id} += $this_line_array[12];
    		            $player_pts{$player_id} += $this_line_array[13];
    		            $player_pf{$player_id} += $this_line_array[17];
    		            
    		            $player_min{$player_id} += $this_line_array[6];
    		            $player_fga{$player_id} += $this_line_array[8];
    		            $player_oreb{$player_id} += $this_line_array[14];
    		            $player_reb{$player_id} += $this_line_array[15];
    		            $player_ast{$player_id} += $this_line_array[16];
    		            $player_blocks{$player_id} += $this_line_array[18];
    		            $player_turnovers{$player_id} += $this_line_array[19];
    		            $player_steals{$player_id} += $this_line_array[20];
    		            
    		            $the_splits{$opponent}{$player_id}{games_played}++; 
    		            $the_splits{$opponent}{$player_id}{fgm} += $this_line_array[7];
    		            $the_splits{$opponent}{$player_id}{ftm} += $this_line_array[9];
    		            $the_splits{$opponent}{$player_id}{fta} += $this_line_array[10];
    		            $the_splits{$opponent}{$player_id}{fgm3} += $this_line_array[11];
    		            $the_splits{$opponent}{$player_id}{fga3} += $this_line_array[12];
    		            $the_splits{$opponent}{$player_id}{pts} += $this_line_array[13];
    		            $the_splits{$opponent}{$player_id}{pf} += $this_line_array[17];
    		            
    		            $the_splits{$opponent}{$player_id}{min} += $this_line_array[6];
    		            $the_splits{$opponent}{$player_id}{fga} += $this_line_array[8];
    		            $the_splits{$opponent}{$player_id}{oreb} += $this_line_array[14];
    		            $the_splits{$opponent}{$player_id}{reb} += $this_line_array[15];
    		            $the_splits{$opponent}{$player_id}{ast} += $this_line_array[16];
    		            $the_splits{$opponent}{$player_id}{blocks} += $this_line_array[18];
    		            $the_splits{$opponent}{$player_id}{turnovers} += $this_line_array[19];
    		            $the_splits{$opponent}{$player_id}{steals} += $this_line_array[20];
            		}
            	
            		# TBD - this probably needs to be separate road and home hashes in order to accurately reflect each team, 
            		# but for now let's keep it this way and treat a stat as complete for both or neither
            		
                	$current_game_counters{games}++;
        	        if ($this_line_array[6] ne "")
        	        {
        		        $current_game_counters{minutes}++;
        	        }
        	        if ($this_line_array[7] ne "")
        	        {
        		        $current_game_counters{fgm}++;
        	        }
        	        if ($this_line_array[8] ne "")
        	        {
        		        $current_game_counters{fga}++;
        	        }
        	        if ($this_line_array[9] ne "")
        	        {
        		        $current_game_counters{ftm}++;
        	        }
        	        if ($this_line_array[10] ne "")
        	        {
        		        $current_game_counters{fta}++;
        	        }
        	        if ($this_line_array[11] ne "")
        	        {
        		        $current_game_counters{fgm3}++;
        	        }
        	        if ($this_line_array[12] ne "")
        	        {
        		        $current_game_counters{fga3}++;
        	        }
        	        if ($this_line_array[13] ne "")
        	        {
        		        $current_game_counters{pts}++;
        	        }
        	        if ($this_line_array[17] ne "")
        	        {
        		        $current_game_counters{pf}++;
        	        }
        	        if ($this_line_array[14] ne "")
        	        {
        		        $current_game_counters{oreb}++;
        	        }
        	        if ($this_line_array[15] ne "")
        	        {
        		        $current_game_counters{reb}++;
        	        }
        	        if ($this_line_array[16] ne "")
        	        {
        		        $current_game_counters{ast}++;
        	        }
        	        if ($this_line_array[18] ne "")
        	        {
        		        $current_game_counters{blocks}++;
        	        }
        	        if ($this_line_array[19] ne "")
        	        {
        		        $current_game_counters{turnovers}++;
        	        }
        	        if ($this_line_array[20] ne "")
        	        {
        		        $current_game_counters{steals}++;
        	        }
                }
            }
            elsif ($line =~ /^tstat/)
            {
                # split the line and add to hash
                @this_line_array = parse_csv_line($line);
                
                if ($this_line_array[1] eq "rteam")
                {
                	$tm_str = $road_team_name;
            	}
            	else
                {
                	$tm_str = $home_team_name;
            	}
            	
                $tm_str_abbrev = Boxtop_GetBRAbbreviationFromTeamName($tm_str);
                if ($team eq $tm_str_abbrev)
                {
        	        # This is the team we care about. Grab the stats.
        			# tstat,rteam,,44,,27,38,,,115,,,,34,,,,,
        # tstat,rteam|hteam,MIN,FGM,FGA,FTM,FTA,FG3M,FG3A,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS,TEAMREBOUNDS,TECHNICALFOUL
        # 0     1           2   3   4   5   6   7    8    9   10   11  12  13 14     15        16     17           18
        			$season_team_games_played{$tm_str_abbrev}++;
        			$the_team_splits{$opponent}{games_played}++;
        			
        			# Note, perl is smart enough to do the math correctly (i.e. add zero) if
        			# the string is empty. But since we want to count the number of times 
        			# that a particular stat is available, we might as well check.
        			#
        			# But I found that this causes some stats totals to not get printed if we're missing a game.
        			# So in Nov 2014 I disabled these checks in abateamplits.pl
        			
#        			if ($this_line_array[3] ne "")
        			{
        				$season_team_fgm{$tm_str_abbrev} += $this_line_array[3];
        				$the_team_splits{$opponent}{fgm} += $this_line_array[3];
        			}
        			
#        			if ($this_line_array[5] ne "")
        			{
        				$season_team_ftm{$tm_str_abbrev} += $this_line_array[5];
        				$the_team_splits{$opponent}{ftm} += $this_line_array[5];
        			}
        		
#        			if ($this_line_array[6] ne "")
        			{
        				$season_team_fta{$tm_str_abbrev} += $this_line_array[6];
        				$the_team_splits{$opponent}{fta} += $this_line_array[6];
        			}
        			
#        			if ($this_line_array[7] ne "")
        			{
        				$season_team_fgm3{$tm_str_abbrev} += $this_line_array[7];
        				$the_team_splits{$opponent}{fgm3} += $this_line_array[7];
        			}
        			
#        			if ($this_line_array[8] ne "")
        			{
        				$season_team_fga3{$tm_str_abbrev} += $this_line_array[8];
        				$the_team_splits{$opponent}{fga3} += $this_line_array[8];
        			}
        			
#        			if ($this_line_array[13] ne "")
        			{
        				$season_team_pf{$tm_str_abbrev} += $this_line_array[13];
        				$the_team_splits{$opponent}{pf} += $this_line_array[13];
        			}
        			
#       			if ($this_line_array[9] ne "")
        			{
        				$season_team_pts{$tm_str_abbrev} += $this_line_array[9];
        				$the_team_splits{$opponent}{pts} += $this_line_array[9];
        			}
        			
#        			if ($this_line_array[2] ne "")
        			{
        				$season_team_min{$tm_str_abbrev} += $this_line_array[2];
        				$the_team_splits{$opponent}{min} += $this_line_array[2];
        			}
        			
#        			if ($this_line_array[4] ne "")
        			{
        				$season_team_fga{$tm_str_abbrev} += $this_line_array[4];
        				$the_team_splits{$opponent}{fga} += $this_line_array[4];
        			}
        			
#        			if ($this_line_array[10] ne "")
        			{
        				$season_team_oreb{$tm_str_abbrev} += $this_line_array[10];
        				$the_team_splits{$opponent}{oreb} += $this_line_array[10];
        			}
        			
#        			if ($this_line_array[11] ne "")
        			{
        				$season_team_reb{$tm_str_abbrev} += $this_line_array[11];
        				$the_team_splits{$opponent}{reb} += $this_line_array[11];
        			}
        			
#        			if ($this_line_array[12] ne "")
        			{
        				$season_team_ast{$tm_str_abbrev} += $this_line_array[12];
        				$the_team_splits{$opponent}{ast} += $this_line_array[12];
        			}
        			
#        			if ($this_line_array[14] ne "")
        			{
        				$season_team_blocks{$tm_str_abbrev} += $this_line_array[14];
        				$the_team_splits{$opponent}{blocks} += $this_line_array[14];
        			}
        			
#        			if ($this_line_array[15] ne "")
        			{
        				$season_team_turnovers{$tm_str_abbrev} += $this_line_array[15];
        				$the_team_splits{$opponent}{turnovers} += $this_line_array[15];
        			}
        			
#        			if ($this_line_array[16] ne "")
        			{
        				$season_team_steals{$tm_str_abbrev} += $this_line_array[16];
        				$the_team_splits{$opponent}{steals} += $this_line_array[16];
        			}
        			
        			
        			if ($this_line_array[17] ne "")
        			{
        				$season_team_team_reb{$tm_str_abbrev} += $this_line_array[17];
        				$the_team_splits{$opponent}{team_reb} += $this_line_array[17];
        				
        				# Special case where we can increment the season stat counters right here
        				$season_stat_counters_team_reb{$tm_str_abbrev}++;
        			}
                }
            }
            elsif ($line =~ /^linescore/)
            {
                # ignore
            }   
        
        
        } # end of main loop
        
        # We're finished with the LAST box score, so determine if we need to increment our team stat counters
	    if ($current_game_counters{games} > 0)
        {
            # the last box score we processed included the team we care about, so update the counters
            update_stat_counters($team,$opponent);
        }
        
        # Save data to file
        if ($next_game_would_be_playoffs eq "no")
        {
            # This writes the stats to a file if the CSV file is INCOMPLETE
            # Once the CSV file contains a "playoffsstarthere" tag, the $next_game_would_be_playoffs flag 
            # will be set to "yes" and we'll write the regular season stats into the file at that time.
            
 		    # We're done with the regular season stats, so save stats to file
            print output_filehandle "<a id=$team><\/a>\n";		    
            dump_stats_to_file("Regular Season",$team);
# was        		dump_stats_summary_to_file("regular season",$_);
        }
        elsif ($found_playoffs{$team} eq "yes")
        {
            # $found_playoffs is only set to yes if we actually find "playoffsstarthere" followed by a playoff game played by this team
            dump_stats_to_file("Playoff",$team);
# was        		dump_stats_summary_to_file("playoff",$_);
        } 
        
    	print output_filehandle "<p>\n";
    	
        print output_filehandle "<a id=Glossary></a>\n";
        print output_filehandle "<hr>\n";
        
        print output_filehandle "<h3><strong>Glossary</strong></h3>\n";
        print output_filehandle "<p>3FG/3FA = Three-point field goals made/attempted\n";
        print output_filehandle "<br>ORB = Offensive Rebounds, REB = Total Rebounds (Offensive + Defensive)\n";
        print output_filehandle "<br>AST = Assists, TO = Turnovers, BL = Blocks, ST = Steals\n";
        print output_filehandle "<p>Statistics shown are based on those in the BOXTOP box scores, which are taken from unofficial sources.\n";
        print output_filehandle "<br> Errors exist for some games, and in other cases complete data may be available for some players but not others.\n";
        print output_filehandle "<br> In team statistics, incomplete season totals are displayed in <span style=\"color:blue\">blue</span>.\n";

        print output_filehandle "<br> Known inconsistencies as compared to statistics on Basketball-Reference.com are displayed in <span style=\"color:red\">red</span> except for team splits where no official totals exist";
        if ($print_debug_info eq "yes")
        {
            print output_filehandle " with the \"official\" figure in ().\n";
            print output_filehandle "<p><strong>Games Available</strong> denotes the number of games for which that statistic is available for every player who played in the game.\n";
        }
        else
        {
            print output_filehandle ".\n";
        }
        
        print output_filehandle "<hr>\n";
        print output_filehandle Boxtop_HtmlFooter("abateamsplits.pl");
        
        close (output_filehandle);
        
        print "File $output_filename created.\n";
    } # end of team loop

	
#    print output_filehandle "<br>\n";

} # end of if block for season stats check code


print "Done.\n";