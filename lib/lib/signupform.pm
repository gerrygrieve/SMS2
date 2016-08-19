package signupform;

## this is to handle html issue for the student shop signup..

use lib "/www/Gform/sshop/lib/";
use sshop_part;
use Date::Calc qw (Today Week_of_Year Monday_of_Week Add_Delta_Days);
my $tdtopright = '<td valign="top" align="right">';
my $tdtop      = '<td valign="top">';
my $sp = '&nbsp;';
my $today     = sprintf ("%04d-%02d-%02d", Today() );

1;

sub new_App_Data {
    my $q = shift;
    
    Debug::dsay (" this is signupform::new_App_Data ");
    my %element_info = my %el_info =  sshop_part::get_element_info();
    
    my $out = "";

    $out .= qq{<table class="appinfo">\n};   
    foreach my $t ( sort {$element_info{$a}{rank} <=>
                          $element_info{$b}{rank} } keys %element_info ) {
   ###  Debug::dsay("do_form:: t is {$t}");
    #    $out .= "<p> tag {$t} is typed {$element_info{$t}{qtype}}</p>" 
    #   if ($element_info{$t}{qtype} eq "AoH");
        my $value = $q->param($t) ? $q->param($t) : "" ;
        my $pout = $element_info{$t}{prompt} ? $element_info{$t}{prompt}: "";
        my $qout = $element_info{$t}{qtype}  ? $element_info{$t}{qtype} : "";
        next unless $pout;
        $pout =~ s[\s+][\&nbsp;]g;
        next if ($t =~ /omment/);
        last if ($t =~ /week/);
        $out .= qq{<tr> <td class="prompt"> $pout: </td>\n}; 
    
        $value = $today  if ($t eq "date" and !$value);                
        my $xout = Form_Util::input_query(\%{$element_info{$t}}, $t, $value);
 
        $out .=  qq{<td class="input"> $xout</td></tr>\n};
   }
    
    $out .= qq{ <tr><td class="explain" colspan="2"> Please use the calendar tools bellow to selcted one or more preferred week in which
                                   you would like to attend a student shop course.  The courses are normally held
                                   4 consecutive days (Tues, Wed, Thrus & Fri).
    You can check the
            <a href="JavaScript:newPopup('http://gamma.phas.ubc.ca/cgi-bin/SMS/mkcal');">SMS Calendar</a> for available dates.
              </td></tr>};
             
    foreach my $i (1..3) {
        $out .= qq {<tr>  <td class="prompt">Preferred Week $i:</td>
                        <td class="input"><div><input id="week$i" type="text" size='60' name="preferred_week_$i"></div></td></tr>\n};
    }
    $out .= qq{<tr><td class="explain" colspan="2"> You can also set an excluded interval during which you};
    $out .= qq{            would be unavailable for the training course ( away on vacation, say). };
    $out .= qq{          </td></tr>};
    $out .= qq {<tr><td class="prompt">Excluded\&nbsp;Interval\&nbsp;Start:</td>
                  <td class="input"><div><input id="mystart" type="text" size='60' name="excluded_from"></div></td></tr>\n};
    $out .= qq {<tr><td class="prompt">Excluded Interval End:</td>
                  <td class="input"><div><input id="myend" type="text" size='60' name="excluded_to"></div></td></tr>\n};

###write the Comments...
     my $t = "comment";
     my $value = $q->param($t) ? $q->param($t) : "" ;
     my $pout = $element_info{$t}{prompt} ? $element_info{$t}{prompt}: "";
     my $qout = $element_info{$t}{qtype}  ? $element_info{$t}{qtype} : "";
     $out .=  qq{<tr> <td class="prompt"> $pout: </td>\n};                   
     my $xout = Form_Util::input_query(\%{$element_info{$t}}, $t, $value);
     $out .=  qq{<td class="input"> $xout</td></tr>\n};  
     $out .= "</table>\n";

    return $out;   
}


