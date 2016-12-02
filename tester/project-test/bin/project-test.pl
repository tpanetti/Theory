#!/usr/bin/perl -w

# Perl script for testing a CSCE 355 project submission on a linux box

# Usage:
# $ project-test.pl [your-submission-root-directory]
#
# The directory argument is optional.  If not there, then the default is
# $default_submission_root, defined below

# Appends to file "comments.txt" in your submission root directory

# This script must be run under the bash shell!


######## Edit the following to reflect your directories (mandatory):

# root directory for the test files
$test_suite_root = "$ENV{HOME}/public_html/csce355/prog-proj/test-suite";

# directory holding the executables used in testing
$bin_dir = "$ENV{HOME}/public_html/csce355/prog-proj/bin";


######## Edit the following to add or remove test files (optional):

# DFAs to feed to the simulator
# (in $test_suite_root/simulator; base names only)
@sim_test_files = ("bigDFA", "biggerDFA", "handoutDFA", "randomDFA1",
		 "randomDFA2", "randomDFA3", "randomDFA4", "randomDFA5");

# DFAs to feed the complement construction
# (in $test_suite_root/boolop; base names only)
@bop_comp_test_files = ("randomHexDFA", "handoutDFA", "bigDFA", "bigDFA-comp");

# DFA pairs to feed to the product construction (in $test_suite_root/boolop)
@bop_prod_test_files = (
    ["smallDFA","smallDFA2"],
    ["smallerDFA","handoutDFA"],
    ["handoutDFA","smallerDFA"],
    ["searchDFA1","searchDFA2"],
    ["searchDFA2","searchDFA1"],
    ["bigDFA","randomHexDFA"],
    ["bigDFA","bigDFA-comp"],
    ["bigDFA-comp","randomHexDFA"]
);

# files to feed to the inverse homomorphism construction
# (in $test_suite_root/invhom; base names only)
@hom_test_files = ("bigDFA", "biggerDFA", "handoutDFA",
		   "randomDFA1", "randomDFA2", "randomDFA3");

# NOTE: test file names for minimizer, searcher, and properties are uniform,
# differing only by number.  If adding or removing test files from these
# directories, you should adhere to the naming convention you see there, and
# the numbers should be contiguous from 1 to n, where n is number of test
# files in the directory.


######## Miscellaneous values

# Time limit for each run of your program (in seconds).  This is the value
# I will use when grading.
$timeout = 11;

# Flag to control deletion of temporary files --
# a nonzero value means all temp files are deleted after they are used;
# a zero value means no temp files will be deleted (but they will be
# overwritten on subsequent executions of this script).
# This flag has NO effect on files created by running your program if
# it times out (that is, exceeds the $timeout limit, above); those files will
# always be deleted.
# Set this value to 0 if you want to examine your own programs' output as
# produced by this script.
$delete_temps = 1;


############# You should not need to edit below this line ##############

@programs = ("simulator", "minimizer", "searcher",
	     "boolop", "invhom", "properties");

# Holds which programs were implemented and what progress was made on each:
# Values:
#    0 - not implemented at all ($prog.txt file does not exist)
#    1 - $prog.txt file exists, but there was an error parsing it
#    2 - $prog.txt parsed OK, but the build failed (error return value)
#    3 - $prog built OK, but execution timed out at least once
#    4 - $prog execution always completed (but there were errors)
#    5 - $prog execution always completed without errors
%progress = ();

# Hash for counting errors for each program (only execution errors counted)
%error_counts = ();

# Holds build and run commands for the program
%build_run = ();

# Check existence and readability of the test suite directory
die "No test suite directory $test_suite_root\n"
    unless -d $test_suite_root && -r $test_suite_root;

#sub main
{
    if (@ARGV) {
	$udir = shift @ARGV;
	$udir =~ s/\/$//;
	$udir ne "" or die "Cannot use root directory\n";
    }
    else {
	print STDERR "Usage: project-test.pl your_source_code_directory\n";
	exit(1);
    }
    $uname = "self-test";
    process_user();
}


