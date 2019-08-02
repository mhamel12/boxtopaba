package Boxtop;

use strict;
use Date::Calc qw(:all);
require Exporter;

# use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %Boxtop_br_team_page_from_full_name_hash);

our $VERSION     = 1.00;
our @ISA         = qw(Exporter);
our @EXPORT      = qw(Boxtop_GetBRPlayerPageLink Boxtop_GetBRAbbreviationFromTeamName Boxtop_GetBRTeamPageLink Boxtop_GetGameLinkText Boxtop_GetFullGameLinkText Boxtop_HtmlHeader Boxtop_HtmlFooter);

# ===================================================================

my $br_player_link = "http:\/\/www.basketball-reference.com\/players";
my $br_coach_link = "http:\/\/www.basketball-reference.com\/coaches";
my $br_team_page_preamble = "http:\/\/www.basketball-reference.com\/teams\/";

# Full list of ABA abbreviations from BR.com
my %Boxtop_br_team_page_from_full_name_hash =
(
    "Pittsburgh Pipers" => "PTP",
    "Minnesota Muskies" => "MNM",
    "Indiana Pacers" => "INA",
    "Kentucky Colonels" => "KEN",
    "New Jersey Americans" => "NJA",
    "New Orleans Buccaneers" => "NOB",
    "Dallas Chaparrals" => "DLC",
    "Denver Rockets" => "DNR",
    "Denver Nuggets" => "DNA",
    "Houston Mavericks" => "HSM",
    "Anaheim Amigos" => "ANA",
    "Oakland Oaks" => "OAK",
    "Miami Floridians" => "MMF",
    "Minnesota Pipers" => "MNP",
    "New York Nets" => "NYA",
    "Oakland Oaks" => "OAK",
    "Los Angeles Stars" => "LAS",
    "Carolina Cougars" => "CAR",
    "Washington Capitols" => "WSA",
    "Virginia Squires" => "VIR",
    "The Floridians" => "FLO",
    "Utah Stars" => "UTS",
    "Texas Chaparrals" => "TEX",
    "Pittsburgh Condors" => "PTC",
    "Memphis Pros" => "MMP",
    "Memphis Tams" => "MMT",
    "San Diego Conquistadors" => "SDA",
    "Spirits of St. Louis" => "SSL",
    "Memphis Sounds" => "MMS",
    "San Antonio Spurs" => "SAA",
    "San Diego Sails" => "SDS",
    
);

sub Boxtop_GetBRPlayerPageLink($)
{
    my $id = $_[0];
    
    my $ch = substr($id,0,1);
	return "<a href=\"$br_player_link\/$ch\/$id.html\">";

} # end of sub Boxtop_GetBRPlayerPageLink()   

sub Boxtop_GetBRAbbreviationFromTeamName($)
{
    my $team_name = $_[0];
    
    if (exists $Boxtop_br_team_page_from_full_name_hash{$team_name})
    {
        return $Boxtop_br_team_page_from_full_name_hash{$team_name};
    }   

#    print "$team_name\n";
    return "INVALID";

} # end of Boxtop_GetBRAbbreviationFromTeamName()

sub Boxtop_GetBRTeamPageLink($$)
{
    my $team_name = $_[0];
    my $date_of_first_game = $_[1];

#    print ("Date: $date_of_first_game\n");
        
    # now we need to build a link to this specific game, for use in the team-by-team game listings
    my ($mon,$mday,$year) = split('/',$date_of_first_game );
    
    my $season_year = $year;
    if ($mon > 7) # game took place after July, so this is the following season (October 1956 game is during "1957" season from BR.com's perspective
    {
        $season_year++;
    }    

    return ("<a href=" . $br_team_page_preamble . Boxtop_GetBRAbbreviationFromTeamName($team_name) . "\/" . $season_year . ".html>"); 

} # end of sub Boxtop_GetBRTeamPageLink() 

# ===================================================================

