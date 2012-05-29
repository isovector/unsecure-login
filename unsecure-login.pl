#!/usr/bin/perl

### EDIT THESE IF YOU DON'T WANT TO ENTER THEM AS FLAGS ###
my $opt_user        = "";
my $opt_pwd         = "";

###########################################################
# unsecure-login - logs into uw-unsecure automatically    #
#    written by Sandy Maguire (amaguire@uwaterloo.ca)     #
#                                                         #
# Last revised 2012-05-28                                 #
#                                                         #
# This software is licensed under the GPLv2               #
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html   #
###########################################################

use Getopt::Long qw(:config bundling);

# options
my $opt_verbose     = 0;
my $opt_help        = 0;

GetOptions (
    'user=s'    => \$opt_user,
    'pass=s'    => \$opt_pwd,
    'verbose!'  => \$opt_verbose,
    'help'      => \$opt_help
);

# boring help display
if ($opt_help) {
    print "Usage: unsecure-login.pl [--help] [--verbose] [<options>]\n";
    print "  options:\n";
    print "  --user=<str>\t\tlogin as user <str>\n";
    print "  --pass=<str>\t\tlogin with password <str>\n";
    exit;
}

use LWP;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use HTML::Form;

print "Requesting login form\n" if $opt_verbose;

# build the user agent
my $ua = LWP::UserAgent->new();
$ua->agent('Mozilla/5.0');
$ua->cookie_jar({ file => "$ENV{HOME}/.cookies.txt" });

# attempt to load google.com
my $req   = HTTP::Request->new(GET => 'http://google.com');
my $res   = $ua->request($ua->prepare_request($req));

# google doesn't have a University of Waterloo string
unless ($res->as_string =~ m/University of Waterloo/) {
    print "Authentication is not required\n" if $opt_verbose;
    exit 0;
}

# no username/password
if ($opt_user eq "" || $opt_pwd eq "") {
    print "Error: no username and/or password specified\n";
    print "You must either specify defaults by editing unsecure-login.pl,\n";
    print "or set these options with the --user and --pass flags.\n";
    exit;
}

# but we do, so we need to log in
my @forms = HTML::Form->parse($res);
my $form  = $forms[0];

print "Logging in as $opt_user...\n" if $opt_verbose;

# fill in the form with our username and password
$form->value('user', $opt_user);
$form->value('password', $opt_pwd);
my $freq = $form->click;
$freq = $ua->prepare_request($freq);
my $fres = $ua->request($freq);


if ($fres->as_string =~ m/User Authenticated/) {
    print "Logged in successfully" if $opt_verbose;
    exit(0);
}

die "Unable to login: Invalid username and/or password\n" if $opt_verbose;
