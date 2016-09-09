package SMS_Person;

###
### 2011-06-08 grieve
###

use lib "/www/Gform/lib";
use Form_Util;
use Data::Dumper;
use Perl6::Slurp;
my $Root = '/www/Gform/SMS/';

$data_dir   = $Root . "Data/";
my $cdir    = $data_dir . "Courses/";
my $def     = $Root . "lib/SMS_Person.def";
my $exweeks = $data_dir . "excluded_weeks";
my $invite  = $Root . "lib/invitemessage";
my $xml_element = "sms_person";

my %elements = Form_Util::_Read_Defaults_Simple($def);
my $t900 = 900;
foreach my $time ( "AM", "PM" ){		
	foreach $day ( qw[ Mon Tue Wed Thr Fri] ) {
		my $tag  = "avail_" . $day . "_" . $time;
		$t900++;
#		$elements{$tag}++;
		$elements{$tag}{rank} = $t900;
	}
}

my @etags = sort ( keys  %elements);

my $Next_ID = get_NextID();
$Group_for_file_ownership = 0;
$Course_email = q{sms-course\@phas.ubc.ca};

1;

sub Intro {
    my $ifile = $Root ."lib/Intro";
	my $intro = slurp $ifile;
   
	return $intro;
}

sub new  {
    my $class = shift;
    my $self = { _permitted => \%elements };

    bless $self, $class;
 #   $self->{ID} = get_NextID(); 
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
    else    {  return $self->{$name};	      }	#get   
}

sub save {
    my $t  = shift;
  
    Debug::dsay("SMS_Person::save  line 80   save... [$t]");
    my $tab = " "x4;
	$xid = $t->{ID};
	my $sn = $t->{UBC_id};
 #   Debug::dsay("sshop::save   ID is  {$xid} sn is  {$sn}"); 
    my $f = get_file_name($sn);
 
  #  Debug::dsay("sshop::save  get a file name w ID  {$xid}  -- {$f}");

    open (O, ">$f") || die "cannot open $f $!\n"; 
    print O "<$xml_element>\n";

    foreach $e (@etags) {
        $out = defined ($t->{$e}) ? $t->{$e} : "";
 #       Debug::dsay("SMS_Person::save:: element {$e} value {$out}");
        print O $tab, "<$e>", $out,"</$e>\n" if $out;
    }

    print O "</$xml_element>\n";    
    close O;
##
## set the mod & ownership of file...; for now we do not worry about
## failures...$> is ggk for Real_user_id

    chmod 0664, $f;
    my $cnt = chown  $>, $Group_for_file_ownership, $f if ($Group_for_file_ownership);
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
   
   return $Next_ID unless -d $data_dir;
   opendir (D, $data_dir) || die "cannot open directory $data_dir \n";
   while (defined($f = readdir(D)))    {
       next unless $f =~ /(\d*).xml/;
       my $thisid = $1;
       $Next_ID = $thisid if  $thisid > $Next_ID;
   }
#   Debug::dsay("get_NextID:: id from data dir {$Next_ID");
   $Next_ID++;
   
 #     Debug::dsay("get_NextID:: return id  {$Next_ID");
   return $Next_ID;
}

sub course_name {
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
	Debug::dsay("get_Data:: reading dir [$data_dir]  ");
   my  @xfiles =  grep { /xml$/ } readdir (XD);
   closedir(XD);
   my @apps = ();
   
   foreach my $f (@xfiles) {
		Debug::dsay("get_Data:: reading file {$f}");
		my $s = rd_file($f); 
		push @apps, $s;
   }

   return @apps;
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

	my $sn   = shift;
	my $file = $data_dir.$sn;
	my $s = rd_file($file);
	
	return $s;
   ##opendir (XD, $data_dir ) || die "cannot get dir $data_dir  $! \n";
   ##my  @xfiles =  grep { /xml/ } readdir (XD);
   ##closedir(XD);
   #my %things = ();
   #foreach my $f (@xfiles) {
   #   my $s = rd_file($f);
   #   my $id = $s->{ID};
   # 
   ##   Debug::dsay ("get_Data_byID:: id is {$id}  ");
   #   $things{$id} = $s;
   #}
   #return %things;
}

sub get_Data_for_ID {  
## input is a ID & out is data object for that id 

   my $id = shift;
   my $s; 
   my $f = $data_dir . $id . ".xml";
   print " get_Data_for_ID \n";
   Debug::dsay ("get_Data_for_ID:: id  is {$id} [$f} "); 
   $s = get_app_hash($f);
  
   return $s;
}

sub filelist {    
   opendir (XD, $xml_dir) || die "cannot get dir $xml_dir $! \n";
   my  @xfiles =  grep { /xml/ } readdir (XD);
   closedir(XD);

   return @xfiles;
}

sub get_elements {	
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

sub datestr_to_array {
    my $d = shift;
    my @array = (split "-",$d);
}


sub get_Weeks2 {
   my @apps =  sshop_part::get_Data();
   my %weeks = ();
   my @out = ();
   foreach my $a ( @apps ) {
      foreach my $ii (1..3) {
          my $t = "preferred_week_".$ii;
          if (defined $a->{$t}) {
            $weeks{$a->{$t}}{count}++;
            $weeks{$a->{$t}}{$ii}++ ;
          }
      }
   }
   foreach my $w (sort byISO  keys %weeks ) {
       my $zut = sprintf "%s  %d ", $w,  $weeks{$w}{count};
       my $xot = sprintf "( %d, %d, %d )", (map $weeks{$w}{$_}, qw(1 2 3) );
       push @out, $zut . $xot;                
   }

   return @out;
}

sub get_InviteMessage {

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
        $body = qq{This is from mail-admin:: this should not happen};
    }
    mail_it($to, $from, $subj, $body);    

    return;  
}