sub process_user {
    print "Processiong user $uname\n";

    die "No accessible directory $udir ($!)\n"
	unless -d $udir && -r $udir && -w $udir && -x $udir;

    die "Cannot change to directory $udir ($!)\n"
	unless chdir $udir;

    # Copy STDOUT and STDERR to errlog.txt in $udir
    open STDOUT, "| tee errlog.txt" or die "Can't redirect stdout\n";
    open STDERR, ">&STDOUT" or die "Can't dup stdout\n";
    select STDERR; $| = 1;	# make unbuffered
    select STDOUT; $| = 1;	# make unbuffered

    if (-e "comments.txt") {
	print "comments.txt exists -- making backup comments.bak\n";
	rename "comments.txt", "comments.bak";
    }

    open(COMMENTS, "> comments.txt");

    cmt("Comments for $uname -------- " . now() . "\n");

    mkdir "test-outputs"
	unless -d "test-outputs";

    $error_count = 0;

    foreach $prog (@programs) {
	$progress{$prog} = 0;
	$error_counts{$prog} = 0;
	next unless -e "$prog.txt";	# proceed only if implemented
	$progress{$prog}++;
	cmt("parsing $prog.txt ...");
	if (parse_build_run("$prog.txt")) {
	    cmt("ERROR PARSING $prog.txt ... SKIPPING $prog\n");
	    next;
	}
	cmt(" done\n");
	$progress{$prog}++;
	cmt("building $prog ...\n");
	$rc = 0;
	foreach $command (@{$build_run{BUILD}}) {
	    cmt("  $command\n");
	    $rc = system($command);
	    if ($rc >> 8) {
		cmt("    FAILED ... SKIPPING $prog\n");
		last;
	    }
	    else {
		cmt("    succeeded\n");
	    }
	}
	next if $rc >> 8;
	cmt("done\n");
	$progress{$prog}++;
	$command = $build_run{RUN};
	test_dispatch($prog, $command);
    }

    report_summary();

    rmdir "test-outputs" if $delete_temps;

    close COMMENTS;

    print "\nDone.\nComments are in $udir/comments.txt\n\n";
}


sub test_dispatch {
    my ($prog, $command) = @_;

    $out_dir = "test-outputs/$prog";
    mkdir $out_dir
	unless -d $out_dir;
    $test_dir = "$test_suite_root/$prog";
    cmt("testing $prog ...\n");
    $no_error = $no_timeout = 1;
    if ($prog eq "simulator") {
	test_simulator($command);
	$error_count += $error_counts{$prog};
	$no_error = 0 if $error_counts{$prog} > 0;
    }
    elsif ($prog eq "minimizer") {
	test_minimizer($command);
	$error_count += $error_counts{$prog};
	$no_error = 0 if $error_counts{$prog} > 0;
    }
    elsif ($prog eq "searcher") {
	test_searcher($command);
	$error_count += $error_counts{$prog};
	$no_error = 0 if $error_counts{$prog} > 0;
    }
    elsif ($prog eq "boolop") {
	test_boolop($command);
	$error_count += $error_counts{$prog};
	$no_error = 0 if $error_counts{$prog} > 0;
    }
    elsif ($prog eq "invhom") {
	test_invhom($command);
	$error_count += $error_counts{$prog};
	$no_error = 0 if $error_counts{$prog} > 0;
    }
    elsif ($prog eq "properties") {
	test_properties($command);
	$error_count += $error_counts{$prog};
	$no_error = 0 if $error_counts{$prog} > 0;
    }
    $progress{$prog} += $no_timeout + $no_error;
    rmdir $out_dir if $delete_temps;
    cmt("done with $prog\n\n");
}


