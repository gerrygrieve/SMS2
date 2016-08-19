#package itt;

package task;

###
### 2010-01-12 grieve
### a module for storing & itt data

use lib "/www/Gform/lib";
use Form_Util;

use Data::Dumper;
my $Root = '/www/Gform/ITT/';

my $xml_dir =  $Root . "Data/";
my $def  =  $Root . "lib/itt.def";

$xml_element = "it_task";
$sub_element = "task";
my %sel;					#A hash to hold attributes
my %sel_el = Form_Util::_Read_Defaults_Simple($def);

my @etags = keys  %sel_el;
foreach my $k ( keys %sel_el )
{
    $sel{$k} = undef; 
}

$Group_for_file_ownership = 0;
1;

sub Intro
{
    my $ifile = $Root ."lib/Intro";
    open (X, $ifile) || die "cannot open $ifile \n";

   my $intro = "";
   {
      local ( $/ );
      $intro = <X>;
      close X;  
 
  }
   return $intro;
}
sub new 
{
    my $class = shift;
    my $self = { _permitted => \%sel, %sel};
    bless $self, $class;
  #  print "you now have a new Survey <br />\n";
    return $self;
}

sub AUTOLOAD
{
   my $self = shift;
#   print "task::AUTOLOAD: self--> $self\n"; 
   my $type = ref($self) || die "<<$self>> is not an object\n";
   my $name = $AUTOLOAD;
    $name =~ s/.*://;
    return if $name eq 'DESTROY';
    print "task::AUTOLOAD: name--> $name\n"; 
    unless ( exists $self->{_permitted}->{$name} )
    {
	die "Cannot access <$name> field in $self which is a        $type\n";
    }
    if (@_) {  return $self->{$name} = shift;	#set
    } esle  {  return $self->{$name};		#get
    }
}

sub User
{
    my $user = shift;
    $xml_dir = $xml_dir . $user ."/";

    mkdir $xml_dir unless ( -s $xml_dir);

    return $xml_dir; 

}

sub saveit
{
    my $t = shift;           # ref to an array of task
    my $date = shift;
    my $tab = " "x4;
    my $f = get_file_name($date);
  
    $f = $xml_dir. $f ;
    open (O, ">$f") || die "cannot open $f $!\n";
 	
    print O "<$xml_element>\n";
    foreach my $tsk ( @{$t} )
    {
        print O $tab, "<$sub_element>\n";
        foreach $e (@etags)
        {
            $out = defined ($tsk->{$e}) ? $tsk->{$e} : "";
	    print O $tab.$tab, "<$e>", $out,"</$e>\n";
        }
        print O $tab, "</$sub_element>\n";
    }
    print O "</$xml_element>\n";    
    close O;
##
## set the mod & ownership of file...; for now we do not worry about
## failures...$> is ggk for Real_user_id

    chmod 0664, $f;
    if ($Group_for_file_ownership)
    {   my $cnt = chown  $>, $Group_for_file_ownership, $f;
    }
} 

sub get_file_name
{
    my $lname = shift;
 
    if ($lname =~ /^([\w\._-]+)$/ )
    { $lname = $1;
    }
    else 
    { die "Bad file name $lname\n";}
    $lname .= ".xml" unless ($lname =~ /xml$/) ;
    return $lname;
}

sub get_FileNames
{    
   opendir (XD, $xml_dir) || die "cannot get dir $xml_dir $! \n";
   my  @xfiles =  grep { /20.*xml/ } readdir (XD);
   closedir(XD);

   return @xfiles;
   
}

sub get_Data
{    
   opendir (XD, $xml_dir) || die "cannot get dir $xml_dir $! \n";
   my  @xfiles =  grep { /xml/ } readdir (XD);
   closedir(XD);
   my @surveys = ();
   foreach my $f (@xfiles)
   {

      my $s = rdfile($f); 
      push @surveys, $s;
   }
   return @surveys;
}

sub filelist
{    
  #print " Survey::filelist:: look in  $xml_dir<br />\n";
   opendir (XD, $xml_dir) || die "cannot get dir $xml_dir $! \n";
   my  @xfiles =  grep { /xml/ } readdir (XD);
   closedir(XD);

   return @xfiles;
}

sub get_elements
{	
#   Debug::dsay("itt:: get_elements ");
   return @etags;
}

sub get_defaults
{	
   return %defaults;
}

sub get_rank
{	 
# Return the structuce indexed by <tag> with prompts, ranks, default & edit; 
 #  print "Get_rank.... \n";
   return %sel_el;
 }

sub rd_file
{
#        input a filename 
#####    return Survey object reference...
    my $f = shift;
  # print "Survey::rd_file:: passed file name is $f  <br /> \n";


    $nl = "\n";
   
    $xml_file = $xml_dir . $f . ".xml";   
  
 #   print "Survey::rd_file:: passed fname is $f --> $xml_file <br /> \n"; 
    {
       open (X,$xml_file) || die "cannot open <$xml_file> $!\n"; 
       local ( $/ );
       $_=<X>;
       close X;
    }
     
  
    m[<$xml_element>(.*?)</$xml_element>]msg;
    my $data = $1;


    while ( $data =~ m[<$sub_element>(.*?)</$sub_element>]msg )
    {
        my $tdata = $1;
	my $t = new task;
#       print $tdata;
        foreach my $e ( @etags )
        {
#	    Debug::dsay("rd_file:: tag is {$e}");
            if ($tdata =~ m[<$e>(.+?)</$e>]msg)
            {
#               Debug::dsay("rd_file:: tag is {$e} get {$1}");
	       $t->{$e} = $1;
	    }
        }

        push @tasks, $t;
    } 

    return \@tasks;
}