# Use this when you need just a relative link to a single box score within a box score page
sub Boxtop_GetGameLinkText($$$$)
{
    my $game_date = $_[0];
    my $home_team = $_[1];
    my $road_team = $_[2];
    my $game_number = $_[3]; # usually blank, but for January 24, 1976 we have two games for Nets vs. Squires

  	my ($mon,$mday,$year) = split(/\//, $game_date);
    
    my $home_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($home_team);
    my $road_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($road_team);
    my $link_text = sprintf("Game%s_%02d_%02d_%s_%s",$game_number,$mon,$mday,$home_abbrev,$road_abbrev);
    
    return($link_text);
}

# ===================================================================

# Use this when you need a full link to an individual boxscore
sub Boxtop_GetFullGameLinkText($$$$$)
{
    my $game_date = $_[0];
    my $home_team = $_[1];
    my $road_team = $_[2];
    my $game_number = $_[3]; # usually blank, but for January 24, 1976 we have two games for Nets vs. Squires
    my $page_preamble = $_[4];

  	my ($mon,$mday,$year) = split(/\//, $game_date);
    
  	my $month_of_game_abbrev = lc(substr (Month_to_Text($mon),0,3));
  	
    my $home_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($home_team);
    my $road_abbrev =  Boxtop_GetBRAbbreviationFromTeamName($road_team);
    my $link_text = sprintf("%s%s.htm#Game%s_%02d_%02d_%s_%s",$page_preamble,$month_of_game_abbrev,$game_number,$mon,$mday,$home_abbrev,$road_abbrev);
    
    return($link_text);
}

# ===================================================================

sub Boxtop_HtmlHeader($$)
{
    my $page_title = $_[0];
    my $java_sorting = $_[1]; # on or off
    
    my $header;

	# start setting up the html file
	$header = "<html>\n<head>\n";
#	print output_filehandle "<style type=\"text/css\">\n<!--\nh1 { font-family: Verdana, sans-serif;\n   }\nh2 { font-family: Verdana, sans-serif;\n   }\n-->\n<\/style>\n";

	$header = $header . "<style type=\"text/css\">\n<!--\n";

    $header = $header . "h1 { font-family: Georgia, Verdana, Arial, sans-serif;\n   }\n";
    $header = $header . "h2 { font-family: Georgia, Verdana, Arial,  sans-serif;\n   }\n";
    $header = $header . "h3 { font-family: Georgia, Verdana, Arial,  sans-serif;\n   }\n";
    $header = $header . "h4 { font-family: Verdana, Arial,  sans-serif;\n   }\n";
    $header = $header . "h5 { font-family: Verdana, Arial,  sans-serif;\n   }\n";

    # New link formatting 10/26/2016 - don't override underlining
    
    $header = $header . "a:link { color: #0066cc;\n text-decoration: none;\n   }\n";
    $header = $header . "a:visited { color: #000066;\n text-decoration: none;\n   }\n";
    $header = $header . "a:hover { color: #0066cc;\n text-decoration: underline;\n   }\n";
    $header = $header . "a:active { color: #0066cc;\n text-decoration: underline;\n   }\n";
    
	# On 10/26/2016 I changed the table text to Helvetica to get rid of the misaligned "3" in "3FGA" which I never liked.
#    $header = $header . "table, th, td { border:1px solid gray; border-collapse:collapse\n }\n";
#    $header = $header . "td { font-family: Georgia, Verdana, Arial,  sans-serif;\n   }\n";
#    $header = $header . "th { font-family: Georgia, Verdana, Arial,  sans-serif; color: black\n   }\n";
#    $header = $header . "thead { font-family: Georgia, Verdana, Arial,  sans-serif; background-color: lightgray\n   }\n";
    
    $header = $header . "table, th, td { border:1px solid gray; border-collapse:collapse\n }\n";
    $header = $header . "td { font-family: Helvetica, Arial,  sans-serif;\n   }\n";
    $header = $header . "th { font-family: Helvetica, Arial,  sans-serif; color: black\n   }\n";
    $header = $header . "thead { font-family: Helvetica, Arial,  sans-serif; background-color: lightgray\n   }\n";
    
    # The following line adds shading for column header if sorting is active
    $header = $header . "table.tablesorter thead tr .headerSortDown, table.tablesorter thead tr .headerSortUp {\n background-color: #8dbdd8;\n   }\n";
    
	$header = $header . "-->\n<\/style>\n";
	
	if ($java_sorting eq "on")
    {
        $header = $header . "<script type=\"text/javascript\" src=\"../javatools/jquery-latest.js\"></script>\n";
        $header = $header . "<script type=\"text/javascript\" src=\"../javatools/jquery.tablesorter.js\"></script>\n"; 
        
        $header = $header . "<script type=\"text/javascript\" id=\"js\">\$(document).ready(function() {\n";
        $header = $header . "                                           \$(\"table\").tablesorter();\n";
        $header = $header . "}); </script>\n";
    }
    
	$header = $header . "<title>$page_title - BOXTOP<\/title>\n";
	$header = $header . "<\/head>\n";
	$header = $header . "<h1>$page_title<\/h1>\n";
	
	return ($header);
}

# ===================================================================

sub Boxtop_HtmlFooter1($)
{
    my $script_name = $_[0];

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

	my $dateline = sprintf "<p><h5><span style=\"color:gray\">Web page created at %02d:%02d:%02d on %02s\/%02d\/%4d using $script_name based on <a href=\"http://www.michaelhamel.net/boxtop-project\">boxtop format data<\/a>, (c) 2010-2016 <a href=\"http://www.michaelhamel.net/bio\">Michael Hamel<\/a>.<\/span><\/h5>\n",$hour,$min,$sec,$mon+1,$mday,$year+1900;
	
	my $footer = "<p>This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.<br>To view a copy of this license, visit <a href=\"http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/\">http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/<\/a>\n";
	$footer = $footer . "<p>Recommended Citation: The information used here was obtained free of charge from and is copyrighted by the <a href=\"http://www.michaelhamel.net/boxtop-project\">Basketball BOXTOP Project<\/a>.\n";
	$footer = $footer . "<p>Major Sources: The Sporting News (TSN), <a href=\"http://www.Basketball-Reference.com\">Basketball-Reference.com</a>, <a href=\"http://www.remembertheaba.com\">RememberTheABA.com</a>, <a href=\"http://www.shrpsports.com\">ShrpSports.com</a>, <a href=\"http://www.NBAStats.net\">NBAStats.net</a> game logs (NGL), and <a href=\"http://webuns.chez-alice.fr/home.htm\">http://webuns.chez-alice.fr/home.htm</a> (W, referenced by <a href=\"http://www.apbr.org\">APBR.org</a>).\n";
	$footer = $footer . "<p>Newspaper Abbreviations: New York Times (NYT), Indianapolis Star (IS), The Courier-Journal (CJ), Los Angeles Times (LAT).\n";
	$footer = $footer . $dateline;

	return($footer);
} # end of sub Boxtop_HtmlFooter1()

sub Boxtop_HtmlFooter($)
{
    my $script_name = $_[0];

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

	my $dateline = sprintf "<p><h5><span style=\"color:gray\">Web page created at %02d:%02d:%02d on %02s\/%02d\/%4d using $script_name based on <a href=\"http://www.michaelhamel.net/boxtop-project\">boxtop format data<\/a>, (c) 2010-2016 <a href=\"http://www.michaelhamel.net/bio\">Michael Hamel<\/a>.<\/span><\/h5>\n",$hour,$min,$sec,$mon+1,$mday,$year+1900;

	my $footer = "<table style=\"border: 0px\"><tr><td style=\"width:75px; border: 0px\"><img src=\"boxtop_70s_logo_footer.png\"></td><td style=\"border: 0px\">\n";
	
	$footer = $footer . "<p>This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.<br>To view a copy of this license, visit <a href=\"http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/\">http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/<\/a>\n";
	$footer = $footer . "<p>Recommended Citation: The information used here was obtained free of charge from and is copyrighted by the <a href=\"http://www.michaelhamel.net/boxtop-project\">Basketball BOXTOP Project<\/a>.\n";
	$footer = $footer . "<p>Major Sources: The Sporting News (TSN), <a href=\"http://www.Basketball-Reference.com\">Basketball-Reference.com</a>, <a href=\"http://www.remembertheaba.com\">RememberTheABA.com</a>, <a href=\"http://www.shrpsports.com\">ShrpSports.com</a>, <a href=\"http://www.NBAStats.net\">NBAStats.net</a> game logs (NGL), and <a href=\"http://webuns.chez-alice.fr/home.htm\">http://webuns.chez-alice.fr/home.htm</a> (W, referenced by <a href=\"http://www.apbr.org\">APBR.org</a>).\n";
	$footer = $footer . "<p>Newspaper Abbreviations: New York Times (NYT), Indianapolis Star (IS), The Courier-Journal (CJ), Los Angeles Times (LAT), St. Louis Post-Dispatch (SPD), Newport News (Virginia) Daily Press (NNDP).\n";
	$footer = $footer . $dateline;
	
	$footer = $footer . "</td></tr></table>\n";

	return($footer);
} # end of sub Boxtop_HtmlFooter()