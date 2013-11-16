#!/usr/bin/perl -T
# nagios: -epn
#
#  Author: Hari Sekhon
#  Date: 2011-05-28 22:23:05 +0000 (Sat, 28 May 2011)
#
#  http://github.com/harisekhon
#
#  License: see accompanying LICENSE file
#

$DESCRIPTION = "Nagios Plugin to check MemCached statistics";

$VERSION = "0.7";

use strict;
use warnings;
use IO::Socket;
BEGIN {
    use File::Basename;
    use lib dirname(__FILE__) . "/lib";
}
use HariSekhonUtils;

my $default_port = 11211;
$port = $default_port;
$timeout_min = 1;
$timeout_max = 60;

%options = (
    "H|host=s"           => [ \$host,       "Host to connect to" ],
    "P|port=i"           => [ \$port,       "Port to connect to (defaults to $default_port)" ],
    "w|warning=i"        => [ \$warning,    "Warning threshold for current connections" ],
    "c|critical=i"       => [ \$critical,   "Critical threshold for current connections" ],
);
@usage_order = qw/host port warning critical/;

get_options();

$host = validate_host($host);
$port = validate_port($port);
validate_thresholds(1,1);
vlog2;

set_timeout();

vlog2 "connecting to $host:$port";
my $conn = IO::Socket::INET->new (
                                    Proto    => "tcp",
                                    PeerAddr => $host,
                                    PeerPort => $port,
                                 ) or quit "CRITICAL", "Failed to connect to '$host:$port': $!";
vlog2 "OK connected";
$conn->autoflush(1);
vlog3 "set autoflush on";

my %stats;
# List of stats to collect, format is NAME => (OUTPUT_STAT, IS_COUNTER)
# IF YOU CHANGE THIS STUFF YOU MUST CHANGE THE PNP4NAGIOS DATATYPES WHICH I'VE ADDED SUPPORT TO PRINT OUT FOR YOU IF YOU USE VERBOSE. OTHERWISE GRAPHING WILL GET SCREWED
my %stats2 = (
    "accepting_conns"       => [1, 0],
    "auth_cmds"             => [1, 1],
    "auth_errors"           => [1, 1],
    "bytes"                 => [1, 0],
    "bytes_read"            => [1, 1],
    "bytes_written"         => [1, 1],
    "cas_badval"            => [1, 0],
    "cas_hits"              => [1, 0],
    "cas_misses"            => [1, 0],
    "cmd_flush"             => [1, 0],
    "cmd_get"               => [1, 1],
    "cmd_set"               => [1, 1],
    "conn_yields"           => [1, 0],
    "connection_structures" => [1, 0],
    "curr_connections"      => [1, 0],
    "curr_items"            => [1, 0],
    "decr_hits"             => [1, 0],
    "decr_misses"           => [1, 0],
    "delete_hits"           => [1, 0],
    "delete_misses"         => [1, 0],
    "evictions"             => [1, 1],
    "get_hits"              => [1, 1],
    "get_misses"            => [1, 1],
    "incr_hits"             => [1, 1],
    "incr_misses"           => [1, 1],
    "limit_maxbytes"        => [0, 0],
    "listen_disabled_num"   => [0, 0],
    "pid"                   => [0, 0],
    "pointer_size"          => [0, 0],
    "reclaimed"             => [1, 1],
    "rusage_system"         => [1, 1],
    "rusage_user"           => [1, 1],
    "threads"               => [1, 0],
    "time"                  => [0, 0],
    "total_connections"     => [0, 0],
    "total_items"           => [0, 0],
    "uptime"                => [0, 0],
    "version"               => [0, 0],
);

vlog3 "sending stats request";
print $conn "stats\n" or quit "CRITICAL", "Failed to send stat request: $!";
vlog3 "stats request sent";
my $line;
my $linecount = 0;
my $err_msg;
while (<$conn>){
    chomp;
    s/\r$//;
    if(/ERROR/){
        if(/^ERROR$/){
            $err_msg = "unknown command sent to";
        } elsif(/CLIENT_ERROR/){
            $err_msg = "client error returned from";
        } elsif (/SERVER_ERROR/){
            $err_msg = "server error returned from";
        } else {
            $err_msg = "unknown error returned from";
        }
        quit "CRITICAL", "$err_msg memcached '$host:$port': '$_'";
    }
    last if /END/;
    /^STAT \w+ [\d\.]+$/ or quit "CRITICAL", "unrecognized line in output: '$_'";
    #vlog3 "processing line: '$_'";
    $line = $_;
    $linecount++;
    foreach(sort keys %stats2){
        #vlog3 "checking for stat $_";
        if($line =~ /^STAT $_ ([\d\.]+)$/){
            #vlog3 "found $_";
            $stats{$_} = $1;
            next;
        }
    }
}
vlog3 "got response" if ($linecount > 0);
close $conn;
vlog2 "closed connection\n";
# Different versions of memcached output different stats unfortunately so this sanity check while good may break stuff
#foreach(sort keys %stats){
#    defined($stats{$_}) or quit "CRITICAL", "$_ was not found in output from memcached on '$host:$port'";
#    #vlog "$_: $stats{$_}";
#}

my $msg = "Memcached ";
foreach(qw/curr_connections threads curr_items total_items version uptime/){
    defined($stats{$_}) or quit "CRITICAL", "$_ was not found in output from memcached on '$host:$port'";
    $msg .= "$_: " . $stats{$_};
    $msg .= "(w=$warning/c=$critical)" if /^curr_connections$/;
    $msg .= ", ";
}

$msg =~ s/, $/|/;
my $var;
my $pnp4nagios_datatype = "";
foreach(sort keys %stats2){
    unless($stats2{$_}[0]){
        #vlog "skipping $_ since it's set to no output in stats2 hash";
        next;
    }
    if(!defined($stats{$_})){
        vlog2 "$_ not found in output, probably due to the memcached version on the server not supporting this stat... skipping...";
        next;
    }
    if($stats2{$_}[1]){
        $pnp4nagios_datatype .= "COUNTER,";
        if (/rusage_system/ or /rusage_user/){
            vlog3 "converting $_ to from secs to millisecs (us) - PNP4Nagios breaks on floats for COUNTER type";
            $stats{$_} = $stats{$_} * 1000000 . "us";
        }
        # PNP4Nagios doesn't respect or use this and it comes out in the graphs unfortunately so don't output it
        #$msg .= "'$_'=$stats{$_}c ";
        $msg .= "$_=$stats{$_} ";
    } else {
        $pnp4nagios_datatype .= "GAUGE,";
        $msg .= "$_=$stats{$_}";
        if($_ =~ /^curr_connections$/){
            $msg .= ";$warning;$critical";
        }
        $msg .= " ";
    }
}
$pnp4nagios_datatype =~ s/,$//;
vlog3 "\nPNP4Nagios DataType: '$pnp4nagios_datatype'\n";

my $status = "OK";
my %stats3;
my $msg2 = "Unknown stats found: ";
foreach(sort keys %stats){
    unless(defined($stats2{$_})){
        $status = "WARNING";
        $stats3{$_} = 1;
    }
}
if(scalar keys %stats3 > 0){
    $status = "WARNING";
    foreach(sort keys %stats3){
        $msg2  .= "$_,";
    }
    $msg2 =~ s/,$//;
    $msg2 .= " (plugin may need updating)";
    $msg = "$msg2. $msg";
}
if($stats{"curr_connections"} >= $critical){
    $status = "CRITICAL";
} elsif($stats{"curr_connections"} >= $warning) {
    $status = "WARNING";
}

quit($status, $msg);