# Sets build_run hash to the building and execution commands for this program
# Returns nonzero if error
sub parse_build_run {
    my ($br_file) = @_;
    open BR, "< $br_file"
	or die "Cannot open $br_file for reading ($!)\n";
    get_line(1) or return 1;
    $line = eat_comments();
    if ($line !~ /^\s*Build:\s*$/i) {
	cmt("NO Build SECTION FOUND; ABORTING PARSE\n");
	return 1;
    }
    $build_run{BUILD} = [];
    get_line(1) or return 1;
    $line = eat_comments();
    $build_run{BUILD} = [];
    while ($line ne "" && $line !~ /^\s*Run:\s*$/i) {
	$line =~ s/^\s*//;
	push @{$build_run{BUILD}}, $line;
	get_line(1) or return 1;
	$line = eat_comments();
    }
    if ($line eq "") {
	cmt("NO Run SECTION FOUND; ABORTING PARSE\n");
	return 1;
    }
    # This is now true: $line =~ /^\s*Run:\s*$/i
    get_line(1) or return 1;
    $line = eat_comments();
    $line =~ s/^\s*//;
    $build_run{RUN} = $line;
    get_line(0) or return 0;
    $line = eat_comments();
    if ($line ne "") {
	cmt("EXTRA TEXT IN FILE; ABORTING PARSE\n");
	return 1;
    }
    close BR;
    return 0;
}


sub get_line {
    my ($flag) = @_;
    return 1
	if defined($line = <BR>);
    if ($flag) {
	cmt(" FILE ENDED PREMATURELY\n");
    }
    return 0;
}


# Swallow comments and blank lines
sub eat_comments {
    chomp $line;
    while ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
	$line = <BR>;
	defined($line) or return "";
	chomp $line;
    }
    return $line
}


sub test_simulator {
    ($command) = @_;

    foreach $base (@sim_test_files) {

	cmt("  Running simulator on $base ...\n");

	cmt("    $command $base.txt ${base}-strings.txt > $out_dir/${base}-out.txt 2> $out_dir/${base}-err.txt\n");
	eval {
	    local $SIG{ALRM} = sub { die "TIMED OUT\n" };
	    alarm $timeout;
	    $rc = system("$command $test_dir/$base.txt $test_dir/${base}-strings.txt > $out_dir/${base}-out.txt 2> $out_dir/${base}-err.txt");
	    alarm 0;
	};
	if ($@ && $@ eq "TIMED OUT\n") {
	    cmt("    $@");		# program timed out before finishing
	    $error_counts{$prog}++;
	    unlink "$out_dir/${base}-out.txt"
		if -e "$out_dir/${base}-out.txt";
	    unlink "$out_dir/${base}-err.txt"
		if -e "$out_dir/${base}-err.txt";
	    $no_timeout = 0;
	    next;
	}
	if ($rc >> 8) {
	    cmt("    terminated abnormally\n");
	    # $error_counts{$prog}++;
	    error_report("$out_dir/$base");
	}
	else {
	    cmt("    terminated normally\n");
	    error_report("$out_dir/$base");
	}

	if (!(-e "$out_dir/${base}-out.txt")) {
	    cmt("  OUTPUT FILE ${base}-out.txt DOES NOT EXIST\n");
	    $error_counts{$prog}++;
	    next;
	}

	cmt("  ${base}-out.txt exists -- comparing acc/rej outcomes with solution file\n");

	$report = check_sim_outcomes($base);
	unlink "$out_dir/${base}-out.txt" if $delete_temps;
	chomp $report;
	if ($report eq '') {
	    cmt("  outcomes match (correct)\n");
	}
	else {
	    cmt("  OUTCOMES DIFFER:\nvvvvv\n$report\n^^^^^\n");
	    $error_counts{$prog}++;
	}
    }
}


sub check_sim_outcomes {
    my ($base) = @_;
    my $report = '';

    my $solSeq = get_outcome_sequence("$test_dir/${base}-out.txt");
    my $testSeq = get_outcome_sequence("$out_dir/${base}-out.txt");

    if ($solSeq ne $testSeq) {
	$report .= "    outcomes differ:\n      $solSeq (solution)\n      $testSeq (yours)\n";
	$error_counts{$prog}++;
    }
    return $report;
}


