# ===============================================================
# 
# ababgames.pl
#
# (c) 2011 Michael Hamel
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of this license, visit # http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
#
# Version history
# 08/07/2011  1.0  MH  Initial version
# 07/18/2014  1.1  MH  Rework for ABA with new table format
#
# ===============================================================


#! usr/bin/perl
use Getopt::Std;
use Boxtop;

my $output_filename;

# ===============================================================

sub usage
{
    print "\nCreate game logs for ALL players and coaches based on boxtop file(s).";
    print "\nOutput is written to an html file.\n";
    
    print "\n";
    print "\nUSAGE:";
    print "\n ababgames.pl -f configuration file [-o outputfilename] [-t output file title]";
    print "\n           [-r lastnamerange] [-j java sorting on|off]";
    print "\n\n";
    print "\n IMPORTANT: You must have a copy of abagamelog.pl in the same directory";
    print "\n            where you are running this script.";
    print "\n";
    print "\n Default output filename is log.htm unless specified.";
    print "\n Default title is the outputfilename unless specified.";
    print "\n Range = 'ad' would create output with last names A-D";
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

# ===============================================================

$br_player_link = "http:\/\/www.basketball-reference.com\/players";
$br_coach_link = "http:\/\/www.basketball-reference.com\/coaches";

# ===============================================================

sub add_html_footer()
{
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

	print output_filehandle "<hr><p>This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.<br>To view a copy of this license, visit <a href=\"http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/\">http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/<\/a>\n";
	printf output_filehandle "<p>Web page created at %02d:%02d:%02d on %02s\/%02d\/%4d using ababgames.pl and abagamelog.pl based on boxtop format data, (c) 2010-2014 Michael Hamel.\n",$hour,$min,$sec,$mon+1,$mday,$year+1900;
}
# end of sub add_html_footer()

# ===============================================================


sub print_game_log_index()
{
    # Assume the rest of the filenames follows this convention, as defined in ABARelease.bat :
    #  aba_A_log_index.html
    
    # Also assumes no players ending in U, X, Y
    
    print output_filehandle "<hr>\n";
    print output_filehandle "<table style=\"border:0px; padding:10px\">\n"; # override border property in stylesheet
    print output_filehandle "<tr>\n";
    print output_filehandle "<td style=\"border:0px; padding:10px\">Game Log Index: <\/td>\n";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_A_log_index.html\">A<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_B_log_index.html\">B<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_C_log_index.html\">C<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_D_log_index.html\">D<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_E_log_index.html\">E<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_F_log_index.html\">F<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_G_log_index.html\">G<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_H_log_index.html\">H<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_I_log_index.html\">I<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_J_log_index.html\">J<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_K_log_index.html\">K<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_L_log_index.html\">L<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_M_log_index.html\">M<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_N_log_index.html\">N<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_O_log_index.html\">O<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_P_log_index.html\">P<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_Q_log_index.html\">Q<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_R_log_index.html\">R<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_S_log_index.html\">S<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_T_log_index.html\">T<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\">U<\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_V_log_index.html\">V<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_W_log_index.html\">W<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\">X<\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_Y_log_index.html\">Y<\/a><\/td>";
    print output_filehandle "<td style=\"text-align:center; border:0px; padding:10px\"><a href=\"aba_Z_log_index.html\">Z<\/a><\/td>";
    print output_filehandle "<\/tr>\n";
    print output_filehandle "<\/table>\n";
    print output_filehandle "<hr>\n";
    
}
# end of sub print_game_log_index()

##########################################################################
#
# Parse command line arguments
#
##########################################################################


$start_of_boxscore = "gamebxt";

# default filenames
@input_filename_array;
@html_link_filename_array;

my $java_sorting = "off";

getopts('f:o:h:t:r:j:',\%cli_opt);

if (exists ($cli_opt{"h"}))
{
	usage();
	exit;
}

if (exists ($cli_opt{"j"}))
{
	$java_sorting = lc($cli_opt{"j"});
}

if (exists ($cli_opt{"o"}))
{
    $output_filename = $cli_opt{"o"};
}
else # use default name for output file
{
	$output_filename = "log.htm";
}

if (exists ($cli_opt{"t"}))
{
    $output_title = $cli_opt{"t"};
}
else # use default title for output file
{
	$output_title = $output_filename;
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
#		print "Config: $line\n";
		@this_line_array = parse_csv_line($line);
		push(@input_filename_array,$this_line_array[0]);
		push(@html_link_filename_array,$this_line_array[1]);
	}

	close(config_filehandle);
}
else
{
	die "Config file is a required argument\n";
}

if (exists ($cli_opt{"r"}))
{
	$range = lc($cli_opt{"r"});
}
else
{
	$range = "az";
}
$last_names_greater_or_equal_to = substr($range,0,1);
$last_names_less_or_equal_to = substr($range,1,1);

##########################################################################
#
# Finished with argument parsing, let's get to work
#
# Step One: Build list of player and coach ids
#
##########################################################################

