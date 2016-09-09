package sshop_part;

###
### 2011-06-08 grieve
###

use lib "/www/Gform/lib";
use Form_Util;
use Data::Dumper;
my $Root = '/www/Gform/sshop/';

$data_dir   = $Root . "Data/";
my $cdir    = $data_dir . "Courses/";
my $def     = $Root . "lib/sshop_part.def";
my $exweeks = $data_dir . "excluded_weeks";
my $invite  = $Root . "lib/invitemessage";
my $xml_element = "sshop_part";

my %elements = Form_Util::_Read_Defaults_Simple($def);

my @etags = sort ( keys  %elements);
my $Next_ID = get_NextID();
$Group_for_file_ownership = 0;
$Course_email = q{sms-course@phas.ubc.ca};

1;

sub Intro {
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

sub new_ori  {
    my $class = shift;
    my $self = { _permitted => \%elements };
    bless $self, $class;
    return $self;
}

sub new  {
    my $class = shift;
    my $self = { _permitted => \%elements };

    bless $self, $class;
    $self->{ID} = get_NextID(); 
    return $self;
}

sub AUTOLOAD {
   my $self = shift;
   my $type = ref($self) || die " AUTOLOAD::<<$self>> is not an object\n";
   my $name = $AUTOLOAD;
    $name =~ s/.*://;
    return if $name eq 'DESTROY';
    unless ( exists $self->{_permitted}->{$name} )
    {
	die "Cannot access <$name> field in $self which is a    $type\n";
    }
    if (@_) {  return $self->{$name} = shift; }	#set
    esle    {  return $self->{$name};	      }	#get   
}

sub save {
    my $t  = shift;
    my $id = shift;
    Debug::dsay("sshop_part:: line 80   save...");
    my $tab = " "x4;
 
    $id = $t->{ID} unless $id;
	$xid = $t->{ID};
    Debug::dsay("sshop::save   ID is  {$id} xid is  {$xid}"); 
    my $f = get_file_name($id);
 
  
     Debug::dsay("sshop::save  get a file name w ID  {$id}  -- {$f}");  
    open (O, ">$f") || die "cannot open $f $!\n"; 
    print O "<$xml_element>\n";

    foreach $e (@etags) {
        $out = defined ($t->{$e}) ? $t->{$e} : "";

        Debug::dsay("sshop::save;; element {$e} value {$out}");
        print O $tab, "<$e>", $out,"</$e>\n" if $out;
    }

    print O "</$xml_element>\n";    
    close O;
##
## set the mod & ownership of file...; for now we do not worry about
## failures...$> is ggk for Real_user_id

    chmod 0664, $f;
    if ($Group_for_file_ownership)
    {   my $cnt = chown  $>, $Group_for_file_ownership, $f; }
    return $id;
} 

sub get_file_name {
    my $ID = shift;
    Debug::dsay("get_file_name get file name w  $ID");
    if ($ID =~ /^([\w\._-]+)$/ ) { $lname = $1; }
    else 						 { die "Bad file name $lname\n";}
    $lname .= ".xml" unless ($lname =~ /xml$/) ;
	my $f = $data_dir. $lname ;
    return $f;
}

sub get_NextID {
   $Next_ID = 0;
   opendir (D, $data_dir) || die "cannot open directory $data_dir \n";
   while (defined($f = readdir(D)))
   {
       next unless $f =~ /(\d*).xml/;
       my $thisid = $1;
       $Next_ID = $thisid if  $thisid > $Next_ID;
   }
#   Debug::dsay("get_NextID:: id from data dir {$Next_ID");
   $Next_ID++;
   
 #     Debug::dsay("get_NextID:: return id  {$Next_ID");
   return $Next_ID;
}

sub course_name
{
    my $iso_wk = shift;
    Debug::dsay("course_name:: l144 in is {$iso_wk}");
 
    my $cname = $cdir . $iso_wk . ".xml";
    return $cname;    
}

sub ISOWeek {
   my $y = shift;
   my $w = shift;
   $w =~ s/W//i;

   my $iso = sprintf("%4d-W%2.2d", $y,$w);
#   Debug::dsay("ISO_Week:: iso {$iso} year {$y}");  
   return $iso;
}

sub get_One_Course {
    my $wnum = shift;
    my $year = shift;
    
    if ( ! $year) {
	  ($year,$wk) = $wnum =~ m[(\d\d\d\d)-];
    }
    Debug::dsay("get_One_Course::l169 wnum {$wnum} year {$year} $wk");
   
	$wnum = ISOWeek($year,$wnum);

    my $cfile = course_name($wnum, $year);
    my %chash = ();
    my $cdata = "";
#      Debug::dsay("get_One_Course:: cfile {$cfile}");
    {
	if (open (XF,$cfile) ) 
        { 
	   local ( $/ );
	   $cdata = <XF>;
	   close (XF);
        }   
    }

    $chash{wnum} = $wnum;
    $chash{instructor} = $1 if $cdata =~ m[<instructor>(.*?)</instructor>]msg;
  
    while ($cdata =~ m[<app>(.*?)</app>]msg ) {
		my $adata = $1;
 #      Debug::dsay("get_One_Course:: adata {$adata}");     
        my $ahash = {};
        foreach my $t ( qw [ id booked_date name ] )
        {
	    $ahash->{$t} = $1 if  $adata =~ m[<$t>(.*?)</$t>];
        }
        push @{$chash{apps}}, $ahash;
    }
    return  %chash;
}

sub get_CourseList {
  Debug::dsay(" get_CourseList:: xml dit is {$cdir}");
   opendir (CD, $cdir ) || die "cannot get dir $cdir  $! \n";
   my  @cfiles =  grep { /xml$/ } readdir (CD);
   closedir(XD);
  @cfiles = sort @cfiles;

   return @cfiles;
}

sub get_Course_Data {
    my $iso_wk = shift;
    if ( !  $iso_wk =~ /\d\d\d\d-W\d\d/ ) {
		die " Invalid input to get_Course_Data should be ISO week ";
    }
    Debug::dsay("get_Course_Data::l225 week {$iso_wk} ");
 
    my $cfile = course_name($iso_wk);
    my %chash = ();
    my $cdata = "";
     Debug::dsay("get_Course_Data:: cfile {$cfile}");
    {
	if (open (XF,$cfile) ) 
        { 
	   local ( $/ );
	   $cdata = <XF>;
	   close (XF);
        }   
    }
    if ( $cdata =~  m[<instructor>(.*?)</instructor>]msg ) {
		$chash{wnum}       = $iso_wk;
        $chash{instructor} = $1;
    }
  
    while ($cdata =~ m[<app>(.*?)</app>]msg )  {
		my $adata = $1;
 #      Debug::dsay("get_One_Course:: adata {$adata}");     
        my $ahash = {};
        foreach my $t ( qw [ id  name booked_date ] ) {
			$ahash->{$t} = $1 if  $adata =~ m[<$t>(.*?)</$t>];
        }
        push @{$chash{apps}}, $ahash;
    }
    return  %chash;
}

sub get_Current_Data {
    use Date::Calc  ( qw {Today Delta_Days});

   opendir (XD, $data_dir ) || die "cannot get dir $data_dir  $! \n";
   my  @xfiles =  grep { /xml/ } readdir (XD);
   closedir(XD);
   my @things = ();
   my @apps  = get_Data();
   my @Today = Today();
   foreach my $a (@apps) {
        my $id = $a->{ID} // 0;
      
        next if ($id < 170  );
        push @things, $a;
    }
    return @things;
}

sub get_Data {
	
   opendir (XD, $data_dir ) || die "cannot get dir $data_dir  $! \n";
   my  @xfiles =  grep { /xml$/ } readdir (XD);
   closedir(XD);
   my @things = ();
   
   foreach my $f (@xfiles) {
    #  Debug::dsay("get_Data:: reading file {$f}");
       my $s = rd_file($f); 
    #   my $ss = Dumper($s);
	#    my $x  = $s->{full_name};
	#	my $id = $s->{ID};
	#	    Debug::dsay("get_Data:: id {$id} name {$x}");
    #  Debug::dsay("get_Data:: dump the ohject\n $ss") if ($f =~ /106/);
      push @things, $s;
   }
   return @things;
}
sub get_Booked_Dates {
    my @apps = get_Data();
    my %bookeddates =();
    foreach my $o ( @apps ) {
        my $id = $o->{ID};
        if (defined $o->{booked_for_course}) {
			my $iso_wk = $o->{booked_for_course};
			push @{$bookeddates{$iso_wk}}, $id;
		}
    }
    return %bookeddates;
}

sub pref_weeknum {
    my $pdate = shift;
 
#	Debug::dsay(" pref_weeknum:: {$pdate}");
 
    my ($y,$m,$d) = $pdate =~ m[:\s+(\d\d\d\d)-(\d\d)-(\d\d)];
    my ($wk,$yr)  = Week_of_Year($y,$m,$d);
    $iso_wk = ISOWeek($yr,$wk);
    
    return $iso_wk;
}

sub get_Preferred_Dates {
#    Debug::dsay("sshop_part::get_Preferred_Dates:: ");
    my @apps = get_Data();
    my %bdates = sshop_part::get_Booked_Dates();
    
    my %prefdates = ();
    my %HofA = ();
    foreach my $o ( @apps) {
        my $id = $o->{ID};
		$xline = "x"x20;
		Debug::dsay ( "get_Preferred_Date:: line 326 ID  --> {$id} $xline");
		foreach my $i ( 1,2,3) {
			my $tag = "preferred_week_" .$i;
			if (defined $o->{$tag})	   {
				my $xo = $o->{$tag};
				Debug::dsay("get_Preferred_Dates:: line 323 preferred week {$xo}");
				my $iso_wk = pref_weeknum( $xo );
				Debug::dsay("get_Preferred_Dates:: the pweek seq  is {$i} week is {$iso_wk}");
				next if (grep /$id/, @{ $bdates{$iso_wk} });
				push @{$prefdates{$i}{$iso_wk}}, $id;
			}
		}
    }
	Debug::dsay (" leaving get_Preferred_Dates");
    return \%prefdates, \%bdates;
}

sub get_Data_by_ID {    
   opendir (XD, $data_dir ) || die "cannot get dir $data_dir  $! \n";
   my  @xfiles =  grep { /xml/ } readdir (XD);
   closedir(XD);
   my %things = ();
   foreach my $f (@xfiles) {
      my $s = rd_file($f);
      my $id = $s->{ID};
      next if $id <= 169;
   #   Debug::dsay ("get_Data_byID:: id is {$id}  ");
      $things{$id} = $s;
   }
   return %things;
}

sub get_Data_for_ID
{  
## input is a ID & out is data object for that id 

   my $id = shift;
   my $s; 
   my $f = $xml_dir . $id . ".xml";
    Debug::dsay ("get_Data_for_ID:; id  is {$id}");
   $s = rd_file($f);
    Debug::dsay ("get_Data_for_ID:; a  is {$s}");
   foreach my $k ( keys %$s )
   {
          Debug::dsay ("get_Data_for_ID:; key  is {$s}");
   }
   return $s;
}

sub filelist
{    
   opendir (XD, $xml_dir) || die "cannot get dir $xml_dir $! \n";
   my  @xfiles =  grep { /xml/ } readdir (XD);
   closedir(XD);

   return @xfiles;
}

sub get_elements
{	
   Debug::dsay("itt:: get_elements ");
   return %elements;
}

sub get_WeekData
{
   my $week = shift;
   Debug::dsay (" get_WeekData:;  week is {$week}"); 
   my %apps_by_week = ();
   foreach my $a( get_Data() )
   {
      my $id = $a->{ID};
      my $fn = $a->{full_name};
      next if $a->{booked_for_course};
      foreach my $ii (1..3)
      {
         my $t = "preferred_week_".$ii;
         if (defined $a->{$t}) {
	    	my $ident = "$fn $id";
	    	my $wnum = $1 if ( $a->{$t} =~ /week # (\d+)/ );
#	    	Debug::dsay (" get_WeekData:;  push ident {$ident} {$t} {$wnum}");
            push @{$apps_by_week{$wnum}{$ii}}, $ident;       
         }
      }
   }

   return \%apps_by_week; 
}

sub get_Tues_Date
{
    # gieven a week number & year -- return Tuesday's date in iso 8601.
    use Date::Calc qw( Add_Delta_Days  Monday_of_Week);

    my $wnum = shift;
    my $year = shift;
  
    @td = Add_Delta_Days(Monday_of_Week($wnum,$year),1);
    my $out = sprintf "%4.4d-%2.2d-%2.2d", @td;
    return $out;
}

sub get_Week
{
   my @apps =  sshop_part::get_Data();
   my %weeks = ();
   my @out = ();
   foreach my $a ( @apps )
   {
      foreach my $ii (1..3)
      {
          my $t = "preferred_week_".$ii;
          if (defined $a->{$t})
          {
            $weeks{$a->{$t}}{count}++;
            $weeks{$a->{$t}}{$ii}++ ;
          }
      }
   }
   foreach my $w (sort byISO  keys %weeks )
   {
       my $zut = sprintf "%s  %d ", $w,  $weeks{$w}{count};
       my $xot = sprintf "( %d, %d, %d )", (map $weeks{$w}{$_}, qw(1 2 3) );
       push @out, $zut . $xot;         
   }
   return @out;
}

sub get_Week_Avail
{
   my @apps =  sshop_part::get_Data();
   my %weeks = ();
   my @out = ();
   foreach my $a ( @apps )
   {
      foreach my $pref ( qw [ preferred_week ]) ## unavailable_week ] )
      {
         foreach my $ii (1..3)
         {
             my $t = $pref."_".$ii;
             if ( $a->{$t})
             {
                $weeks{$a->{$t}}{$t}++ ;
	     }
         }
      }
   }
   return %weeks;
}

sub get_NoRestrict_Apps
{
    my $week = shift;
    Debug::dsay ("this is get_NoRestrict_Apps for  week {$week}");
    my @apps =  get_Data();
    my %norest =();
    foreach my $a (@apps )
    {
        my $name = $a->{full_name};
#	Debug::dsay ("get_NoRestrict_Apps app {$name}");
        my $id = $a->{ID};
	my $restricted = 0;
	foreach my $i (1,2,3)
        {
            my $t = "preferred_week_".$i;
            my $wtest = $a->{$t};
            next unless $wtest;
            my $pw = $1 if ($a->{$t} =~ /week # (\d+):/);
            $restricted++ if $pw == $week;
        }
	    my $date1 = $a->{excluded_from} ? $a->{excluded_from} : "";
	    my $date2 = $a->{excluded_to}   ? $a->{excluded_to}   : "";

#	Debug::dsay ("get_NoRestrict_Apps app {$name} xd1 {$date1} xd2 {$date2}");	
	my @res_weeks = get_Resweeks( $date1, $date2) if ($date1 and $date2);
	foreach my $xw ( @res_weeks)  { $restricted++ if $xw == $week; }
	
        $norest{$id} = $name unless $restricted;
   }
   return %norest;
}

sub get_Resweeks
{
    my $d1 = shift;
    my $d2 = shift;
    my @exweeks =();          #restricted weeks numbers will be return 
    my @sv = split "-", $d1;
    my @lv = split "-", $d2;
    my %weeks =  sshop_part::get_excluded_weeks();

    my $wn = Week_of_Year(@sv);
    my @sm = Monday_of_Week($wn,$sv[0]);
    my @t1 = Add_Delta_Days(@sm,1);
    my @f1 = Add_Delta_Days(@sm,4);
 
    my @m = @sm;
    while (1)
    {
        my @t = Add_Delta_Days(@m,1);
        my @f = Add_Delta_Days(@m,4);
        my $xw = Week_of_Year(@t);
        my $t = sprintf "%4.4d-%2.2d-%2.2d", @t;
        my $f = sprintf "%4.4d-%2.2d-%2.2d", @f;
#     print " \n Tues is $t   Excluding from $d1 to $d2\n";
        my $x1 = Delta_Days(@t, @sv);
        my $x2 = Delta_Days(@t, @lv);
        my $x3 = Delta_Days(@f, @sv);
        my $x4 = Delta_Days(@f, @lv);
 #       print " delta 1 is $x1 delta  2 is $x2 \n";
                  
        if  (   ( ($x1 <  0) and ($x2 > 0) )
             or ( ($x3 < 0) and ($x4 > 0) )
            )
        {
            push @exweeks, $xw;
        }
        @m = Add_Delta_Days(@m,7);
        last if Delta_Days (@m,@lv) < 0;
    }
    return @exweeks;
}

sub get_Prefercounts
{
   use Date::Calc qw(Delta_Days Add_Delta_Days Week_of_Year Monday_of_Week );
   my $start_wk = shift;
   my $num_wk   = shift;
   my $y = 2013;
   Debug::dsay("get_Prefercounts.. st week  {$start_wk} {$num_wk}");
   my %eweeks =  sshop_part::get_excluded_weeks();
    Debug::dsay("call get_Data_by_ID...");
   my %edata  =  sshop_part::get_Data_by_ID();

   my %unrest = ();
   my %pcounts= ();
   my ($this_ref, $b_ref)   = get_Preferred_Dates();
    my %this = %{$this_ref};
    my %bdates = %{$b_ref};

    Debug::dsay("get  the unrestricted counts...");

## Get the unrestricted counts...
 
    foreach my $w (  $start_wk .. $start_wk+$num_wk-1)
    {
	my $iso_wk = sshop_part::ISOWeek($y,$w);
	APP_LOOP:
        foreach my $k ( sort keys %edata )
        {
#	   Debug::dsay( "working id $k week $iso_wk");
	   if (grep /$k/, @{ $bdates{$iso_wk} })
	   {
		Debug::dsay( "skipping if $k because of booked\n");
		next APP_LOOP;
	   }
           my $es = $edata{$k};
           my $rest = 0;
	   PWEEK_LOOP:
           foreach my $i (1,2,3)
            {
		my %p1 = %{$this{$i}};
		if (grep /$k/, @{ $p1{$iso_wk} } )
		{
#		    Debug::dsay( "skipping if $k because of pref $iso_wk\n");
		    next APP_LOOP;
		}
#		Debug::dsay( " id $k no rests  p$i \n");
                $rest++;
            }
            $unrest{$iso_wk}++ if $rest;
        }
    }
   return \%unrest;
}

sub get_App_excluded_weeks {
    my $app = shift;			# an applicant object
    my @res_wks = ();
    if ($app->{excluded_from} and $app->{excluded_to} )  {
	
		my @d2 = datestr_to_array( $app->{excluded_to} );
		my @d1 = datestr_to_array( $app->{excluded_from} );
		my @this_date = @d1;
		my $xc = sprintf "%4d-%2.2d-%2.2d", @this_date;
		Debug::dsay("get_App_excluded_weeks:: id $app->{ID} $app->{excluded_from} $app->{excluded_to} tis {$xc}");
	
		while ( Delta_Days(@d2,@this_date) < 0) {
		   my ($w1,$y1) = Week_of_Year(@this_date);
		   my $iso_wk = sprintf "%4d-W%2.2d", $y1, $w1;
		   push @res_wks, $iso_wk;
			@this_date = Add_Delta_Days(@this_date, 7);
		}
	#	Debug::dsay("get_App_excluded_weeks:: id $app->{ID} $app->{excluded_from} $app->{excluded_to} ");
    }
 
    return @res_wks;
}

sub datestr_to_array {
    my $d = shift;
    my @array = (split "-",$d);
}
sub get_NoRestCounts
{
    use Date::Calc qw(Delta_Days Add_Delta_Days Week_of_Year Monday_of_Week );
    my $start_wk = shift;
    my $y        = shift;
    my $num_wk   = shift;

    Debug::dsay("get_NoRestCounts.. l:627 st week  {$start_wk} {$y} {$num_wk}");
    my %eweeks =  sshop_part::get_excluded_weeks();
    my %edata  =  sshop_part::get_Data_by_ID();

    my %unrest = ();
    my ($this_ref, $b_ref)   = get_Preferred_Dates();
    my %this = %{$this_ref};
    my %bdates = %{$b_ref};

#   Debug::dsay("get  the unrestricted counts...");
## Get the unrestricted counts...
 
    foreach my $w (  $start_wk .. $start_wk+$num_wk-1)
    {
	my $iso_wk = sshop_part::ISOWeek($y,$w);
	APP_LOOP:
        foreach my $k ( sort keys %edata )
        {
	#    Debug::dsay (" working id {$k}");
	    my $es = $edata{$k};
####    Check for excluded weeks
	    my @xweeks = get_App_excluded_weeks($es);
	 #   Debug::dsay( "working id $k week $iso_wk");
	    if ( grep /$iso_wk/, @xweeks)
	    {
	#	Debug::dsay( "get_NoRestCounts:: skipping  id $k week $iso_wk excluded");
		next APP_LOOP;
	    }
#	   Debug::dsay( "working id $k week $iso_wk");
##         Check for booked week
	   if (grep /$k/, @{ $bdates{$iso_wk} })
	   {
	#	Debug::dsay( "get_NoRestCounts::l625 skipping id {$k} because of booked\n");
		next APP_LOOP;
	   }
          
           my $rest = 0;
	   PWEEK_LOOP:
           foreach my $i (1,2,3)
            {
		my %p1 = %this ? %{$this{$i}} : ();
		if (grep /$k/, @{ $p1{$iso_wk} } )
		{
	#	    Debug::dsay( "skipping if $k because of pref $iso_wk\n");
		    next APP_LOOP;
		}
            }
	#     Debug::dsay( "put { $k } on the unrest array \n");
	    push @{$unrest{$iso_wk}}, $k;
 #           $unrest{$iso_wk}++ if $rest;
        }
    }
   return \%unrest;
}

sub get_UnRestricted_Weeks
{
   use Date::Calc qw(Delta_Days Add_Delta_Days Week_of_Year Monday_of_Week );
   my $start_wk = shift;
   my $num_wk   = shift;
   my %eweeks =  sshop_part::get_excluded_weeks();
   my %edata  =  sshop_part::get_Data_by_ID();

   my %unrest = ();
   
   foreach my $week ( $start_wk .. $start_wk+$num_wk-1)
   {
 
       my @date = Monday_of_Week($week,2012);
   
       @date = Add_Delta_Days(@date,1);
       my $d = sprintf "%4d-%2.2d-%2.2d", @date;
       
       foreach my $k ( sort keys %edata )
       {
          my $restricted = 0;
          my $es = $edata{$k};
          foreach my $i ( 1,2,3)
          {
             my $n = 0;
             my $t = "preferred_week_".$i;
             my $u = "unavailable_week_".$i;

             $restricted++ if exists $es->{$t} and $es->{$t} eq $d;
             $restricted++ if exists $es->{$u} and $es->{$u} eq $d;
          }
          push @{$unrest{$d}}, $es->{ID} unless $restricted;
       }
       @date = Add_Delta_Days(@date,7);
   }
   return \%unrest;
}

sub get_excluded_weeks
{
    my %weeks  = ();
    my %xweeks = ();
    {
       open (F, $exweeks) || die "Cannot open $exweeks\n";
       local ( $/ );
       $_=<F>;
       close F;
    }
 
    $weeks{start} = $1 if $_ =~ m[<start_date>(.*?)</start_date>];
    $weeks{last}  = $1 if $_ =~ m[<last_date>(.*?)</last_date>];

    while (/<exweek>(.*?)<\/exweek>/msg )
    {
       my $x = $1;
       my $date = $1 if $x =~ m[<date>(.*)</date>];
       my $comm = $1 if $x =~ m[<comment>(.*)</comment>];
#    Debug::dsay("sshop_part::get_excluded_weeks..   {$date} {$comm}");
       $xweeks{$date} = $comm;
    }
    $weeks{excluded} = \%xweeks;
    return %weeks;
}
sub save_excluded_weeks {
    
    my %weeks = @_;
 
    open (F, ">$exweeks") || die "Cannot open $exweeks\n";
    print F "<dates>\n";
    print F "   <start_date>$weeks{start}</start_date>\n" if $weeks{start};
    print F "   <last_date>$weeks{last}</last_date>\n"    if $weeks{last};
    print F "   <excluded_weeks>\n";
    my $tag = " "x4;
    
    foreach my $k ( keys %{$weeks{excluded}})
    {
	print F "   <exweek>\n";
	print F "   $tab<date>$k</date>\n";
	print F "   $tab<comment>${$weeks{excluded}}{$k}</comment>\n";
#	Debug::dsay(" key == {$k} value => ${$weeks{excluded}}{$k}");
	print F "   </exweek>\n"
    }
    print F "   </excluded_weeks>\n";
    print F "</dates>\n";
    close F;
}

sub get_Weeks2 {
   my @apps =  sshop_part::get_Data();
   my %weeks = ();
   my @out = ();
   foreach my $a ( @apps )
   {
      foreach my $ii (1..3)
      {
          my $t = "preferred_week_".$ii;
          if (defined $a->{$t})
          {
            $weeks{$a->{$t}}{count}++;
            $weeks{$a->{$t}}{$ii}++ ;
          }
      }
   }
   foreach my $w (sort byISO  keys %weeks )
   {
       my $zut = sprintf "%s  %d ", $w,  $weeks{$w}{count};
       my $xot = sprintf "( %d, %d, %d )", (map $weeks{$w}{$_}, qw(1 2 3) );
       push @out, $zut . $xot;                
   }

   return @out;
}

sub get_InviteMessage
{

      my $im = "";
    { local $_ = undef;
      open (F,$invite) || die "cannot open invite file \n";
      binmode F;
      $im = <F>;
      close F;
    }
   
    return $im;
}

sub mail_admin {

    my $mailer = "/usr/sbin/sendmail -oi -t ";	
 
    my $id     = shift;
    my $name   = shift;
    my $course = shift;
    my $response = shift;
    my $to = $Course_email;
    my $from = "sms_signup";
    my $subj = "Applicant Responses to Invite";

    if ( $response eq "Confirmed") {
           $body = qq{Applicant $id ($name) has confirmed for course $course.};
    } elsif ($response eq "Declined" ) {
        $body = qq{ Applicant $id ($name) has declined course $course.};
        
    } else {
        $body = qq{This is from mail-adimn:: this should not happen};
    }
    mail_it($to, $from, $subj, $body);    

    return;
    
    
}

sub mail_signup {
   Debug::dsay("sshop:: mail_signup ");
    my $mailer = "/usr/sbin/sendmail -oi -t ";	
 
    my $app_info = shift;
    my $to = $Course_email;
    my $from = "sms_signup";
    my $subj = "New SMS Course Applicant";
    my $body = qq {FYI:  The following person has signed up for a SMS course \n\n
                   $app_info\n"
                  };
   
    mail_it($to, $from, $subj, $body);    

    return;
}

sub mail_it {
    my $mailer = "/usr/sbin/sendmail -oi -t ";	
    my $to   = shift;
    my $from = shift;
    my $subj = shift;
    my $body = shift;
 Debug::dsay("from {$from} to {$to}" );
    if  ( $to ) {
       open (MAIL, "|$mailer") || die "cannot mail pipe \n";
       print MAIL "To: $to\n";
       print MAIL "Subject:  $subj\n";
       print MAIL "From: $from \n";
       print MAIL "\n$body\n.\n";
       close MAIL;
    }
    return;
}

sub cn2id {
    my $cn = shift;
    my $id = $cn;
    $id = $1 if $cn =~ /^\w\w\w\D*(\d+)\w\w\w/;
    return $id;    
}

sub  confirmationnumber {
## this routine is to obfuscate the applicant's id number
## into a random looking url 
#
#   current procedure:
##    prefix $ID with randon uppercase letters until length is three chars.
##    add 3 random numbers to front
##    add 3 random # to rear
    my $id = shift;
    my $l = length $id;
#    Debug::dsay ("confirmationnnumber:: id starts at {$id}");
    while ($l < 3)
    {
        my $s = int (rand 25) + 65;
        $id =  (chr $s) . $id;
#	Debug::dsay ("confirmationnnumber:: padding id is now {$id} l is {$l} s {$s}");
	$l++;
    }
    my $cn = $id;
    for $i (1,2,3) { $cn = int (rand 9) . $cn;
#		     Debug::dsay ("confirmationnnumber:: prepend  id is now {$cn}");
		     }    
    for $i (1,2,3) { $cn .= int (rand 9);
#		    	Debug::dsay ("confirmationnnumber:: append  id is now {$cn}");
		    }  
    return $cn;  
}

sub update_course_record {
    my $iso_wk = shift;
    my $id_to_drop = shift;
    Debug::dsay("update_course_record;; drop  {$id_to_drop} {$iso_wk} ");
    my $action = shift;
    my %data = sshop_part::get_Course_Data($iso_wk);
    my @apps = @{$data{apps}};
#  print Dumper(%data);
 #   print "the apps arry is \n";
 #     print Dumper(@apps);
    if ( $action eq "Delete")
    {
	my @keep_apps = ();
	foreach my $i (0 ..$#apps) {
	    my $app = $apps[$i];
	    my $id = $app->{id};
#	    Debug::dsay("update_course_record;; looking at   {$id} ");
	    next if $id == $id_to_drop;
	       Debug::dsay("update_course_record;; NOt dropping  {$app->{id}} ");
	    push @keep_apps, $app;
	}
 
	@{$data{apps}} = @keep_apps;
#	     print Dumper( @{ $data{apps} } );
	
    }
#    print "dump the data in update_course_record\n";
#    print Dumper( %data );

    save_Course_Data ( $iso_wk, \%data);
}

sub save_Course_Data {
    my $iso_wk = shift;
    my $d_ref = shift;
    my %data   = %{$d_ref};
 #     print "dump the data ...save_Course_Data \n";
 #     print Dumper(%data);
   
    my $cfile = $cdir. $iso_wk . ".xml";
 #      my $cfile = "/tmp/" . $iso_wk . ".xml";
    my $tab = " "x4;
    Debug::dsay("sshoppart::save_Course_Data:: 902 cfile is {$cfile}");
    open (C, ">$cfile") || die "Cannot open a file $cfile \n";
    
    print C "<course>\n";
    print C "$tab<wnum>$data{wnum}</wnum>\n";
    print C "$tab<instructor>$data{instructor}</instructor>\n" if $data{instructor};
    if ( @{$data{apps}})
    {
        foreach my $app ( @{$data{apps}} )
        {
            print C "$tab<app>\n";
            my %ap = %{ $app };
            print C "$tab$tab<id>$ap{id}</id>\n";
            print C "$tab$tab<name>$ap{name}</name>\n";            
            print C "$tab$tab<booked_date>$ap{booked_date}</booked_date>\n";
            print C "$tab</app>\n";
        }
    }
    print C "</course>\n"; 
    close C;
}

sub save_Course {
    my $iso_wk   = shift;
    my $inst = shift;
    my %names = @_;
    $inst = "not specified" unless $inst;
    Debug::dsay("sshoppart::save_course:: l849 week is {$iso_wk} inst {$inst}");
 

    my $tab = " "x4;
    my $today  = sprintf ("%04d-%02d-%02d", Date::Calc::Today() );
    
    my %data = sshop_part::get_Course_Data($iso_wk);
    if ( %data )
    {
 #       Print_Course(%coursedata);
     #   print Dumper (%coursedata);
    } else
    {
        $data{wnum} = $iso_wk;
	$data{instructor} = $inst;
	@{$data{apps}} = ();
#	print Dumper(%data);
    }  
    
    foreach my $s ( keys %names )	# save the booking date in app record...
					# update_app_record($s, {      booked_date => $today,
    {					#                              booked_for_course => $isowk} );
	my %app = ();
        Debug::dsay("sshoppart::save_course:: l962 keys to names hash {$s}");	
	$app{"id"}   = $s;
	$app{"name"} = $names{$s};
	$app{"booked_date"} = $today;
	push @{$data{apps}}, \%app;
	print "dump the app hash .. \n"; 
#	print Dumper(%app);
    }
    	print "dump the apps Array  .. \n"; 
#      print Dumper(@{$data{apps}});
    my $cfile = $cdir. $iso_wk . ".xml";
    
    Debug::dsay("sshoppart::save_course:: 882 cfile is {$cfile}");
    open (C, ">$cfile") || die "Cannot open a file $cfile \n";
    
    print  C "<course>\n";
    print   C "$tab<wnum>$data{wnum}</wnum>\n";
    print   C "$tab<instructor>$data{instructor}</instructor>\n" if $data{instructor};
    if ( @{$data{apps}})
    {
        foreach my $app ( @{$data{apps}} )
        {
            print  C "$tab<app>\n";
            my %ap = %{ $app };
	#    print Dumper(%ap);
	    my $id = $ap{id};
     # Debug::dsay("sshoppart::save_course:: l984 id  {$id}");		    
            print  C "$tab$tab<id>$ap{id}</id>\n";
            print  C  "$tab$tab<name>$ap{name}</name>\n";            
            print  C "$tab$tab<booked_date>$ap{booked_date}</booked_date>\n";
            print  C "$tab</app>\n";
	 
	    #update the application record
	   Debug::dsay("shoppart::save_course:: l986 update {$id}");
	    update_app_record($id, { booked_date => $today,
                                     booked_for_course => $iso_wk} );
        }
    }
    print   C "</course>\n"; 
   close C;
}

sub update_app_record
{
    my $id = shift;
    my $tags = shift;
    my $action = shift;
    Debug::dsay("sshoppart::update_app_record:: id is {$id}  ");

 #   my $value = shift;
    my $app  = get_app_by_ID($id);
    foreach my $t ( keys %$tags )
    {
#	Debug::dsay("sshoppart::update_app_record:: tag is {$t} $tags->{$t} ");
	if ($action eq "Delete") { delete $app->{$t}; }
	else                     { $app->$t($tags->{$t}); }
#        $app->$t($tags->{$t});
    }
    Debug::dsay("sshoppart::update_app_record:: call save...  ");

    my $err = save($app);
}



sub get_app_by_ID {
    my $id = shift;
    
    Debug::dsay (" get_app_by_ID:: fetching id {$id}");
    my $app = rd_file($id.".xml");
    return $app;
}    

sub rd_file {
#        input a filename 
#####    return Survey object reference...
	use CGI::Carp qw(fatalsToBrowser set_message);

    my $f = shift;

    $nl = "\n";
    $xml_file = $data_dir  . $f ;   
 
    {
       open (X,$xml_file ) ||  return -1;
       local ( $/ );
       $_=<X>;
       close X;
    }

    m[<$xml_element>(.*?)</$xml_element>]msg;
    my $talk = $1;
    my $t = new sshop_part;

    while  ($talk =~ m[<(\w+?)>(.*?)</\1>]msg) {
        next unless ($1 );
      	my $field = $1;
        my $value = $2;
        $value =~ s/\s*$//;
        $t->$field($value);
#	Debug::dsay("rd-file:: tag {$field} valu {$value} ") if $f =~ /106/;
    } 
    return $t;
}

sub delete_file
{
#        input an app id & delete the file
    my $id = shift;
 
    $id = $1 if ($id =~ /^(\d+)/);

    $nl = "\n";
    $xml_file = $data_dir  . $id . ".xml";
    Debug::dsay("sshop_part::delete file:: {$xml_file} is to be deleted");
    my $nfile = $data_dir  . "Deleted/" . $id . ".xml";
    rename $xml_file, $nfile || die " cannot rename $xml_file "; 
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

sub get_hdr {
	my $out = qq{<h2  class="ss_head">Physics &amp; Astronomy Student Machine Shop (SMS)</h2>};
}

sub get_weeklist
{
    use Date::Calc qw( Add_Delta_Days Week_of_Year);
    my $nweeks = shift;
    my @start  = @_;
    my @out = ();
    foreach my $i ( 0..$nweeks )
    {
       my $weeknum = Week_of_Year(@start);
       my $iso = sprintf "%4d-%2.2D-%2.2d", @start;
       @fri =  Add_Delta_Days(@start,3);
       my $fso = sprintf "%4d-%2.2D-%2.2d", @fri;
       @start =  Add_Delta_Days(@start,7);
       push @out, sprintf "week: %s - %s to %s", $weeknum, $iso, $fso;
    }
    return @out;

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



sub get_element_info { return %elements; }

sub byISO
{
    my ($ay, $am, $ad);
    my ($by, $bm, $bd);
   
    if ( $a =~ /(\d\d\d\d)-(\d\d)-(\d\d)/)
    {
	$ay = $1;
        $am = $2;
        $ad = $3;
    } else
    {  	$ay = $am = $ad = 0 ;
    }
    if ( $b =~ /(\d\d\d\d)-(\d\d)-(\d\d)/)
    {
	$by = $1;
        $bm = $2;
        $bd = $3;
    } else
    {  	$by = $bm = $bd = 0 ;
    }

    $ay <=> $by ||
    $am <=> $bm ||
    $ad <=> $bd;
}
 