sub test_minimizer {
    ($command) = @_;

    for ($i=1; -e "$test_dir/nonminimalDFA$i.txt"; $i++) {
	$in_base = "nonminimalDFA$i";
	$out_base = "$out_dir/minDFA$i";
	cmt("  Running minimizer on $in_base ...\n");

	cmt("    $command $in_base.txt > $out_base.txt 2> ${out_base}-err.txt\n");
	eval {
	    local $SIG{ALRM} = sub { die "TIMED OUT\n" };
	    alarm $timeout;
	    $rc = system("$command $test_dir/$in_base.txt > $out_base.txt 2> ${out_base}-err.txt");
	    alarm 0;
	};
	if ($@ && $@ eq "TIMED OUT\n") {
	    cmt("    $@");		# program timed out before finishing
	    $error_counts{$prog}++;
	    unlink "$out_base.txt"
		if -e "$out_base.txt";
	    unlink "${out_base}-err.txt"
		if -e "${out_base}-err.txt";
	    $no_timeout = 0;
	    next;
	}
	if ($rc >> 8) {
	    cmt("    terminated abnormally\n");
	    # $error_counts{$prog}++;
	    error_report($out_base);
	}
	else {
	    cmt("    terminated normally\n");
	    error_report($out_base);
	}

	if (!(-e "$out_base.txt")) {
	    cmt("  OUTPUT FILE $out_base.txt DOES NOT EXIST\n");
	    $error_counts{$prog}++;
	    next;
	}

	cmt("  $out_base.txt exists -- checking isomorphism with solution DFA\n");

	$report = `$bin_dir/isDFA < $out_base.txt`;
	chomp $report;
	if ($report eq "Not a DFA") {
	    cmt("  OUTPUT FILE IS NOT A DFA (DFA PARSE ERROR)\n");
	    $error_counts{$prog}++;
	    next;
	}

	# $out_base.txt is a DFA; check for isomorphism with the solution
	$report = `$bin_dir/DFAiso $test_dir/minDFA$i.txt < $out_base.txt`;
	unlink "$out_base.txt" if $delete_temps;
	chomp $report;
	if ($report =~ /The two DFAs are isomorphic/) {
	    cmt("  the DFAs are isomorphic (correct)\n");
	}
	elsif ($report =~ /The two DFAs are different/) {
	    cmt("  THE DFAs DIFFER (INCORRECT):\nvvvvv\n$report\n^^^^^\n");
	    $error_counts{$prog}++;
	}
	else {
	    print STDERR "ERROR: BUG in DFAiso (fatal)\n";
	    exit(1);
	}
    }
}


sub test_searcher {
    ($command) = @_;

    for ($i=1; -e "$test_dir/str$i.txt"; $i++) {
	$in_file = "str$i.txt";
	$out_base = "$out_dir/DFA$i";
	cmt("  Running searcher on str$i ...\n");

	cmt("    $command $in_file > $out_base.txt 2> ${out_base}-err.txt\n");
	eval {
	    local $SIG{ALRM} = sub { die "TIMED OUT\n" };
	    alarm $timeout;
	    $rc = system("$command $test_dir/$in_file > $out_base.txt 2> ${out_base}-err.txt");
	    alarm 0;
	};
	if ($@ && $@ eq "TIMED OUT\n") {
	    cmt("    $@");		# program timed out before finishing
	    $error_counts{$prog}++;
	    unlink "$out_base.txt"
		if -e "$out_base.txt";
	    unlink "${out_base}-err.txt"
		if -e "${out_base}-err.txt";
	    $no_timeout = 0;
	    next;
	}
	if ($rc >> 8) {
	    cmt("    terminated abnormally\n");
	    # $error_counts{$prog}++;
	    error_report($out_base);
	}
	else {
	    cmt("    terminated normally\n");
	    error_report($out_base);
	}

	if (!(-e "$out_base.txt")) {
	    cmt("  OUTPUT FILE $out_base.txt DOES NOT EXIST\n");
	    $error_counts{$prog}++;
	    next;
	}

	cmt("  $out_base.txt exists -- checking isomorphism with solution DFA\n");

	$report = `$bin_dir/isDFA < $out_base.txt`;
	chomp $report;
	if ($report eq "Not a DFA") {
	    cmt("  OUTPUT FILE IS NOT A DFA (DFA PARSE ERROR)\n");
	    $error_counts{$prog}++;
	    next;
	}

	# $out_base.txt is a DFA; check number of states
	# and equivalence with the solution
	$string = `cat $test_dir/$in_file`;
	chomp $string;
	if ($report !~ /with (\d+) states/) {
	    print STDERR "ERROR: BUG in isDFA (fatal)\n";
	    exit(1);
	}
	if ($1 > 1 + length($string)) {
	    cmt("  DFA IS TOO LARGE ($1 STATES)\n");
	    $error_counts{$prog}++;
	}
	$report = `$bin_dir/DFAiso $test_dir/DFA$i.txt < $out_base.txt`;
	unlink "$out_base.txt" if $delete_temps;
	chomp $report;
	if ($report =~ /The two DFAs are isomorphic/) {
	    cmt("  the DFAs are isomorphic (correct)\n");
	}
	elsif ($report =~ /The two DFAs are different/) {
	    cmt("  THE DFAs DIFFER (INCORRECT)\n");
	    $error_counts{$prog}++;
	}
	else {
	    print STDERR "ERROR: BUG in DFAequiv (fatal)\n";
	    exit(1);
	}
    }
}


