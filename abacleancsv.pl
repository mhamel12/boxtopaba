# ===============================================================
# 
# abacleancsv.pl
#
# (c) 2010-2016 Michael Hamel
#
# This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License. To view a copy of this license, visit # http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
#
# Version history
# 06/04/2016  1.0  MH  Initial version, designed to remove extra commas and fix date changes introduced if Excel is used to edit the .csv file
#
# ===============================================================

#! usr/bin/perl
use Getopt::Std;
use lib '../tools';
use Boxtop;
use Date::Calc qw(:all);


# ===============================================================


sub usage
{
    print "Clean a BOXTOP .csv file\n";
    print "Remove extra commas and fix date changes introduced if Excel is used to edit the .csv file.n";
    print "\n";
    print "Output is written in .csv format\n";
   
    print "\n";
    print "\nUSAGE:\n";
    print "abacleancsv.pl [-i inputfilename] [-o outputfilename]";
    print "\n";
    print " Defaults:\n";
    print "  Input file: input.csv   Output file: input_clean.csv\n\n";
   
}
# end of sub usage()

# ===============================================================

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

# default filenames
$input_filename = "input.csv";
$output_filename = "output.csv";

getopts('i:o:h:',\%cli_opt);


if (exists ($cli_opt{"i"}))
{
    $input_filename = $cli_opt{"i"};
}

if (exists ($cli_opt{"o"}))
{
    $output_filename = $cli_opt{"o"};
}
else
{
    @input = split (/\./, $input_filename);
    $output_filename = $input[0] . "_clean.csv";
}

if (exists ($cli_opt{"h"}))
{
	usage();
	exit;
}

# open for writing, creating if needed
if (!open(output_filehandle, ">$output_filename")) 
{
        die "Can't open output file $output_filename\n";
}


if (!open(input_filehandle, "$input_filename"))
{
	print "Unable to open $input_filename\n";
    close(output_filehandle);
	exit;
}

while ($line = <input_filehandle>)
{
    # At a minimum, we need to:
    # 1. Fix date by adding the leading zeros back in for single-digit month and day
    # 2. Remove lines that just consist of commas (\S)
    
    $line =~ s/\"//g; # remove any quote characters
    
    $copyline = $line;
    @this_line_array = parse_csv_line($line);
	$column_count = $#this_line_array - 1;
	
	$printed_line_to_output_file = "no";    
	
	$replace_line_with_a_blank_line = "yes";
    for ($a=0; $a<$column_count; $a++)
    {
        if ($this_line_array[$a] =~ /\S/)
        {
            # found a non-whitespace character
            $replace_line_with_a_blank_line = "no";
        }
    }
    
    if ($replace_line_with_a_blank_line eq "yes")
    {
        print output_filehandle "\n";
        $printed_line_to_output_file = "yes";
    }
    elsif ($this_line_array[0] eq "gamebxt")
    {
        print output_filehandle "gamebxt\n";
        $printed_line_to_output_file = "yes";
    }   
    elsif ($this_line_array[0] eq "version")
    {
        print output_filehandle "version,$this_line_array[1]\n";
        $printed_line_to_output_file = "yes";
    }   
    elsif ($this_line_array[0] eq "info")
    {   
        if ($this_line_array[1] eq "date")
        {
            my ($mon,$mday,$year) = split(/\//, $this_line_array[2]);
            $padded_month = sprintf("%02d",$mon); # add leading zero for 6/10/1973 
            $padded_day = sprintf("%02d",$mday); # add leading zero for 11/1/1973
            print output_filehandle "info,date,$padded_month\/$padded_day\/$year\n";
            $printed_line_to_output_file = "yes";
        }
        elsif (($this_line_array[1] eq "note") ||
               ($this_line_array[1] eq "prelim") ||
               ($this_line_array[1] eq "event") ||
               ($this_line_array[1] eq "techs"))
        {
            # these are free-form text fields which could include commas so we cannot enforce strict number of columns
            $copyline =~ s/\,{2}//g;
            $copyline =~ s/\,$//g;
        }
        elsif ($this_line_array[1] eq "neutral")
        {
            print output_filehandle "$this_line_array[0],$this_line_array[1]\n";
            $printed_line_to_output_file = "yes";
        }
        else
        {
            # all other INFO fields should be 3 fields
            print output_filehandle "$this_line_array[0],$this_line_array[1],$this_line_array[2]\n";
            $printed_line_to_output_file = "yes";
        }
    }
    elsif ($this_line_array[0] eq "coach")
    {
        for ($t=0; $t<5; $t++)
        {
            print output_filehandle "$this_line_array[$t],";
        }
        print output_filehandle "\n";
        $printed_line_to_output_file = "yes";
    }
    elsif ($this_line_array[0] eq "stat")
    {
        for ($t=0; $t<21; $t++)
        {
            print output_filehandle "$this_line_array[$t],";
        }
        print output_filehandle "\n";
        $printed_line_to_output_file = "yes";
    }
    elsif ($this_line_array[0] eq "tstat")
    {
        for ($t=0; $t<18; $t++)
        {
            print output_filehandle "$this_line_array[$t],";
        }
        print output_filehandle "\n";
        $printed_line_to_output_file = "yes";
    }
    elsif (($this_line_array[0] eq "linescore") ||
           ($this_line_array[0] eq "ignore") ||
           ($this_line_array[0] eq "playoffsstarthere") ||
           ($this_line_array[0] eq "abatiebreaker") ||
           ($this_line_array[0] eq "sources"))
    {
        # variable length, so get rid of extra commas at end
        $copyline =~ s/\,{2}//g;
        $copyline =~ s/\,$//g;
    }
    
    
    # If we haven't printed the line yet, print it now
    if ($printed_line_to_output_file eq "no")
    {
        print output_filehandle $copyline;
    }
    
}

close (input_filehandle);
close (output_filehandle);

print "File $output_filename created.\n";
