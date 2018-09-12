#!/usr/bin/perl

package clone;

sub new 
{
    my ($class, $cloneSet, $fileIdx, $filename, $fromToken, $fromLine, $fromCol, $fromByte, $toToken, $toLine, $toCol, $toByte) = @_;
    my $self = {};

    bless $self, $class;

    $self->{filename} = $filename;
    $self->{fileIdx} = $fileIdx - 1;
    $self->{cloneSetId} = $cloneSet;
    $self->{fromToken} = $fromToken;
    $self->{fromLine} = $fromLine;
    $self->{fromCol} = $fromCol;
    $self->{fromByte} = $fromByte;
    $self->{toToken} = $toToken;
    $self->{toLine} = $toLine;
    $self->{toCol} = $toCol;
    $self->{toByte} = $toByte;

    my $newFname = $self->{filename};
    $newFname =~ s/\//,/g;
    $self->{cleanFileName} = $newFname;

    return $self;
}

sub print
{
    my $self = shift;
    
    my $result = sprintf("%-40s\t%6d\t%6d\t%6d\t%6d%6d%6d%6d%6d%7d%7d", 
	   $self->{filename},
	   $self->{fileIdx},
	   $self->{cloneSetId},
	   $self->{fromToken},
	   $self->{toToken},
	   $self->{fromLine},
	   $self->{fromCol},
	   $self->{toLine},
	   $self->{toCol},
	   $self->{fromByte},
	   $self->{toByte}
	);
    return $result;
}

sub lines
{
    my ($self) = @_;
    
    return ($self->{fromLine}, $self->{toLine});
    
}

sub load
{
    # create  a clone from data saved in print
    my ($class, $field) = @_;

    my @f = split(/[ \t]+/, $field);

    my $self = {};
    bless $self, $class;

    ($self->{filename}, 
     $self->{fileIdx},
     $self->{cloneSetId},
     $self->{fromToken},
     $self->{toToken},
     $self->{fromLine},
     $self->{fromCol},
     $self->{toLine},
     $self->{toCol},
     $self->{fromByte},
     $self->{toByte}) = @f;

    my $newFname = $self->{filename};
    $newFname =~ s/\//,/g;
    $self->{cleanFileName} = $newFname;

    return $self;

}

sub token_begin
{
    my ($self) = @_;
    return $self->{fromToken};
}



sub tokens
{
    my ($self) = @_;
    return ($self->{fromToken}, $self->{toToken});
}

sub fileIdx
{
    my ($self) = @_;
    
    return $self->{fileIdx};
}

sub filename
{
    my ($self) = @_;
    
    return $self->{filename};
}

sub setId
{
    my ($self) = @_;
    
    return $self->{cloneSetId};
}

sub from_Token
{
    my ($self) = @_;
    
    return $self->{fromToken};
}

sub clean_FileName
{
    my ($self) = @_;
    
    return $self->{cleanFileName};
}

sub clone_Data
{
    my ($self) = @_;
    if (!defined $self->{cloneData}) {
	$self->extract;
    } 
    return $self->{cloneData};
}

sub generate_FileName
{
    my ($self, $suffix) = @_;
    
    my $fname = sprintf("%04d:%s:%04d.%s", 
			$self->setId, 
			$self->clean_FileName,
			$self->from_Token,
			$suffix);
    return $fname;
}

sub save 
{
    my ($self) = @_;
    my $data = $self->clone_Data;
    
    my $newFname = $self->{cleanFileName};
    my $fname = $self->generate_FileName("clone");
#    print STDERR ("Saving to file [$fname]\n");
    open (OUT, ">$fname") or die "Unable to create save file for clone ", $self->print;
    print OUT $data;
    close OUT;
}


sub extract
{
    my ($self) = @_;
    my $f = $self->{filename};

    open(IN, "<$f") or die "Unable to open file for clone ", $self->print;

    my $cloneData;
    my $len = $self->{toByte} - $self->{fromByte};
    
    if (seek(IN, $self->{fromByte}, SEEK_SET) == 0) {
	die "Unable to seek in file to read clone ", $self->print;
    }
    my $read = read (IN, $cloneData, $len);

    if ($len != $read) {
	die "Unable to read clone (only read $read from $len)", $self->print;
    }
    close IN;
    $self->{cloneData} = $cloneData;
    return $cloneData;
}


sub equal
{
    my ($self,$other) = @_;
    
    my $result = 
	($self->{filename} eq $other->{filename})
	&& ($self->{cloneSetId} == $other->{cloneSetId})
	&& ($self->{fromToken} == $other->{fromToken}) 
	&& ($self->{fromLine} == $other->{fromLine})
	&& ($self->{fromCol} == $other->{fromCol})
	&& ($self->{toToken} == $other->{toToken})
	&& ($self->{toLine} == $other->{toLine}) 
	&& ($self->{toCol} == $other->{toCol})
	;
#    if ($result) {
#	$self->print;
#	print "\n";
#	$other->print;
#	print "\n\n";
#	die;
#    }
#
    return $result;
}

1;