sub test_boolop {
    ($command) = @_;

    # First test complement constructions
    foreach $base (@bop_comp_test_files) {
	$out_base = "$out_dir/$base";
	cmt("  Running boolop (complement) on $base ...\n");

	cmt("    $command $base.txt > $out_base.txt 2> ${out_base}-err.txt\n");
	eval {
	    local $SIG{ALRM} = sub { die "TIMED OUT\n" };
	    alarm $timeout;
	    $rc = system("$command $test_dir/$base.txt > $out_base.txt 2> ${out_base}-err.txt");
	    alarm 0;
	};
	if ($@ && $@ eq "TIMED OUT\n") {
	    cmt("    $@");		# program timed out before finishing
	    $error_counts{$prog}++;
	    unlink "$out_base.txt"
		if -e "$out_base.txt";
	    unlink "${out_base}-err.txt"
		if -e "${out_base}-err.txt";
	    $no_timeout = 0;
	    next;
	}
	if ($rc >> 8) {
	    cmt("    terminated abnormally\n");
	    # $error_counts{$prog}++;
	    error_report($out_base);
	}
	else {
	    cmt("    terminated normally\n");
	    error_report($out_base);
	}

	if (!(-e "$out_base.txt")) {
	    cmt("  OUTPUT FILE $out_base.txt DOES NOT EXIST\n");
	    $error_counts{$prog}++;
	    next;
	}

	cmt("  $out_base.txt exists -- checking equivalence with solution DFA\n");

	$report = `$bin_dir/isDFA < $out_base.txt`;
	chomp $report;
	if ($report eq "Not a DFA") {
	    cmt("  OUTPUT FILE IS NOT A DFA (DFA PARSE ERROR)\n");
	    $error_counts{$prog}++;
	    next;
	}

	# $out_base.txt is a DFA; check number of states
	# and equivalence with the solution
	$dfa = `cat $test_dir/$base.txt`;
	$dfa =~ /Number of states:\s+(\d+)/;
	$nstates = $1;
	if ($report !~ /with (\d+) states/) {
	    print STDERR "ERROR: BUG in isDFA (fatal)\n";
	    exit(1);
	}
	if ($1 > $nstates) {
	    cmt("  DFA IS TOO LARGE ($1 STATES)\n");
	    $error_counts{$prog}++;
	}
	$report = `$bin_dir/DFAequiv $test_dir/${base}-comp.txt $out_base.txt`;
	unlink "$out_base.txt" if $delete_temps;
	chomp $report;
	if ($report =~ /The two DFAs are equivalent/) {
	    cmt("  the DFAs are equivalent (correct)\n");
	}
	elsif ($report =~ /The two DFAs are not equivalent/) {
	    cmt("  THE DFAs ARE NOT EQUIVALENT (INCORRECT)\n");
	    $error_counts{$prog}++;
	}
	else {
	    print STDERR "ERROR: BUG in DFAequiv (fatal)\n";
	    exit(1);
	}
    }

    # Done with complements; now test product constructions
    foreach $pair (@bop_prod_test_files) {
	($base1, $base2) = @$pair;
	$out_base = "$out_dir/${base1}-x-$base2";
	cmt("  Running boolop (product) on $base1 and $base2 ...\n");

	cmt("    $command $base1.txt $base2.txt > $out_base.txt 2> ${out_base}-err.txt\n");
	eval {
	    local $SIG{ALRM} = sub { die "TIMED OUT\n" };
	    alarm $timeout;
	    $rc = system("$command $test_dir/$base1.txt $test_dir/$base2.txt > $out_base.txt 2> ${out_base}-err.txt");
	    alarm 0;
	};
	if ($@ && $@ eq "TIMED OUT\n") {
	    cmt("    $@");		# program timed out before finishing
	    $error_counts{$prog}++;
	    unlink "$out_base.txt"
		if -e "$out_base.txt";
	    unlink "${out_base}-err.txt"
		if -e "${out_base}-err.txt";
	    $no_timeout = 0;
	    next;
	}
	if ($rc >> 8) {
	    cmt("    terminated abnormally\n");
	    # $error_counts{$prog}++;
	    error_report($out_base);
	}
	else {
	    cmt("    terminated normally\n");
	    error_report($out_base);
	}

	if (!(-e "$out_base.txt")) {
	    cmt("  OUTPUT FILE $out_base.txt DOES NOT EXIST\n");
	    $error_counts{$prog}++;
	    next;
	}

	cmt("  $out_base.txt exists -- checking equivalence with solution DFA\n");

	$report = `$bin_dir/isDFA < $out_base.txt`;
	chomp $report;
	if ($report eq "Not a DFA") {
	    cmt("  OUTPUT FILE IS NOT A DFA (DFA PARSE ERROR)\n");
	    $error_counts{$prog}++;
	    next;
	}

	# $out_base.txt is a DFA; check number of states
	# and equivalence with the solution
	$dfa = `cat $test_dir/${base1}-x-$base2.txt`;
	$dfa =~ /Number of states:\s+(\d+)/;
	$nstates = $1;
	if ($report !~ /with (\d+) states/) {
	    print STDERR "ERROR: BUG in isDFA (fatal)\n";
	    exit(1);
	}
	if ($1 > $nstates) {
	    cmt("  DFA IS TOO LARGE ($1 STATES)\n");
	    $error_counts{$prog}++;
	}
	$report = `$bin_dir/DFAequiv $test_dir/${base1}-x-$base2.txt $out_base.txt`;
	unlink "$out_base.txt" if $delete_temps;
	chomp $report;
	if ($report =~ /The two DFAs are equivalent/) {
	    cmt("  the DFAs are equivalent (correct)\n");
	}
	elsif ($report =~ /The two DFAs are not equivalent/) {
	    cmt("  THE DFAs ARE NOT EQUIVALENT (INCORRECT)\n");
	    $error_counts{$prog}++;
	}
	else {
	    print STDERR "ERROR: BUG in DFAequiv (fatal)\n";
	    exit(1);
	}
    }
}