sub App_Data {
    my $ap = shift;
    my %element_info =  sshop_part::get_element_info();

	my $out = qq{<h2> App Data Page</h2>};
	$out .=   qq{<table border="0" cellpadding="4" cellspacing="10">\n};   
	foreach my $t ( sort {$element_info{$a}{rank} <=>
                          $element_info{$b}{rank} }
				      keys %element_info ) {
		my $value = $ap->{$t} ? $ap->{$t} : "" ;
		my $pout = $element_info{$t}{prompt} ? $element_info{$t}{prompt}: "";
		my $qout = $element_info{$t}{qtype}  ? $element_info{$t}{qtype} : "";
		next unless $pout;
		$out .= qq{<tr>$tdtopright  $pout: </td>\n};
		if ($qout) {
			  my $x = Form_Util::input_query(\%{$element_info{$t}}, $t, $value);
			  $out .= qq{     $tdtop $x</td></tr>\n};
		} else {
			 $out .= qq {  $tdtop $value</td></tr>\n};
		}
   }
   $out .=    "</table></center>\n";
   return $out;
}

sub mail_signup {
#
    use sshop_part;
    my $to   = shift;
    my $body = shift;
    
       Debug::dsay("sshop:: mail_signup to is {$to} ");
    my $from = "sms_signup";
    my $subj = "New SMS Course Application";

    sshop_part::mail_it($to, $from, $subj, $body);    

    return;
}
sub mk_myfuncs {
      # Get the excluding times...
      my $ex = get_exdates();
      my $enddate = "2014-12-30";
      my $out = << "EndofScript";
<script type="text/javascript">
\$(document).ready(function() {    
    \$(\'#week1\').Zebra_DatePicker({
      show_week_number: "w#",
      disabled_dates: [\'* * * 0,6\', $ex],
      direction: [true,$enddate],
      });
    \$(\'#week2\').Zebra_DatePicker({
      show_week_number: "w#",
      disabled_dates: [\'* * * 0,6\', $ex],
      direction: [true,$enddate],
                  });
    \$(\'#week3\').Zebra_DatePicker({
      show_week_number: "w#",
      disabled_dates: [\'* * * 0,6\', $ex],
      direction: [true,$enddate],
                   });
    \$(\'#mystart\').Zebra_DatePicker({
        direction: ["2014-01-07", "2014-12-20"],
	ret_week: false,
	pair: \$('#myend')
    });
    \$(\'#myend\').Zebra_DatePicker({
        direction: ["2014-01-07", "2014-12-20"],
	ret_week: false
    });

 });
 function newPopup(url) {
    popupWindow = window.open(
		  url,'popUpWindow',
                 'height=700,width=900,left=10,top=10,resizable=yes,scrollbars=no,toolbar=no,menubar=no,location=no,directories=no,status=yes')
 }
 
</script>
EndofScript
}


sub get_exdates {
	Debug::dsay("get_exdates::");
    my %weeks =  sshop_part::get_excluded_weeks();
    my $sv = $weeks{"start"};
    my $lv = $weeks{"last"};
      Debug::dsay("get_exdates::start {$sv} end {$lv}");
    my %eweeks = %{$weeks{"excluded"}};
    my $out ="";
    foreach my $e ( keys  %eweeks ) {
       my $days ="";
       my ($y, $m,$d) = split "-", $e;
 
       my $wk = Week_of_Year($y,$m,$d);
       my ($my,$mm,$md) = Monday_of_Week($wk,$y);
      
       my ($fy,$fm,$fd) = Add_Delta_Days($my,$mm,$md,4);
 
       if ( $mm == $fm) {
            $days = qq{'$md-$fd $mm $my'}; ;
       } else {
          if ($fd > 1) { $days = qq{'1-$fd $fm $fy'}; }
          else         { $days = qq{'$fd $fm $fy"};}
          my ($xy,$xm,$xd) = Add_Delta_Days($my,$mm,$md,$fd);   # get last days og monday's month
          $days = qq{'$md-$xd $mm $my',$days};
       }
       $out .= $days . ",";
    }
    return $out;    
}