sub mail_signup {
   Debug::dsay("SMS_person:: mail_signup ");
    my $mailer = "/usr/sbin/sendmail -oi -t ";	
 
    my $to = shift;
	my $body = shift;
  
    my $from = "sms_signup";
    my $subj = "SMS Course Registration";
     
     Debug::dsay("SMS_person:: $to $from $subj");
     Debug::dsay("SMS_person:: $body");

#	my $html_top =<<EndofTop;
#		<html>
#		<body>
#EndofTop
#	my $html_bot =<<EndofBot;
#		</body>
#		</html>
#EndofBot
#
#	$body = $html_top . $body . $html_bot;
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
#
    my $sn  = shift;
	my $cn = sn2cn($sn);

	return $cn;
}

sub sn2cn {
	my $sn = shift;
	my $r = reverse $sn;
    my @chars = split //, $r;

	my $s = $chars[0] + 65 +12;
	$chars[0] = chr $s;

	my $s2 = $chars[2] + 8 + 65;
	$chars[2] = chr $s2;
	$cn = join "",@chars;
	
	return $cn;
}

sub cn2sn {
	my $cn = shift;

	my @chars = split //, $cn;

	my $s = ord($chars[0]) - 12 - 65;
	$chars[0] =  $s;
	my $s2 = ord($chars[2]) - 8 - 65;
	$chars[2] =  $s2;

	$r = join "", @chars;
	my $u = reverse $r;

	return $u;
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

sub update_app_record {
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
 #	Debug::dsay("rd-file:: $f ");
    {
       open (X,$xml_file ) ||  return -1;
       local ( $/ );
       $_=<X>;
       close X;
    }

    m[<$xml_element>(.*?)</$xml_element>]msg;
    my $talk = $1;
    my $t = new SMS_Person;

    while  ($talk =~ m[<(\w+?)>(.*?)</\1>]msg) {
        next unless ($1 );
      	my $field = $1;
        my $value = $2;
        $value =~ s/\s*$//;
        $t->$field($value);
#	Debug::dsay("rd-file:: tag {$field} valu {$value} ");
    } 
    return $t;
}
sub get_app_hash {
#        input a filename 
#####    return Survey object reference...
	use CGI::Carp qw(fatalsToBrowser set_message);

    my $f = shift;
    $nl = "\n";
     Debug::dsay ("get_app_hash:: file  is {$f}  ");
    $xml_file =  $f ;   
 
    {
       open (X,$xml_file ) ||  return -1;
       local ( $/ );
       $_=<X>;
       close X;
    }

    m[<$xml_element>(.*?)</$xml_element>]msg;
    my $talk = $1;
    my %app = ();
    Debug::dsay("get_app_hash:: $talk ");
    while  ($talk =~ m[<(\w+?)>(.*?)</\1>]msg) {
        next unless ($1 );
      	my $field = $1;
        my $value = $2;
        $value =~ s/\s*$//;
        $app{$field} = $value;
        Debug::dsay("get_app_hash:: tag {$field} valu {$value} ");
    } 
    return \%app;
}


sub delete_file {
#        input an app id & delete the file
    my $id = shift;
 
    $id = $1 if ($id =~ /^(\d+)/);

    $nl = "\n";
    $xml_file = $data_dir  . $id . ".xml";
    Debug::dsay("sshop_part::delete file:: {$xml_file} is to be deleted");
    my $nfile = $data_dir  . "Deleted/" . $id . ".xml";
    rename $xml_file, $nfile || die " cannot rename $xml_file "; 
}

sub set_group {
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

sub get_weeklist {
    use Date::Calc qw( Add_Delta_Days Week_of_Year);
    my $nweeks = shift;
    my @start  = @_;
    my @out = ();
    foreach my $i ( 0..$nweeks )  {
       my $weeknum = Week_of_Year(@start);
       my $iso = sprintf "%4d-%2.2D-%2.2d", @start;
       @fri =  Add_Delta_Days(@start,3);
       my $fso = sprintf "%4d-%2.2D-%2.2d", @fri;
       @start =  Add_Delta_Days(@start,7);
       push @out, sprintf "week: %s - %s to %s", $weeknum, $iso, $fso;
    }
    return @out;

} 

sub get_date_time {
    my ($s, $Min, $Hrs,$mday, $month,$year) = localtime();
    $year += 1900;
    $month++;
    my $xx = sprintf ("%4d-%2.2d-%2.2dT%2.2d:%2.2d", $year, $month, $mday,$Hrs,$Min);
}

sub is_tainted {
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
   
    if ( $a =~ /(\d\d\d\d)-(\d\d)-(\d\d)/) {
		$ay = $1;
        $am = $2;
        $ad = $3;
    } else
    {  	$ay = $am = $ad = 0 ;
    }
    if ( $b =~ /(\d\d\d\d)-(\d\d)-(\d\d)/)  {
		$by = $1;
        $bm = $2;
        $bd = $3;
    } else {
		$by = $bm = $bd = 0 ;
    }

    $ay <=> $by ||
    $am <=> $bm ||
    $ad <=> $bd;
}
