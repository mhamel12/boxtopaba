# boxtopaba
Scripts for processing basketball box scores

The scripts in this repository were used during the processing of ABA box scores but could be modified to work with basketball games in general. Every box score in ABA league history, from 1967-68 through 1975-76, was digitized using these scripts. The results of this work are posted at http://michaelhamel.net/boxtop-aba/ but the raw data was also provided to Pro Basketball Reference in 2015 (http://www.sports-reference.com/blog/2015/03/aba-box-scores-splits-added/) and 2016 (http://www.sports-reference.com/blog/2016/02/find-every-box-score-in-aba-history/).

These scripts are no longer actively in use or development, but I am posting them on GitHub in case they can be useful for someone.

All of these scripts were run using Perl 5.10.1 as obtained from ActiveState years ago.

ababoxtop.pl - Input games and save them in the Boxtop basketball format

BoxtopInfo.htm - Explanation of the Boxtop basketball file format

abacrosscheck.pl - Script to check a Boxtop file for inconsistencies, including cross-checks of season totals vs. totals from all entered box scores.

ababox2html.pl - Create HTML pages, one per month, containing box scores and a calendar of links
ababox2html_singlepage.pl - Older version of ababox2html.pl that created one HTML page per season

ababgames.pl - Create game logs for all players and coaches
abagamelog.pl - Create game log for a specific player or coach

abateamsplits.pl - Create team reports that include complete season statistics and statistics (splits) against each opponent.

abacleancsv.pl - Boxtop files can be loaded into Excel because they are .csv files, and it can be convenient to edit them as .csv files because Excel will display the data by columns. But Excel likes to add quotes and extra commas when you save the file. This script will clean up these changes, restoring the file so it is compatible with the HTML and game log scripts.

boxtop.pm - Some generic utilities, but also a list of team names/abbreviations that is ABA-specific
