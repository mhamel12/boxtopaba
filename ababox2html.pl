# ===============================================================
# 
# ababox2html.pl
#
# (c) 2010-2016 Michael Hamel
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of this license, visit # http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
#
# Version history
# 12/28/2010  1.0  MH  Initial version
# 03/11/2011  1.1  MH  Team rebounds in box scores = REB + TEAMREBOUNDS
# 04/02/2011  1.2  MH  Added meta tags, BOXTOP links, and citation info
# 04/23/2011  1.3  MH  Cleanup radio/tv and some other fields
# 05/26/2011  1.4  MH  Support for multiple game note fields and title argument
# 08/21/2011  1.5  MH  Event, Prelim, Note fields can now include commas
# June  2014  1.6  MH  Russell version added links to BR.com team pages
# 07/14/2014  1.7  MH  Optimized for ABA, added calendar of links
# 10/30/2014  1.8  MH  Added neutral site game handling
# 10/26/2016  1.9  MH  Gray background for table headers
# 11/02/2016  1.10 MH  Split page on month boundaries to speed loading
#
# ===============================================================


#! usr/bin/perl
use Getopt::Std;
use Time::Local;
use Date::Calc qw(:all);

use lib '../tools';
use Boxtop;

# store data split in these hashes
my %info;

# store data unsplit in these hashes, indexed by hteam and rteam
my %coaches;
my %team_stats;
my %linescores;

# store data unsplit in these hashes, indexed by player id
my %road_player_stats;
my %home_player_stats;

my %game_days;
my %list_of_teams;

my $sources_note = "";

my $index_count = 1;
my $game_count = 1;

# Team pages on BR.com of the form: http://www.basketball-reference.com/teams/BOS/1957.html
my $BR_team_page_preamble = "http:\/\/www.basketball-reference.com\/teams\/";

# ===============================================================

sub usage
{
    print "Convert a boxtop-format file into a single html format page.\n\n";
    print "Output includes html tables with dynamic row shading (could cause ActiveX warnings in IE).\n";
    print "\n";
    print "\nUSAGE:\n ababox2html.pl [-i inputfilename] [-o outputfilename] [-t outputpagetitle]\n";
    print "                [-j Java sorted tables on|off]\n";
    print " Default filenames are input.csv and output.htm unless specified.\n";
}
# end of sub usage()

# ===============================================================

sub getstring
{
    $string = <>;
    chomp($string); # strip off CR
    return $string;
}
# end of sub getstring()

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

