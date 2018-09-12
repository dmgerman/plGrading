package ccparse;

require "clone.pm";
use strict;
use support;



sub new 
{
    my ($class, $file, $prefix) = @_;
    my $self = {_prefix => $prefix};

    bless $self, $class;

   $self->parse_stdin;

#    $self->load($file);
#    $self->parse;


#    $self->print("output");
#   
#    $self->load_Token_Files;
#    $self->create_Clones;
    return $self;
}

sub load
{
    my ($self,$filename) = @_;
    $self->{file} = $filename;
    my $save = $/;
    undef $/;
    open (IN, $self->{file}) or die "unable to open clone file [$filename]";
    $self->{data} = <IN>;
    close IN;
    $/ = $save;
}

sub iterate_Files
{
    my ($self, $parms) = @_;
    
    my $files = $self->{files};

    foreach my $file (@$files) {
#	printf("%d\t%s\t%d\n", $file->{index}, $file->{name}, $file->{size});
	my $f = $parms->{function};
	&$f($self, $file, $parms);
    }
}

sub print_Clones_Set_Selected
{
    my ($self, $set, $fname) = @_;
    my %parms;
    open (OUT, ">$fname") or die  "unable to create output file [$fname]\n";
    $parms{function} = sub { my ($self, $clone) = @_; print OUT $clone->print, "\n";  };
    $self->iterate_Clones_In_Set($set, \%parms);
    close OUT;
}

sub extract_Clones_Set_Selected
{
    my ($self, $set) = @_;
    my %parms;
    $parms{function} = sub { my ($self, $clone) = @_; $clone->save;  };
    $self->iterate_Clones_In_Set($set, \%parms);
}

sub extract_Clones_Abstract_Set_Selected
{
    my ($self, $set) = @_;
    my %parms;
    $parms{function} = \&extract_Clone_Abstract;
    $self->iterate_Clones_In_Set($set, \%parms);
}



sub iterate_Clones_In_Set
{
    my ($self, $set, $parms) = @_;
    
    my $clones = $self->{clones};

    foreach my $clone (@$clones) {
	if (inList($clone->setId, $set) > 0) {
	    my $f = $parms->{function};
	    &$f($self, $clone, $parms);
	}
#	printf("%d\t%s\t%d\n", $file->{index}, $file->{name}, $file->{size});
    }
}



sub load_Token_Files
{
    my $self = shift;

    my $files = $self->{files};
    my @result;
    foreach my $f (@$files) {
	push @result, $self->load_Token_File($f ->{name});
    }
    $self->{tokens} = [@result];
}

sub load_Token_File
{
    my ($self,$name) = @_;
    my $lang = $self->{preprocess};
    my $fileName = $name . ".${lang}.ccfxprep";
#    print "Before:[$fileName]\n";
    my $prefix = $self->{_prefix};
    $fileName =~ s/^$prefix//;
#    print "After:[$fileName]\n";
    my $t = cctokens->new($fileName);
    return $t;
}



sub print
{
    my ($self, $fname) = @_;
    
    open(OUT, ">$fname") or die "Unable to open output file [$fname]";
#    $self->print_Options;
    
    print OUT $self->print_Files;
    print "---------------\n";
    $self->print_Clone_Pairs;
#    $self->print_Clones_w_Lines;
#    print OUT $self->print_Clones;

    close OUT;
}

sub extract_Clone
{
    my ($self, $clone,$parms) = @_;
    $clone->save;
}


sub extract_Clone_Abstract
{
    my ($self, $clone,$parms) = @_;

    # we need the index, and the 
    
    my $file = $clone->fileIdx;
    my ($from, $to) = $clone->tokens;

    my $tokens = $self->{tokens};

    die "illegal index [$file] to token data (" . scalar(@$tokens) . ")" if $file >= scalar(@$tokens);
    
    my $newFname = $clone->clean_FileName;

    my $fname = $clone->generate_FileName("cloneToken");

    open (OUT, ">$fname") or die "Unable to create output file $fname" ;

    print OUT $$tokens[$file]->token_Sequence($from, $to) . "\n";
    close;

    my $fname = $clone->generate_FileName("cloneAbs");
    open (OUT, ">$fname") or die "Unable to create output file $fname" ;
    print OUT $$tokens[$file]->token_Sequence_Abstract($from, $to) . "\n";
    close;
}