sub set_group
{
#	accept a number which will be used to set group ownership of files
 
     my $grp = shift;

     if ($grp =~ /^\d+$/ ) 
         {$Group_for_file_ownership = $grp; }    
     else 
         { print "Survey::set_group:: Invalid  group -- $grp\n";}


     1;
}
sub update_file
{
#    print "<h2>Survey::update_file</h2>\n";

    my $survey_data = shift;
    my $r_ip = shift;

   #  print "update_file:: updating an existing file   <br> \n";
     my $f = get_file_name($survey_data);
   #  print "update_file:: updating an real file  $f<br> \n";
    
     my $tab = " "x4;
     my $lines ="<br />"x5;
  
 #   print "update_file:: updating an LOCAL INFO  file  $f <br> \n";
 
    my $tf;
    if ($f =~ /^([\w\._-]+)$/ ) {  $f = $1; }
    else                        { die "Bad file name $f\n";}

   
    $f = $xml_dir. $f ;
 
   # print "update_file::  $f and <br />\n";
  
  
    print "update_file::$f is tainted<br />\n"  if is_tainted($f);
    open (O, ">$f") || die "cannot open $f $!\n";
 	
    print O "<$xml_element>\n";

    my %obj_info = get_rank();
    my @cats = qw [course local];
    foreach my $cat ( @cats )		#qw [ sis course] )
    { 
        foreach my $tag ( sort { $obj_info{$cat}{$a}{rank} 
                           <=> $obj_info{$cat}{$b}{rank} }
                        keys %{$obj_info{$cat}} ) 
       {
          my $xo = "-";
          $out = defined ($survey_data->{$tag}) ? $survey_data->{$tag} : "";        #use NEW if exists
          $out =~ s/^\s+$//;
    #      print "Survey:Update:: tag; $tag value :$out$xo<br />";
    #      print "[$tag]", $out,"[$tag]<br />";
          print O "$tab<$tag>",$out,"</$tag>\n";
       }
     }

#print the modification info
#first get a date_time ..
    my $date_time = get_date_time();
  
    print O "$tab<modified>\n";
    print O "$tab$tab<by_user>$u</by_user>\n";
    print O "$tab$tab<from_IP>$r_ip</from_IP>\n";
    print O "$tab$tab<date>$date_time</date>\n";
    print O "$tab</modified>\n";
    print O "</$xml_element>\n";    
    close O;
##
## set the mod & ownership of file...; for now we do not worry about
## failures...$> is ggk for Real_user_id

    chmod 0664, $f;
    if ($Group_for_file_ownership)
    {   my $cnt = chown  $>, $Group_for_file_ownership, $f;
    }
  return;
} 


   
sub get_date_time
{
    my ($s, $Min, $Hrs,$mday, $month,$year) = localtime();
    $year += 1900;
    $month++;
    my $xx = sprintf ("%4d-%2.2d-%2.2dT%2.2d:%2.2d", $year, $month, $mday,$Hrs,$Min);
}




sub is_tainted
{
    my $v = shift;
    return ! eval { $v++,0; 1;};
}

sub Get_Course_List
{
#  return a list of courses ... eesentially the file names in sis_dir
   opendir (XD, $xml_dir) || die "cannot get dir $xml_dir $! \n";
   my  @xfiles = grep { /(ASTR|PHYS)_\w\w\w\d{0,1}/ } readdir (XD);
   closedir(XD);

   return sort @xfiles;
}


sub Get_Survey_Info
{

    my $out = shift;
    my $cnt_by_spec = shift;

    foreach my $f ( filelist() )
    {
   #   print "file:$f<br />\n";
       my $t = rd_file($f);
       ${$out}{$f} =  $t;
  
       my $spec = $t->{program};
       ${$cnt_by_spec}{$spec}++;  
    }
    return;

}
sub get_element_info
{
    return %sel_el;
}

sub  html_appl
{
    my $this_appl = shift;
 
    my $out = "";
#   print "<h2>Survey::html_appl: Applicant: $this_appl  </h2>";
  
    my $ja = Survey::rd_file($this_appl);

   print "<h2>Survey::Individual Response</h2>";
   my %element_info = Survey::get_element_info();
   $out .= "<p>$sp</p><table border=1>\n";

   my @help = (" ",
               "not at all",
               "weakly",
               "moderately",
               "strongly",
               "very strongly" );

   my $cat = "local";
   foreach my $t ( sort {$element_info{$cat}{$a}{rank} <=>
                         $element_info{$cat}{$b}{rank} } keys %{ $element_info{$cat}} )
   {

     $out .= "<tr><td><strong> $element_info{$cat}{$t}{prompt} </strong></td>\n";
     my $ot = $ja->{$t} ?  $ja->{$t} : '<span class="missing">not entered</span>';
     $ot = $ot eq "T" ? "Yes" : $ot;
     $ot = $ot eq "F" ? "No " : $ot;
     $ot = $help[$ot] if $t eq "Help";
     $out .= " "x4 . "<td>$ot</td></tr>\n";

   }
 
   $out .= "</table></center>\n";

   return $out;
}
###########################################

