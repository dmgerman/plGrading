


sub inList
{
    my ($v, $list) = @_;
    foreach my $i (@$list) {
#	print "comparing [$i][$v]\n";
	return 1 if "$i" eq "$v";
    }
    return 0;
}


1;
