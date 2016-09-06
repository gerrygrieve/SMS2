package sshop;

###
### 2011-06-08 grieve
###

use lib "/www/Gform/lib";
use Form_Util;

use Data::Dumper;
my $Root = '/www/Gform/sshop/';

$data_dir   = $Root . "Data/";
my $def     = $Root . "lib/sshop_part.def";
my $exweeks = $Root . "lib/excluded_weeks";
my $invite  = $Root . "lib/invitemessage";
$xml_element = "sshop_part";
print "sshop \n";
my %elements = Form_Util::_Read_Defaults_Simple($def);

my @etags = keys  %elements;
my $Next_ID = get_NextID();
$Group_for_file_ownership = 0;
print "sshop returning 1  \n";


1;
