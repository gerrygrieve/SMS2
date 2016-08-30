package SMS_html_Util;

use lib "/www/Gform/lib/";
use lib "/www/Gform/SMS/lib";

use Form_Util;

my $bs_style = "buttonstyle";    


1;
sub sms2form {
    Debug::dsay("sms2form:: ..." );
    my $app = shift;
    my $q   = shift;
    foreach my $t ( keys %{$app} ) {
        next unless $app->{$t};
        next if ($t eq "_permitted" );
        if ($t =~ /^\d/) {
            Debug::dsay("sms2form:: dated t is [$t]" );
           my $tt = $t.$app->{$t};
           $q->param($tt) = "ON";
        } else {
             Debug::dsay("sms2form:: simple t is [$t]" );
            $q->param($t) = $app->{$t};
        }
    }
    return $q;
}
sub student_register {

	my $q = shift;
	my $my_cat = shift;
           Debug::dsay("student_register:: cat  [$my_cat]" );

	use SMS_Person;
    my %element_info = SMS_Person::get_element_info();
	my $out = "";

    $out .=  qq{<table border="1" cellpadding="4"
                       cellspacing="10" width="600px">\n};

    foreach my $t ( sort {$element_info{$a}{rank} <=>
                          $element_info{$b}{rank} }
                   keys %element_info ) {
   ###  Debug::dsay("do_form:: t is {$t}");
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
             ? qq{<span id="req"> required </span>}
			 : q[not required];

		$out .= qq{<td class="input"> $xinp $req xxxxx</td>};
		$out .= qq{</tr>\n};
	
	}
	$out .= mk_avail_table($q);

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

sub mk_avail_table {

	my $q = shift;
	my $out = "";

#	$out .= qq{ <p> Below is a table with which you can indicate your availibility
#				for SMS courses.  Uncheck the slots where you would NOT be available
#               </p>};

	$out .= qq{<table id="avail">};
    $out .= qq{<caption> <p> Below is a table with which you can indicate your availibility
				for SMS courses.  Uncheck the slots where you would NOT be available
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
		foreach $day ( qw[ Mon Tue Wed Thr Fri] ) {
			my $butname = $day . "_" . $time;
			my $but = $q->checkbox(-name=>$butname,
			                       -checked=>1,
			                       -value=>'ON',
			                       -label=>'Available ');
			$out .= qq{   <td class="avail"> $but</td>\n};
		}
		$out .= qq{   </tr>\n};
	}
	$out .= qq{   </table>\n};
}
	