sub iterate_Clones_Pairs
{
#    my $self = shift;
    my ($self, $parms) = @_;

    my $clones = $self->{clonePairs};

    foreach my $clone (@$clones) {
#	printf("%d\t%s\t%d\n", $clone->{fromFile}, $clone->{toFile}, $clone->{cloneSetId});
	my $f = $parms->{function};
	&$f($self, $clone, $parms);
    }
}

sub iterate_Clones_Selected
{
#    my $self = shift;
    my ($self, $parms) = @_;

    my $clones = $self->{clones};

    foreach my $clone (@$clones) {
#	printf("%d\t%s\t%d\n", $file->{index}, $file->{name}, $file->{size});
	my $f = $parms->{function};
	my $select = $parms->{select_function};
	if (&$select($self, $clone, $parms)) {
	    &$f($self, $clone, $parms);
	}
    }
}


#sub print_File
#{
#    my ($self,$file) = @_;
#    
#    printf("%d\t%s\t%d\n", $file->{index}, $file->{name}, $file->{size});
#
#}

sub abc
{
    print "It gets called\n";
    die;
}

sub print_Files
{
    my $self = shift;

    my %parms;
#    my $a = \&abc;
#    &$a();
#    $parms{function} = \&print_File;
    my $files = $self->{files};
    my $result = "TOTALFILES: " .  scalar(@$files) . "\n";
    $parms{function} = sub { my ($self,$file) = @_;
			     $result .= sprintf("%d\t%s\t%d\n", $file->{index}, $file->{name}, $file->{size})};
#    print "source_files {\n";
    $self->iterate_Files(\%parms);
    return $result;
#    print "}\n";
}


sub print_Options
{
    my $self = shift;
    
    printf("version: %s %d.%d.%d\n", substr($self->{magicNumber},0,4),
	   $self->{version},$self->{subVersion}, $self->{subsubVersion});
    
    if ($self->{format} eq "pa:d") {
	print "format: pair_diploid\n";
    } else {
	die "Unknown format\n";
    }
    printf (<<END
option: -b %d // minimumCloneLength
option: -s %d // shapingLevel
option: -u %d // useParameterUnification
option: -t %d // minimumTokenSetSize
preprocess_script: %s
END
, $self->{minLength},$self->{shapingLevel},$self->{useParamUnif},$self->{tokenSetSize},$self->{preprocess});
    
}


sub parse
{
    my $self = shift;

    $self->parse_Header;
    
#    my @files;
    $self->parse_Files;
    $self->parse_Remarks;
#    $self->print_Files;
    $self->parse_Clone_Pairs;
}

sub parse_stdin
{
    my $self = shift;

    $self->parse_Header_plain;
    
#    my @files;
    $self->parse_Files_plain;
    $self->parse_Remarks_plain;
#    $self->print_Files;
    $self->parse_Clone_Pairs_plain;
}

sub parse_Header_plain
{
    my $self = shift;
    while (<>) {
        last if /source_files/;
    }
}

sub parse_Files_plain
{
    my $self = shift;
    my $i=0;
    $self->{files} = [];
    my $files = $self->{files};
    while (<>) {
        chomp;
        my @f = split(/[\t]+/);
        last if /^}/;
        $i++;
	push @$files, {'name' => $f[1], 
		      'index' => $f[0], 
		      'size' => $f[2]};
    }
    print STDERR "Files Read $i\n";
#    $self->{files} = [@files];
#    print $self->print_Files;
    print STDERR ".>>" , $self->count_Files(), "\n";
}

sub parse_Remarks_plain
{
    my $self = shift;
    while (<>) {
        last if /clone_pairs/;
    }
}

