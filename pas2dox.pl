#!/usr/bin/perl -Tw
#use diagnostics;
#
# Convert Pascal code to something that Doxygen can understand
#
# This version is proof of concept, and may/maynot work, as it's my first perl script...
#
# Darren Bowles       18th June 2002
#
# TODO
# handle constructor / destructor
# const's within functions shouldn't be documented.
# handle override, safecall etc.
# cr/lf issues between linux / windows.
# handle type<cr>  x = y;
# handle class function
# handle dispinterface
# TLB's not handled well.

# done in this version
#   process function/procedure merged into build_line
#   obsolete function removed
#   started on handle class function, interface, dispinterface, TLB

use Getopt::Std;
use Getopt::Long;
GetOptions('help', \$help, 'list=s', \$list, 'file=s', \$fle);

if ($help || !($fle | $list))
{
  print "pas2dox -h/--help -f/--file singlefile.pas -l/--list listoffiles\n";
  exit 0;
}

die "No Files Specified" if (!$list & !$fle);

if ($fle)
{
  process_file ($fle);
};

if ($list)
{  
  process_list ($list);
};

print STDERR "\tDone...\n";

# =================================================================================
# functions
# =================================================================================

sub tidy_line
{
  my $str = shift;
  return $str;
}

# =================================================================================
# tidy up line, i.e. remove spaces, tabs and newlines
sub tidy_line2
{
  my $str = shift;

# remove tabs and newlines
  $str =~ s/\t|\n//g;
  
  while ( $str =~ /  / ) 
  {
    $str =~ s/  / /g;
  }
  return $str;
}