sub test_invhom {
    ($command) = @_;

    foreach $base (@hom_test_files) {
	$out_base = "$out_dir/${base}";
	cmt("  Running invhom on $base ...\n");

	cmt("    $command $base.txt ${base}-hom.txt > ${out_base}-out.txt 2> ${out_base}-err.txt\n");
	eval {
	    local $SIG{ALRM} = sub { die "TIMED OUT\n" };
	    alarm $timeout;
	    $rc = system("$command $test_dir/$base.txt $test_dir/${base}-hom.txt > ${out_base}-out.txt 2> ${out_base}-err.txt");
	    alarm 0;
	};
	if ($@ && $@ eq "TIMED OUT\n") {
	    cmt("    $@");		# program timed out before finishing
	    $error_counts{$prog}++;
	    unlink "${out_base}-out.txt"
		if -e "${out_base}-out.txt";
	    unlink "${out_base}-err.txt"
		if -e "${out_base}-err.txt";
	    $no_timeout = 0;
	    next;
	}
	if ($rc >> 8) {
	    cmt("    terminated abnormally\n");
	    # $error_counts{$prog}++;
	    error_report($out_base);
	}
	else {
	    cmt("    terminated normally\n");
	    error_report($out_base);
	}

	if (!(-e "${out_base}-out.txt")) {
	    cmt("  OUTPUT FILE ${out_base}-out.txt DOES NOT EXIST\n");
	    $error_counts{$prog}++;
	    next;
	}

	cmt("  ${out_base}-out.txt exists -- checking equivalence with solution DFA\n");

	$report = `$bin_dir/isDFA < ${out_base}-out.txt`;
	chomp $report;
	if ($report eq "Not a DFA") {
	    cmt("  OUTPUT FILE IS NOT A DFA (DFA PARSE ERROR)\n");
	    $error_counts{$prog}++;
	    next;
	}

	# ${out_base}-out.txt is a DFA; check number of states
	# and equivalence with the solution
	$dfa = `cat $test_dir/$base.txt`;
	$dfa =~ /Number of states:\s+(\d+)/;
	$nstates = $1;
	if ($report !~ /with (\d+) states/) {
	    print STDERR "ERROR: BUG in isDFA (fatal)\n";
	    exit(1);
	}
	if ($1 > $nstates) {
	    cmt("  DFA IS TOO LARGE ($1 STATES)\n");
	    $error_counts{$prog}++;
	}
	$report = `$bin_dir/DFAequiv $test_dir/${base}-out.txt ${out_base}-out.txt`;
	unlink "${out_base}-out.txt" if $delete_temps;
	chomp $report;
	if ($report =~ /The two DFAs are equivalent/) {
	    cmt("  the DFAs are equivalent (correct)\n");
	}
	elsif ($report =~ /The two DFAs are not equivalent/) {
	    cmt("  THE DFAs ARE NOT EQUIVALENT (INCORRECT)\n");
	    $error_counts{$prog}++;
	}
	else {
	    print STDERR "ERROR: BUG in DFAequiv (fatal)\n";
	    exit(1);
	}
    }
}