sub parse_Clone_Pairs_plain
{
    my $self = shift;
    # foreach file 
    #   name
    #   index
    #   size in tokens
    my $result;
    my %clone ;

    $self->{clonePairs} = [];
    $result = $self->{clonePairs};
    while (<>) {
        chomp;
        %clone = ();
        $clone{unknown} = 0;

        last if /^}/;
        die "illegal format [$_] in clone pair " unless
            /([0-9]+)\t([0-9]+)\.([0-9]+)\-([0-9]+)\t([0-9]+)\.([0-9]+)\-([0-9]+)/;
#        next if $2 > 30000;
        (
         $clone{cloneSetId},
         $clone{fromFile},$clone{fromBeginToken},$clone{fromEndToken},
         $clone{toFile},$clone{toBeginToken},$clone{toEndToken}
        ) = ($1,$2,$3,$4,$5,$6,$7);
#        print "CLone  $clone{fromFile},$clone{fromBeginToken},$clone{fromEndToken}, $clone{toFile},$clone{toBeginToken},$clone{toEndToken}, $clone{cloneSetId},$clone{unknown}\n";
        die unless $clone{unknown} == 0;
        last if $clone{unknown} == 0 && 
            $clone{fromFile} == 0 &&
            $clone{fromBeginToken} == 0 &&
            $clone{fromEndToken} == 0 &&
            $clone{toFile} == 0 &&
            $clone{toBeginToken} == 0 && 
            $clone{toEndToken} == 0&& 
            $clone{cloneSetId} == 0;
        $clone{fromLen} = $clone{fromEndToken} - $clone{fromBeginToken};
        $clone{toLen} = $clone{toEndToken} - $clone{toBeginToken};
        push @$result, {%clone};
#        # no invert it
#        my %cloneInv = ();
#        $cloneInv{unknown} = $clone{unknown};
#        $cloneInv{toFile} = $clone{fromFile};
#        $cloneInv{toBeginToken} = $clone{fromBeginToken};
#        $cloneInv{toEndToken} = $clone{fromEndToken};
#        $cloneInv{fromFile} = $clone{toFile};
#        $cloneInv{fromBeginToken} = $clone{toBeginToken};
#        $cloneInv{fromEndToken} = $clone{toEndToken};
#        $cloneInv{cloneSetId} = $clone{cloneSetId};
#        $cloneInv{fromLen} = $clone{toLen};
#        $cloneInv{toLen} = $clone{fromLen};
#	push @result, {%cloneInv};
    } 
#    $self->{clonePairs} = [@result];
#    print "added ", scalar(@result) / 2, " clone pairs\n";
}


sub create_Clones
{
    my $self = shift;


    my $clonePairs = $self->{clonePairs};

    my @newClones = ();
#    print "clone_pairs {\n";
    foreach my $clonePair (@$clonePairs) {
	last if $clonePair->{fromFile} == 0;

	my $clone =clone->new($clonePair->{cloneSetId},
			      $clonePair->{fromFile},
			      $self->translate_Filename($clonePair->{fromFile}),
			      $clonePair->{fromBeginToken},
			      $self->get_Token_Line_Col_Byte($clonePair->{fromFile},
							     $clonePair->{fromBeginToken}),
			      $clonePair->{fromEndToken},
			      $self->get_Token_Line_Col_Byte($clonePair->{fromFile},
							     $clonePair->{fromEndToken})
	    );

	my $repeated = 0;
	foreach my $c (@newClones) {
	    # the clone is already inserted...
	    # then skip to next
	    if ($clone->equal($c)) {
		$repeated =1;
		last;
	    }
	}
	if (!$repeated) {
	    push @newClones, $clone;
	} 
    }
    print STDERR "added ", scalar(@newClones), " clones\n";
#    print "}\n";
    $self->{clones} = [@newClones];
}

sub count_Clones
{
    my $self = shift;
    my $c = $self->{clones};

    return scalar(@$c);
    
}

sub count_Files
{
    my $self = shift;
    my $c = $self->{files};

    return scalar(@$c);
    
}

sub get_Clone
{
    my ($self,$index) = @_;
    my $c = $self->{clones};

    die "Illegal index to get clone [$index] (out of " . $self->count_clones .  ")" 
	unless ($index >= 0 && $index < $self->count_Clones);

    return $$c[$index];
    
}

sub get_File
{
    my ($self,$index) = @_;
    my $c = $self->{files};
    $index --;
    die "Illegal index to get clone [$index] (out of " . $self->count_Files .  ")" 
	unless ($index >= 0 && $index < $self->count_Files);

    die "files are not in the same order internally as in the outside " unless $index + 1 == $$c[$index]->{index};
    return $$c[$index];
    
}


sub get_Token_Line_Col_Byte
{
    my ($self,$fileIdx,$token) = @_;
    my $t = $self->{tokens}[$fileIdx-1];
    return $t->token_Translate($token);
}


sub translate_Filename
{
    # convert a file number to real filename
    my ($self,$fileIdx) = @_;
    my $files = $self->{files};
    # fileidx is out offset by one
    $fileIdx --;
    die "out of range [$fileIdx]" unless $fileIdx >= 0 and $fileIdx < scalar(@$files);

    # let us make sure that they are always ordered
    die "we need to scan the list" unless $$files[$fileIdx]->{index} == $fileIdx+1;

    return $$files[$fileIdx]->{name};
}


sub get_Clone_Pairs
{
    my $self = shift;

    my $clones = $self->{clonePairs};
    return $clones;
}