# =================================================================================
# process class block
sub process_class
{
  my $line = shift;
#$newline .= "processing class line $line\n";
  
SWITCH: for (tidy_line($line))
        {
# handle comments
          m/^\/\// && do
          {
            $newline .= "$line\n";
            last;
          };
          
          /(private|protected|public)/i && do
          {
            # output keyword as lowercase
            $newline .= lc ($1);
            $newline .= " : \n";      
            last;
          };
          
# special handling of published
          m/published/i && do
          {
            $newline .= "// published: \n";
            last;
          };
          
# todo Not sure how to handle property yet
#property x : type read fx write fy;
          m/^property/i && do
          {
#property MessageListThread: TMessageListThread read oMessageListThread write oMessageListThread;
            $newline .= "// property = $line\n";
            #if ( $line =~ /(property)(.*)(:)(.*)(read)(.*)(write)(.*)/i )
            if ( $line =~ /(property)(.*)(:)(.*)( read)(.*)( write)(.*)(;)/i )
            {
              $newline .= "$4 $2;\n";
            }
#property x : type read or write f;
            elsif ($line =~ /(property)(.*)(:)(.*)( read| write)(.*)/i )
            {
#$newline .= "pf1 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";
              $newline .= "$4 $2;\n";
            }
            else
            {
# FIX : does get here if property is in the line
# i.e. procedure xxxPropertyxxx(const Propertyxxx: type;
#        out x: type; out b: type); safecall;

              $newline .= "// should not get here -> ";
              $newline .= $line;
            }
            last;
          };
          
# end of class
          /end;/i && do
          {
            $state = $DO_DEFAULT;
            $newline .= "};\n";
            last;
          };
          
          /function/i && do
          {
#$newline .= "processing a function\n";
            $state = $DO_CLASSFUNCTION;
            $function = 1;
            if ( build_line ($line, "1", 1) == 1)
            {
              $function = 1;
              $split_line = 1;
            }
            else
            {
              $function = 0;
              $split_line = 0;
            }
            
            last;
          };
          
          /procedure/i && do
          {    
            $state = $DO_CLASSPROCEDURE;
            $procedure = 1;
            if ( build_line ($line, "1", 0) == 1)
            {
              $procedure = 1;
              $split_line = 1;
            }
            else
            {
              $procedure = 0;
              $split_line = 0;
            }
            
            last;
          };         
          

          /dispinterface/i && do
          {
            if ( $line =~ /(.*)(\=)(.*)/ )
            {
              $newline .= "dispinterface $1;\n";
            }

            last;
          };

          #      x = interface(IDispatch)
      /(.*)(\=)(.*)(interface)([^(]*)(.*\()(.*)(\))(.*)/i && do
      {
        $newline .= "interface $1 : $7\n{\n";

        last;
      };

      /(.*)(\=)(.*)(interface)(.*)(;)/i && do
      {
        $newline .= "interface $1;\n";
        last;
      };



# X : Y;
          /(.*)(:)(.*)(;)(.*)/ && do
          {
            $newline .= "$3 $1;";

# add untrimmed comments
            $comments = $line;
            $comments =~ /(.*)(;)(.*)/;

            $newline .= "$3\n";
            
            last;
          };
          
# get rid of {} style commenting
          $line =~ s/{\/\// /;
          $line =~ s/}//;
          
          $newline .= "//<?> $line\n";
  }
}

# =================================================================================
# Parse function line
sub parse_function
{
#  $newline .= "parsing function\n";
#  $newline .= "\n>> $funcline<<\n";

  # remove safecall line
  $funcline =~ s/safecall\;//;

  $mline = "";

  # function a.b(x, y : type) : type;
  if ( tidy_line($funcline) =~ /(function)(.*)(\.)([^(]*)(.*\()(.*)(\))(.*\:)(.*)(;)/i )        
  {
    $mline = func1($funcline);
  }
  # function b(x, y : type) : type;
  elsif ( tidy_line($funcline) =~ /(function)(.*)(\()(.*)(\))(.*\:)(.*)(;)/i )
  {
    $mline = func2($funcline);
  }
  # function a.b : type;
  elsif ( tidy_line($funcline) =~ /(function)(.*)(\.)(.*)(:)(.*)(;)/i )
  {
    $mline = func3($funcline);
  }
  # function a.b;
  elsif ( tidy_line($funcline) =~ /(function)(.*)(\.)(.*)(;)/i )
  {
    $mline = func4($funcline);
  }
  # function a : type;
  elsif ( tidy_line($funcline) =~ /(function)(.*)(:)(.*)(;)/i )
  {
    $mline = func5($funcline);
  }
  # function x;
  else
  {
$newline .= $funcline;
    $mline = func6($funcline);
  }

  $newline .= $mline;
  $funcline = "";
}

# =================================================================================
# Build up a func/proc line
sub build_line
{
  my $line = shift;
  $type = shift;
  my $buildtype = shift;  # are we building a function or procedure
    
    chomp($line);
    # TODO pretty sure i was stripping out ^M's here... code broke on
    # windows, so commented out...
    #  $line =~ s///;

#$newline .= "build_line = $line\n";
  
  # Are we processing a func or proc?
  if ( $function == 1 | $procedure == 1)
  {
    # are we working on a split function?
    if ( $split_line == 1 )
    {
      # we have ended the parameter list on this line
      #  or we have already reached the endparameters )
      if ( $line =~ /\)/ | $end_parameter == 1 )
      {
        $end_parameter = 1;
        # have we got the end of the function?
        if ( $line =~ /\;/ )
        {
          $funcline .= $line;
          
          # now we need to parse the full function declaration
          
          if ( $buildtype == 1 )
          {
            parse_function;
            $function = 0;
          }
          else
          {
            parse_procedure();
            $procedure = 0;
          }

          $funcline = "";
          return 0;
        }
        # not at end of declaration yet.
        else
        {
          $funcline .= $line;
          return 1;
        }
      }
      # not end of parameter list yet.
      else
      {
        $funcline .= $line;
        return 1;
      }
    }
    # Process first line of the function
    else
    {
      # we have started parameter list
      if ( $line =~ /\(/ )
      {
        # starting the parameter list
        $end_parameter = 0;
        
        # we have ended the parameter list on this line
        if ( $line =~ /\)/ )
        {
          $end_parameter = 1;
          
          # have we got a semicolon on this line?
          if ( $line =~ /;/ )
          {
            $funcline .= $line;
            
            if ( $buildtype == 1 )
            {
              parse_function;
            }
            else
            {
              parse_procedure();
            }
          }
          # we have a multiline declaration
          else
          {
            $split_line = 1;
            $funcline .= $line;
            return 1;
          }          
        }
        # line didn't have an ending ), so we must be split over multiple lines
        else
        {
          $split_line = 1;
          $funcline .= $line;
          return 1;
        }
      }
      # parameter list not started on this line
      else
      {
        # have we got a semicolon on this line?
        if ( $line =~ /;/ )
        {
          $funcline .= $line;
          
          if ( $buildtype == 1 )
          {
            parse_function;
          }
          else
          {
            parse_procedure();
          }
        }
        # we have a multiline declaration
        else
        {
          $split_line = 1;
          $funcline .= $line;
          return 1;
        }
      }      
    }
  }
  
  $newline .= $funcline;
  
  if ( $buildtype == 1 )
  {
    $function = 0;
  }
  else
  {
    $procedure = 0;
  }
  
  $funcline = "";
  return 0;
}

# =================================================================================
# process parameters
sub process_params
{

  my $str = shift;

#  $newline .= "// >> $str <<\n";

   
# split parameters out
  
  @a = split(/;/, $str);
  
  $cur = 0;
chomp @a;
  foreach $z (@a)
  {
# x, y, x : type;
    
   
    $z =~ /([^:]*)(:)(.*)/;
    $typ = $3;

# now sort out any comma'd parameters
    
    @p1 = split(/,/, $1);
    
    $v = 0;
    foreach $t (@p1)
    {
      $mline .= $typ;
      $mline .= " ";
      $mline .= $t;

      if ( $v < $#p1 )
      {
        $mline .= ", ";
      }

      $v++;

    }

    if ( $cur < $#a )
    {
      $mline .= ", ";
    }

    $cur++;
  }
  
}

# =================================================================================
#  function class.name(x, y : type) : type;
sub func1
{
 my $funcline = shift;

  tidy_line($funcline) =~ /(function)(.*)(\.)([^(]*)(.*\()(.*)(\))(.*\:)(.*)(;)/i;

    $mline .= "// function class.name(x, y : type) : type\n";
#$newline .= "pf0 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";
    $mline .= $9;
    $mline .= " ";
    $mline .= $2;
    $mline .= "::";
    $mline .= $4;
    $mline .= "(";
        
    $v = $6;

    process_params ($v);
        
    $mline .= ")";
        
    $function = 0;
    if ( $type == 0)
    {
      if ( $implementation == 0 )
      {
        $mline .= ";";
      }
      
      $mline .= "\n";
      $state = $DO_DEFAULT;
    }
    else
    {
      $mline .= ";\n";
      $state = $DO_CLASS;
    }

    #      $newline .= $mline;
    #    $funcline = "";

    return $mline;
}

# =================================================================================
# function b(x, y : type) : type;
sub func2
{
  my $funcline = shift;
  tidy_line($funcline) =~ /(function)(.*)(\()(.*)(\))(.*\:)(.*)(;)/i;

  $mline = "// function b(x, y : type) : type;\n";
  $mline .= "$7 $2 (";
  $v = $4;

  process_params($v);

  $mline .= ")";

  $function = 0;
  if ( $type == 0)
  {
    if ( $implementation == 0 )
    {
      $mline .= ";";
    }

    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }

  return $mline;

}

# =================================================================================
# function a.b : type;
sub func3
{
  my $funcline = shift;

  tidy_line($funcline) =~ /(function)(.*)(\.)(.*)(:)(.*)(;)/i;

  #$newline .= "func3 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";

  $mline = "// function a.b : type;\n";
  $mline .= "$6 $2::$4 ()";

  $function = 0;
  if ( $type == 0)
  {
    if ( $implementation == 0 )
    {
      $mline .= ";";
    }

    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }

  return $mline;
}

# =================================================================================
# function a.b;
sub func4
{
  my $funcline = shift;

  tidy_line($funcline) =~ /(function)(.*)(\.)(.*)(;)/i;

  #$newline .= "pf0 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";

  $mline = "// function a.b;\n";
  $mline .= "void $2::$4 ()";

  $function = 0;
  if ( $type == 0)
  {
    if ( $implementation == 0 )
    {
      $mline .= ";";
    }

    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }


  return $mline;

}

# =================================================================================
# function a : type;
sub func5
{
  my $funcline = shift;

  tidy_line($funcline) =~ /(function)(.*)(:)(.*)(;)/i;

  $mline = "// function a : type;\n";
  $mline .= "$4 $2()";

  $function = 0;
  if ( $type == 0)
  {
    if ( $implementation == 0 )
    {
      $mline .= ";";
    }

    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }

  return $mline;
}

# =================================================================================
# function x;
sub func6
{
  my $funcline = shift;
  
  tidy_line($funcline) =~ /(function)(.*)(;)/i;

  $mline = "// function x;\n";
#  $newline .= "func6 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";
  $mline .= "void $2 ()";

  $function = 0;
  if ( $type == 0)
  {
    if ( $implementation == 0 )
    {
      $mline .= ";";
    }
    
    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }

  return $mline;
}
# =================================================================================


# =================================================================================
# Parse procedure line
sub parse_procedure
{
#  $newline .= "parsing procedure\n";
#  $newline .= "\n>> $funcline<<\n";

# procedure a.b(x, y : type);
# procedure b(x, y : type);
# procedure a.b;
# procedure a;

# remove safecall line
  $funcline =~ s/safecall\;//;

  $mline = "";

  # procedure a.b(x, y : type);
  if ( tidy_line($funcline) =~ /(procedure)(.*)(\.)([^(]*)(.*\()(.*)(\))(.*)(;)/i )        
  {
    $mline = proc1($funcline);
  }
  # procedure b(x, y : type);
  elsif ( tidy_line($funcline) =~ /(procedure)(.*)(\()(.*)(\))(.*)(;)/i )
  {
    $mline = proc2($funcline);
  }
  # procedure a.b;
  elsif ( tidy_line($funcline) =~ /(procedure)(.*)(\.)(.*)(;)/i )
  {
    $mline = proc3($funcline);
  }
  # procedure a;
  else
  {
    $mline = proc4($funcline);
  }

  $newline .= $mline;
  $funcline = "";
}



# =================================================================================
# procedure a.b(x, y : type);
sub proc1
{
  my $funcline = shift;

  tidy_line($funcline) =~ /(procedure)(.*)(\.)([^(]*)(.*\()(.*)(\))(.*)(;)/i;

  $mline = "// procedure a.b(x, y : type);\n";
#$newline .= "pf0 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";
  $mline .= "void $2::$4 (";

  $v = $6;
  process_params($v);

  $mline .= ")";

  $procedure = 0;
  if ( $type == 0)
  {

    if ( $implementation == 0 )
    {
      $mline .= ";";
    }
    
    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }

  return $mline;
}


# =================================================================================
# procedure b(x, y : type);
sub proc2
{
  my $funcline = shift;

  tidy_line($funcline) =~ /(procedure)(.*)(\()(.*)(\))(.*)(;)/i;

  $mline = "// procedure b(x, y : type);\n";
#$newline .= "pf0 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";

  $mline .= "void $2 (";

  $v = $4;
# --- processing for COM stuff
  $v =~ s/ out / \[out\] /g;
# ---

  process_params($v);

  $mline .= ")";

  $procedure = 0;
  if ( $type == 0)
  {

    if ( $implementation == 0 )
    {
      $mline .= ";";
    }

    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }

  return $mline;
}

# =================================================================================
# procedure a.b;
sub proc3
{
  my $funcline = shift;

  tidy_line($funcline) =~ /(procedure)(.*)(\.)(.*)(;)/i;

  $mline = "// procedure a.b;\n";
#$newline .= "pf0 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";
  $mline .= "void $2::$4 ()";

  $procedure = 0;
  if ( $type == 0)
  {

    if ( $implementation == 0 )
    {
      $mline .= ";";
    }

    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }

  return $mline;
}


# =================================================================================
# procedure a;
sub proc4
{
  my $funcline = shift;

  tidy_line($funcline) =~ /(procedure)(.*)(;)/i;
  
  $mline = "// procedure a;\n";
#$newline .= "pf0 - 1-$1,\n2-$2,\n3-$3,\n4-$4,\n5-$5,\n6-$6,\n7-$7,\n8-$8,\n9-$9,\n10-$10\n";
  $mline .= "void $2 ()";

  $procedure = 0;
  if ( $type == 0)
  {
    if ( $implementation == 0 )
    {
      $mline .= ";";
    }

    $mline .= "\n";
    $state = $DO_DEFAULT;
  }
  else
  {
    $mline .= ";\n";
    $state = $DO_CLASS;
  }

  return $mline;
}

# =================================================================================
sub process_file
{
  my $fle = shift;
  open (CFG, $fle);
  print STDERR "Analyzing $fle\n";

  analyse_file ($fle);
}

# =================================================================================
sub process_list
{
  my $list = shift;

  #open the file to read the list of projects from
  open (FILE, "<$list");

  # while we still have files to iterate through
  open (FILE, "<$list");
  
  print STDERR "Analyzing list $list...\n";

  while ($fle = <FILE> )
  {
    process_file ($fle);
  }  

  close (FILE);
}

sub analyse_file
{
  my $fle = shift;

  if ( $fle =~ /(.*)\.(.+)$/ )
  {
    $name = $1;
    # $2 will hold the extension, TODO convert .pas files only.
  }
  
  print STDERR "\tConverting file $fle";
  
# open file for output
  
  $outname = $name;
  $outname .= ".";
  $outname .= "cpp";
  
  open (OUT, ">$outname");
  
# reset flags
  
  $newline = "";        # line to be generated
  $funcline = "";       # function line being generated
  $block_cnt = 0;       # block counter
  $skip = 1;            # skip lines
  $function = 0;        # processing function
  $procedure = 0;       # processing procedure
  $split_line = 0;      # func/proc split over multiple lines
  $implementation = 0;  # implementation not reached yet
  
  $DO_DEFAULT = 1;
  $DO_BLOCK = 2;
  $DO_CLASS = 3;
  $DO_CONST = 4;
  $DO_FUNCTION = 5;
  $DO_PROCEDURE = 6;
  $DO_CLASSFUNCTION = 7;
  $DO_CLASSPROCEDURE = 8;
  $DO_DISPINTERFACE = 9;
  
  $state = $DO_DEFAULT;
  
  while ( $line = <CFG> )
  {
LOOP:
  {
#   $newline .= "$function, $split_line, $state, line = $line\n";
    if ( $state == $DO_DEFAULT )	
    {
# Ignore comments
      if ( $line =~ m/^\/\// )
      {
        $newline .= $line;
        last;
      }
      elsif ( $line =~ /(.*{)(.*)(.*})/ )
      {
        $newline .= "/*$2*/\n";
        $skip = 1;
        last;
      }
      elsif ( $line =~ /(.*{)(.*)/ )
      {
        $newline .= "/* $2";
        $skip = 1;
        last;
      }
      elsif ( $line =~ /(.*})/ )
      {
        $newline .= "$1 */\n";
        $skip = 0;
        last;
      }
      elsif( $line =~ m/^type/i )
      {
        $skip = 0;
      }
      elsif ( $line =~ m/^constructor/i )
      {
        $skip = 1;
      }
      elsif ( $line =~ m/destructor/i )
      {
        $skip = 1;
      }
      elsif ( $line =~ m/^const/i )
      {
        $state = $DO_CONST;
        $skip = 1;
      }
      elsif ( tidy_line($line) =~ m/^begin/i )			    # process begin block
      {
        $skip = 0;
        $state = $DO_BLOCK;
        $block_cnt++;
        $newline .= "{\n";
      }
      elsif ( tidy_line($line) =~ m/^var/i )           # variable block
      {
        $state = $DO_DEFAULT;
        $skip = 1;
      }
      elsif ( tidy_line($line) =~ m/^implementation/i )
      {
        $state = $DO_DEFAULT;
        $skip = 0;
        $implementation = 1;
        last;
      }
      elsif ( tidy_line($line) =~ m/^function/i )
      {
        $state = $DO_FUNCTION;
        $function = 1;
      }
      elsif ( tidy_line($line) =~ /class/i )
      {
        if ( tidy_line($line) =~ m/^class/i )
        {
          if ( tidy_line($line) =~ /class function/i )
          {
            $line =~ s/class //g;
            $state = $DO_FUNCTION;
            $function = 1;
          }
          else
          {
            $state = $DO_CLASS;
          }
        }
        elsif ( tidy_line($line) =~ /(.*)(\=)(.*)(class)/i )
        {
#$newline .= "aclass $1\n{\n";
          $state = $DO_CLASS;
        }

      }
      elsif ( tidy_line($line) =~ m/^procedure/i )
      {
        $state = $DO_PROCEDURE;
        $procedure = 1;
      }
      elsif ( tidy_line($line) =~ /dispinterface/i )
      {
        if ( tidy_line($line) =~ /(.*)(\=)(.*)(;)/ )
        {
          $newline .= "$3 $1;\n";
          last;
        }
        else
        {
          if ( tidy_line($line) =~ /(.*)(\=)(.*)/ )
          {
            $newline .= "dispinterface $1\n{\n";
          }

          $state = $DO_CLASS;
          last LOOP;
        }
      }
      elsif ( tidy_line($line) =~ /interface/i )
      {
#$newline .= "// 2 >>> $line\n";
 
        if ( tidy_line($line) =~ /(.*)(\=)(.*)(;)/i )
        {
          $newline .= "interface $1;\n";
        }
        elsif ( tidy_line($line) =~ /^interface/i )
        {
          $newline .= "// interface ignored\n";
        }
        elsif ( tidy_line($line) =~ /(.*)(\=)(.*)(interface)([^(]*)(.*\()(.*)(\))(.*)/i )
        {
          $newline .= "interface $1 : $7\n{\n";
          $state = $DO_CLASS;
        }
        else
        {
#$newline .= ">>> 1 - $line\n";
$state = $DO_CLASS;
          last LOOP;
        }

        last;
#$state = $DO_CLASS;
      }
      

      
# Working on a function
      if ( $state == $DO_FUNCTION )
      {
#$newline .= "about to process a function\n";
        if ( build_line ($line, "0", 1) == 1 )
        {
          $function = 1;
          $split_line = 1;
        }
        else
        {
          $function = 0;
          $split_line = 0;
        }
        last LOOP;
      };
      
# Working on a procedure
      if ( $state == $DO_PROCEDURE )
      {
        if ( build_line ($line, "0", 0) == 1 )
        {
          $procedure = 1;
          $split_line = 1;
        }
        else
        {
          $procedure = 0;
          $split_line = 0;
        }
        last LOOP;
      };

#$newline .= "about to do block - $line\n";
      if ( $block_cnt == 0)
      {
        if ( $skip == 0 )
        {
          if ( $line =~ /(^.*)( = class)()(.*)$/i) # class definition
          {
            $newline .= "class ";
            $newline .= $1;
            $newline .= ":";
            $newline .= $4;
            $newline .= "{\n";
            $state = $DO_CLASS;
          }
          else        # Get rid of { } style commenting
          {
            $line =~ s/{/\/\/\/ /;
            $line =~ s/}//;
            
            if ( tidy_line($line) =~ m/procedure/i )
            {
              build_line ($line, "1", 0);
            }            
            else
            {
              if ( tidy_line($line) =~ m/^\/\// )
              {
                $newline .= $line;
              }
              else
              {
                $newline .= "// > $line";
              }
            }
          }
        }
      }  
      
      last LOOP;
    };
    
    
    if ( $state == $DO_BLOCK )
    {
      if ( $line =~ m/^end/i )				# end block
      {
        $state = $DO_DEFAULT;
        $block_cnt--;
        $newline .= "}";
        $newline .= "\n";
      }
      
      last LOOP;
    };
    
    if ( $state == $DO_CONST )
    {
#NAME = 'SOMETHING';
      if ( $line =~ /([^=]*)(.*=)(.*)(;)(.*)/i )
      {
        $newline .= "#define ";
        $newline .= $1;
        $newline .= " ";
        $newline .= $3;
        $newline .= ";\n";
      }
      else
      {
        $newline .= "// const error - ";
#      $newline .= $line;
        $state = $DO_DEFAULT;
        $skip = 0;
      }
      
      last LOOP;
    };
    
# Working on a class structure
    if ( $state == $DO_CLASS )
    {
#$newline .= "then got here - $line \n";
      process_class ($line);
      
      last LOOP;
    };
    
# working on function split over lines
    if ( $state == $DO_FUNCTION )
    {
      if ( build_line ($line, "0", 1) == 0)
      {
        $function = 0;
        $split_line = 0;
        $state = $DO_DEFAULT;
      }
    };
    
# working on class function declaration, split over lines
    if ( $state == $DO_CLASSFUNCTION )
    {
      if ( build_line ($line, "1", 1) == 0)
      {
        $function = 0;
        $split_line = 0;
        $state = $DO_CLASS;
      }
    };
    
# working on procedure split over lines
    if ( $state == $DO_PROCEDURE )
    {
      if ( build_line ($line, "0", 0) == 0)
      {
        $procedure = 0;
        $split_line = 0;
        $state = $DO_DEFAULT;
      }
    };
    
    
# working on class procedure declaration, split over lines
    if ( $state == $DO_CLASSPROCEDURE )
    {
      if ( build_line ($line, "1", 0) == 0)
      {
        $procedure = 0;
        $split_line = 0;
        $state = $DO_CLASS;
      }
    };       
}
}

print OUT $newline;
close (OUT);


}