sub test_properties {
    ($command) = @_;

    for ($i=1; -e "$test_dir/DFA$i.txt"; $i++) {
	$base = "DFA$i";
	$out_base = "$out_dir/${base}";
	cmt("  Running properties on $base ...\n");

	cmt("    $command $base.txt > ${out_base}-out.txt 2> ${out_base}-err.txt\n");
	eval {
	    local $SIG{ALRM} = sub { die "TIMED OUT\n" };
	    alarm $timeout;
	    $rc = system("$command $test_dir/$base.txt > ${out_base}-out.txt 2> ${out_base}-err.txt");
	    alarm 0;
	};
	if ($@ && $@ eq "TIMED OUT\n") {
	    cmt("    $@");		# program timed out before finishing
	    $error_counts{$prog}++;
	    unlink "${out_base}-out.txt"
		if -e "${out_base}-out.txt";
	    unlink "${out_base}-err.txt"
		if -e "${out_base}-err.txt";
	    $no_timeout = 0;
	    next;
	}
	if ($rc >> 8) {
	    cmt("    terminated abnormally\n");
	    # $error_counts{$prog}++;
	    error_report($out_base);
	}
	else {
	    cmt("    terminated normally\n");
	    error_report($out_base);
	}

	if (!(-e "${out_base}-out.txt")) {
	    cmt("  OUTPUT FILE ${out_base}-out.txt DOES NOT EXIST\n");
	    $error_counts{$prog}++;
	    next;
	}

	cmt("  ${out_base}-out.txt exists -- checking against solution\n");

	$report = `cat ${out_base}-out.txt`;
	chomp $report;
	($emp,$fin) = extract_props($report);
	unlink "${out_base}-out.txt" if $delete_temps;

	$solreport = `cat $test_dir/${base}-out.txt`;
	chomp $solreport;
	($solemp,$solfin) = extract_props($solreport);

	if ($emp==$solemp && $fin==$solfin) {
	    cmt("  answers match correctly: $report\n");
	}
	else {
	    cmt("  ANSWERS DON'T MATCH:\n");
	    cmt("    CORRECT ANSWERS ARE $solreport\n");
	    cmt("    YOUR ANSWERS ARE $report\n");
	    $pec_save = $error_counts{$prog};
	    $error_counts{$prog}++ if $emp != $solemp;
	    $error_counts{$prog}++ if $fin != $solfin;
	    $pec_diff = $error_counts{$prog} - $pec_save;
	    cmt("    ($pec_diff ERROR(S))\n");
	}
    }
}