sub print_Clone_Pairs
{
    my $self = shift;

    my $clones = $self->{clonePairs};

    print "clone_pairs {\n";
    foreach my $clone (@$clones) {
	last if $clone->{fromFile} == 0;

	printf("%d\t%d.%d-%d\t%d.%d-%d\n", $clone->{cloneSetId},
	       $clone->{fromFile},$clone->{fromBeginToken},$clone->{fromEndToken},
	       $clone->{toFile},$clone->{toBeginToken},$clone->{toEndToken});
    }
    print "}\n";
}

sub extract_Clones
{
    my $self = shift;
    my %parms;
    $parms{function} = \&extract_Clone;

    $self->iterate_Clones(\%parms);
    
}

sub extract_Clones_Abstract
{
    my $self = shift;
    my %parms;
    $parms{function} = \&extract_Clone_Abstract;

    $self->iterate_Clones(\%parms);
    
}



sub print_Clones
{
    my $self = shift;
    my %parms;
    my $result;
    my $clones = $self->{clones};
    $result = "TOTALCLONES: " . scalar(@$clones) . "\n";
    $parms{function} = sub { my ($self, $clone) = @_; $result .= $clone->print . "\n";  };

    $self->iterate_Clones(\%parms);

    return $result;
#
#    my $clones = $self->{clones};
#
##    print "Clones {\n";
#    my $i=0;
#    foreach my $clone (@$clones) {
#	print "$i\t";
#	print $clone->print;
#	print "\n";
#	$i++;
#    }
##    print "}\n";
}


sub print_Clones_Selected
{
    my ($self,$list) = @_;

    my $clones = $self->{clones};

#    print "Clones {\n";
    my $i=0;
    foreach my $clone (@$clones) {
	my $t;
	if (($t = inList($clone->filename, $list)) > 0) {
#	    print "T" , $t , "\n";
#	    print "List[" , join(",", @$list), "]\n";
#	    print "Filename " , $clone->filename,"\n";
	    print $clone->print;
	    print "\n";
	    $i++;
	}
    }
#    print "}\n";
}


sub get_Clones_Sets_Selected
{
    my ($self,$list) = @_;

    my $clones = $self->{clones};

    my $i=0;
    my @result;
    foreach my $clone (@$clones) {
	my $t;
	if (($t = inList($clone->filename, $list)) > 0) {
	    if (!inList($clone->setId, \@result)) {
#		printf "Adding %d\n", $clone->setId;
		push  @result, $clone->setId;
	    }
#	    print "List[" , join(",", @$list), "]\n";
#	    print "Filename " , $clone->filename,"\n";
#	    print $clone->print;
#	    $i++;
	}
    }
    return @result;
#    print "}\n";
}



sub get_Clone_Count
{
    my $self = shift;
    my $clones = $self->{clonePairs};
    return scalar(@$clones);
}

sub get_Clone_Count
{
    my $self = shift;
    my $clones = $self->{clonePairs};
    return scalar(@$clones);
}

sub parse_Clone_Pairs
{
    # foreach file 
    #   name
    #   index
    #   size in tokens
    my $self = shift;
    my ($cc) = $self->{toParse};
    my @result;
    my %clone;

    while ($cc ne "") {
#	   and ($cc !~ /^\x0a/)) {
	%clone = ();
	(
         $clone{unknown},
	 $clone{fromFile},$clone{fromBeginToken},$clone{fromEndToken},
	 $clone{toFile},$clone{toBeginToken},$clone{toEndToken},
	 $clone{cloneSetId}
	) = unpack('llllllll',$cc);
#        print "CLone  $clone{fromFile},$clone{fromBeginToken},$clone{fromEndToken}, $clone{toFile},$clone{toBeginToken},$clone{toEndToken}, $clone{cloneSetId},$clone{unknown}, \n";
        die unless $clone{unknown} == 0;
	$cc = substr($cc, 8*4);
        last if $clone{unknown} == 0 && 
            $clone{fromFile} == 0 &&
            $clone{fromBeginToken} == 0 &&
            $clone{fromEndToken} == 0 &&
            $clone{toFile} == 0 &&
            $clone{toBeginToken} == 0 && 
            $clone{toEndToken} == 0&& 
            $clone{cloneSetId} == 0;
        $clone{fromLen} = $clone{fromEndToken} - $clone{fromBeginToken};
        $clone{toLen} = $clone{toEndToken} - $clone{toBeginToken};
	push @result, {%clone};
        # no invert it
        my %cloneInv = ();
        $cloneInv{unknown} = $clone{unknown};
        $cloneInv{toFile} = $clone{fromFile};
        $cloneInv{toBeginToken} = $clone{fromBeginToken};
        $cloneInv{toEndToken} = $clone{fromEndToken};
	$cloneInv{fromFile} = $clone{toFile};
        $cloneInv{fromBeginToken} = $clone{toBeginToken};
        $cloneInv{fromEndToken} = $clone{toEndToken};
	$cloneInv{cloneSetId} = $clone{cloneSetId};
        $cloneInv{fromLen} = $clone{toLen};
        $cloneInv{toLen} = $clone{fromLen};
#	push @result, {%cloneInv};
    } 
    $self->{toParse} = $cc;
    $self->{clonePairs} = [@result];
    print "added ", scalar(@result) / 2, " clone pairs\n";
}