# not currently used in this script
sub get_day_of_week($)
{
	$date = $_[0];
	
   	my ($mon,$mday,$year) = split(/\//, $date);
 
	$wday = Day_of_Week($year,$mon,$mday);
	$the_day = Day_of_Week_to_Text($wday);
 
   	return($the_day);
}

# ===============================================================


sub make_calendar_of_links($$$)
{
    $starting_month = $_[0]; # months go 1-12
    $ending_month = $_[1]; # months go 1-12
    $year = $_[2]; # starting year (1974 in the case of 1974-75)

    print output_filehandle "<center><table cellpadding=2>\n";

    $next_month = $starting_month;
    $done = "no";
    
    my %months;
    
    while ($done eq "no")
    {
        #
        # fill in data structure for the months involved - assumes minimum of 3 months duration
        #
        
        $months{aleft}{number} = $next_month;
        $months{aleft}{year} = $year;
        if ($next_month < 8)
        {   
            $months{aleft}{year}++;
        }

        $months{aleft}{opening_day_of_week} = (Day_of_Week($months{aleft}{year},$months{aleft}{number},1)) % 7; # library returns 7 for Sunday, we want 0
        $months{aleft}{days_in_month} = Days_in_Month($months{aleft}{year},$months{aleft}{number});
        $months{aleft}{days_generated} = 0;
        
        if ($next_month == $ending_month)
        {
            $months{center}{number} = 0;
            $months{center}{year} = 0;
            $months{center}{opening_day_of_week} = 0;
            $months{center}{days_in_month} = 0; # This is our sentinel to tell us to print NOTHING for this month
            $months{center}{days_generated} = 0;
            
            $months{right}{number} = 0;
            $months{right}{year} = 0;
            $months{right}{opening_day_of_week} = 0;
            $months{right}{days_in_month} = 0; # This is our sentinel to tell us to print NOTHING for this month
            $months{right}{days_generated} = 0;        
            
            $done = "yes"; # stop main loop after this set of months
        }
        else
        {    
            $next_month++;
            if ($next_month == 13)
            {
                $next_month = 1; # months go 1-12
            }
        
            $months{center}{number} = $next_month;
            $months{center}{year} = $year;
            if ($next_month < 8) 
            {   
                $months{center}{year}++;
            }
            $months{center}{opening_day_of_week} = (Day_of_Week($months{center}{year},$months{center}{number},1)) % 7; # library returns 7 for Sunday, we want 0
            $months{center}{days_in_month} = Days_in_Month($months{center}{year},$months{center}{number});
            $months{center}{days_generated} = 0;
            
            if ($next_month == $ending_month)
            {
                $months{right}{number} = 0;
                $months{right}{year} = 0;
                $months{right}{opening_day_of_week} = 0;
                $months{right}{days_in_month} = 0; # This is our sentinel to tell us to print NOTHING for this month
                $months{right}{days_generated} = 0;
                
                $done = "yes"; # stop main loop after this set of months
            }
            else
            {
                $next_month++;
                if ($next_month == 13)
                {
                    $next_month = 1; # months go 1-12
                }

                $months{right}{number} = $next_month;
                $months{right}{year} = $year;
                if ($next_month < 8)
                {   
                    $months{right}{year}++;
                }
                $months{right}{opening_day_of_week} = (Day_of_Week($months{right}{year},$months{right}{number},1)) % 7; # library returns 7 for Sunday, we want 0
                $months{right}{days_in_month} = Days_in_Month($months{right}{year},$months{right}{number});
                $months{right}{days_generated} = 0;
            }        
        }
    
        #
        # go row by row
        #
        
        for ($row=0; $row < 7; $row++)
        {
    #        print "Row = $row\n";
            if ($row eq 0)
            {
                # print headers
                print output_filehandle "<tr>\n";
                
                foreach my $this_column (sort keys %months)
                {
                    if ($months{$this_column}{days_in_month} > 0)
                    {
                        print output_filehandle "<td colspan\=\"7\" style=\"background-color:lightgray\"><center><strong>";
                        $month_in_text = Month_to_Text($months{$this_column}{number});
                        print output_filehandle "$month_in_text  $months{$this_column}{year}";
                        print output_filehandle "</strong></center></td>";
                    }
                    
    #                print "Number:$months{$this_column}{number} Open:$months{$this_column}{opening_day_of_week} Yr:$months{$this_column}{year} DiM:$months{$this_column}{days_in_month} DG:$months{$this_column}{days_generated}\n";
                    
                }
                
                print output_filehandle "</tr>\n";
            }
            else
            {
                # print grids
                print output_filehandle "<tr>\n";
                
                foreach my $this_column (sort keys %months)
                {
    #                print "Got here: Column is $this_column\n";
                
                    # need to have 21 columns, either blank or not - worry about extra spacing between them later
                    
                    for ($subcolumn = 0; $subcolumn < 7; $subcolumn++)
                    {
                        if (($row == 1) && ($subcolumn < $months{$this_column}{opening_day_of_week}))
                        {
                            # empty spaces to lead off the table
                            print output_filehandle "<td></td>";
                        }
                        elsif ($months{$this_column}{days_generated} < $months{$this_column}{days_in_month})
                        {
                            $months{$this_column}{days_generated}++;
                        
                            # link look up
                            $padded_month = sprintf("%02d",$months{$this_column}{number}); # add leading zero for 6/10/1973 so it is 06_10_1973
                            $padded_day = sprintf("%02d",$months{$this_column}{days_generated}); # add leading zero for 11/1/1973 so it is 11_01_1973
                            $link_month_day = join("/", $padded_month,$padded_day,$months{$this_column}{year});
#                            print "Checking: $link_month_day\n";
                            if (exists $game_days{$link_month_day})
                            {
                                $link_month_day =~ s/\//_/g;
                                $padded_month_abbrev = lc(substr (Month_to_Text($padded_month),0,3));
                                $the_link = $output_filename_preamble . $padded_month_abbrev . ".htm#" . $link_month_day;
                                print output_filehandle "<td style=\"text-align:center; background-color:#e5e5e5;\"><a href=$the_link>$months{$this_column}{days_generated}</a></td>";
                            }
                            else
                            {        
                                print output_filehandle "<td style=\"text-align:center\">$months{$this_column}{days_generated}</td>";
                            }
                        }
#                        else # Replaced this simple "else" with the following line on 9/5/2014 so we do not get a fully blank month in output
                        elsif ($months{$this_column}{days_in_month} > 0)
                        {
                            # empty spaces to end the table
                            print output_filehandle "<td></td>";
                        }
                    }
                    print output_filehandle "\n";
                }
                
                print output_filehandle "</tr>\n";
            }
        }
        
        #
        # Are we done?
        #
        if ($next_month == $ending_month)
        {
            $done = "yes";
        }
        else
        {
            $next_month++;
            if ($next_month == 13)
            {
                $next_month = 1; # months go 1-12
            }

        }
    }
    
    print output_filehandle "</table></center>\n";
}

# ===============================================================

# ABA stats
# $formatted_stat_line_header = "<tr><td><\/td><td align = \"right\">Min<\/td><td align = \"right\">FGM<\/td><td align = \"right\">FGA<\/td><td align = \"right\">FTM<\/td><td align = \"right\">FTA<\/td><td align = \"right\">REB<\/td><td align = \"right\">AST<\/td><td align = \"right\">PF<\/td><td align = \"right\">PTS<\/td><\/tr>";
$formatted_stat_line_header = "<tr style=\"background-color:lightgray\"><td><\/td><td style=\"width:20px; text-align:right\">MIN<\/td><td style=\"width:20px; text-align:right\">FGM<\/td><td style=\"width:20px; text-align:right\">FGA<\/td><td style=\"width:20px; text-align:right\">FTM<\/td><td style=\"width:20px; text-align:right\">FTA<\/td><td style=\"width:20px; text-align:right\">3FG<\/td><td style=\"width:20px; text-align:right\">3FA<\/td><td style=\"width:20px; text-align:right\">PTS<\/td><td style=\"width:20px; text-align:right\">ORB<\/td><td style=\"width:20px; text-align:right\">REB<\/td><td style=\"width:20px; text-align:right\">AST<\/td><td style=\"width:20px; text-align:right\">PF<\/td><td style=\"width:20px; text-align:right\">TO<\/td><td style=\"width:20px; text-align:right\">BL<\/td><td style=\"width:20px; text-align:right\">ST<\/td><\/tr>";
$basic_stat_line_header = "<tr style=\"background-color:lightgray\"><td><\/td><td style=\"width:20px; text-align:right\">FGM<\/td><td style=\"width:20px; text-align:right\">3FG<\/td><td style=\"width:20px; text-align:right\">FTM<\/td><td style=\"width:20px; text-align:right\">FTA<\/td><td style=\"width:20px; text-align:right\">PTS<\/td><\/tr>";

$br_player_link = "http:\/\/www.basketball-reference.com\/players";
$br_coach_link = "http:\/\/www.basketball-reference.com\/coaches";

$date_link = "none";

sub dump_data_to_file()
{
#   print(%info);
#   print(%coaches);
#   print(%team_stats);
#   print(%linescores);
#   print(%road_player_stats);
#   print(%home_player_stats);

    $home_abbrev = Boxtop_GetBRAbbreviationFromTeamName($info{hteam});
    $road_abbrev = Boxtop_GetBRAbbreviationFromTeamName($info{rteam});

    # create link if needed so the link calendar works
    if ($date_link ne $info{date})
    {
        # this is the first game on this date, so create a link
        $date_link = $info{date}; # store with slashes for quick comparisons
        
        $date_link_text = $date_link;
        $date_link_text =~ s/\//_/g; # replace slashes with underscores for the actual links
        print output_filehandle "<a id=$date_link_text><\/a>\n";  
    }      
    
    # now we need to build a link to this specific game, for use in the team-by-team game listings
    ($mon,$mday,$year) = split('/',$info{date});
    $season_year = $year;
    if ($mon > 7) # game took place after July, so this is the following season (October 1956 game is during "1957" season from BR.com's perspective
    {
        $season_year++;
    }    
    
#    $link_text = sprintf("Game_%02d_%02d_%s_%s",$mon,$mday,$home_abbrev,$road_abbrev);
    $link_text = Boxtop_GetGameLinkText($info{date},$info{hteam},$info{rteam},$info{gamenumber});
    
    print output_filehandle "<a id=$link_text><\/a>\n";
    $game_count++;
    print output_filehandle "<h2>$info{rteam} vs. $info{hteam}<\/h2>\n";
    print output_filehandle "<h3>\n$info{title}<br>\n$info{dayofweek} $info{date} at $info{arena}<br>\n$info{city}, $info{state}, $info{country}\n<\/h3>\n";

# head coaches

# stats go here in tables... road on top, home on bottom. Need to have links and fangraph-style shading.

    $team_with_link = $BR_team_page_preamble .  Boxtop_GetBRAbbreviationFromTeamName($info{rteam}) . "\/" . $season_year . ".html"; 

    print output_filehandle  "<p><h3><a href=$team_with_link>$info{rteam}<\/a><\/h3>";

    print output_filehandle "<table>\n";
    
    $header_printed = "no";
    
    # This fixes 10/26/1972 forfeit by only printing player stats table if we find a player in the road player hash - 
    # all of the table prints below will print only if stats_type is changed to "full" or "basic"
    $stats_type = "empty"; 
    
    foreach $value (sort values %road_player_stats)
    {
#       print $value;
        @stats_line = parse_csv_line($value);
        
        if ($header_printed eq "no")
        {
            # Check if we have rebounds or FGA for this game
            if (($stats_line[15] ne "") || ($stats_line[8] ne ""))
            {
                $stats_type = "full";
                print output_filehandle $formatted_stat_line_header;
            }
            else
            {
                $stats_type = "basic";
                print output_filehandle $basic_stat_line_header;
            }
            
            $header_printed = "yes";
        }
        
        $ch = substr($stats_line[3],0,1);
#       print $ch;

        if ($stats_type eq "full")
        {
            # 0    1           2      3  4         5        6   7   8   9   10  11   12   13  14   15  16  17 18     19        20     21
            # stat,rteam|hteam,player,ID,FIRSTNAME,LASTNAME,MIN,FGM,FGA,FTM,FTA,3FGM,3FGA,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS,TECHNICALFOUL
            print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\"><td><a href=\"$br_player_link\/$ch\/$stats_line[3].html\">$stats_line[4] $stats_line[5]<\/a><\/td><td align = \"right\">$stats_line[6]<\/td><td align = \"right\">$stats_line[7]<\/td><td align = \"right\">$stats_line[8]<\/td><td align = \"right\">$stats_line[9]<\/td><td align = \"right\">$stats_line[10]<\/td><td align = \"right\">$stats_line[11]<\/td><td align = \"right\">$stats_line[12]<\/td><td align = \"right\">$stats_line[13]<\/td><td align = \"right\">$stats_line[14]<\/td><td align = \"right\">$stats_line[15]<\/td><td align = \"right\">$stats_line[16]<\/td><td align = \"right\">$stats_line[17]<\/td><td align = \"right\">$stats_line[19]<\/td><td align = \"right\">$stats_line[18]<\/td><td align = \"right\">$stats_line[20]<\/td><\/tr>\n";
        }
        elsif ($stats_type eq "basic")
        {
            print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\"><td><a href=\"$br_player_link\/$ch\/$stats_line[3].html\">$stats_line[4] $stats_line[5]<\/a><\/td><td align = \"right\">$stats_line[7]<\/td><td align = \"right\">$stats_line[11]<\/td><td align = \"right\">$stats_line[9]<\/td><td align = \"right\">$stats_line[10]<\/td><td align = \"right\">$stats_line[13]<\/td><\/tr>\n";
        }    
    }
    $value = $team_stats{rteam};
    @stats_line = parse_csv_line($value);

    $road_team_fouls = $stats_line[13];
    
    # Add rebounds + teamrebounds together to match usual boxscore format
    # If no rebounds available, then print a blank
    $rebounds = $stats_line[11] + $stats_line[17];
    	
    if ($stats_type eq "full")	
    {
    	# 0     1           2   3   4   5   6   7    8    9   10   11  12  13 14     15        16     17           18
    	# tstat,rteam|hteam,MIN,FGM,FGA,FTM,FTA,FG3M,FG3A,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS,TEAMREBOUNDS,TECHNICALFOUL
    	print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\"><td><strong>Totals</strong><\/td><td style=\"text-align:right\"><\/td><td style=\"text-align:right\">$stats_line[3]<\/td><td style=\"text-align:right\">$stats_line[4]<\/td><td style=\"text-align:right\">$stats_line[5]<\/td><td style=\"text-align:right\">$stats_line[6]<\/td><td style=\"text-align:right\">$stats_line[7]<\/td><td style=\"text-align:right\">$stats_line[8]<\/td><td style=\"text-align:right\">$stats_line[9]<\/td><td style=\"text-align:right\">$stats_line[10]<\/td><td style=\"text-align:right\">$rebounds<\/td><td style=\"text-align:right\">$stats_line[12]<\/td><td style=\"text-align:right\">$stats_line[13]<\/td><td style=\"text-align:right\">$stats_line[15]<\/td><td style=\"text-align:right\">$stats_line[14]<\/td><td style=\"text-align:right\">$stats_line[16]<\/td><\/tr>\n";
    }
    elsif ($stats_type eq "basic")
    {
        print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\"><td><strong>Totals</strong><\/td><td style=\"text-align:right\">$stats_line[3]<\/td><td style=\"text-align:right\">$stats_line[7]<\/td><td style=\"text-align:right\">$stats_line[5]<\/td><td style=\"text-align:right\">$stats_line[6]<\/td><td style=\"text-align:right\">$stats_line[9]<\/td><\/tr>\n";
    }
    print output_filehandle "<\/table>\n";

    if ($stats_line[17] ne "") { print output_filehandle "<h5>Team Rebounds: $stats_line[17]<\/h5>\n"; }

    # re-use season_year and stats_type derived above    
    $team_with_link = $BR_team_page_preamble . Boxtop_GetBRAbbreviationFromTeamName($info{hteam}) . "\/" . $season_year . ".html"; 

    print output_filehandle  "<p><h3><a href=$team_with_link>$info{hteam}<\/a><\/h3>";
    
    print output_filehandle "<table>\n";
    
    if ($stats_type eq "full")    
    {
        print output_filehandle $formatted_stat_line_header;
    }
    elsif ($stats_type eq "basic")
    {
        print output_filehandle $basic_stat_line_header;
    }

    foreach $value (sort values %home_player_stats)
    {
#       print $value;
        @stats_line = parse_csv_line($value);
        $ch = substr($stats_line[3],0,1);
#       print $ch;
        if ($stats_type eq "full")
        {
            # 0    1           2      3  4         5        6   7   8   9   10  11   12   13  14   15  16  17 18     19        20     21
            # stat,rteam|hteam,player,ID,FIRSTNAME,LASTNAME,MIN,FGM,FGA,FTM,FTA,3FGM,3FGA,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS,TECHNICALFOUL
            print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\"><td><a href=\"$br_player_link\/$ch\/$stats_line[3].html\">$stats_line[4] $stats_line[5]<\/a><\/td><td style=\"text-align:right\">$stats_line[6]<\/td><td style=\"text-align:right\">$stats_line[7]<\/td><td style=\"text-align:right\">$stats_line[8]<\/td><td style=\"text-align:right\">$stats_line[9]<\/td><td style=\"text-align:right\">$stats_line[10]<\/td><td style=\"text-align:right\">$stats_line[11]<\/td><td style=\"text-align:right\">$stats_line[12]<\/td><td style=\"text-align:right\">$stats_line[13]<\/td><td style=\"text-align:right\">$stats_line[14]<\/td><td style=\"text-align:right\">$stats_line[15]<\/td><td style=\"text-align:right\">$stats_line[16]<\/td><td style=\"text-align:right\">$stats_line[17]<\/td><td style=\"text-align:right\">$stats_line[19]<\/td><td style=\"text-align:right\">$stats_line[18]<\/td><td style=\"text-align:right\">$stats_line[20]<\/td><\/tr>\n";
        }
        elsif ($stats_type eq "basic")
        {
            print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\"><td><a href=\"$br_player_link\/$ch\/$stats_line[3].html\">$stats_line[4] $stats_line[5]<\/a><\/td><td style=\"text-align:right\">$stats_line[7]<\/td><td style=\"text-align:right\">$stats_line[11]<\/td><td style=\"text-align:right\">$stats_line[9]<\/td><td style=\"text-align:right\">$stats_line[10]<\/td><td style=\"text-align:right\">$stats_line[13]<\/td><\/tr>\n";
        }    
    }
    $value = $team_stats{hteam};
    @stats_line = parse_csv_line($value);

    $home_team_fouls = $stats_line[13];
    
    $rebounds = $stats_line[11] + $stats_line[17];

	if ($stats_type eq "full")
	{
    	# 0     1           2   3   4   5   6   7    8    9   10   11  12  13 14     15        16     17           18
    	# tstat,rteam|hteam,MIN,FGM,FGA,FTM,FTA,FG3M,FG3A,PTS,OREB,REB,AST,PF,BLOCKS,TURNOVERS,STEALS,TEAMREBOUNDS,TECHNICALFOUL
    	print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\"><td><strong>Totals</strong><\/td><td style=\"text-align:right\"><\/td><td style=\"text-align:right\">$stats_line[3]<\/td><td style=\"text-align:right\">$stats_line[4]<\/td><td style=\"text-align:right\">$stats_line[5]<\/td><td style=\"text-align:right\">$stats_line[6]<\/td><td style=\"text-align:right\">$stats_line[7]<\/td><td style=\"text-align:right\">$stats_line[8]<\/td><td style=\"text-align:right\">$stats_line[9]<\/td><td style=\"text-align:right\">$stats_line[10]<\/td><td style=\"text-align:right\">$rebounds<\/td><td style=\"text-align:right\">$stats_line[12]<\/td><td style=\"text-align:right\">$stats_line[13]<\/td><td style=\"text-align:right\">$stats_line[15]<\/td><td style=\"text-align:right\">$stats_line[14]<\/td><td style=\"text-align:right\">$stats_line[16]<\/td><\/tr>\n";
    }
    elsif ($stats_type eq "basic")
    {
        print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\"><td><strong>Totals</strong><\/td><td style=\"text-align:right\">$stats_line[3]<\/td><td style=\"text-align:right\">$stats_line[7]<\/td><td style=\"text-align:right\">$stats_line[5]<\/td><td style=\"text-align:right\">$stats_line[6]<\/td><td style=\"text-align:right\">$stats_line[9]<\/td><\/tr>\n";
    }

	
	print output_filehandle "<\/table>\n";

    if ($stats_line[17] ne "") { print output_filehandle "<h5>Team Rebounds: $stats_line[17]<\/h5>\n"; }
    
    # linescores in a table
    @road_linescore = parse_csv_line($linescores{rteam});
    @home_linescore = parse_csv_line($linescores{hteam});
    $column_count = $#road_linescore - 1; # assume both the same length
#    print "column count = $column_count\n";
    print output_filehandle "<table><tr style=\"background-color:lightgray\"><td><\/td>";
    for ($cc=1; $cc<$column_count-1; $cc++)
    {
	    if ($cc==5)
	    {
		    $period = "OT";
		}
	    elsif ($cc>5)
	    {
		    $period = "O".($cc-4);
		}
		else
		{
			$period = $cc;
		}
        print output_filehandle "<td style=\"width:20px; text-align:right\">$period<\/td>";
    }
    print output_filehandle "<td><\/td><td style=\"width:20px; text-align:right\">F<\/td><br>\n";

    print output_filehandle "<tr><td>$info{rteam}<\/td>";
    for ($cc=2; $cc<$column_count; $cc++)
    {
        print output_filehandle "<td style=\"text-align:right\">$road_linescore[$cc]<\/td>";
    }
    print output_filehandle "<td><\/td><td style=\"text-align:right\">$road_linescore[$column_count+1]<\/td><\/tr>\n";
    
    print output_filehandle "<tr><td>$info{hteam}<\/td>";
    for ($cc=2; $cc<$column_count; $cc++)
    {
        print output_filehandle "<td style=\"text-align:right\">$home_linescore[$cc]<\/td>";
    }
    print output_filehandle "<td><\/td><td style=\"text-align:right\">$home_linescore[$column_count+1]<\/td><\/tr>\n";

    print output_filehandle "<\/table>\n";
    
    @road_coach_line = parse_csv_line($coaches{rteam});
    @home_coach_line = parse_csv_line($coaches{hteam});

    print output_filehandle "<h4>Head Coaches: ";
    print output_filehandle "$info{rteam} - <a href=\"$br_coach_link\/$road_coach_line[2].html\">$road_coach_line[3] $road_coach_line[4]<\/a>";
    print output_filehandle ", ";
    print output_filehandle "$info{hteam} - <a href=\"$br_coach_link\/$home_coach_line[2].html\">$home_coach_line[3] $home_coach_line[4]<\/a>";
    print output_filehandle "<p>\n";
    print output_filehandle "</h4>\n";

    print output_filehandle "<h5>\n";

    if ($stats_type eq "basic")
    {
        if (($road_team_fouls > 0) && ($home_team_fouls > 0))
        {
            print output_filehandle "Team Fouls: <span style=\"color:gray\">$info{rteam} $road_team_fouls, $info{hteam} $home_team_fouls</span><br>\n";
        }    
    }

    # Omit the following fields if they are empty
    if ($info{techs} ne "") { print output_filehandle "Technical Fouls: <span style=\"color:gray\">$info{techs}</span><br>\n"; }
    if ($info{attendance} ne "") { print output_filehandle "Attendance: <span style=\"color:gray\">$info{attendance}</span><br>\n"; }
    if ($info{prelim} ne "") { print output_filehandle "Preliminary Game: <span style=\"color:gray\">$info{prelim}</span><br>\n"; }
    if ($info{event} ne "") { print output_filehandle "Special Event: <span style=\"color:gray\">$info{event}</span><br>\n"; }
    if ($info{ref1} ne "") { print output_filehandle "Referees: <span style=\"color:gray\">$info{ref1}, $info{ref2}</span><br>\n"; }
    if ($info{starttime} ne "") { print output_filehandle "Start Time: <span style=\"color:gray\">$info{starttime} $info{timezone}</span><br>\n"; }
    if ($info{radio} ne "") { print output_filehandle "Radio: <span style=\"color:gray\">$info{radio}</span><br>\n"; }
    if ($info{tv} ne "") { print output_filehandle "TV: <span style=\"color:gray\">$info{tv}</span>\n"; }
    if ($info{note} ne "") { print output_filehandle "Game Notes: <span style=\"color:gray\">$info{note}</span><br>\n"; }

#    if ($sources_note ne "") { print output_filehandle "<p style = \"font-size:50%\;\">Sources: $sources_note</p>\n"; }
    if ($sources_note ne "") { print output_filehandle "<p>Sources: <span style=\"color:gray\">$sources_note</p></span>\n"; }
    
    print output_filehandle "</h5>\n";
    print output_filehandle "<hr>\n";

} # end of sub dump_data_to_file()

# ===============================================================


$start_of_boxscore = "gamebxt";

# default filenames
$input_filename = "input.csv";
$output_filename_preamble = "output";

my $java_sorting = "off";

getopts('i:o:h:t:j:',\%cli_opt);


if (exists ($cli_opt{"i"}))
{
    $input_filename = $cli_opt{"i"};
}

if (exists ($cli_opt{"o"}))
{
    $output_filename_preamble = $cli_opt{"o"};
    $output_filename_preamble =~ s/.htm//; # strip .htm to preserve existing scripts
}

if (exists ($cli_opt{"h"}))
{
	usage();
	exit;
}

if (exists ($cli_opt{"j"}))
{
	$java_sorting = lc($cli_opt{"j"});
}

if (exists ($cli_opt{"t"}))
{
	$page_title = $cli_opt{"t"};
}
else
{
	print "Enter page title: ";
	$page_title = getstring();
}

# open for reading
if (!open(input_filehandle, "$input_filename")) 
{
        die "Can't open input file $input_filename\n";
}

# open for writing, creating if needed
$output_index_filename = $output_filename_preamble . ".htm";
if (!open(output_filehandle, ">$output_index_filename")) 
{
        close(input_filehandle);
        die "Can't open output file $output_index_filename\n";
}

# start setting up the html file
print output_filehandle Boxtop_HtmlHeader("$page_title Box Scores",$java_sorting);

print output_filehandle "<h3>For more seasons and details on this data, <a href=\"http://www.michaelhamel.net/boxtop-project\">click here<\/a><\/h3>\n";

my $first_gamebxt_read = "no";

# ####
# Step one - scan the input file to build index hashes, indexed by index_count
# ####
my %index_date, %index_hteam, %index_rteam, %index_hscore, %index_rscore, %index_title, %index_overtime, %index_gamenumber, %index_neutral_site;
my $index_count_for_first_playoff_game = 10000; # init to a very large number so that until we find the playoffsstarthere sentinel, we categorize all of the games as regular season

while ($line = <input_filehandle>)
{
    # read until we read a "gamebxt" which tells us we're done with the previous boxscore
    # but skip everything until after we read the first one
    if ($first_gamebxt_read eq "no")
    {
	    if ($line =~ /^$start_of_boxscore/)
	    {
		    # flip the flag, but ignore this line
		    $first_gamebxt_read = "yes";
		}
		# else just skip the line
	}			  
    elsif ($line =~ /^$start_of_boxscore/)
    {
        $index_count++;
        $index_neutral_site{$index_count} = "no";
    }
    elsif ($line =~ /^version/)
    {
        # ignore
    }
    elsif ($line =~ /^info/)
    {
        # split the line and add date and team names to hash (drop the rest on the floor)
        @this_line_array = parse_csv_line($line);
        
        # grab date
        if ($this_line_array[1] eq "date")
        {
            $index_date{$index_count} = $this_line_array[2];
            
            # this hash is used to track which days games were played on
            # must eliminate leading zeroes and put it back together again
            ($mn,$dy,$yr) = split(/\//, $index_date{$index_count});
            
            # strip any leading zeroes
            $mn =~ s/^0//g;
            $mn_padded = sprintf("%02d",$mn);
            $dy =~ s/^0//g;
            $dy_padded = sprintf("%02d",$dy);
            $yr =~ s/^0//g; # should never be a leading zero
            $this_day = join("/",$mn_padded,$dy_padded,$yr);
#            print "Game today! $this_day\n";           
            $game_days{$this_day}++;
        }
        elsif ($this_line_array[1] eq "neutral")
        {
            $index_neutral_site{$index_count} = "yes";
        }
        elsif ($this_line_array[1] eq "rteam")
        {
            $index_rteam{$index_count} = $this_line_array[2];
            
            $list_of_teams{$this_line_array[2]}++;
        }
        elsif ($this_line_array[1] eq "hteam")
        {
            $index_hteam{$index_count} = $this_line_array[2];

            $list_of_teams{$this_line_array[2]}++;
        }
        elsif ($this_line_array[1] eq "title")
        {
            $index_title{$index_count} = $this_line_array[2];
        }
        elsif ($this_line_array[1] eq "gamenumber")
        {
            $index_gamenumber{$index_count} = $this_line_array[2];
        }
    }
    elsif ($line =~ /^coach/)
    {
	    # ignore
    }
    elsif ($line =~ /^stat/)
    {
	    # ignore
    }
    elsif ($line =~ /^tstat/)
    {
	    # ignore
    }
    elsif ($line =~ /^playoffsstarthere/)
    {
        $index_count_for_first_playoff_game = $index_count+1;
    }
    elsif ($line =~ /^linescore/)
    {
        # split the line and add final score to hash
        @this_line_array = parse_csv_line($line);
        if ($this_line_array[1] eq "rteam")
        {
	        $index_rscore{$index_count} = $this_line_array[$#this_line_array];
    	}
        elsif ($this_line_array[1] eq "hteam")
        {
	        $index_hscore{$index_count} = $this_line_array[$#this_line_array];
    	}
    	
	    # figure out if this game is an overtime game
        $counter = 0;
        $found_colon = 0;
        $index_overtime{$index_count} = "";
        
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
	        $index_overtime{$index_count} = "OT";
        }
        elsif ($found_colon > 7)
        {
            $number_of_ot = $found_colon-6;
	        $index_overtime{$index_count} = $number_of_ot . "OT";
        }
    	
    }   	
}

close(input_filehandle);

($first_month,$first_day,$first_year) = split(/\//, $index_date{1});
($last_month,$last_day,$last_year) = split(/\//, $index_date{$index_count});

# strip any leading zeroes
$first_month =~ s/^0//g;
$last_month =~ s/^0//g;
$first_year =~ s/^0//g;

make_calendar_of_links($first_month,$last_month,$first_year);


print output_filehandle "<h2>Team-by-Team Results</h2>\n\n";
print output_filehandle "<h3>\n";
foreach $tm (sort keys %list_of_teams)
{
    # TBD - make this multiple columns later if desired
    $link_text = join("_", Boxtop_GetBRAbbreviationFromTeamName($tm),"results");
    print output_filehandle "<a href=#$link_text>$tm</a><br>\n";
}
print output_filehandle "</h3>\n";

# Team-by-team game listings
# Widths look screwed up now, but once everyone has a game vs. Conquistadors it should be ok (San Diego will be narrower)
foreach $tm (sort keys %list_of_teams)
{
    $games_for_this_team = 0;
    $wins = 0;
    $losses = 0;
    
    $team_link_text = join("_", Boxtop_GetBRAbbreviationFromTeamName($tm),"results");
    print output_filehandle "<a id=$team_link_text></a>\n";
    if ($java_sorting eq "on")
    {
        print output_filehandle "<h2>$tm</h2>\n";
        print output_filehandle "<h3>Regular Season</h3>\n";
        print output_filehandle "<h5><span style=\"color:gray\">Click on any column header to sort</span></h5>\n";
#        print output_filehandle "<p style = \"font-size:90%\;\">Click on any column header to sort</p>\n";
        print output_filehandle "<table cellspacing=5 class=\"tablesorter\">\n";
    }
    else
    {
        print output_filehandle "<h2>$tm</h2>\n<table cellspacing=5>\n";
        print output_filehandle "<h3>Regular Season</h3>\n";
        print output_filehandle "<table cellspacing=5>\n";
    }
    print output_filehandle "<thead><tr>";
    print output_filehandle "<th>Game</th><th>Date</th><th></th><th>Opponent</th><th></th><th>Tm</th><th>Opp</th><th>OT</th><th>W</th><th>L</th></tr></thead>\n";
    print output_filehandle "<tbody>\n";
    
    $playoffs_table_started = "no";
    
    for ($index_scan=1; $index_scan <= $index_count; $index_scan++)
    {
        $home = "";
        
        if ($tm eq $index_rteam{$index_scan})
        {
            $home = "no";
            if ($index_neutral_site{$index_scan} eq "yes")
            {
                $location = "N";
            }
            else
            {
                $location = "@";
            }
            $opponent = $index_hteam{$index_scan};
            $team_score = $index_rscore{$index_scan};
            $opponent_score = $index_hscore{$index_scan};
        }
        elsif ($tm eq $index_hteam{$index_scan})
        {
            $home = "yes";
            if ($index_neutral_site{$index_scan} eq "yes")
            {
                $location = "N";
            }
            else
            {
                $location = " ";
            }
            $opponent = $index_rteam{$index_scan};
            $team_score = $index_hscore{$index_scan};
            $opponent_score = $index_rscore{$index_scan};
        }
        # else, skip to next game
        
        if (($home eq "no") || ($home eq "yes"))
        {
            $games_for_this_team++;
            
            if (($index_scan >= $index_count_for_first_playoff_game) && ($playoffs_table_started eq "no"))
            {
                # close the regular season table and start the playoff table
                print output_filehandle "</tbody>\n";
                print output_filehandle "</table>\n";

                print output_filehandle "<h3>Playoffs</h3>\n";
                
                if ($java_sorting eq "on")
                {
                    print output_filehandle "<h5><span style=\"color:gray\">Click on any column header to sort</span></h5>\n";
                    print output_filehandle "<table cellspacing=5 class=\"tablesorter\">\n";
                }
                else
                {
                    print output_filehandle "<table cellspacing=5>\n";
                }                
                
                print output_filehandle "<thead><tr>";
                print output_filehandle "<th>Game</th><th>Date</th><th></th><th>Opponent</th><th></th><th>Tm</th><th>Opp</th><th>OT</th><th>Info</th></tr></thead>\n";
                print output_filehandle "<tbody>\n";
                
                $playoffs_table_started = "yes";
            }
            
            if ($team_score > $opponent_score)
            {
                $outcome = "W";
                $wins++;
            }
            else
            {
                $outcome = "L";
                $losses++;
            }
 
# 7/27 switched to Boxtop module                       
#            ($mon,$mday,$year) = split (/\//, $index_date{$index_scan});
#            $home_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($index_hteam{$index_scan});
#            $road_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($index_rteam{$index_scan});
#            $link_text = sprintf("Game_%02d_%02d_%s_%s",$mon,$mday,$home_abbrev,$road_abbrev);
            
#            ($mon1,$day1,$year1) = split('/',$index_date{$index_scan});
#            $padded_mon = sprintf("%02d",$mon1);
#            $link_text = $output_filename_preamble . "_" . $padded_mon . ".htm#" . Boxtop_GetGameLinkText($index_date{$index_scan},$index_hteam{$index_scan},$index_rteam{$index_scan},$index_gamenumber{$index_scan});
            $link_text = Boxtop_GetFullGameLinkText($index_date{$index_scan},$index_hteam{$index_scan},$index_rteam{$index_scan},$index_gamenumber{$index_scan},$output_filename_preamble);

            print output_filehandle "<tr onmouseover=\"this.style.backgroundColor = '#CCCCCC';\" onmouseout=\"this.style.backgroundColor = '#f7f6eb';\">\n";
            print output_filehandle "<td style=\"text-align:right\">$games_for_this_team</td><td style=\"text-align:right\"><a href=$link_text>$index_date{$index_scan}</a></td>\n";
            print output_filehandle "<td style=\"text-align:center\">$location</td><td>$opponent</td><td style=\"text-align:center\">$outcome</td>\n";
            print output_filehandle "<td style=\"text-align:right\">$team_score</td><td style=\"text-align:right\">$opponent_score</td><td style=\"text-align:right\">$index_overtime{$index_scan}</td>";
            if ($index_scan >= $index_count_for_first_playoff_game)
            {
                # print title of playoff game instead of W/L record
                print output_filehandle "<td>$index_title{$index_scan}</td>\n";
            }
            else
            {
                print output_filehandle "<td style=\"text-align:right\">$wins</td><td style=\"text-align:right\">$losses</td>\n";
            }
            print output_filehandle "</tr>\n";
        }
    }
    
    print output_filehandle "</tbody>\n";
    print output_filehandle "</table>\n";
   
    print output_filehandle "<hr>\n";
}

# done with index page
print output_filehandle Boxtop_HtmlFooter("ababox2html.pl");
print output_filehandle "\n<\/html>\n";
close(output_filehandle);
print "Created index file: $output_index_filename\n";

# ####
# Step two - scan the input file again to build the actual boxscores
# ####

# re-open for reading
if (!open(input_filehandle, "$input_filename")) 
{
        die "Can't re-open input file $input_filename\n";
}

my $ref_count = 1;

$output_filename = "empty";

$first_gamebxt_read = "no";

while ($line = <input_filehandle>)
{
    # read until we read a "gamebxt" which tells us to loop back around to the next boxscore
    if ($first_gamebxt_read eq "no")
    {
	    if ($line =~ /^$start_of_boxscore/)
	    {
		    # flip the flag, but ignore this line
		    $first_gamebxt_read = "yes";
		}
		# else just skip the line
	}
    elsif ($line =~ /^$start_of_boxscore/)
    {
        ($mon,$mday,$year) = split('/',$info{date});
        $month_of_game = lc(substr (Month_to_Text($mon),0,3));
        $month_string = $month_of_game . ".htm";
        if (($output_filename eq "empty") || ($output_filename !~ /$month_string$/))
        {
            if ($output_filename ne "empty")
            {
                # close the previous month's file
                print output_filehandle Boxtop_HtmlFooter("ababox2html.pl");
                print output_filehandle "\n<\/html>\n";
                close (output_filenandle);
                print "Monthly File $output_filename created.\n";              
            }
            
            # open new file for writing, creating if needed
            $output_filename = $output_filename_preamble . $month_of_game . ".htm";
            if (!open(output_filehandle, ">$output_filename")) 
            {
                close(input_filehandle);
                die "Can't open output file $output_filename\n";
            }
#            print "Opened: $output_filename\n";

            # start setting up the html file
            print output_filehandle Boxtop_HtmlHeader("$page_title Box Scores",$java_sorting);

            $month_of_game_text = Month_to_Text($mon);
            print output_filehandle "<h2>$month_of_game_text $year<\/h2>\n";
            print output_filehandle "<h3><a href=$output_index_filename>Back to $page_title index</a><\/h3>\n";
            print output_filehandle "<h3>For more seasons and details on this data, <a href=\"http://www.michaelhamel.net/boxtop-project\">click here<\/a><\/h3>\n";
            print output_filehandle "<hr>\n";
        }
        
        dump_data_to_file();
        $ref_count = 1;
        
        # clear all hashes
        %info = ();
        %coaches = ();
        %team_stats = ();
        %linescores = ();
        %road_player_stats = ();
        %home_player_stats = ();
        $sources_note = "";
    }
    elsif ($line =~ /^version/)
    {
        # ignore
    }
    elsif ($line =~ /^info/)
    {
        # split the line and add to hash, but save a copy of the original line because parse_csv_line() destroys it
        $save_this_line = $line;
        @this_line_array = parse_csv_line($line);
        
        # special case for refs
        if ($this_line_array[1] eq "ref")
        {
            $info{$this_line_array[1].$ref_count} = $this_line_array[2];
            $ref_count++;
        }
        # special case for game notes (concatenate and allow for commas inside the following text string)
        elsif (($this_line_array[1] eq "note") ||
        	   ($this_line_array[1] eq "event") ||
        	   ($this_line_array[1] eq "prelim") ||
        	   ($this_line_array[1] eq "techs"))
        {
	        # the following works, but we want to insert '...' only in between entries, not after last entry
	        # it also does not support commas inside the note
#	        $info{note} = $info{note} . $this_line_array[2];

			# grab everything except for "info,note," and remove any CR/LF
			# note, event, prelim are all different lengths so we need to use correct width
			$complete_note = substr($save_this_line,(6 + length($this_line_array[1])));
			chomp($complete_note);    
			
#			print ("This is $this_line_array[1] $complete_note\n");

	        if (exists($info{$this_line_array[1]}))
	        {
		        # Add to output
		        $info{$this_line_array[1]} = $info{$this_line_array[1]} . " ... " . $complete_note;
	    	}
	    	else
	    	{
		    	# First note for this game
	            $info{$this_line_array[1]} = $complete_note;
	    	}
    	}
        else
        {
            $info{$this_line_array[1]} = $this_line_array[2];
        }
    }
    elsif ($line =~ /^coach/)
    {
        # split the line and add to hash
        $copyline = $line;
        @this_line_array = parse_csv_line($line);
        $coaches{$this_line_array[1]} = $copyline;
    }
    elsif ($line =~ /^stat/)
    {
        # split the line and add to hash
        $copyline = $line;
        @this_line_array = parse_csv_line($line);
        if ($this_line_array[1] eq "rteam")
        {
            $road_player_stats{$this_line_array[3]} = $copyline;
        }
        else
        {
            $home_player_stats{$this_line_array[3]} = $copyline;
        }
    }
    elsif ($line =~ /^tstat/)
    {
        # split the line and add to hash
        $copyline = $line;
        @this_line_array = parse_csv_line($line);
        $team_stats{$this_line_array[1]} = $copyline;
    }
    elsif ($line =~ /^linescore/)
    {
        # split the line and add to hash
        $copyline = $line;
        @this_line_array = parse_csv_line($line);
        $linescores{$this_line_array[1]} = $copyline;
    }   
    elsif ($line =~ /^sources/)
    {
        @this_line_array = parse_csv_line($line);
        $sources_note = $this_line_array[1];
    }


} # end of main loop


($mon,$mday,$year) = split('/',$info{date});
$month_of_game = lc(substr (Month_to_Text($mon),0,3));
if (($output_filename eq "empty") || ($output_filename !~ /$month_of_game.htm/))
{
    if ($output_filename ne "empty")
    {
        # close the previous month's file
        print output_filehandle Boxtop_HtmlFooter("ababox2html.pl");
        print output_filehandle "\n<\/html>\n";
        close (output_filenandle);
        print "File $output_filename created.\n";              
    }
    
    # open new file for writing, creating if needed
    $output_filename = $output_filename_preamble . $month_of_game . ".htm";
    if (!open(output_filehandle, ">$output_filename")) 
    {
        close(input_filehandle);
        die "Can't open output file $output_filename\n";
    }

    # start setting up the html file
    print output_filehandle Boxtop_HtmlHeader("$page_title Box Scores",$java_sorting);

    $month_of_game_text = Month_to_Text($mon);
    print output_filehandle "<h2>$month_of_game_text $year<\/h2>\n";
    print output_filehandle "<h3><a href=$output_index_filename>Back to $page_title index</a><\/h3>\n";
    print output_filehandle "<h3>For more seasons and details on this data, <a href=\"http://www.michaelhamel.net/boxtop-project\">click here<\/a><\/h3>\n";
    print output_filehandle "<hr>\n";
}

dump_data_to_file();

print output_filehandle Boxtop_HtmlFooter("ababox2html.pl");
print output_filehandle "\n<\/html>\n";
close (output_filenandle);
print "Last Monthly File $output_filename created.\n";
