#!/usr/bin/perl

#### it reads from standard input now!


$0 =~ m@/([^/]+)$@;
my $dir = $`; #'

push @INC, $dir ;

use strict;

package main;

require "ccparse.pm";

my $ccFile = shift @ARGV;

#my $ccFinder = ccfinder->new("/Users/dmg/working/trunk/conf/trunk/hacking/ccfinder",['before.c','after.c']);


my %parms;

my $ccFinder = ccparse->new($ccFile);


my $clonePairs = $ccFinder->get_Clone_Pairs;

#foreach my $c (@clonePairs) {
#    
#}

my @result = sort { $a->{fromFile} <=> $b->{fromFile} ||
                        $a->{toFile} <=> $b->{toFile} || 
                        $a->{fromBeginToken} <=> $b->{fromBeginToken} ||
                        $a->{fromLen} <=> $b->{fromLen} ||
                        $a->{toBeginToken} <=> $b->{toBeginToken}
} @$clonePairs;


# create an array of them, including the inverse
my $prevFromFile = -1;
my $prevToFile = -1;
my ($currentBegin, $currentEnd, $currentTotal) = (0,0,0);

foreach my $c (@result) {
    my $fromLen = $c->{fromLen};
    my $toLen = $c->{toLen};
#    print "$c->{fromFile}, $c->{toFile}, $c->{fromBeginToken}, $fromLen, $c->{fromEndToken}, $c->{toBeginToken}, $toLen\n";

    my ($beg1, $l1, $beg2, $l2) =($c->{fromBeginToken},  $fromLen,  
                                  $c->{toBeginToken}, $toLen);

    if (not ($c->{fromFile} == $prevFromFile &&
             $c->{toFile} ==  $prevToFile )) {
        # new pair of files
        # report results 
        # count last one
        $currentTotal +=  $currentEnd - $currentBegin;
        if ($prevToFile >= 0) {
            # might be exactly the first pass, so check
            Report($prevFromFile,$prevToFile,$currentBegin, $currentEnd, $currentTotal);
            ($currentBegin, $currentEnd, $currentTotal) = (0,0,0);
        }
    }

    # we are still processing the same files.
    
    my $last1  = $beg1 + $l1;
#        print join(":",@row),":$last1";
    if ($beg1 > $currentEnd) {
        # new block
        $currentTotal += $currentEnd - $currentBegin;
        $currentBegin = $beg1;
        $currentEnd = $last1;
    } elsif ($last1 > $currentEnd) {
        $currentEnd = $last1;
    } else {
        #do nothing  
    }
    $prevFromFile = $c->{fromFile};
    $prevToFile = $c->{toFile};
#    print "So far: $prevFromFile, $prevToFile, $currentTotal\n";
}
$currentTotal +=  $currentEnd - $currentBegin;
if ($prevToFile >= 0) {
    # might be exactly the first pass, so check
    Report($prevFromFile,$prevToFile,$currentBegin, $currentEnd, $currentTotal);
    ($currentBegin, $currentEnd, $currentTotal) = (0,0,0);
}

exit 0;

sub Report
{
    my ($prevFromFile, $prevToFile, $currentBegin, $currentEnd, $currentTotal) = @_;

    my $f1 = $ccFinder->get_File($prevFromFile);
    my $f2 = $ccFinder->get_File($prevToFile);
    my $totalTokens = $f1->{size};
    my $ratio;
    if ($f1->{size} == 0) {
        $ratio = -1;
    } else {
        $ratio = $currentTotal * 1.0 / $f1->{size};
    }
    if ($prevFromFile != $prevToFile) {
        print join(';', $f1->{name}, $f2->{name}, $currentTotal, $f1->{size}, $ratio), "\n";
    }
    
}


$parms{function} = sub { 
    my ($self, $file) = @_; 
    print STDERR "File " , $file->{name}, "\n"; 
    my $index = $file->{index};
    my %parmsInside;
    #set parameters to inside function
    $parmsInside{function} = sub { 
        my ($self, $file) = @_;
        my $second = $file->{index};
        my $first = $parmsInside{index};
        next if $first <= $second;
        Process_Pair($ccFinder, $first, $second);
    };
    $parmsInside{index} = $file->{index};
    
    $ccFinder->iterate_Files(\%parmsInside);
    
};

$ccFinder->iterate_Files(\%parms);



#foreach my $other ($ccFinder->get_Fileindex_List) {
#    my ($self, $file) = @_; 
#    print "File " , $other, "\n"; 
#    foreach my $other (sort @$self->{files}) {
#        next if 
#    }
#};
#$ccFinder->iterate_Files(\%parms);

print "Done\n";
exit;

sub Process_Pair
{

    my ($ccfinder, $f1, $f2) = @_;
    my ($currentBegin, $currentEnd, $currentTotal) = (0,0,0);
    my @clonesFiles ;
    my @pairs;
    my %parms2;

    $parms2{function} = sub {
        my ($self, $clone, $parms) = @_; 
        if ($clone->{fromFile} == $f1 &&
            $clone->{toFile} == $f2) {
            print "Match1\n";
            push @clonesFiles, $clone;
        }
        if ($clone->{fromFile} == $f1 &&
            $clone->{toFile} == $f2) {
            push @clonesFiles, $clone;
            print "Match2\n";
        }
    };
    $ccFinder->iterate_Clones_Pairs(\%parms2);

    return;

    # sort pairs by filenumber, linenumber
    foreach my $row (@pairs) {# there are mrs
        my ($beg1, $last1, $beg2, $last2) =@$row;
#        print join(":",@row),":$last1";
        if ($beg1 > $currentEnd) {
            $currentTotal += $currentEnd - $currentBegin;
            $currentBegin = $beg1;
            $currentEnd = $last1;
        } elsif ($last1 > $currentEnd) {
            $currentEnd = $last1;
        } else {
          #do nothing  
        }
 #       print ">>>Current $currentBegin:$currentEnd:$currentTotal\n";
    }
    $currentTotal +=  $currentEnd - $currentBegin;
    return $currentTotal;
}



#if ($whatToTest eq "list") {

#    $ccFinder = ccfinder->new("");
#    $ccFinder->set_Files_List(['before.c', 'after.c','mod_proxy.c','http_core.c']);
#    $ccFinder->execute([],"a.ccfxd");
#}  elsif ($whatToTest eq 'withFileList') {
#    $ccFinder = ccfinder->new("");
#    $ccFinder->execute('rip.txt', "a.ccfxd");
#} elsif ($whatToTest eq 'load') {
#    $ccFinder = ccfinder->new("./apache/");
#    $ccFinder->load_File("a.ccfxd");
#} else {
#    die "$0 (list|withFileList|load)\n";
#}
#
#
my %parms;

# display files
$parms{function} = sub { my ($self, $file) = @_; print STDERR "File " , $file->{name}, "\n"; };
$ccFinder->iterate_Files(\%parms);

$ccFinder->print("clonesStats.txt");

#printf "Length of raw data %d\n", length($ccFinder->get_ccdata_raw);

#print $ccFinder->get_ccdata_pretty;
#print $ccFinder->print;

my @setsClones = $ccFinder->get_Clones_Sets_Selected(['./http_core.c']);

print STDERR "Clone set", join(":", @setsClones), "\n";

if (scalar(@setsClones) > 0) {
    print $ccFinder->print_Clones_Set_Selected(\@setsClones, "clonesInMR.txt");
    print $ccFinder->extract_Clones_Set_Selected(\@setsClones);
    print $ccFinder->extract_Clones_Abstract_Set_Selected(\@setsClones);
} else {
    print STDERR "No clones in this MR\n";
}

#print "--after.c-------------------\n";
#print $ccFinder->print_Clones_Selected(['after.c']);

exit 0;
