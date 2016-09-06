package SMS_html_Util;

use lib "/www/Gform/lib/";
use lib "../lib";

use Form_Util;
use Date::Calc qw (Today);
my $today = printf "%4d-%2.2d-%2.2d", Today();
my $bs_style = "buttonstyle";    

1;


sub sms2form {
    Debug::dsay("sms2form:: ..." );
    my $app = shift;
    my $q   = shift;

	my %element_info = SMS_Person::get_element_info();
    foreach my $t ( keys %element_info ) {
        next unless $app->{$t};
		my $vv =  $app->{$t};
        next if ($t eq "_permitted" );
#        if ($t =~ /^avail/) {
#            Debug::dsay("sms2form:: t is [$t]" );
#			my $val = $app->{$t};
#			$q->param(name =>$t, value =>$val);
#          
#        } else {
           
			$val = $app->{$t};
            $q->param(-name=>$t, -value=>$val);
#        }
    }
    return $q;
}
sub student_register {

	my $q = shift;
	my $my_cat = shift;
    Debug::dsay("student_register:: cat  [$my_cat]" );

	my $qsub =$q->submit( -name  => "Submit_Reg",
						   -class => $bs_style,      
						   -value => "Submit"); 

    my %element_info = SMS_Person::get_element_info();
	my $out = "";
	$out .= qq{<div id="inputform">};
    $out .=  qq{<table class="appinfo">\n};

    foreach my $t ( sort {$element_info{$a}{rank} <=>
                          $element_info{$b}{rank} }
                   keys %element_info ) {
   ###  Debug::dsay("do_form:: t is {$t}");
   
        my $this_cat = $element_info{$t}{cat};
		next if ( $element_info{$t}{cat} eq "admin"
				  and $my_cat ne "admin"
				);
		next if ( $element_info{$t}{cat} eq "internal" );

		my $value = $q->param($t) ? $q->param($t) : "" ;
		my $pout  = $element_info{$t}{prompt} ? $element_info{$t}{prompt}: "";
		my $qout  = $element_info{$t}{qtype}  ? $element_info{$t}{qtype} : "";
		next unless $pout;
		$pout =~ s[\s+][\&nbsp;]g;
     
		$out .= qq{<tr> <td class="prompt"> $pout: </td>\n    }; 
    
		$value = $today  if ($t eq "date" and !$value);                
		my $xinp = Form_Util::input_query(\%{$element_info{$t}}, $t, $value);

		my $req = defined ($element_info{$t}{required})
             ? qq{<span class="req">  &#9756; required </span>}
			 : q[&nbsp;];

		$out .= qq{<td class="input"> $xinp $req </td>};
		$out .= qq{</tr>\n};
	
	}
	$out .= mk_avail_table($q);
	$out .= qq{<p>$qsub</p>};
	$out .= qq{</div>};

#	$out .=  qq{ <tr><td class="explain" colspan="2"> Below is the list of upcoming courses.
# 
#    You can check the
#	<a href="JavaScript:newPopup('http://gamma.phas.ubc.ca/cgi-bin/SMS2/mkcal');">SMS Calendar</a> for available dates.
#              </td></tr>};
# 
#	my $data = course_metadata::get_Course_Data_json();
#	my @courses = @{$data->{course_data}};
#	my $ctable = "";
#	my $headers = qq{<tr>};
#	$headers   .= qq{<th class="ct">Modules</th>};
#	$headers   .= qq{<th class="ct">Title</th>};
#	$headers   .= qq{<th class="ct">Date</th>};
#	$headers   .= qq{<th class="ct">Request</th>};
#	$headers   .= qq{<th class="ct">Registered</th>};
#	$headers   .= qq{<th class="ct">Completed</th>};
#	$headers   .= qq{</tr>};
#	my $modnum;
#	foreach my $c (  @courses ) {
#		$modnum = $c->{num};
#		my $title  = $c->{title};
#		$ctable .= qq{  <tr><td class="ct"> Module # $modnum</td>};
#		$ctable .= qq{      <td  class="ct"> $title</td>};
#		my @dates = @{$c->{date_upcoming}};
#		my $dtable = qq{<table class="dtable"><tr>};
#		$ctable .= qq{  <td  class="ct">};
#		foreach my $date ( @dates ) {
#			next if $date < $isotoday;
#			$ctable .= qq{  $date<br />};
#		}
#		$ctable .= qq{</td> <td  class="ct"> };
#		foreach my $date ( @dates ) {
#			next if $date < $isotoday;
#			my $but = "$modnum.ask.$date";
#            
#			my $xbut = $q->checkbox(-name=>$but,
#			                        -checked=>0,
#									-value=>'ON',
#									-label=>' ');
#			$ctable .= qq{  $xbut<br />};
#		}
#		$ctable .= qq{</td> <td  class="ct"> };
#		foreach my $date ( @dates ) {
#			next if $date < $isotoday;
#			$ctable .= qq{     --<br />};
#		}
#		$ctable .= qq{</td> <td  class="ct"> };
#		foreach my $date ( @dates ) {
#			next if $date < $isotoday;	
#			$ctable .= qq{  --<br />};
#		}
#		$ctable .= qq{</td> };
#		$ctable .= qq{</tr>\n};
#    }
#	$out .= qq{<table id="ctable">$headers $ctable</table>};     

	return $out;
}

sub edit_student_register {

	my $q = shift;
	my $my_cat = shift;
	my $sn = shift;
    Debug::dsay("student_register:: cat  [$my_cat]" );

	my $qsub =$q->submit( -name  => "Submit_Reg",
						   -class => $bs_style,      
						   -value => "Submit"); 
	my $this_app     = SMS_Person::get_app_by_ID($sn);
	$q = SMS_html_Util::sms2form ( $this_app,   $q );

    my %element_info = SMS_Person::get_element_info();
	my $out = "";
	$out .= qq{<div id="inputform">};
    $out .=  qq{<table class="appinfo">\n};

    foreach my $t ( sort {$element_info{$a}{rank} <=>
                          $element_info{$b}{rank} }
                   keys %element_info ) {
   ###  Debug::dsay("do_form:: t is {$t}");
		next if ( $element_info{$t}{cat} eq "admin"
				  and $my_cat ne "admin"
				);
		next if ( $element_info{$t}{cat} eq "internal" );

		if ($t =~ /_[AP]M$/) {
			
			my $tag  = "avail_" . $t;
			my $value = $this_app->{$t};
		}

		my $value = $this_app->{$t} ? $this_app->{$t} : "" ;
		my $pout  = $element_info{$t}{prompt} ? $element_info{$t}{prompt}: "";
		my $qout  = $element_info{$t}{qtype}  ? $element_info{$t}{qtype} : "";
		next unless $pout;
		$pout =~ s[\s+][\&nbsp;]g;
     
		$out .= qq{<tr> <td class="prompt"> $pout: </td>\n    }; 
    
		$value = $today  if ($t eq "date" and !$value);                
		my $xinp = Form_Util::input_query(\%{$element_info{$t}}, $t, $value);

		my $req = defined ($element_info{$t}{required})
                ? qq{<span class="req">  &#9756; required </span>}
			    : q[&nbsp;];

		$out .= qq{<td class="input"> $xinp $req </td>};
		$out .= qq{</tr>\n};
	
	}
	$out .= mk_avail_table($q);
	$out .= qq{<p>$qsub</p>};
	$out .= qq{</div>};


	return $out;
}


sub check_input {
	my $q = shift;
	my %element_info = SMS_Person::get_element_info();
	my $out = "";

	foreach my $p ( $q->param ) {
		my $input = $q->param($p);
		next if $input;
		if  (defined ($element_info{$p}{required}) )	{
			$out .= qq{Field $p is Required !! <br />};
		}
	}
	$out = qq{<div class="warn"> $out </div> } if ( $out ); 
		
	return $out;
}

sub mk_avail_table {

	my $q = shift;
	my $out = "";

#	$out .= qq{ <p> Below is a table with which you can indicate your availibility
#				for SMS courses.  Uncheck the slots where you would NOT be available
#               </p>};

	$out .= qq{<table id="avail">};
    $out .= qq{<caption> <p> Below is a table with which you can indicate your availibility
				for SMS courses.  Check the slots where you would  be available
               </p></caption>};
	$out .= qq{<tr class="avail_head">};
	$out .= qq{   <th class="avail_head"> &nbsp; </th>};
	$out .= qq{   <th class="avail_head"> Mon </th>};
	$out .= qq{   <th class="avail_head"> Tue </th>};
	$out .= qq{   <th class="avail_head"> Wed </th>};
	$out .= qq{   <th class="avail_head"> Thr </th>};
	$out .= qq{   <th class="avail_head"> Fri </th>};
	$out .= qq{   </tr>};

	$out .= qq{<tr class="avail">\n};
	foreach my $time ( "AM", "PM" ){
		$out .= qq{   <td class="avail"> $time </td>\n};
		foreach my  $day ( qw[ Mon Tue Wed Thr Fri] ) {
			my $butname = $day . "_" . $time;
			my $tagname = "avail_" . $butname;
			my $pq = $q->param($tagname);

			my $checked = $q->param($tagname) ? 1 : 0;
			my $value   = $checked ? "Yes" : "no";

			my $but = $q->checkbox(-name=>$tagname,
			                       -checked=>$checked,
			                       -value=>$value,
			                       -label=>'Available ');
			$out .= qq{   <td class="avail"> $but</td>\n};
		}
		$out .= qq{   </tr>\n};
	}
	$out .= qq{   </table>\n};
}
	