sub parse_Remarks
{
    my $self = shift;

    $self->{toParse} = substr($self->{toParse}, 9);
}

sub parse_Files
{
    my $self = shift;

    my @files;
    my $name;
    my $index;
    my $size;
    while ($self->{toParse} !~ /^\x0a/) {
	$name = $self->parse_String;
	($index,$size) = unpack('ll',$self->{toParse});
#	print "Name $name, $index, $size\n";
	push @files, {'name' => $name, 
		      'index' => $index, 
		      'size' => $size};
	$self->{toParse} = substr($self->{toParse}, 8);

    } 
    #eat marker
    $self->{toParse} = substr($self->{toParse}, 1);
    $self->{files} = [@files];
}

sub parse_Header
{

    my $self = shift;
    my $toParse = $self->{data};

#my ($a) = unpack('I', $toParse);

    ($self->{magicNumber}, $self->{version},$self->{subVersion}, $self->{subsubVersion}, $self->{format}) = unpack('a8llla4', $toParse);

    # Skip the 24 characters we just read...
#    print "($self->{magicNumber}, $self->{version},$self->{subVersion}, $self->{subsubVersion}, $self->{format}\n";

    $toParse = substr($toParse, 24);

    while (not ($toParse =~ /^\x0a/)) {
        die "assertion in parsing header" unless $toParse =~ /^([^\x09]+)\x09([^\x0a]+)\x0a/;
        $self->{options}{$1} = $2;
#        print "$1->$2\n";
        $toParse = $'; # ';
    }
    # eat the separator
    $self->{toParse} = substr($toParse, 1);
    $self->{preprocess} = $self->parse_String;
}


sub parse_String
{
    my $self = shift;
    
    my ($st) = $self->{toParse};
#    print "Len: ", length($st) , "\n"; #';    
    if ($st =~ /\x0a/) {
#	print "Len:before ", length($`) , "\n"; #';
#	print "Len:in     ", length($&) , "\n"; #';
#	print "Len:after  ", length($') , "\n"; #';
	$self->{toParse} = $'; #';
	return $`;
    } else {
        die "expecting string";
	return '';
    }
}


sub print_Clones_w_Lines
{
    my ($self) = @_;

    my $clones = $self->{clonePairs};
    my $tokens = $self->{tokens};
    print "clone_pairs {\n";
    foreach my $clone (@$clones) {
	last if $clone->{fromFile} == 0;

	# they come always in twos
	next if $clone->{fromFile} > $clone->{toFile};

	# if the files are the same, then process the one with the
	# smallest line number and skip the other
	
	next if ($clone->{fromFile} == $clone->{toFile}) and
	    $clone->{fromBeginToken} > $clone->{toBeginToken};

#	printf("%d\t%d.%d-%d\t%d.%d-%d\n", $clone->{cloneSetId},
#	       $clone->{fromFile},$clone->{fromBeginToken},$clone->{fromEndToken},
#	       $clone->{toFile},$clone->{toBeginToken},$clone->{toEndToken});

	# skip if they are the "same" file and clone
	my @from1 = Translate_Token($clone->{fromBeginToken}, $tokens, $clone->{fromFile});
	my @to1 = Translate_Token($clone->{fromEndToken}, $tokens, $clone->{fromFile});

	my @from2 = Translate_Token($clone->{toBeginToken}, $tokens, $clone->{toFile});
	my @to2 = Translate_Token($clone->{toEndToken}, $tokens, $clone->{toFile});

	printf("%d\t%d.%d:%d-%d:%d\t%d.%d:%d-%d:%d\n", $clone->{cloneSetId},
	       $clone->{fromFile},
	       @from1,
	       @to1,
	       $clone->{toFile},
	       @from2,
	       @to2
	    );
	      # $clone->{toBeginToken},$clone->{toEndToken});
    }
    print "}\n";
}



1;