sub error_report {
    my ($base) = @_;
    if (-e "${base}-err.txt") {
	if (-s "${base}-err.txt") {
	    cmt("  standard error output:\nvvvvv\n");
	    $report = `cat ${base}-err.txt`;
	    chomp $report;
	    cmt("$report\n^^^^^\n");
	}
	unlink "${base}-err.txt" if $delete_temps;
    }
}


sub extract_props {
    my ( $report ) = @_;
    my $emp;
    my $fin;
    if ($report !~ /(non)?empty/i) {
	$emp = 2;
    }
    elsif ($& eq "empty") {
	$emp = 1;
    }
    else {
	$emp = 0;
    }

    if ($report !~ /(in)?finite/i) {
	$fin = 2;
    }
    elsif ($& eq "finite") {
	$fin = 1;
    }
    else {
	$fin = 0;
    }

    return ($emp,$fin);
}


sub report_summary {
    my $report;
    cmt("######################################################\n");
    cmt("Summary for $uname:\n\n");

    foreach $prog (@programs) {
	$report = report_progress($prog);
	cmt("$prog: $report with $error_counts{$prog} execution errors\n");
    }
    cmt("\nThere were a total of $error_count execution errors found.\n");
    cmt("######################################################\n");
}


# Possible progress report values:
#    0 - not implemented at all ($prog.txt file does not exist)
#    1 - $prog.txt file exists, but there was an error parsing it
#    2 - $prog.txt parsed OK, but the build failed (error return value)
#    3 - $prog built OK, but execution timed out at least once
#    4 - $prog execution always completed (but there were errors)
#    5 - $prog execution always completed without errors
sub report_progress {
    my ( $prog ) = @_;
    my $p = $progress{$prog};
    my $ret = "\n  progress level $p";
    return "not implemented -- $prog.txt does not exist" . $ret
	if $p == 0;
    return "$prog.txt exists, but there was an error parsing it" . $ret
	if $p == 1;
    return "$prog.txt parsed OK, but build failed" . $ret
	if $p == 2;
    return "built OK, but execution timed out at least once" . $ret
	if $p == 3;
    return "execution always completed, but there were errors" . $ret
	if $p == 4;
    return "execution always completed without errors" . $ret
	if $p == 5;
    return "??? unknown progress status for $prog" . $ret
}


sub cmt {
    my ($str) = @_;
#  print $str;
    print(COMMENTS $str);
}


sub now {
    my $ret;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
    $ret = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat')[$wday];
    $ret .= " ";
    $ret .= ('Jan','Feb','Mar','Apr','May','Jun','Jul',
	     'Aug','Sep','Oct','Nov','Dec')[$mon];
    $ret .= " $mday, ";
    $ret .= $year + 1900;
    $ret .= " at ${hour}:${min}:${sec} ";
    if ( $isdst ) {
	$ret .= "EDT";
    } else {
	$ret .= "EST";
    }
    return $ret;    
}


sub get_outcome_sequence {
    my ($file) = @_;
    my $ret = '';
    my $src = `cat $file`;
    while ($src =~ /aCCept|rEJect/i) {
	$ret .= $& eq 'accept' ? 'A' : 'R';
	$src = $';
    }
    return $ret;
}