my $temp_filename = "BoxtopIds.tmp";

# open for writing, creating if needed
if (!open(temp_filehandle, ">$temp_filename")) 
{
        die "Can't open temp file $temp_filename\n";
}

my %id_hash = ();

foreach $element (@input_filename_array)
{
	# open for reading
	if (!open(input_filehandle, "$element")) 
	{
	        die "Can't open input file $element\n";
	}
	
	while ($line = <input_filehandle>)
	{
	    if ($line =~ /^coach/)
	    {
	        # split the line and add to hash
	        @this_line_array = parse_csv_line($line);
	        $id = $this_line_array[2];
			$firstname = $this_line_array[3];
			$lastname = $this_line_array[4];
			
			$first_letter = lc(substr($id,0,1));
			if (($last_names_greater_or_equal_to le $first_letter) && ($first_letter le $last_names_less_or_equal_to))
			{
				if (exists($id_hash{$id}))
		        {
			        # This is just a sanity check to look for misspellings
			        if ($id_hash{$id} ne join(" ",$firstname,$lastname))
			        {
				        print "Coach Mismatch $id hash=$id_hash($id) but this entry = $firstname $lastname\n";
			    	}
		    	}
		    	else # add to hash
		    	{
			    	$id_hash{$id} = join(" ",$firstname,$lastname);
		    	}
	    	}
		}
	    elsif ($line =~ /^stat/)
	    {
	        # split the line and add to hash
	        @this_line_array = parse_csv_line($line);
	        $id = $this_line_array[3];
			$firstname = $this_line_array[4];
			$lastname = $this_line_array[5];
		
			$first_letter = lc(substr($id,0,1));
			if (($last_names_greater_or_equal_to le $first_letter) && ($first_letter le $last_names_less_or_equal_to))
			{
				if (exists($id_hash{$id}))
		        {
			        # This is just a sanity check to look for misspellings
			        if ($id_hash{$id} ne join(" ",$firstname,$lastname))
			        {
				        print "Mismatch $id hash=$id_hash{$id} but this entry = $firstname $lastname\n";
			    	}
		    	}
		    	else # add to hash
		    	{
			    	$id_hash{$id} = join(" ",$firstname,$lastname);
		    	}
	    	}
	    }
	}
}


# Sort the hash and dump to temp file
foreach $key (sort keys %id_hash)
{
#	print temp_filehandle "$key\n"; did not need name with one page per letter
	print temp_filehandle "$key,$id_hash{$key}\n";
}


close (temp_filehandle);

###############################################################
#
# Step Two: Now re-open the tmp file and pass the ids to abagamelog.pl
#
###############################################################

# open temp file for reading
if (!open(temp_filehandle, "$temp_filename")) 
{
        die "Can't open temp file $temp_filename\n";
}

# open the output file for writing, creating if needed
if (!open(output_filehandle, ">$output_filename")) 
{
        die "Can't open output file $output_filename\n";
}

print output_filehandle Boxtop_HtmlHeader($output_title,$java_sorting);

print_game_log_index();

# close(output_filehandle);

$first_char = "";
$new_first_char = "";

# $common_title = "\"ABA Game Logs\"";
$common_title = "ABA Game Logs";

# Main loop starts here
while ($line = <temp_filehandle>)
{
	chop $line; # remove CR/LF

	# Print an alphabet soup for a progress bar	
	$new_first_char = substr($line,0,1);
	if ($new_first_char ne $first_char)
	{
		$first_char = $new_first_char;
		print "$first_char";
	}
	
	@this_line_array = parse_csv_line($line);
	$id = $this_line_array[0];
	$name = $this_line_array[1];
	
	# The following line creates one big file per first letter of last name but has
	# not been tested since we added support for creating individual pages per person
# `abagamelog.pl -p $line -f $config_file -o $output_filename -j $java_sorting -a`;

    $individual_page_filename = "aba_log_" . $id . ".htm";
    $individual_page_title = $name . " " . $common_title;
#	`abagamelog.pl -p $id -f $config_file -o $individual_page_filename -j $java_sorting -t $common_title`;
	`abagamelog.pl -p $id -f $config_file -o $individual_page_filename -j $java_sorting -t \"$individual_page_title\"`;

	# add to table of links on the index page
	$check_if_coach = substr($id, -1); # if last digit of id is "c", this person is a coach
	if ($check_if_coach eq "c")
	{
    	print output_filehandle "<a href=\"$individual_page_filename\">$name (coach)</a><br>\n";
    }
    else
	{
    	print output_filehandle "<a href=\"$individual_page_filename\">$name</a><br>\n";
    }
}

print "\n";

# open the output file for writing, appending
# if (!open(output_filehandle, ">>$output_filename")) 
#{
#	die "Can't open output file $output_filename\n";
#}

# add_html_footer();
print output_filehandle "<hr>\n";
print output_filehandle Boxtop_HtmlFooter("ababgames.pl and abagamelog.pl");

close (output_filehandle);

close (temp_filehandle);

print "File $output_filename created.\n";
