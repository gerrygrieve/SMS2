package course_metadata;

my $Debug = 1;
use Data::Dumper;
use JSON;
my $jfile = "/www/Gform/SMS/lib/coursedata.json";

1;

sub put_Course_Data_json {

	my $data = shift;
	my $nfile = "$jfile.$$";
	$nfile =~ s[lib/][lib/oldjson/];
	rename $jfile, $nfile;

	my $json    = JSON->new->allow_nonref;
	my $pretty  = $json->pretty->encode( $data );

	open  O, ">", $jfile || die "Cannot open $jfile\n";
	print O $pretty;
	close O;

}

sub get_Course_Data_json {
	
	use Perl6::Slurp;

	my $json  = slurp $jfile;
	my $data  = decode_json($json);
	return $data;
}

sub get_Courses_by_ModNum {
	my $data = course_metadata::get_Course_Data_json();
	my @courses = @{$data->{course_data}};
	
    my %out = ();
	foreach my $c (  @courses ) {
		my $modnum = $c->{num};
        $out{$modnum}{title} = $c->{title},
        $out{$modnum}{desc}  = $c->{desc};
    }
    return %out;
}
sub get_Course_Data_XML {
	use XML::Simple;
	#my $xml_file = "/www/Gform/SMS/lib/coursedata.xml";
	my $xml_file = "../coursedata.xml";

	my $xs1 = XML::Simple->new();
	my $data = $xs1->XMLin($xml_file, KeyAttr => [],
                                 ForceArray => ['date_upcoming']);

	print Dumper($data) if $Debug;
	my @courses = @{$data->{course}};

	return \@courses;
}