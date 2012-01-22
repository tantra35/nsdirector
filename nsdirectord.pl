#!/usr/bin/perl -w
######################################################################
# nsdirectord                 http://www.vergenet.net/linux/ldirectord/
# Linux Director Daemon - run "perldoc ldirectord" for details
#
# 1999-2006 (C) Jacob Rief <jacob.rief@tiscover.com>,
#               Horms <horms@verge.net.au> and others
#
# License:      GNU General Public License (GPL)
#
# Note: * The original author of this software was Jacob Rief circa 1999
#       * It was maintained by Jacob Rief and Horms
#         from November 1999 to July 2003.
#       * From July 2003 Horms is the maintainer
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
#
######################################################################

# A Brief history of versions:
#
# From oldest to newest
# 1.1-1.144: ldirecord maintained in CVS HEAD branch
# 1.145-1.186: ldirectord.in maintained in CVS HEAD BRANCH
# 1.186-ha-VERSION: ldirectord.in maintained in mercurial

=head1 NAME

ldirectord - Linux Director Daemon

Daemon to monitor remote services and control Linux Virtual Server


=head1 SYNOPSIS

B<ldirectord> [B<-d|--debug>] [--] [I<configfile>]
B<start> | B<stop> | B<restart> | B<try-restart> | B<reload> | B<force-reload> | B<status>

B<ldirectord> [B<-h|-?|--help|-v|--version>]

=head1 DESCRIPTION

B<ldirectord> is a daemon to monitor and administer real servers in a
cluster of load balanced virtual servers. B<ldirectord> typically is
started from heartbeat but can also be run from the command line. On
startup B<ldirectord> reads the file B</usr/etc/ha.d/conf/>I<configuration>.
After parsing the file, entries for virtual servers are created on the LVS.
Now at regular intervals the specified real servers are monitored and if
they are considered alive, added to a list for each virtual server. If a
real server fails, it is removed from that list. Only one instance of
B<ldirectord> can be started for each configuration, but more instances of
B<ldirectord> may be started for different configurations. This helps to
group clusters of services.  Normally one would put an entry inside
B</usr/etc/ha.d/haresources>

I<nodename virtual-ip-address ldirectord::configuration>

to start ldirectord from heartbeat.


=head1 OPTIONS

I<configuration>:
This is the name for the configuration as specified in the file
B</usr/etc/ha.d/conf/>I<configuration>

B<-d|--debug> Don't start as daemon and log verbosely.

B<-h|--help> Print user manual and exit.

B<-v|--version> Print version and exit.

B<start> the daemon for the specified configuration.

B<stop> the daemon for the specified configuration. This is the same as sending
a TERM signal to the running daemon.

B<restart> the daemon for the specified configuration. The same as stopping and starting.

B<reload> the configuration file. This is only useful for modifications
inside a virtual server entry. It will have no effect on adding or
removing a virtual server block. This is the same as sending a HUP signal to
the running daemon.

B<status> of the running daemon for the specified configuration.


=head1 SYNTAX

=head2 Description of how to write configuration files

B<virtual = >I<(ip_address|hostname:portnumber|servicename)|firewall-mark>

Defines a virtual service by IP-address (or hostname) and port (or
servicename) or firewall-mark.  A firewall-mark is an integer greater than
zero. The configuration of marking packets is controlled using the C<-m>
option to B<ipchains>(8).  All real services and flags for a virtual
service must follow this line immediately and be indented.

B<checktimeout = >I<n>

Timeout in seconds for connect, external, external-perl and ping checks. If the timeout is
exceeded then the real server is declared dead.

If defined in a virtual server section then the global value is overridden.

If undefined then the value of negotiatetimeout is used.  negotiatetimeout
is also a global value that may be overridden by a per-virtual setting.

If both checktimeout and negotiatetimeout are unset, the default is used.

Default: 5 seconds

B<negotiatetimeout = >I<n>

Timeout in seconds for negotiate checks.

If defined in a virtual server section then the global value is overridden.

If undefined then the value of connecttimeout is used.  connecttimeout is
also a global value that may be overridden by a per-virtual setting.

If both negotiatetimeout and connecttimeout are unset, the default is used.

Default: 30 seconds

B<checkinterval = >I<n>

Defines the number of second between server checks.

When fork=no this option defines the amount of time ldirectord sleeps
between running all of the realserver checks in all virtual service pools.

When fork=yes this option defines the amount of time each forked child
sleeps per virtual service pool after running all realserver checks for
that pool.

If set in the virtual server section then the global value is overridden,
but ONLY if using forking mode (B<fork = >I<yes>).

Default: 10 seconds

B<checkcount = >I<n>

This option is deprecated and slated for removal in a future version.
Please see the 'failurecount' option.

The number of times a check will be attempted before it is considered to
have failed. Only works with ping checks. Note that the
checktimeout/negotiatetimeout is additive, so if a connect check is used,
checkcount is 3 and checktimeout is 2 seconds, then a total of 6 seconds
worth of timeout will occur before the check fails.

If defined in a virtual server section then the global value is overridden.

Default: 1

B<failurecount = >I<n>

The number of consecutive times a failure will have to be reported by a
check before the realserver is considered to have failed.  A
value of 1 will have the realserver considered failed on the first failure.
A successful check will reset the failure counter to 0.

If defined in a virtual server section then the global value is overridden.

Default: 1

B<autoreload = >B<yes> | B<no>

Defines if <ldirectord> should continuously check the configuration file
for modification. If this is set to 'yes' and the configuration file
changed on disk and its modification time (mtime) is newer than the
previous version, the configuration is automatically reloaded.

Default: no

B<callback = ">I</path/to/callback>B<">

If this directive is defined, B<ldirectord> automatically calls
the executable I</path/to/callback> after the configuration
file has changed on disk. This is useful to update the configuration
file through B<scp> on the other heartbeated host. The first argument
to the callback is the name of the configuration.

This directive might also be used to restart B<ldirectord> automatically
after the configuration file changed on disk. However, if B<autoreload>
is set to yes, the configuration is reloaded anyway.

B<fallback = >I<ip_address|hostname[:portnumber|sercvicename]> [B<gate> | B<masq> | B<ipip>]

the server onto which a webservice is redirected if all real
servers are down. Typically this would be 127.0.0.1 with
an emergency page.

If defined in a virtual server section then the global value is overridden.

B<fallbackcommand = ">I<path to script>B<">

If this directive is defined, the supplied script is executed whenever all
real servers for a virtual service are down or when the first real server
comes up again. In the first case, it is called with "start" as its first
argument, in the latter with "stop".

If defined in a virtual server section then the global value is overridden.

B<logfile = ">I</path/to/logfile>B<">|syslog_facility

An alternative logfile might be specified with this directive. If the logfile
does not have a leading '/', it is assumed to be a syslog(3) facility name.

Default: log directly to the file I</var/log/ldirectord.log>.


B<emailalert = ">I<emailaddress>[, I<emailaddress>]...B<">

A valid email address for sending alerts about the changed connection status
to any real server defined in the virtual service.  This option requires
perl module MailTools to be installed.  Automatically tries to send email
using any of the built-in methods. See perldoc Mail::Mailer for more info on
methods.

Multiple addresses may be supplied, comma delimited.

If defined in a virtual server section then the global value is overridden.


B<emailalertfrom = >I<emailaddress>

A valid email address to use as the from address of the email alerts.  You
can use a plain email address or any RFC-compliant string for the From header
in the body of an email message (such as: "ldirectord Alerts" <alerts@example.com>)
Do not quote this string unless you want the quotes passed in as part of the
From header.

Default: unset, take system generated default (probably root@hostname)


B<emailalertfreq => I<n>

Delay in seconds between repeating email alerts while any given real server
in the virtual service remains inaccessible.  A setting of zero seconds
will inhibit the repeating alerts. The email timing accuracy of this
setting is dependent on the number of seconds defined in the checkinterval
configuration option.

If defined in a virtual server section then the global value is overridden.

Default: 0


B<emailalertstatus = >B<all> | B<none> | B<starting> | B<running> | B<stopping> | B<reloading>,...

Comma delimited list of server states in which email alerts should be sent.
B<all> is a short-hand for
"B<starting>,B<running>,B<stopping>,B<reloading>".  If B<none> is
specified, no other option may be specified, otherwise options are ored
with each other.

If defined in a virtual server section then the global value is overridden.

Default: all


B<smtp = >I<ip_address|hostname>B<">

A valid SMTP server address to use for sending email via SMTP.

If defined in a virtual server section then the global value is overridden.


B<execute = ">I<configuration>B<">

Use this directive to start an instance of ldirectord for
the named I<configuration>.


B<supervised = >B<yes> | B<no>

If I<yes>, then ldirectord does not go into background mode.
All log-messages are redirected to stdout instead of a logfile.
This is useful to run B<ldirectord> supervised from daemontools.
See http://untroubled.org/rpms/daemontools/ or http://cr.yp.to/daemontools.html
for details.

Default: I<no>


B<fork = >B<yes> | B<no>

If I<yes>, then ldirectord will spawn a child process for every virtual server,
and run checks against the real servers from them.  This will increase response
times to changes in real server status in configurations with many virtual
servers.  This may also use less memory then running many separate instances of
ldirectord.  Child processes will be automatically restarted if they die.

Default: I<no>


B<quiescent = >B<yes> | B<no>

If I<yes>, then when real or failback servers are determined
to be down, they are not actually removed from the kernel's LVS
table. Rather, their weight is set to zero which means that no
new connections will be accepted.

This has the side effect, that if the real server has persistent
connections, new connections from any existing clients will continue to be
routed to the real server, until the persistent timeout can expire. See
L<ipvsadm> for more information on persistent connections.

This side-effect can be avoided by running the following:

echo 1 > /proc/sys/net/ipv4/vs/expire_quiescent_template

If the proc file isn't present this probably means that
the kernel doesn't have LVS support, LVS support isn't loaded,
or the kernel is too old to have the proc file. Running
ipvsadm as root should load LVS into the kernel if it is possible.

If I<no>, then the real or failback servers will be removed
from the kernel's LVS table. The default is I<yes>.

If defined in a virtual server section then the global value is overridden.

Default: I<yes>


B<cleanstop = >B<yes> | B<no>

If I<yes>, then when ldirectord exits it will remove all of the virtual
server pools that it is managing from the kernel's LVS table.

If I<no>, then the virtual server pools it is managing and any real
or failback servers listed in them at the time ldirectord exits will
be left as-is.  If you want to be able to stop ldirectord without having
traffic to your realservers interrupted you will want to set this to I<no>.

If defined in a virtual server section then the global value is overridden.

Default: I<yes>


B<maintenancedir = >I<directoryname>

If this option is set ldirectord will look for a special file in the specified
directory and, if found, force the status of the real server identified by the
file to down, skipping the normal health check.  This would be useful if you
wish to force servers down for maintenance without having to modify the actual
ldirectord configuration file.

For example, given a realserver with IP 172.16.1.2, service on port 4444, and
a resolvable reverse DNS entry pointing to "realserver2.example.com" ldirectord
will check for the existence of the following files:

=over

=item 172.16.1.2:4444

=item 172.16.1.2

=item realserver2.example.com:4444

=item realserver2.example.com

=item realserver2:4444

=item realserver2

=back

If any one of those files is found then ldirectord will immediately force the
status of the server to down as if the check had failed.

Note: Since it checks for the IP/hostname without the port this means you can
decide to place an entire realserver into maintenance across a large number of
virtual service pools with a single file (if you were going to reboot the server,
for instance) or include the port number and put just a particular service into
maintenance.

This option is not valid in a virtual server section.

Default: disabled


=head2 Section virtual

The following commands must follow a B<virtual> entry and must be indented
with a minimum of 4 spaces or one tab.

B<real => I<ip_address|hostname[-E<gt>ip_address|hostname][:portnumber|servicename>] B<gate> | B<masq> | B<ipip> [I<weight>] [B<">I<request>B<", ">I<receive>B<">]

Defines a real service by IP-address (or hostname) and port (or
servicename). If the port is omitted then a 0 will be used, this is
intended primarily for fwmark services where the port for real servers is
ignored. Optionally a range of IPv4 addresses (or two hostnames) may be
given, in which case each IPv4 address in the range will be treated as a real
server using the given port. The second argument defines the forwarding
method, must be B<gate>, B<ipip> or B<masq>.  The third argument is
optional and defines the weight for that real server. If omitted then a
weight of 1 will be used. The last two arguments are also optional. They
define a request-receive pair to be used to check if a server is alive.
They override the request-receive pair in the virtual server section. These
two strings must be quoted. If the request string starts with I<http://...>
the IP-address and port of the real server is overridden, otherwise the
IP-address and port of the real server is used.

=head2
For TCP and UDP (non fwmark) virtual services, unless the forwarding method
is B<masq> and the IP address of a real server is non-local (not present on
a interface on the host running ldirectord) then the port of the real
server will be set to that of its virtual service. That is, port-mapping is
only available to if the real server is another machine and the forwarding
method is B<masq>.  This is due to the way that the underlying LVS code in
the kernel functions.

=head2
More than one of these entries may be inside a virtual section.  The
checktimeout, negotiatetimeout, checkcount, fallback, emailalert,
emailalertfreq and quiescent options listed above may also appear inside a
virtual section, in which case the global setting is overridden.

B<checktype =
>B<connect> | B<external> | B<external-perl> | B<negotiate> | B<off> | B<on> | B<ping> | B<checktimeout>I<N>

Type of check to perform. Negotiate sends a request and matches a receive
string. Connect only attempts to make a TCP/IP connection, thus the
request and receive strings may be omitted.  If checktype is a number then
negotiate and connect is combined so that after each N connect attempts one
negotiate attempt is performed. This is useful to check often if a service
answers and in much longer intervals a negotiating check is done. Ping
means that ICMP ping will be used to test the availability of real servers.
Ping is also used as the connect check for UDP services. Off means no
checking will take place and no real or fallback servers will be activated.
On means no checking will take place and real servers will always be
activated. Default is I<negotiate>.

B<service = >B<dns> | B<ftp> | B<http> | B<https> | B<http_proxy> | B<imap> | B<imaps> | B<ldap> | B<mysql> | B<nntp> | B<none> | B<oracle> | B<pgsql> | B<pop> | B<pops> | B<radius> | B<simpletcp> | B<sip> | B<smtp> | B<submission>

The type of service to monitor when using checktype=negotiate. None denotes
a service that will not be monitored.

simpletcp sends the B<request> string to the server and tests it against
the B<receive> regexp. The other types of checks connect to the server
using the specified protocol. Please see the B<request> and B<receive>
sections for protocol specific information.

Default:

=over 4

=item * Virtual server port is 21: ftp

=item * Virtual server port is 25: smtp

=item * Virtual server port is 53: dns

=item * Virtual server port is 80: http

=item * Virtual server port is 110: pop

=item * Virtual server port is 119: nntp

=item * Virtual server port is 143: imap

=item * Virtual server port is 389: ldap

=item * Virtual server port is 443: https

=item * Virtual server port is 587: submission

=item * Virtual server port is 993: imaps

=item * Virtual server port is 995: pops

=item * Virtual server port is 1521: oracle

=item * Virtual server port is 1812: radius

=item * Virtual server port is 3128: http_proxy

=item * Virtual server port is 3306: mysql

=item * Virtual server port is 5432: pgsql

=item * Virtual server port is 5060: sip

=item * Otherwise: none

=back


B<checkcommand = ">I<path to script>B<">

This setting is used if checktype is external or external-perl and is the command to be run
to check the status of a real server. It should exit with status 0 if
everything is ok, or non-zero otherwise.

Four parameters are passed to the script:

=over 4

=item * virtual server ip/firewall mark

=item * virtual server port

=item * real server ip

=item * real server port

=back

If the checktype is external-perl then the command is assumed to be a
Perl script and it is evaluated into an anonymous subroutine which is
called at check time, avoiding a fork-exec.  The argument signature and
exit code conventions are identical to checktype external.  That is, an
external-perl checktype should also work as an external checktype.

Default: /bin/true

B<checkport = >I<n>

Number of port to monitor. Sometimes check port differs from service port.

Default: port specified for each real server

B<request = ">I<uri to requested object>B<">

This object will be requested each checkinterval seconds on each real
server.  The string must be inside quotes. Note that this string may be
overridden by an optional per real-server based request-string.

For an HTTP/HTTPS check, this should be a relative URI, while it has to
be absolute for the 'http_proxy' check type. In the latter case, this
URI will be requested through the proxy backend that is being checked.

For a DNS check this should the name of an A record, or the address
of a PTR record to look up.

For a MySQL, Oracle or PostgeSQL check, this should be an SQL SELECT query.
The data returned is not checked, only that the
answer is one or more rows.  This is a required setting.

For a simpletcp check, this string is sent verbatim except any occurrences
of \n are replaced with a new line character.

B<receive = ">I<regexp to compare>B<">

If the requested result contains this I<regexp to compare>, the real server
is declared alive. The regexp must be inside quotes. Keep in mind that
regexps are not plain strings and that you need to escape the special
characters if they should as literals. Note that this regexp may be
overridden by an optional per real-server based receive regexp.

For a DNS check this should be any one the A record's addresses or
any one of the PTR record's names.

For a MySQL check, the receive setting is not used.

B<httpmethod = GET> | B<HEAD>

Sets the HTTP method which should be used to fetch the URI specified in
the request-string. GET is the method used by default if the parameter is
not set. If HEAD is used, the receive-string should be unset.

Default: GET

B<virtualhost = ">I<hostname>B<">

Used when using a negotiate check with HTTP or HTTPS. Sets the host header
used in the HTTP request.  In the case of HTTPS this generally needs to
match the common name of the SSL certificate. If not set then the host
header will be derived from the request url for the real server if present.
As a last resort the IP address of the real server will be used.

B<login = ">I<username>B<">

For FTP, IMAP, LDAP, MySQL, Oracle, POP and PostgreSQL, the username
used to log in.

For Radius the passwd is used for the attribute User-Name.

For SIP, the username is used as both the to and from address for an
OPTIONS query.

Default:

=over 4

=item * FTP: Anonymous

=item * MySQL Oracle, and PostgreSQL: Must be specified in the configuration

=item * SIP: ldirectord\@<hostname>, hostname is derived as per the passwd
	option below.

=item * Otherwise: empty string, which denotes that
	case authentication will not be attempted.

=back

B<passwd = ">I<password>B<">

Password to use to login to FTP, IMAP, LDAP, MySQL, Oracle, POP, PostgreSQL
and SIP servers.

For Radius the passwd is used for the attribute User-Password.

Default:

=over 4

=item * FTP: ldirectord\@<hostname>,
	where hostname is the environment variable HOSTNAME evaluated at
	run time, or sourced from uname if unset.

=item * Otherwise: empty string.
	In the case of LDAP, MySQL, Oracle, and PostgreSQL this means
	that authentication will not be performed.

=back

B<database = ">I<databasename>B<">

Database to use for MySQL, Oracle and PostgreSQL servers, this is the
database that the query (set by B<receive> above) will be performed
against.  This is a required setting.

B<secret = ">I<radiussecret>B<">

Secret to use for Radius servers, this is the secret used to perform an
Access-Request with the username (set by B<login> above) and passwd (set by
B<passwd> above).

Default: empty string

B<scheduler => I<scheduler_name>

Scheduler to be used by LVS for loadbalancing.
For an information on the available sehedulers please see
the ipvsadm(8) man page.

Default: "wrr"

B<persistent => I<n>

Number of seconds for persistent client connections.

B<netmask => I<w.x.y.z>

Netmask to be used for granularity of persistent client connections.

B<protocol = tcp> | B<udp> | B<fwm>

Protocol to be used. If the virtual is specified as an IP address and port
then it must be one of tcp or udp. If a firewall
mark then the protocol must be fwm.

Default:

=over 4

=item * Virtual is an IP address and port, and the port is not 53: tcp

=item * Virtual is an IP address and port, and the port is 53: udp

=item * Virtual is a firewall mark: fwm

=back

B<monitorfile = ">I</path/to/monitorfile>B<">

File to continuously log the real service checks to for this virtual
service. This is useful for monitoring when and why real services were down
or for statistics.

The log format is:
[timestamp|pid|real_service_id|status|message]

Default: no separate logging of service checks.

=head1 IPv6

Directives for IPv6 are virtual6, real6, fallback6.
IPv6 addresses specified for virtual6, real6, fallback6 and a file
of maintenance directory should be enclosed by
brackets ([2001:db8::abcd]:80).

Following checktype and service are supported.

B<checktype: >B<connect> | B<external> | B<external-perl> | B<negotiate> | B<off> | B<on> | B<checktimeout>I<N>

B<service: >B<dns> | B<nntp> | B<none> | B<simpletcp> | B<sip>


=head1 FILES

B</usr/etc/ha.d/ldirectord.cf>

B</var/log/ldirectord.log>

B</var/run/ldirectord.>I<configuration>B<.pid>

B</etc/services>

=head1 SEE ALSO

L<ipvsadm>, L<heartbeat>

Ldirectord Web Page: http://www.vergenet.net/linux/ldirectord/


=head1 AUTHORS

Horms <horms@verge.net.au>

Jacob Rief <jacob.rief@tiscover.com>

=cut

use strict;
# Set defaults for configuration variables in the "set_defaults" function
use vars qw(
	    $VERSION_STR
	    $AUTOCHECK
	    $CHECKINTERVAL
	    $LDIRECTORD
	    $LDIRLOG
	    $NEGOTIATETIMEOUT
	    $DEFAULT_NEGOTIATETIMEOUT
	    $RUNPID
	    $CHECKTIMEOUT
	    $DEFAULT_CHECKTIMEOUT
	    $CHECKCOUNT
	    $FAILURECOUNT
	    $QUIESCENT
	    $FORKING
	    $EMAILALERT
	    $EMAILALERTFREQ
	    $EMAILALERTSTATUS
	    $EMAILALERTFROM
	    $SMTP
	    $CLEANSTOP
	    $MAINTDIR
			$CONTROLPOINT
	    $CALLBACK
	    $CFGNAME
	    $CMD
	    $CONFIG
	    $DEBUG
	    $FALLBACK
	    $FALLBACK6
	    $FALLBACKCOMMAND
	    $SUPERVISED
	    $PY_NSUPDATE
	    $checksum
	    $DAEMON_STATUS
	    $DAEMON_STATUS_STARTING
	    $DAEMON_STATUS_RUNNING
	    $DAEMON_STATUS_STOPPING
	    $DAEMON_STATUS_RELOADING
	    $DAEMON_STATUS_ALL
	    $DAEMON_TERM
	    $DAEMON_HUP
	    $DAEMON_CHLD
	    $opt_d
	    $opt_h
	    $stattime
	    %LD_INSTANCE
	    @OLDVIRTUAL
	    @REAL
	    @VIRTUAL
	    $HOSTNAME
	    %EMAILSTATUS
	    %FORK_CHILDREN
	    $SERVICE_UP
	    $SERVICE_DOWN
	    %check_external_perl__funcs

	    $CRLF
);

$VERSION_STR = "Linux Director v1.186-ha";

$DAEMON_STATUS_STARTING  = 0x1;
$DAEMON_STATUS_RUNNING   = 0x2;
$DAEMON_STATUS_STOPPING  = 0x4;
$DAEMON_STATUS_RELOADING = 0x8;
$DAEMON_STATUS_ALL       = $DAEMON_STATUS_STARTING |
			   $DAEMON_STATUS_RUNNING  |
			   $DAEMON_STATUS_STOPPING |
			   $DAEMON_STATUS_RELOADING;

$SERVICE_UP	= 0;
$SERVICE_DOWN	=1;

# default values
$DAEMON_TERM      = undef;
$DAEMON_HUP       = undef;
$LDIRECTORD       = ld_find_cmd("nsdirectord", 1);
if (! defined $LDIRECTORD) {
	$LDIRECTORD = "/usr/sbin/nsdirectord";
}
$RUNPID           = "/var/run/nsdirectord";

$CRLF = "\x0d\x0a";

# Set global configuration default values:
set_defaults();

use Getopt::Long;
use Pod::Usage;
#use English;
#use Time::HiRes qw( gettimeofday tv_interval );
use Socket;
use Socket6;
use Sys::Hostname;
use POSIX qw(setsid :sys_wait_h);
use Sys::Syslog qw(:DEFAULT setlogsock);

BEGIN
{
	# wrap exit() to preserve replacability
	*CORE::GLOBAL::exit = sub { CORE::exit(@_ ? shift : 0); };
}

# command line options
my @OLD_ARGV = @ARGV;
my $opt_d = '';
my $opt_h = '';
my $opt_v = '';
Getopt::Long::Configure ("bundling", "no_auto_abbrev", "require_order");
GetOptions("debug|d" => \$opt_d,
	   "help|h|?" => \$opt_h,
	   "version|v" => \$opt_v) or usage();

# main code
$DEBUG = $opt_d ? 3 : 0;

if ($opt_h) {
	exec_wrapper("/usr/bin/perldoc -U $LDIRECTORD");
	&ld_exit(127, "Exec failed");
}
if ($opt_v) {
	print("$VERSION_STR\n" .
	      "1999-2006 Jacob Rief, Horms and others\n" .
	      "<http://www.vergenet.net/linux/ldirectord/>\n".
	      "\n" .
	      "nsdirectord comes with ABSOLUTELY NO WARRANTY.\n" .
	      "This is free software, and you are welcome to redistribute it\n".
	      "under certain conditions. " .
		      "See the GNU General Public Licence for details.\n");

	&ld_exit(0, "");
}

if ($DEBUG>0 and -f "./py-nsupdate") {
	$PY_NSUPDATE="./py-nsupdate";
} else {
	if (-x "/bin/py-nsupdate") {
		$PY_NSUPDATE="/bin/py-nsupdate";
	} elsif (-x "/usr/bin/py-nsupdate") {
		$PY_NSUPDATE="/usr/bin/py-nsupdate";
	} else {
		die "Can not find py-nsupdate";
	}
}

# There is a memory leak in perl's socket code when
# the default IO layer is used. So use "perlio" unless
# something else has been explicitly set.
# http://archive.develooper.com/perl5-porters@perl.org/msg85468.html
unless(defined($ENV{'PERLIO'})) {
	$ENV{'PERLIO'} = "perlio";
	exec_wrapper($0, @OLD_ARGV);
}

$DAEMON_STATUS = $DAEMON_STATUS_STARTING;
ld_init();
ld_setup();
ld_start();
ld_cmd_children("start", %LD_INSTANCE);                           
$DAEMON_STATUS = $DAEMON_STATUS_RUNNING;
ld_main();

&ld_rm_file("$RUNPID.$CFGNAME.pid");
&ld_exit(0, "Reached end of \"main\"");

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
};

# Left trim function to remove leading whitespace
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
};

# Right trim function to remove trailing whitespace
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
};

sub parse_backets_str_parse_block_params($)
{
	my $block_params = shift;
	my $retval = {};

	foreach my $l_param_str(split(/\s*\,\s*/, $block_params))
	{
		if ($l_param_str =~ /\:/)
		{
			my($l_pname, $l_pvalue) = split(/\s*\:\s*/, $l_param_str, 2);
			$retval->{lc($l_pname)} = $l_pvalue;
		}
		else
		{
			my $l_pname = $l_param_str;
			$retval->{lc($l_pname)} = 1;
		};
	};
	
	return $retval;
};

sub parse_backets_str($)
{
	my $line = shift;
	my $retval = undef;

	my $l_retval = {};
	my $l_line = trim($line);
	my $l_parse_error = 0;

  while (length($l_line))
  {  
  	if($l_line =~ /(^([a-z]+)\s*\{([^\{\}]*)\})/)
  	{  	
  		my $l_block_name = uc($2);
  		my $l_block_params = parse_backets_str_parse_block_params($3);
  		
    	$l_retval->{$l_block_name} = $l_block_params;
  		$l_line = ltrim(substr($l_line, length($1)));
  	}
  	else
  	{
  		$l_parse_error = 1;
  		last;
  	};
  };

  if(!$l_parse_error)
  {
	  $retval = $l_retval;
  };
	  
  return $retval;
}; 

# functions
sub ld_init
{
	# install signal handlers (this covers TERM)
	#require Net::LDAP;
	$SIG{'INT'} = \&ld_handler_term;
	$SIG{'QUIT'} = \&ld_handler_term;
	$SIG{'ILL'} = \&ld_handler_term;
	$SIG{'ABRT'} = \&ld_handler_term;
	$SIG{'FPE'} = \&ld_handler_term;
	$SIG{'SEGV'} = \&ld_handler_term;
	$SIG{'TERM'} = \&ld_handler_term;

	$SIG{'BUS'} = \&ld_handler_term;
	$SIG{'SYS'} = \&ld_handler_term;
	$SIG{'XCPU'} = \&ld_handler_term;
	$SIG{'XFSZ'} = \&ld_handler_term;

	$SIG{'IOT'} = \&ld_handler_term;


	# This used to call a signal handler, that logged a message
	# However, this typically goes to syslog and if syslog
	# is playing up a loop will occur.
	$SIG{'PIPE'} = "IGNORE";

	# HUP is actually used
	$SIG{'HUP'} = \&ld_handler_hup;

	# Reap Children
	$SIG{'CHLD'} = \&ld_handler_chld;

	if (defined $ENV{HOSTNAME}) {
		$HOSTNAME = "$ENV{HOSTNAME}";
	}
	else {
		use POSIX "uname";
		my ($s, $n, $r, $v, $m) = uname;
		$HOSTNAME = $n;
	}

	# search for the correct configuration file
	if ( !defined $ARGV[0] ) {
		usage();
	}
	if ( defined $ARGV[0] && defined $ARGV[1] ) {
		$CONFIG = $ARGV[0];
		if ($CONFIG =~ /([^\/]+)$/) {
			$CFGNAME = $1;
		}
		$CMD = $ARGV[1];
	} elsif ( defined $ARGV[0] ) {
		$CONFIG = "nsdirectord.cf";
		$CFGNAME = "nsdirectord";
		$CMD = $ARGV[0];
	}
	if ( $CMD ne "start" and $CMD ne "stop" and $CMD ne "status"
			and $CMD ne "restart" and $CMD ne "try-restart"
			and $CMD ne "reload" and $CMD ne "force-reload") {
		usage();
	}
	if ( -f "/usr/etc/ha.d/$CONFIG" ) {
		$CONFIG = "/usr/etc/ha.d/$CONFIG";
	} elsif ( -f "/usr/etc/ha.d/conf/$CONFIG" ) {
		$CONFIG = "/usr/etc/ha.d/conf/$CONFIG";
	} elsif ( ! -f "$CONFIG" ) {
		init_error("Config file $CONFIG not found");
	}
	read_config();
	undef @OLDVIRTUAL;

	{
		my $log_str = "Invoking nsdirectord invoked as: $0 ";
		for my $i (@ARGV) {
			$log_str .= $i . " ";
		}
		ld_log($log_str);
	}

	my $oldpid;
	my $filepid;
	if (open(FILE, "<$RUNPID.$CFGNAME.pid")) {
		$_ = <FILE>;
		chomp;
		$filepid = $_;
		close(FILE);
		# Check to make sure this isn't a stale pid file
		if (open(FILE, "</proc/$filepid/cmdline")) {
			$_ = <FILE>;
			if (/nsdirectord/) {
				$oldpid = $filepid;
			}
			close(FILE);
		}
	}
	if (defined $oldpid) {
		if ($CMD eq "start") {
			ld_exit(0, "Exiting from nsdirectord $CMD");
		} elsif ($CMD eq "stop") {
			kill 15, $oldpid;
			ld_exit(0, "Exiting from nsdirectord $CMD");
		} elsif ($CMD eq "restart" or $CMD eq "try-restart") {
			kill 15, $oldpid;
			while (-f "$RUNPID.$CFGNAME.pid") {
				# wait until old pid file is removed
				sleep 1;
			}
			# N.B Fall through
		} elsif ($CMD eq "reload" or $CMD eq "force-reload") {
			kill 1, $oldpid;
			ld_exit(0, "Exiting from nsdirectord $CMD");
		} else { # status
			print STDERR "nsdirectord for $CONFIG is running with pid: $oldpid\n";
			ld_cmd_children("status", %LD_INSTANCE);
			ld_log("nsdirectord for $CONFIG is running with pid: $oldpid");
			ld_log("Exiting from nsdirectord $CMD");
			ld_exit(0, "Exiting from nsdirectord $CMD");
		}
	} else {
		if ($CMD eq "start" or $CMD eq "restart") {
			;
		} elsif ($CMD eq "stop" or $CMD eq "try-restart") {
			ld_exit(0, "Exiting from nsdirectord $CMD");
		} elsif ($CMD eq "status") {
			my $status;
			if (defined $filepid) {
				print STDERR "nsdirectord stale pid file " .
					"$RUNPID.$CFGNAME.pid for $CONFIG\n";
				ld_log("nsdirectord stale pid file " .
					"$RUNPID.$CFGNAME.pid for $CONFIG");
				$status = 1;
			} else {
				$status = 3;
			}
			print "nsdirectord is stopped for $CONFIG\n";
			ld_exit($status, "Exiting from nsdirectord $CMD");
		} else {
			ld_log("nsdirectord is stopped for $CONFIG");
			ld_exit(1, "Exiting from nsdirectord $CMD");
		}
	}

	# Run as daemon
	if ($SUPERVISED eq "yes" || $opt_d) {
		&ld_log("Starting $VERSION_STR with pid: $$");
	} else {
		&ld_log("Starting $VERSION_STR as daemon");
		open(FILE, ">$RUNPID.$CFGNAME.pid") ||
			init_error("Can not open $RUNPID.$CFGNAME.pid");
		&ld_daemon();
		print FILE "$$\n";
		close(FILE);
	}
}

sub usage
{
	pod2usage(-input => $LDIRECTORD, -exitval => -1);
}

sub init_error
{
	my $msg = shift;
	chomp($msg);
	&ld_log("$msg");
	unless ($opt_d) {
		print STDERR "$msg\n";
	}
	ld_exit(1, "Initialisation Error");
}

# ld_handler_term
# If we get a signal then log it and quit
sub ld_handler_term
{
	my ($signal) = (@_);

	if (defined $DAEMON_TERM) {
		$SIG{'__DIE__'} = "IGNORE";
		$SIG{"$signal"} = "IGNORE";
		die("Exit Handler Repeatedly Called\n");
	}
	$DAEMON_TERM = $signal;
	$DAEMON_STATUS = $DAEMON_STATUS_STOPPING;
}

sub ld_process_term
{
	$DAEMON_STATUS = $DAEMON_STATUS_STOPPING;
	ld_cmd_children("stop", %LD_INSTANCE);
	ld_stop();
	&ld_log("Linux Director Daemon terminated on signal: $DAEMON_TERM");
	&ld_rm_file("$RUNPID.$CFGNAME.pid");
	&ld_exit(0, "Linux Director Daemon terminated on signal: $DAEMON_TERM");
}

sub ld_handler_hup
{
	$DAEMON_HUP=1;
}

sub ld_process_hup
{
	&ld_log("Reloading Linux Director Daemon config on signal");
	$DAEMON_HUP = undef;
	&reread_config();
}

sub ld_handler_chld
{
	$DAEMON_CHLD=1;
	# NOTE: calling waitpid here would mess up $?
}

sub ld_process_chld
{
	my $i = 0;

	undef $DAEMON_CHLD;
	while (waitpid(-1, WNOHANG) > 0) {
		print "child: $i\n";
		$i++;
	}
}

sub check_signal
{
	if (defined $DAEMON_TERM) {
		ld_process_term();
	}
	if (defined $DAEMON_HUP) {
		ld_process_hup();
	}
	if (defined $DAEMON_CHLD) {
		ld_process_chld();
	}
}

sub reread_config
{
	@OLDVIRTUAL = @VIRTUAL;
	@VIRTUAL = ();
	my %OLD_INSTANCE = %LD_INSTANCE;
	my %RELOAD;
	my %STOP;
	my %START;
	my $child;
	$DAEMON_STATUS = $DAEMON_STATUS_RELOADING;
	eval {
		&read_config();

		foreach $child (keys %LD_INSTANCE) {
			if (defined $OLD_INSTANCE{$child}) {
				$RELOAD{$child} = 1;
			}
			else {
				$START{$child} = 1;
			}
		}

		foreach $child (keys %OLD_INSTANCE) {
			if (not defined $LD_INSTANCE{$child}) {
				$STOP{$child} = 1;
			}
		}

		&ld_cmd_children("stop", %STOP);
		&ld_cmd_children("reload_or_start", %RELOAD);
		&ld_cmd_children("start", %START);

		foreach my $vid (keys %FORK_CHILDREN) {
			&ld_log("Killing child $vid (PID=$FORK_CHILDREN{$vid})");
			kill 15, $FORK_CHILDREN{$vid};
		}

		&ld_setup();
		&ld_start();
	};
	if ($@) {
		@VIRTUAL = @OLDVIRTUAL;
		%LD_INSTANCE = %OLD_INSTANCE;
	}
	$DAEMON_STATUS = $DAEMON_STATUS_RUNNING;
	undef @OLDVIRTUAL;
}

sub parse_emailalertstatus
{
	my ($line, $arg) = (@_);

	my @s = split/\s*,\s*/, $arg;
	my $none = 0;
	my $status = 0;

	for my $i (@s) {
		if ($i eq "none") {
			$none++;
		}
	}

	for my $i (@s) {
		if ($i eq "none") {
			next;
		}
		elsif ($i eq "all") {
			$status = $DAEMON_STATUS_ALL;
		}
		elsif ($i eq "starting") {
			$status |= $DAEMON_STATUS_STARTING;
		}
		elsif ($i eq "stopping") {
			$status |= $DAEMON_STATUS_STOPPING;
		}
		elsif ($i eq "running") {
			$status |= $DAEMON_STATUS_RUNNING;
		}
		elsif ($i eq "reloading") {
			$status |= $DAEMON_STATUS_RELOADING;
		}
		else {
			&config_error($line,
				      "invalid email alert status at: \"$i\"")
		}
		if ($none > 0) {
			&config_error($line, "invalid email alert status: " .
				      "\"$i\" specified with \"none\"");
		}
	}
	return $status;
}

sub set_defaults
{
	$AUTOCHECK        = "no";
	$CALLBACK         = undef;
	$CHECKCOUNT       = 1;
	$CHECKINTERVAL    = 10;
	$CHECKTIMEOUT     = -1;
	$CLEANSTOP	  = "yes";
	$DEFAULT_CHECKTIMEOUT     = 5;
	$DEFAULT_NEGOTIATETIMEOUT = 30;
	$EMAILALERT	  = "";
	$EMAILALERTFREQ	  = 0;
	$EMAILALERTFROM   = undef;
	$EMAILALERTSTATUS = $DAEMON_STATUS_ALL;
	$FAILURECOUNT     = 1;
	$FALLBACK         = undef;
	$FALLBACK6        = undef;
	$FALLBACKCOMMAND  = undef;
	$FORKING          = "no";
	$LDIRLOG          = "/var/log/nsdirectord.log";
	$MAINTDIR         = undef;
	$NEGOTIATETIMEOUT = -1;
	$QUIESCENT        = "no";
	$SUPERVISED       = "no";
	$SMTP             = undef;
}

sub read_emailalert
{
	my ($line, $addr) = (@_);

	# Strip of enclosing quotes
	$addr =~ s/^\"([^"]*)\"$/$1/;

	$addr =~ /(.+)/ or &config_error($line, "no email address specified");

	return $addr;
}

sub read_config
{
	undef @VIRTUAL;
	undef @REAL;
	undef $CALLBACK;
	undef %LD_INSTANCE;
	undef $checksum;
	# Reset/set global config variables to defaults before parsing the config file.
	set_defaults();
	$stattime = 0;
	my %virtual_seen;
	open(CFGFILE, "<$CONFIG") or
		&config_error(0, "can not open file $CONFIG");
	my $line = 0;
	my $linedata;
	while(<CFGFILE>) {
		$line++;
		$linedata = $_;
		outer_loop:
		if ($linedata =~ /^virtual(6)?\s*=\s*(.*)/) {
			my $af = defined($1) ? AF_INET6 : AF_INET;
			my $vattr = $2;
			my $ip_port = undef;
			my $fwm = undef;
			my $virtual_id;
			my $virtual_line = $line;
			my $virtual_port;
			my $fallback_line;
			my @rsrv_todo;
			if ($vattr =~ /^(\d+\.\d+\.\d+\.\d+):([0-9A-Za-z-_]+)/ && $af == AF_INET) {
				$virtual_id = $ip_port = "$1:$2";
				$virtual_port = $2;
			} elsif ($vattr =~ /^([0-9A-Za-z._+-]+):([0-9A-Za-z-_]+)/) {
				$virtual_id = $ip_port = "$1:$2";
				$virtual_port = $2;
			} elsif ($vattr =~ /^(\d+)/){
				$virtual_id = $fwm = $1;
			} elsif ($vattr =~ /^\[([0-9A-Fa-f:]+)\]:([0-9A-Za-z-_]+)/ && $af == AF_INET) {
				&config_error($line, "cannot specify an IPv6 address here. please use \"virtual6\" instead.");
			} elsif ($vattr =~ /^\[([0-9A-Fa-f:]+)\]:([0-9A-Za-z-_]+)/ && $af == AF_INET6) {
				my $v6addr = $1;
				my $v6port = $2;
				if (!inet_pton(AF_INET6,$v6addr)) {
					&config_error($line,"invalid ipv6 address for virtual server");
				}
				$virtual_id = $ip_port = "[$v6addr]:$v6port";
				$virtual_port = $v6port;
			} else {
				&config_error($line,
					"invalid address for virtual server");
			}

			my (%vsrv, @rsrv);
			if ($ip_port) {
				$vsrv{checktype} = "negotiate";
				$vsrv{protocol} = "tcp";
				if ($ip_port =~ /:(53|domain)$/) {
					$vsrv{protocol} = "udp";
				}
				$vsrv{port} = $virtual_port;
			} else {
				$vsrv{fwm} = $fwm;
				$vsrv{checktype} = "negotiate";
				$vsrv{protocol} = "fwm";
				$vsrv{service} = "none";
				$vsrv{port} = "0";
			}
			$vsrv{addressfamily} = $af;
			$vsrv{real} = \@rsrv;
			$vsrv{scheduler} = "wrr";
			$vsrv{ttl} = 180;
			$vsrv{checkcommand} = "/bin/true";
			$vsrv{request} = "/";
			$vsrv{receive} = "";
			$vsrv{login} = "";
			$vsrv{passwd} = "";
			$vsrv{database} = "";
			$vsrv{checktimeout} = -1;
			$vsrv{checkcount} = -1;
			$vsrv{negotiatetimeout} = -1;
			$vsrv{failurecount} = -1;
			$vsrv{num_connects} = 0;
			$vsrv{httpmethod} = "GET";
			$vsrv{secret} = "";
			push(@VIRTUAL, \%vsrv);
			while(<CFGFILE>) {
				$line++;
				$linedata=$_;
				if(m/^\s*#/) {
					next;
				}
				s/#.*//;
				s/\t/    /g;
				unless (/^ {4,}(.+)/) {
					last;
				}
				my $rcmd = $1;
				if ($rcmd =~ /^(real(6)?)\s*=\s*(.*)/) {
					if ($af == AF_INET  &&   defined($2) ||
					    $af == AF_INET6 && ! defined($2)) {
					    &config_error($line, join("", ("cannot specify \"$1\" here.  please use \"real", ($af == AF_INET) ?  "" : "6", "\" instead")));
					}
					push @rsrv_todo, [$3, $line];
				} elsif ($rcmd =~ /^request\s*=\s*\"(.*)\"/) {
					$1 =~ /(.+)/ or &config_error($line, "no request string specified");
					$vsrv{request} = $1;
					unless($vsrv{request}=~/^\//){
						$vsrv{request} = "/" . $vsrv{request};
					}

				} elsif ($rcmd =~ /^receive\s*=\s*\"(.*)\"/) {
					$1 =~ /(.+)/ or &config_error($line, "invalid receive string");
					$vsrv{receive} = $1;
				} elsif ($rcmd =~ /^checktype\s*=\s*(.*)/){
					if ($1 =~ /(\d+)/ && $1>=0) {
						$vsrv{num_connects} = $1;
						$vsrv{checktype} = "combined";
					} elsif ( $1 =~ /([\w-]+)/ && ($1 eq "connect" || $1 eq "negotiate" || $1 eq "ping" || $1 eq "off" || $1 eq "on" || $1 eq "external" || $1 eq "external-perl") ) {
						$vsrv{checktype} = $1;
					} else {
						&config_error($line, "checktype must be \"connect\", \"negotiate\", \"on\", \"off\", \"ping\", \"external\", \"external-perl\" or a positive number");
					}
				} elsif ($rcmd =~ /^checkcommand\s*=\s*\"(.*)\"/ or $rcmd =~ /^checkcommand\s*=\s*(.*)/){
					$1 =~ /(.+)/ or &config_error($line, "invalid check command");
					$vsrv{checkcommand} = $1;
				} elsif ($rcmd =~ /^checktimeout\s*=\s*(.*)/){
					$1 =~ /(\d+)/ && $1 or &config_error($line, "invalid check timeout");
					$vsrv{checktimeout} = $1;
				} elsif ($rcmd =~ /^connecttimeout\s*=\s*(.*)/){
					&config_error($line,
						"connecttimeout directive " .
						"deprecated in favour of " .
						"negotiatetimeout");
				} elsif ($rcmd =~ /^negotiatetimeout\s*=\s*(.*)/){
					$1 =~ /(\d+)/ && $1 or &config_error($line, "invalid negotiate timeout");
					$vsrv{negotiatetimeout} = $1;
				} elsif ($rcmd =~ /^checkcount\s*=\s*(.*)/){
					$1 =~ /(\d+)/ && $1 or &config_error($line, "invalid check count");
					$vsrv{checkcount} = $1;
					&config_warn($line, "checkcount option is deprecated and slated for removal.  please see 'failurecount'");
				} elsif ($rcmd =~ /^failurecount\s*=\s*(.*)/){
					$1 =~ /(\d+)/ && $1 or &config_error($line, "invalid failure count");
					$vsrv{failurecount} = $1;
				} elsif ($rcmd =~ /^checkinterval\s*=\s*(.*)/){
					$1 =~ /(\d+)/ && $1 or &config_error($line, "invalid checkinterval");
					$vsrv{checkinterval} = $1
				} elsif ($rcmd =~ /^checkport\s*=\s*(.*)/){
					$1 =~ /(\d+)/ or &config_error($line, "invalid port");
					( $1 > 0 && $1 < 65536 ) or &config_error($line, "checkport must be in range 1..65536");
					$vsrv{checkport} = $1;
				} elsif ($rcmd =~ /^login\s*=\s*\"(.*)\"/) {
					$1 =~ /(.+)/ or &config_error($line, "invalid login string");
					$vsrv{login} = $1;
				} elsif ($rcmd =~ /^passwd\s*=\s*\"(.*)\"/) {
					$1 =~ /(.+)/ or &config_error($line, "invalid password");
					$vsrv{passwd} = $1;
				} elsif ($rcmd =~ /^database\s*=\s*\"(.*)\"/) {
					$1 =~ /(.+)/ or &config_error($line, "invalid database");
					$vsrv{database} = $1;
				} elsif ($rcmd =~ /^secret\s*=\s*\"(.*)\"/) {
					$1 =~ /(.+)/ or &config_error($line, "invalid secret");
					$vsrv{secret} = $1;
				} elsif ($rcmd =~ /^load\s*=\s*\"(.*)\"/) {
					$1 =~ /(\w+)/ or &config_error($line, "invalid string for load testing");
					$vsrv{load} = $1;
				} elsif ($rcmd =~ /^scheduler\s*=\s*(.*)/) {
					# Intentionally ommit checking the
					# scheduler against a list of know
					# schedulers. This is because from
					# time to time new schedulers are
					# added. But nsdirectord is
					# maintained distributed
					# independently of this. Thus
					# nsdirectord needs to be manually
					# updated/upgraded.  So just accept
					# any scheduler that matches
					# [a-z]+. I.e. is syntactically
					# correct (all schedulers so far
					# match that pattern). Ipvsadm will
					# report an error is a scheduler
					# isn't available / doesn't exist.
					$1 =~ /([a-z]+)/
					    or &config_error($line, "invalid scheduler, should be only lowercase letters (a-z)");
					$vsrv{scheduler} = $1;
				} elsif ($rcmd =~ /^persistent\s*=\s*(.*)/) {
					$1 =~ /(\d+)/ or &config_error($line, "invalid persistent timeout");
					$vsrv{persistent} = $1;
				} elsif ($rcmd =~ /^netmask\s*=\s*(.*)/) {
					$1 =~ /(\d+\.\d+\.\d+\.\d+)/ or &config_error($line, "invalid netmask");
					$vsrv{netmask} = $1;
				} elsif ($rcmd =~ /^ttl\s*=\s*(.*)/) {
					$1 =~ /(\d+)/ or &config_error($line, "invalid domain ttl");
					$vsrv{ttl} = $1;
				} elsif ($rcmd =~ /^backets\s*=\s*(.*)/) {
					my $l_backets = parse_backets_str($1);
					$l_backets or &config_error($line, "invalid domain backets formats or emty");
					$vsrv{backets} = $l_backets;
				} elsif ($rcmd =~ /^protocol\s*=\s*(.*)/) {
					if ( $1 =~ /(\w+)/ ) {
						if ( $vsrv{protocol} eq "fwm" ) {
							if ($1 eq "fwm" ) {
								; #Do nothing, it is already set
							} else {
								&config_error($line, "protocol must be fwm if the virtual service is a fwmark (a number)");
							}
						} else {    # tcp or udp
							if ($1 eq "tcp" || $1 eq "udp") {
								$vsrv{protocol} = $1;
							} else {
								&config_error($line, "protocol must be tcp or udp if the virtual service is an address and port");
							}
						}
					} else {
						&config_error($line, "invalid protocol");
					}
				} elsif ($rcmd =~ /^service\s*=\s*(.*)/) {
					$1 =~ /(\w+)/ && ($1 eq "dns"	||
							  $1 eq "ftp"	||
							  $1 eq "http"	||
							  $1 eq "https"	||
							  $1 eq "http_proxy"	||
							  $1 eq "imap"	||
							  $1 eq "imaps"	||
							  $1 eq "ldap"	||
							  $1 eq "nntp"	||
							  $1 eq "mysql"	||
							  $1 eq "none"	||
							  $1 eq "oracle"||
							  $1 eq "pop"	||
							  $1 eq "pops"	||
							  $1 eq "radius"||
							  $1 eq "pgsql"	||
							  $1 eq "sip"	||
							  $1 eq "smtp"	||
							  $1 eq "submission"	||
							  $1 eq "simpletcp")
					    or &config_error($line,
							     "service must " .
							     "be dns, ftp, " .
							     "http, https, " .
							     "http_proxy, " .
							     "imap, imaps, " .
							     "ldap, nntp, "  .
							     "mysql, none, " .
							     "oracle, "      .
							     "pop, pops, "   .
							     "radius, "      .
							     "pgsql, "       .
							     "simpletcp, "   .
							     "sip, smtp "    .
							     "or submission");
					$vsrv{service} = $1;
					if($vsrv{service} eq "ftp" and
							$vsrv{login} eq "") {
						$vsrv{login} = "anonymous";
					}
					elsif($vsrv{service} eq "sip" and
							$vsrv{login} eq "") {
						$vsrv{login} = "nsdirectord\@$HOSTNAME";
					}
					if($vsrv{service} eq "ftp" and
							$vsrv{passwd} eq "") {
						$vsrv{passwd} = "nsdirectord\@$HOSTNAME";
					}
				} elsif ($rcmd =~ /^httpmethod\s*=\s*(.*)/) {
					$1 =~ /(\w+)/ && (uc($1) eq "GET" || uc($1) eq "HEAD")
					    or &config_error($line, "httpmethod must be GET or HEAD");
					$vsrv{httpmethod} = uc($1);
				} elsif ($rcmd =~ /^virtualhost\s*=\s*(.*)/) {
					$1 =~ /\"?([^\"]*)\"?/ or
					&config_error($line, "invalid virtualhost");
					$vsrv{virtualhost} = $1;
				} elsif ($rcmd =~ /^(fallback(6)?)\s*=\s*(.*)/) {    # Allow specification of a virtual-specific fallback host
					if ($af == AF_INET  &&   defined($2) ||
					    $af == AF_INET6 && ! defined($2)) {
					    &config_error($line, join("", ("cannot specify \"$1\" here.  please use \"fallback", ($af == AF_INET) ?  "" : "6", "\" instead")));
					}
					$fallback_line=$line;
					$vsrv{fallback} =
						parse_fallback($line, $3,
							       \%vsrv);
				} elsif ($rcmd =~
				/^fallbackcommand\s*=\s*\"(.*)\"/ or $rcmd =~ /^fallbackcommand\s*=\s*(.*)/) {
					$1 =~ /(.+)/ or &config_error($line, "invalid fallback command");
					$vsrv{fallbackcommand} = $1;
				} elsif ($rcmd =~ /^quiescent\s*=\s*(.*)/) {
					($1 eq "yes" || $1 eq "no")
						or &config_error($line, "quiescent must be 'yes' or 'no'");
					$vsrv{quiescent} = $1;
				} elsif  ($rcmd =~ /^emailalert\s*=\s*(.*)/) {
					$vsrv{emailalert} =
						read_emailalert($line, $1);
				} elsif  ($rcmd =~ /^emailalertfreq\s*=\s*(\d*)/) {
					$1 =~ /(\d+)/ or &config_error($line, "invalid email alert frequency");
					$vsrv{emailalertfreq} = $1;
				} elsif  ($rcmd =~ /^emailalertstatus\s*=\s*(.*)/) {
					$vsrv{emailalertstatus} = &parse_emailalertstatus($line, $1);
				} elsif  ($rcmd =~ /^monitorfile\s*=\s*\"(.*)\"/ or
					  $rcmd =~ /^monitorfile\s*=\s*(.*)/) {
					my $monitorfile = $1;
					unless (open(MONITORFILE, ">>$monitorfile") and close(MONITORFILE)) {
						&config_error($line, "unable to open monitorfile $monitorfile: $!");
					}
					$vsrv{monitorfile} = $monitorfile;
				} elsif  ($rcmd =~ /^cleanstop\s*=\s*(.*)/) {
					($1 eq "yes" || $1 eq "no")
						or &config_error($line, "cleanstop must be 'yes' or 'no'");
					$vsrv{cleanstop} = $1;
				} elsif  ($rcmd =~ /^smtp\s*=\s*(.*)/) {
					$1 =~ /(^([0-9A-Za-z._+-]+))/ or &config_error($line, "invalid SMTP server address");
					$vsrv{smtp} = $1;
				} else {
					&config_error($line, "Unknown command \"$linedata\"");
				}
				undef $linedata;
			}
			# As the protocol needs to be known to call
			# getservbyname() all resolution must be
			# delayed until the protocol is finalised.
			# That is after the entire configuration
			# for a virtual service has been parsed.

			&_ld_read_config_fallback_resolve($fallback_line,
				$vsrv{protocol}, $vsrv{fallback}, $af);
			&_ld_read_config_virtual_resolve($virtual_line, \%vsrv,
				$ip_port, $af);
			&_ld_read_config_real_resolve(\%vsrv, \@rsrv_todo, $af);

			# Check for duplicate now we have all the
			# information to generate the id
			$virtual_id = get_virtual_id_str(\%vsrv);
			if (defined $virtual_seen{$virtual_id}) {
				&config_error($line,
					"duplicate virtual server");
			}
			$virtual_seen{$virtual_id} = 1;

			unless(defined($linedata)) {
				last;
			}
			#Arggh a goto :(
			goto outer_loop;
		}
		next if ($linedata =~ /^\s*$/ || $linedata =~ /^\s*#/);
		if ($linedata  =~ /^checktimeout\s*=\s*(.*)/) {
			($1 =~ /(\d+)/ && $1 && $1>0) or &config_error($line,
					"invalid check timeout value");
			$CHECKTIMEOUT = $1;
		} elsif ($linedata  =~ /^connecttimeout\s*=\s*(.*)/) {
			&config_error($line,
					"connecttimeout directive " .
					"deprecated in favour of " .
					"negotiatetimeout");
		} elsif ($linedata  =~ /^negotiatetimeout\s*=\s*(.*)/) {
			($1 =~ /(\d+)/ && $1 && $1>0) or &config_error($line,
					"invalid negotiate timeout value");
			$NEGOTIATETIMEOUT = $1;
		} elsif ($linedata  =~ /^checkinterval\s*=\s*(.*)/) {
			$1 =~ /(\d+)/ && $1 or &config_error($line,
					"invalid check interval value");
			$CHECKINTERVAL = $1;
		} elsif ($linedata  =~ /^checkcount\s*=\s*(.*)/) {
			$1 =~ /(\d+)/ && $1 or &config_error($line,
					"invalid check count value");
			$CHECKCOUNT = $1;
			&config_warn($line, "checkcount option is deprecated and slated for removal.  please see 'failurecount'");
		} elsif ($linedata  =~ /^failurecount\s*=\s*(.*)/) {
			$1 =~ /(\d+)/ && $1 or &config_error($line,
					"invalid failure count value");
			$FAILURECOUNT = $1;
		} elsif ($linedata  =~ /^fallback(6)?\s*=\s*(.*)/) {
			my $af = defined($1) ? AF_INET6 : AF_INET;
			my $tcp = parse_fallback($line, $2, undef);
			my $udp = parse_fallback($line, $2, undef);
			&_ld_read_config_fallback_resolve($line, "tcp", $tcp, $af);
			&_ld_read_config_fallback_resolve($line, "udp", $udp, $af);
			if ($af == AF_INET) {
				$FALLBACK = { "tcp" => $tcp, "udp" => $udp };
			} else {
				$FALLBACK6 = { "tcp" => $tcp, "udp" => $udp };
			}
		} elsif ($linedata =~ /^fallbackcommand\s*=\s*(.*)/) {
			$1 =~ /(.+)/ or &config_error($line, "invalid fallback command");
			$FALLBACKCOMMAND = $1;
		} elsif ($linedata  =~ /^autoreload\s*=\s*(.*)/) {
			($1 eq "yes" || $1 eq "no")
			    or &config_error($line,
					"autoreload must be 'yes' or 'no'");
			$AUTOCHECK = $1;
		} elsif ($linedata  =~ /^callback\s*=\s*\"(.*)\"/) {
			$CALLBACK = $1;
		} elsif ($linedata  =~ /^logfile\s*=\s*\"(.*)\"/) {
			my $tmpLDIRLOG = $LDIRLOG;
			$LDIRLOG = $1;
			if (&ld_openlog()) {
				$LDIRLOG = $tmpLDIRLOG;
				&config_error($line,
						"unable to open logfile: $1");
			}
		} elsif ($linedata  =~ /^execute\s*=\s*(.*)/) {
			$LD_INSTANCE{$1} = 1;
		} elsif ($linedata  =~ /^fork\s*=\s*(.*)/) {
			($1 eq "yes" || $1 eq "no")
			    or &config_error($line, "fork must be 'yes' or 'no'");
			$FORKING = $1;
		} elsif ($linedata  =~ /^supervised/) {
			if (($linedata  =~ /^supervised\s*=\s*(.*)/) and
			    ($1 eq "yes" || $1 eq "no")) {
				$SUPERVISED = $1;
			}
			elsif ($linedata  =~ /^supervised\s*$/) {
				$SUPERVISED = "yes";
				&config_warn($line,
					"please update your config not to " .
					"use a bare supervised directive");
			}
			else {
				&config_error($line,
					"supervised must be 'yes' or 'no'");
			}
		} elsif ($linedata  =~ /^quiescent\s*=\s*(.*)/) {
			($1 eq "yes" || $1 eq "no")
			    or &config_error($line,
					"quiescent must be 'yes' or 'no'");
			$QUIESCENT = $1;
		} elsif  ($linedata  =~ /^emailalert\s*=\s*(.*)/) {
			$EMAILALERT = read_emailalert($line, $1);
		} elsif  ($linedata  =~ /^emailalertfreq\s*=\s*(\d*)/) {
			$1 =~ /(\d+)/ or &config_error($line,
					"invalid email alert frequency");
			$EMAILALERTFREQ = $1;
		} elsif  ($linedata  =~ /^emailalertstatus\s*=\s*(.*)/) {
			$EMAILALERTSTATUS = &parse_emailalertstatus($line, $1);
		} elsif  ($linedata  =~ /^emailalertfrom\s*=\s*(.*)/) {
			$1 =~ /(.+)/ or &config_error($line,
					"no email from address specified");
			$EMAILALERTFROM = $1;
		} elsif  ($linedata  =~ /^cleanstop\s*=\s*(.*)/) {
			($1 eq "yes" || $1 eq "no")
			    or &config_error($line, "cleanstop must be 'yes' or 'no'");
			$CLEANSTOP = $1;
		} elsif  ($linedata  =~ /^smtp\s*=\s*(.*)/) {
			$1 =~ /(^([0-9A-Za-z._+-]+))/ or &config_error($line,
					"invalid SMTP server address");
			$SMTP = $1;
		} elsif  ($linedata  =~ /^maintenancedir\s*=\s*(.*)/) {
			$1 =~ /(.+)/ or &config_error($line,
					"maintenance directory not specified");
			$MAINTDIR = $1;
			-d $MAINTDIR or &config_warn($line,
					"maintenance directory does not exist");
		} elsif  ($linedata  =~ /^controlpoint\s*=\s*(.*)/) {
			$1 =~ /(.+)/ or &config_error($line,
					"controlpoint not specified");
			$CONTROLPOINT = $1;
		} else {
			if ($linedata  =~ /^timeout\s*=\s*(.*)/) {
				&config_error($line,
						"timeout directive " .
						"deprecated in favour of " .
						"checktimeout and " .
						"negotiatetimeout");
			}
			&config_error($line, "Unknown command $linedata ");
		}
	}
	close(CFGFILE);

	# Check for sensible use of checkinterval, warn if it is used in a virtual
	# service when fork=no
	if ($FORKING eq 'no') {
		foreach my $v (@VIRTUAL) {
			if (defined($$v{checkinterval})) {
				config_warn(-1, "checkinterval in virtual service ".
					get_virtual_id_str($v)." ignored when fork=no");
			}
		}
	}

	return(0);
}

# _ld_read_config_virtual_resolve
# Note: Should not need to be called directly, but won't do any damage if
#       you do.
# Resolve the server (ip address) and port for a virtual service
# pre: line: Line of configuration file fallback server was read from
#            Used for debugging messages
#      vsrv: Virtual Service to resolve server and port of
#      ip_port: server and port in the form
#               ip_address|hostname:port|service
#      af: Address family: AF_INET or AF_INET6
# post: Take ip_port, resolve it as per ld_gethostservbyname
#       and set $vsrv->{server} and $vsrv->{port} accordingly.
#       If $vsrv->{service} is not set, then set according to the value of
#       $vsrv->{port}
# return: none
#        Debugging message will be reported and programme will exit
#        on error.
sub _ld_read_config_virtual_resolve
{
	my($line, $vsrv, $ip_port, $af)=(@_);

	if($ip_port){
		$ip_port=&ld_gethostservbyname($ip_port, $vsrv->{protocol}, $af);
		if ($ip_port =~ /(\[[0-9A-Fa-f:]+\]):(\d+)/) {
			$vsrv->{server} = $1;
			$vsrv->{port} = $2;
		} elsif($ip_port){
			($vsrv->{server}, $vsrv->{port}) = split /:/, $ip_port;
		}
		else {
			&config_error($line,
				"invalid address for virtual service");
		}

		if(!defined($vsrv->{service})){
			$vsrv->{service} = ld_port_to_service($vsrv->{port});
		}
	}
}

# ld_service_to_port
# Resolve an nsdirectord service name from its port number
# pre: port: port number of the service
# return: port name
#         "none" if the service is unknown
sub ld_port_to_service
{
	my ($port) = (@_);

	if ($port eq 21)	{ return "ftp"; }
	if ($port eq 25)	{ return "smtp"; }
	if ($port eq 53)	{ return "dns"; }
	if ($port eq 80)	{ return "http"; }
	if ($port eq 110)	{ return "pop"; }
	if ($port eq 119)	{ return "nntp"; }
	if ($port eq 143)	{ return "imap"; }
	if ($port eq 389)	{ return "ldap"; }
	if ($port eq 443)	{ return "https"; }
	if ($port eq 587)	{ return "submission"; }
	if ($port eq 995)	{ return "pops"; }
	if ($port eq 993)	{ return "imaps"; }
	if ($port eq 1521)	{ return "oracle"; }
	if ($port eq 1812)	{ return "radius"; }
	if ($port eq 3128)	{ return "http_proxy"; }
	if ($port eq 3306)	{ return "mysql"; }
	if ($port eq 5060)	{ return "sip"; }
	if ($port eq 5432)	{ return "pgsql"; }

	return "none";
}

# ld_service_to_port
# Resolve the port number from an nsdirectord service name
# pre: service: name of the service
# return: port number
#         undef if the service is unknown
sub ld_service_to_port
{
	my ($service) = (@_);

	if ($service eq "ftp")		{ return 21; }
	if ($service eq "smtp")		{ return 25; }
	if ($service eq "dns")		{ return 53; }
	if ($service eq "http")		{ return 80; }
	if ($service eq "pop")		{ return 110; }
	if ($service eq "nntp")		{ return 119; }
	if ($service eq "imap")		{ return 143; }
	if ($service eq "ldap")		{ return 389; }
	if ($service eq "https")	{ return 443; }
	if ($service eq "submission")	{ return 587; }
	if ($service eq "imaps")	{ return 993; }
	if ($service eq "pops")		{ return 995; }
	if ($service eq "oracle")	{ return 1521; }
	if ($service eq "radius")	{ return 1812; }
	if ($service eq "http_proxy")	{ return 3128; }
	if ($service eq "mysql")	{ return 3306; }
	if ($service eq "sip")		{ return 5060; }
	if ($service eq "pgsql")	{ return 5432; }

	return undef;
}

# ld_checkport
# Resolve the port to connect to for service checks
# Note: Should only be used inside service checks,
#       as its not the same as the port of the real server
# pre: v: virtual service
#      r: real server
# return: port number
#         undef if the service is unknown
sub ld_checkport
{
	my ($v, $r) = (@_);

	if (defined $v->{checkport}) {
		return $v->{checkport};
	}
	if ($r->{port} > 0) {
		return $r->{port};
	}

	return ld_service_to_port($v->{service});
}

# _ld_read_config_fallback_resolve
# Note: Should not need to be called directly, but won't do any damage if
#       you do.
# Resolve the fallback server for a virtual service
# pre: line: Line of configuration file fallback server was read from
#            Used for debugging messages
#      vsrv: Virtual Service to resolve fallback server of
#      af: Address family: AF_INET or AF_INET6
# post: Take $vsrv->{fallback}, resolve it as per ld_gethostservbyname
#       and set $vsrv->{fallback} to the result
# return: none
#	Debugging message will be reported and programme will exit
#	on error.
sub _ld_read_config_fallback_resolve
{
	my($line, $protocol, $fallback, $af)=(@_);

	my ($ipversion, $ipaddress);

	unless($fallback) {
		return;
	}
	if ($af == AF_INET) {
	 	$ipversion = "IPv4";
	}
	elsif ($af == AF_INET6) {
	 	$ipversion = "IPv6";
	}
	else {
	 	$ipversion = "IP??($af)";
	}
	unless ($ipaddress = &ld_gethostbyname($fallback->{server}, $af)) {
		&config_error($line, "invalid $ipversion address or could not resolve for fallback server: " .
			      $fallback->{server});
	}
	$fallback->{server} = $ipaddress;

	unless($fallback->{"port"}) {
		return;
	}

	$fallback->{port} = &ld_getservbyname($fallback->{port}, $protocol) or
		&config_error($line, "invalid port for fallback server");
}

# _ld_read_config_real_resolve
# Note: Should not need to be called directly, but won't do any damage if
#       you do.
# Run through the list of real servers read in the configuration file for a
# virtual server and parse these entries
# pre: vsrv: Virtual Service to parse real servers for
#      rsrv_todo: List of real servers read from config but not parsed.
#                 List is a list of list reference. The first element in
#                 each list reference is the line read from the
#                 configuration after "real=". The second element is the
#                 line number, used for error reporting
#      af: Address family: AF_INET or AF_INET6
# post: Run through rsrv_todo and parse real servers
# return: none
#	Debugging message will be reported and programme will exit
#	on error.
sub _ld_read_config_real_resolve
{
	my ($vsrv, $rsrv_todo, $af)=(@_);

	my $i;
	my $str;
	my $line;
	my $ip1;
	my $ip2;
	my $port;
	my $resolved_ip1;
	my $resolved_ip2;
	my $resolved_port;
	my $flags;

	for $i (@$rsrv_todo) {
		($str, $line)=@$i;
		$str =~	 /(\d+\.\d+\.\d+\.\d+|[A-Za-z0-9.-]+|\[[0-9A-fa-f:]+\])(->(\d+\.\d+\.\d+\.\d+|[A-Za-z0-9.-]+|\[[0-9A-fa-f:]+\]))?(:(\d+|[A-Za-z0-9-_]+))?(\s+(.*))?/
			or &config_error($line,
				"invalid address for real server" .
				" (wrong format)");

		$ip1=$1;
		$ip2=$3;
		$port=defined($5)?$5:"0";
		$flags=$6;
		$resolved_ip1=&ld_gethostbyname($ip1, $af);

		unless( defined($resolved_ip1) ) {
			&config_error($line,
				"invalid address ($ip1) for real server" .
				" (could not resolve host)");
		}

		if( defined($port) ){
			$resolved_port=&ld_getservbyname($port);
			unless( defined($resolved_port) ){
				&config_error($line,
					"invalid port ($port) for real server" .
					" (could not resolve port)");
			}
		}

		if ( defined ($ip2) ) {
			$resolved_ip2=&ld_gethostbyname($ip2, $af);
			unless( defined ($resolved_ip2) ) {
				&config_error($line,
					"invalid address ($ip2) for " .
					"real server" .
					" (could not resolve end host)");
			}
			&add_real_server_range($line, $vsrv, $resolved_ip1,
				$resolved_ip2, $resolved_port, $flags, $af);
		} else {
			&add_real_server($line, $vsrv, $resolved_ip1,
				$resolved_port, $flags);
		}
	}
}

# add_real_server_range
# Add a real server for each IP address in a range
# pre: line: line number real server was read from
#            Used for debugging information
#      vsrv: virtual server to add real server to
#      first: First IP address in range
#      last: First IP address in range
#      port: Port of real servers
#      flags: Flags for real servers. Should be of the form
#             gate|masq|ipip [<weight>] [">I<request>", "<receive>"]
#      af: Address family: AF_INET or AF_INET6
# post: real servers are added to virtual server
# return: none
#         Debugging message will be reported and programme will exit
#         on error.
sub add_real_server_range
{
	my ($line, $vsrv, $first, $last, $port, $flags, $af) = (@_);

	my (@tmp, $first_i, $last_i, $i, $rsrv);

	if ($af == AF_INET) {
		if ( ($first_i=&ip_to_int($first)) <0 ) {
			&config_error($line, "Invalid IP address: $first");
		}
		if ( ($last_i=&ip_to_int($last)) <0 ) {
			&config_error($line, "Invalid IP address: $last");
		}

		if ($first_i>$last_i) {
			&config_error($line,
				"Invalid Range: $first-$last: First value must be " .
				"greater than or equal to the second value");
		}

		# A for loop didn't seem to want to work
		$i=$first_i;
		while ( $i le $last_i ) {
			&add_real_server($line, $vsrv, &int_to_ip($i), $port, $flags);
			$i++;
		}
	}
	elsif ($af == AF_INET6) {
		# not supported yet
		&config_error($line, "Address range for IPv6 is not supported yet");
	}
	else {
		die "address family must be AF_INET or AF_INET6\n";
	}
}

# add_real_server
# Add a real server to a virtual
# pre: line: line number real server was read from
#            Used for debugging information
#      vsrv: virtual server to add real server to
#      ip: IP address of real server
#      port: Port of real server
#      flags: Flags for real server. Should be of the form
#             gate|masq|ipip [<weight>] [">I<request>", "<receive>"]
# post: real server is added to virtual server
# return: none
#         Debugging message will be reported and programme will exit
#         on error.
sub add_real_server
{
	my ($line, $vsrv, $ip, $port, $flags) = (@_);

	my $ref;
	my $realsrv=0;
	my $new_rsrv;
	my $rsrv;

	$new_rsrv = {"server" => $ip, "port" => $port, "forward" => ""};
	$rsrv=$vsrv->{"real"};

	if(defined($flags) and $flags =~ /\s+(\d+)(.*)/) {
		$new_rsrv->{"weight"} = $1;
		$flags = $2;
	}
	else {
		$new_rsrv->{"weight"} = 1;
	};

	if(defined($flags) and $flags =~ /\s+\"(.*)\"[, ]\s*\"(.*)\"(.*)/) {
		$new_rsrv->{"request"} = $1;
		unless ($new_rsrv->{request}=~/^\//) {
			$new_rsrv->{request} = "/" . $new_rsrv->{request};
		}
		$new_rsrv->{"receive"} = $2;
		$flags = $3;
	};

 	if(defined($flags) and $flags =~ /\s+(\S+)(.*)/) {
 		$new_rsrv->{"backet"} = uc($1);
 		$flags = $2;
	};
	
	if (exists($vsrv->{backets}))
	{
		if(!exists($new_rsrv->{"backet"}))
		{
			&config_error($line, "Real server doesn't belogn to any backets in backet config param");
		}
		elsif(!exists($vsrv->{backets}->{$new_rsrv->{"backet"}}))
		{
			&config_error($line, "Real server belong to not existent backet");
		};
	};

	if (defined($flags) and $flags =~/\S/) {
		&config_error($line, "Invalid real server line, around "
			. "\"$flags\"");
	}

	push(@$rsrv, $new_rsrv);

	my $real    = get_real_id_str($new_rsrv, $vsrv);
	my $virtual = get_virtual_id_str($vsrv);
	for my $r (@REAL){
		if($r->{"real"} eq $real){
			my $ref=$r->{"virtual"};
			push(@$ref, $virtual);
			$realsrv=1;
			last;
		}
	}
	if($realsrv==0){
		push(@REAL, { "real"=>$real, "virtual"=>[ $virtual ] });
	}
}

# parse_fallback
# Parse a fallback server
# pre: line: line number real server was read from
#      fallback: line read from configuration file
#                Should be of the form
#                ip_address|hostname[:port|:service_name] [gate|masq|ipip]
# post: fallback is parsed
# return: Reference to hash of the form
#         { server => blah, forward => blah }
#         Debugging message will be reported and programme will exit
#         on error.
sub parse_fallback
{
	my ($line, $fallback, $vsrv) = (@_);

	my $parse_line;
	my $server;
	my $port;
	my $fwd;

	$parse_line = $fallback;
	if ($parse_line =~ /(\S+)(\s+(\S+))?\s*$/) {
		# get "ip:port" and a forwarding method
		$fwd = $3;
		$parse_line = $1;
	}
	if ($parse_line =~ /(:(\d+|[A-Za-z0-9-_]+))?$/) {
		# get host and port
		$port=$2;
		
		$parse_line =~ s/(:(\d+|[A-Za-z0-9-_]+))?$//;
		$server = $parse_line;
	}
	unless(defined($server)) {
		&config_error($line, "invalid fallback server: $fallback");
	}

	if (not defined($port) and defined($vsrv)) {
		$port = $vsrv->{"port"};
	}

	if($fwd) {
		($fwd eq "gate" || $fwd eq "masq" || $fwd eq "ipip")
		or &config_error($line,
			"forward method must be gate, masq or ipip");
	}
	else {
		$fwd="gate"
	}

	return({"server"=>$server, "port"=>$port, "forward"=>$fwd,
		"weight"=>1});
}

sub __config_log
{
	my ($line, $prefix, $msg) = @_;

	chomp($msg);
	$msg .= "\n";

	my $msg_prefix = "$prefix [$$]";
	if ($line > 0) {
		$msg_prefix .= " reading file $CONFIG at line $line";
	}
	$msg = "$msg_prefix: $msg";

	if ($opt_d or $DAEMON_STATUS == $DAEMON_STATUS_STARTING) {
		print STDERR $msg;
	}
	else {
		&ld_log("$msg");
	}
}

sub config_warn
{
	my ($line, $msg) = @_;

	__config_log($line, "Warning", $msg);
}

sub config_error
{
	my ($line, $msg) = @_;

	__config_log($line, "Error", $msg);
	if ($DAEMON_STATUS == $DAEMON_STATUS_STARTING) {
		&ld_rm_file("$RUNPID.$CFGNAME.pid");
		&ld_exit(2, "config_error: Configuration Error");
	} else {
		die;
	}
}

sub ld_setup
{
	for my $v (@VIRTUAL) {
		if ($$v{protocol} eq "tcp") {
			$$v{proto} = "-t";
		} elsif ($$v{protocol} eq "udp") {
			$$v{proto} = "-u";
		} elsif ($$v{protocol} eq "fwm") {
			$$v{proto} = "-f";
		}
		$$v{flags} = "$$v{proto} " .  &get_virtual_option($v) . " ";
		$$v{flags} .= "-s $$v{scheduler} " if defined ($$v{scheduler});
		if (defined $$v{persistent}) {
			$$v{flags} .= "-p $$v{persistent} ";
			$$v{flags} .= "-M $$v{netmask} " if defined ($$v{netmask});
		}
		my $real = $$v{real};
		for my $r (@$real) {
			$$r{forw} = get_forward_flag($$r{forward});
			my $port=ld_checkport($v, $r);

			my $schema = $$v{service};
			if ($$v{service} eq 'http_proxy') {
				$schema = 'http';
			}

			if (defined $$r{request} && defined $$r{receive}) {
				my $uri = $$r{request};
				$uri =~ s/^\///g;
				if ($$r{request} =~ /$schema:\/\//) {
					$$r{url} = "$uri";
				} else {
					$$r{url} = "$schema:\/\/$$r{server}:$port\/$uri";
				}
			} else {
				my $uri = $$v{request};
				$uri =~ s/^\///g;

				if ($$v{service} eq 'http_proxy') {
					$$r{url} = "$uri";
				} else {
					$$r{url} = "$schema:\/\/$$r{server}:$port\/$uri";
				}

				$$r{request} = $$v{request} unless defined $$r{request};
				$$r{receive} = $$v{receive};
			}
			if ($$v{checktype} eq "combined") {
				$$r{num_connects} = 999999;
			} else {
				$$r{num_connects} = -1;
			}
		}

		# checktimeout and negotiate timeout are
		# mutual defaults for each other, so calculate
		# checktimeout in a temporary variable so as not
		# to affect the calculation of negotiatetimeout.

		my $checktimeout = $$v{checktimeout};
		if ($checktimeout < 0) {
			$checktimeout = $$v{negotiatetimeout};
		}
		if ($checktimeout < 0) {
			$checktimeout = $CHECKTIMEOUT;
		}
		if ($checktimeout < 0) {
			$checktimeout = $NEGOTIATETIMEOUT;
		}
		if ($checktimeout < 0) {
			$checktimeout = $DEFAULT_CHECKTIMEOUT;
		}

		if ($$v{negotiatetimeout} < 0) {
			$$v{negotiatetimeout} = $$v{checktimeout};
		}
		if ($$v{negotiatetimeout} < 0) {
			$$v{negotiatetimeout} = $NEGOTIATETIMEOUT;
		}
		if ($$v{negotiatetimeout} < 0) {
			$$v{negotiatetimeout} = $CHECKTIMEOUT;
		}
		if ($$v{negotiatetimeout} < 0) {
			$$v{negotiatetimeout} = $DEFAULT_NEGOTIATETIMEOUT;
		}

		$$v{checktimeout} = $checktimeout;

		if ($$v{checkcount} < 0) {
			$$v{checkcount} = $CHECKCOUNT;
		}

		if ($$v{failurecount} < 0) {
			$$v{failurecount} = $FAILURECOUNT;
		}
	}
}

# ld_read_ipvsadm
#
# Net::FTP seems to set the input record separator ($\) to null
# putting IO into slurp (whole file at a time, rather than line at a time)
# mode. Net::FTP does this using local $\, which should mean
# that the change doesn' effect code here, but it does. It also
# seems to be impossible to turn it off, by say setting $\ back to '\n'
# Perhaps there is more to this than meets the eye. Perhaps it's a perl bug.
# In any case, this should fix the problem.
#
# This should not affect pid or config file parsing as they are called
# before Net::FTP and as this appears to be a bit of a work around,
# I'd rather use it in as few places as possible
#
# Observed with perl v5.8.8 (Debian's perl 5.8.8-6)
# -- Horms, 17th July 2005
sub ld_readline
{
	my ($fd, $buf) = (@_);
	my $line;

	# Uncomment the following line to turn off this work around
	# return readline($fd);

	$line = shift @$buf;
	if (defined $line) {
		return $line . "\n";
	}

	push @$buf, split /\n/, readline($fd);

	$line = shift @$buf;
	if (defined $line) {
		return $line . "\n";
	}

	return undef;
}

sub ld_start
{
	my $oldsrv;
	my $real_service;
	my $nv;
	my $nr;
	my $server_down = {};

	# make sure real servers are up to date
	foreach $nv (@VIRTUAL)
	{
		my($l_domain, ) = split(/\:/, &get_virtual($nv), 2);

		my $l_execcmd = "$PY_NSUPDATE $CONTROLPOINT -f add_domain $l_domain $nv->{ttl}";
		&system_wrapper($l_execcmd);	
	
		if (exists($nv->{backets}))
		{
			foreach my $l_bname(keys(%{$nv->{backets}}))
			{
				my $l_bvalue = $nv->{backets}->{$l_bname};
				my $l_is_default = exists($l_bvalue->{default})?'True':'False';

				my $l_execcmd = "$PY_NSUPDATE $CONTROLPOINT -f add_domain_backet $l_domain $l_bname $l_bvalue->{longtitude} $l_bvalue->{latitude} $l_is_default";
				&system_wrapper($l_execcmd);
			};
		};
		
		my $nreal = $nv->{real};
		my $ov = $oldsrv->{&get_virtual($nv) . " " . $nv->{protocol}};
		my $or = $ov->{real};
		my $fallback = fallback_find($nv);

		if (defined($fallback)) {
			delete($or->{"$fallback->{server}:$fallback->{port}"});
		}

		for $nr (@$nreal) {
			my $real_str = "$nr->{server}:$nr->{port}";
			if (! defined($or->{$real_str}) or
					$or->{$real_str}->{weight} == 0) {
				$server_down->{$real_str} = [$nv, $nr];
				#service_set($nv, $nr, "down", {force => 1});
			}
			else {
				if (defined $server_down->{$real_str}) {
					delete($server_down->{$real_str});
				}
				service_set($nv, $nr, "up", {force => 1});
			}
			delete($or->{$real_str});
		}

		# remove remaining entries for real servers		
		for my $k (keys %$or) {
			purge_untracked_service($nv, $k, "start");
			delete($$or{$k});
		}

		delete($oldsrv->{&get_virtual($nv) . " " . $nv->{protocol}});
		&fallback_on($nv);
	}

	for my $k (keys (%$server_down)) {
		my $v = $server_down->{$k};
		service_set(@$v[0], @$v[1], "down", {force => 1});
		delete($server_down->{$k});
		#sleep 5;
	}

	# remove remaining entries for virtual servers
	foreach $nv (@OLDVIRTUAL) {
		if (! defined($oldsrv->{&get_virtual($nv) . " " .
					$nv->{protocol}})) {
			next;
		}
		purge_virtual($nv, "start");
	}
}

sub ld_cmd_children
{
	my ($cmd, %children) = (@_);
	# instantiate other nsdirectord, if specified
	my $child;
	foreach $child (keys %children) {
		if ($cmd eq "reload_or_start") {
			if (&system_wrapper("$LDIRECTORD $child reload")) {
				&system_wrapper("$LDIRECTORD $child start");
			}
		}
		else {
			&system_wrapper("$LDIRECTORD $child $cmd");
		}
	}
}

sub ld_stop
{
	# Kill children
	if ($FORKING eq 'yes') {
		foreach my $virtual_id (keys (%FORK_CHILDREN)) {
			my $pid = $FORK_CHILDREN{$virtual_id};
			ld_log("Killing child $virtual_id PID=$pid");
			kill 15, $pid;
		}
	}
	foreach my $v (@VIRTUAL) {
		next if ( (! defined($$v{cleanstop}) and $CLEANSTOP eq 'no') or
			(defined($$v{cleanstop}) and $$v{cleanstop} eq 'no') );
		my $real = $$v{real};
		foreach my $r (@$real) {
			if (defined $$r{virtual_status}) {
				purge_service($v, $r, "stop");
			}
		}
		purge_virtual($v, "stop");
	}
}

sub ld_main
{
	# Main failover checking code
	while (1) {
		if ($FORKING eq 'yes') {
			foreach my $v (@VIRTUAL) {
				my $virtual_id = get_virtual_id_str($v);
				if (!exists($FORK_CHILDREN{$virtual_id})) {
					&ld_log("Child not running for $virtual_id, spawning");
					my $pid = fork;
					if (!defined($pid)) {
						&ld_log("fork failed");
					} elsif ($pid == 0) {
						run_child($v);
					} else {
						$FORK_CHILDREN{get_virtual_id_str($v)} = $pid;
						&ld_log("Spawned child $virtual_id PID=$pid");
					}
				} elsif (waitpid($FORK_CHILDREN{get_virtual_id_str($v)}, WNOHANG)) {
					delete $FORK_CHILDREN{get_virtual_id_str($v)};
				}
			}
			check_signal();
			if (!check_cfgfile()) {
				sleep 1;
			}

			check_signal();

		} else {
			my @real_checked;
			foreach my $v (@VIRTUAL) {
				my $real = $$v{real};
				my $virtual_id = get_virtual_id_str($v);

				REAL: foreach my $r (@$real) {
					my $real_id = get_real_id_str($r, $v);
					check_signal();
					foreach my $tmp_id (@real_checked) {
						if($real_id eq $tmp_id) {
							&ld_debug(3, "Already checked: real server=$real_id (virtual=$virtual_id)");
							next REAL;
						}
					}
					_check_real($v, $r);
					push(@real_checked, $real_id);
				}
			}
			check_signal();
			if (!check_cfgfile()) {
				sleep $CHECKINTERVAL;
			}

			check_signal();
			ld_emailalert_resend();

			check_signal();
		}
	}
}

sub run_child
{
	my $v = shift;
	# Just exit on signals
	$SIG{'INT'} = "DEFAULT";
	$SIG{'QUIT'} = "DEFAULT";
	$SIG{'ILL'} = "DEFAULT";
	$SIG{'ABRT'} = "DEFAULT";
	$SIG{'FPE'} = "DEFAULT";
	$SIG{'SEGV'} = "DEFAULT";
	$SIG{'TERM'} = "DEFAULT";

	$SIG{'BUS'} = "DEFAULT";
	$SIG{'SYS'} = "DEFAULT";
	$SIG{'XCPU'} = "DEFAULT";
	$SIG{'XFSZ'} = "DEFAULT";

	$SIG{'IOT'} = "DEFAULT";

	$SIG{'PIPE'} = "IGNORE";
	$SIG{'HUP'} = sub { exit 1 };

	my $real = $$v{real};
	my $virtual_id = get_virtual_id_str($v);
	my $checkinterval = $$v{checkinterval} || $CHECKINTERVAL;
	$0 = "nsdirectord $virtual_id";
	while (1) {
		foreach my $r (@$real) {
			$0 = "nsdirectord $virtual_id checking $$r{server}";
			_check_real($v, $r);
		}
		$0 = "nsdirectord $virtual_id";
		sleep $checkinterval;
		ld_emailalert_resend();
	}
}

sub _check_real
{
	my $v = shift;
	my $r = shift;


	my $real_id = get_real_id_str($r, $v);
	my $virtual_id = get_virtual_id_str($v);

	if (_check_real_for_maintenance($r)) {
		service_set($v, $r, "down", {do_log => 1, force => 1}, "Server in maintenance");
		return;
	} elsif ($$v{checktype} eq "negotiate" || $$r{num_connects}>=$$v{num_connects}) {
		&ld_debug(2, "Checking negotiate: real server=$real_id (virtual=$virtual_id)");
		if (grep $$v{service} eq $_, ("http", "https", "http_proxy")) {
			$$r{num_connects} = 0 if (check_http($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "pop") {
			$$r{num_connects} = 0 if (check_pop($v, $r, 0) == $SERVICE_UP);
		} elsif ($$v{service} eq "pops") {
			$$r{num_connects} = 0 if (check_pop($v, $r, 1) == $SERVICE_UP);
		} elsif ($$v{service} eq "imap") {
			$$r{num_connects} = 0 if (check_imap($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "imaps") {
			$$r{num_connects} = 0 if (check_imaps($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "smtp" or $$v{service} eq "submission") {
			$$r{num_connects} = 0 if (check_smtp($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "ftp") {
			$$r{num_connects} = 0 if (check_ftp($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "ldap") {
			$$r{num_connects} = 0 if (check_ldap($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "nntp") {
			$$r{num_connects} = 0 if (check_nntp($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "dns") {
			$$r{num_connects} = 0 if (check_dns($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "sip") {
			$$r{num_connects} = 0 if (check_sip($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "radius") {
			$$r{num_connects} = 0 if (check_radius($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "mysql") {
			$$r{num_connects} = 0 if (check_mysql($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "pgsql") {
			$$r{num_connects} = 0 if (check_pgsql($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "oracle") {
			$$r{num_connects} = 0 if (check_oracle($v, $r) == $SERVICE_UP);
		} elsif ($$v{service} eq "simpletcp") {
			$$r{num_connects} = 0 if (check_simpletcp($v, $r) == $SERVICE_UP);
		} else {
			$$r{num_connects} = 0 if (check_none($v, $r) == $SERVICE_UP);
		}
	} elsif ($$v{checktype} eq "connect") {
		if ($$v{protocol} ne "udp") {
			&ld_debug(2, "Checking connect: real server=$real_id (virtual=$virtual_id)");
			check_connect($v, $r);
		}
		else {
			&ld_debug(2, "Checking connect (ping): real server=$real_id (virtual=$virtual_id)");
			check_ping($v, $r);
		}
	} elsif ($$v{checktype} eq "ping") {
		&ld_debug(2, "Checking ping: real server=$real_id (virtual=$virtual_id)");
		check_ping($v, $r);
	} elsif ($$v{checktype} eq "external") {
		&ld_debug(2, "Checking external: real server=$real_id (virtual=$virtual_id)");
		check_external($v, $r);
	} elsif ($$v{checktype} eq "external-perl") {
		&ld_debug(2, "Checking external-perl: real server=$real_id (virtual=$virtual_id)");
		check_external_perl($v, $r);
	} elsif ($$v{checktype} eq "off") {
		&ld_debug(2, "Checking off: No real or fallback servers to be added\n");
	} elsif ($$v{checktype} eq "on") {
		&ld_debug(2, "Checking on: Real servers are added without any checks\n");
		&service_set($v, $r, "up");
	} elsif ($$v{checktype} eq "combined") {
		&ld_debug(2, "Checking combined-connect: real server=$real_id (virtual=$virtual_id)");
		if (check_connect($v, $r) == $SERVICE_UP) {
			$$r{num_connects}++;
		} else {
			$$r{num_connects} = 999999;
		}
	}
}

sub _check_real_for_maintenance
{
	my $r = shift;

	return undef if(!$MAINTDIR);

	my $servername = ld_gethostbyaddr($$r{server});

	# Extract just the first component of the full name so we can match short or FQDN names
	$servername =~ /^([a-z][a-z0-9\-]+)\./;
	my $servershortname = $1;

	if (-e "$MAINTDIR/$$r{server}:$$r{port}") {
		&ld_debug(2, "Server maintenance: Found file $$r{server}:$$r{port}");
		return 1;
	} elsif (-e "$MAINTDIR/$$r{server}") {
		&ld_debug(2, "Server maintenance: Found file $$r{server}");
		return 1;
	} elsif ($servername && -e "$MAINTDIR/$servername:$$r{port}") {
		&ld_debug(2, "Server maintenance: Found file $servername:$$r{port}");
		return 1;
	} elsif ($servername && -e "$MAINTDIR/$servername") {
		&ld_debug(2, "Server maintenance: Found file $servername");
		return 1;
	} elsif ($servershortname && -e "$MAINTDIR/$servershortname:$$r{port}") {
		&ld_debug(2, "Server maintenance: Found file $servershortname:$$r{port}");
		return 1;
	} elsif ($servershortname && -e "$MAINTDIR/$servershortname") {
		&ld_debug(2, "Server maintenance: Found file $servershortname");
		return 1;
	}
	return undef;
}

sub check_http
{
	use LWP::UserAgent;
	use LWP::Debug;
	if($DEBUG > 2) {
		LWP::Debug::level('+');
	}
	my ($v, $r) = @_;

	$$r{url} =~ /(http|https):\/\/([^:\/]+)(:([^\/]+))?(\/.*)/;
	my $host = $2;
	#my $port = $3;
	my $uri = $4;
	my $virtualhost = (defined $$v{virtualhost} ? $$v{virtualhost} : $host);

	&ld_debug(2, "check_http: url=\"$$r{url}\" "
		. "virtualhost=\"$virtualhost\"");

	my $ua = new LWP::UserAgent();

	my $h = undef;
	if ($$v{service} eq "http_proxy") {
		my $port = ld_checkport($v, $r);
		$ua->proxy("http", "http://$$r{server}:$port/");
	} else {
		$h = new HTTP::Headers("Host" => $virtualhost);
	}

	my $req = new HTTP::Request("$$v{httpmethod}", "$$r{url}", $h);
	my $res;

	# LWP does not seem to honour timeouts set using $ua->timeout()
	# for HTTPS. So use an alarm instead. This also has the advantage
	# of being cumulative timeout, rather than a per send/receive
	# timeout.
	eval {
		# LWP makes unguarded calls to eval
		# which throw a fatal exception if they fail
		# Needless to say, this is completely stupid.
		# Resetting of $SIG{'__DIE__'} is also
		# needed now that alarm() is used.
		local $SIG{'__DIE__'} = "DEFAULT";
		local $SIG{'ALRM'} = sub { die "Timeout Alarm" };
		&ld_debug(4, "Timeout is $$v{negotiatetimeout}");
		&ld_debug(2, "Starting Check");
		alarm $$v{negotiatetimeout};

		&ld_debug(2, "Starting HTTP/HTTPS");
		$res = $ua->request($req);
		&ld_debug(2, "Finished HTTP/HTTPS");
		alarm 0; # Cancel the alarm
	};

	if (not defined $res) {
		&ld_debug(2, "check_http: timeout");
		goto down;
	}

	if ($$v{service} eq "https") {
		&ld_debug(2, "SSL-Cipher: " .
			$res->header('Client-SSL-Cipher'));
		&ld_debug(2, "SSL-Cert-Subject: " .
			$res->header('Client-SSL-Cert-Subject'));
		&ld_debug(2, "SSL-Cert-Issuer: " .
			$res->header('Client-SSL-Cert-Issuer'));
	}

	my $recstr = $$r{receive};
	if ($res->is_success && (!($recstr =~ /.+/) ||
				$res->content =~ /$recstr/)) {
		service_set($v, $r, "up", {do_log => 1}, $res->status_line);
		&ld_debug(2, "check_http: $$r{url} is up\n");
		return $SERVICE_UP;
	}

	my $log_message = $res->is_success ? $res->content : $res->status_line;
	service_set($v, $r, "down", {do_log => 1}, $log_message);

	&ld_debug(3, "Headers " .  $res->headers->as_string);
down:
	&ld_debug(2, "check_http: $$r{url} is down\n");
	return $SERVICE_DOWN;
}

sub check_smtp
{
	require Net::SMTP;
	my ($v, $r) = @_;
	my $port = ld_checkport($v, $r);

	&ld_debug(2, "Checking $$v{service}: server=$$r{server} port=$port");

	my $smtp = new Net::SMTP($$r{server}, Port => $port,
			Timeout => $$v{negotiatetimeout});
	if ($smtp) {
		$smtp->quit;
		service_set($v, $r, "up", {do_log => 1});
		return $SERVICE_UP;
	} else {
		service_set($v, $r, "down", {do_log => 1});
		return $SERVICE_DOWN;
	}
}

sub check_pop
{
	require Mail::POP3Client;
	my ($v, $r, $ssl) = @_;
	my $port = ld_checkport($v, $r);

	&ld_debug(2, "Checking pop server=$$r{server} port=$port ssl=$ssl");

	my $pop = new Mail::POP3Client(USER => $$v{login},
					PASSWORD => $$v{passwd},
					HOST => $$r{server},
					USESSL => $ssl,
					PORT => $port,
					DEBUG => 0,
					TIMEOUT => $$v{negotiatetimeout});

	if (!$pop) {
		service_set($v, $r, "down", {do_log => 1});
		return $SERVICE_DOWN;
	}

	if($$v{login} ne "") {
		my $authres = $pop->login();
		$pop->close();
		if (!$authres) {
			service_set($v, $r, "down", {do_log => 1});
			return $SERVICE_DOWN;
		}
	}

	$pop->close();
	service_set($v, $r, "up", {do_log => 1});
	return $SERVICE_UP;
}

sub check_imap
{
	require Net::IMAP::Simple;
	my ($v, $r) = @_;
	my $port = ld_checkport($v, $r);

	&ld_debug(2, "Checking imap server=$$r{server} port=$port");

	my $imap = Net::IMAP::Simple->new($$r{server},
					port => $port,
					timeout => $$v{negotiatetimeout});

	if (!$imap) {
		service_set($v, $r, "down", {do_log => 1});
		return $SERVICE_DOWN;
	}

	if($$v{login} ne "") {
		my $authres = $imap->login($$v{login},$$v{passwd});
		$imap->quit;
		if (!$authres) {
			service_set($v, $r, "down", {do_log => 1});
			return $SERVICE_DOWN;
		}
	}

	$imap->quit();
	service_set($v, $r, "up", {do_log => 1});
	return $SERVICE_UP;
}

sub check_imaps
{
	require Net::IMAP::Simple::SSL;
	my ($v, $r) = @_;
	my $port = ld_checkport($v, $r);

	&ld_debug(2, "Checking imaps server=$$r{server} port=$port");

	my $imaps = Net::IMAP::Simple::SSL->new($$r{server},
					port => $port,
					timeout => $$v{negotiatetimeout});
	if (!$imaps) {
		service_set($v, $r, "down", {do_log => 1});
		return $SERVICE_DOWN;
	}

	if($$v{login} ne "") {
		my $authres = $imaps->login($$v{login},$$v{passwd});
		$imaps->quit;
		if (!$authres) {
			service_set($v, $r, "down", {do_log => 1});
			return $SERVICE_DOWN;
		}
	}

	$imaps->quit();
	service_set($v, $r, "up", {do_log => 1});
	return $SERVICE_UP;
}

sub check_ldap
{
	my ($v, $r) = @_;
	require Net::LDAP;
	my $port = ld_checkport($v, $r);

	&ld_debug(2, "Checking ldap server=$$r{server} port=$port");

	my $recstr = $$r{receive};
	my $ldap = Net::LDAP->new("$$r{server}", port => $port,
					timeout => $$v{negotiatetimeout});
	if(!$ldap) {
		service_set($v, $r, "down", {do_log => 1}, "Connection failed");
		&ld_debug(4, "Connection failed");
		return $SERVICE_DOWN;
	}

	my $mesg;
	if ($$v{login} && $$v{passwd}) {
		$mesg = $ldap->bind($$v{login}, password=>$$v{passwd}) ;
	}
	else {
		$mesg = $ldap->bind ;
	}
	if ($mesg->is_error) {
		service_set($v, $r, "down", {do_log => 1}, "Bind failed");
		&ld_debug(4, "Bind failed");
		return $SERVICE_DOWN;
	}

	&ld_debug(4, "Base : " . substr($$r{request},1));
	my $result = $ldap->search (
		base	=> substr($$r{request},1) . "",
		scope	=> "base",
		filter	=> "(objectClass=*)"
		);

	if($result->count != 1) {
		service_set($v, $r, "down", {do_log => 1}, "No answer received");
		&ld_debug(2, "Count failed : " . $result->count);
		return $SERVICE_DOWN;
	}

	my $href = $result->as_struct;
	my @arrayOfDNs  = keys %$href ;
	if (!($recstr =~ /.+/) || $arrayOfDNs[0] =~ /$recstr/) {
		service_set($v, $r, "up", {do_log => 1}, "Success");
		return $SERVICE_UP;
	} else {
		service_set($v, $r, "down", {do_log => 1}, "Response mismatch");
		&ld_debug(4,"Message differs : " . ", " . $$r{receive}
				. ", " . $arrayOfDNs[0] . ".");
		return $SERVICE_DOWN;
	}
}

sub check_nntp
{
	use IO::Socket;
	use IO::Socket::INET6;
	use IO::Select;
	my ($v, $r) = @_;
	my $sock;
	my $s;
	my $buf;
	my $port = ld_checkport($v, $r);
	my $status = 1;

	&ld_debug(2, "Checking nntp server=$$r{server} port=$port");

	unless ($sock = IO::Socket::INET6->new(PeerAddr => $$r{server},
		PeerPort => $port, Proto => 'tcp',
		TimeOut => $$v{negotiatetimeout})) {
		service_set($v, $r, "down", {do_log => 1});
		return $SERVICE_DOWN;
	}
	$s = IO::Select->new();
	$s->add($sock);
	if (scalar($s->can_read($$v{negotiatetimeout})) == 0) {
		service_set($v, $r, "down", {do_log => 1});
	} else {
		sysread($sock, $buf, 64);
		if ($buf =~ /^2/) {
			service_set($v, $r, "up", {do_log => 1});
			$status = 0;
		} else {
			service_set($v, $r, "down", {do_log => 1});
		}
	}
	$s->remove($sock);
	$sock->close;

	return $status;
}

sub check_radius
{
	require Authen::Radius;

	my ($v, $r) = @_;

	&ld_debug(2, "Checking radius");

	my $port = ld_checkport($v, $r);
	my $radius;
	my $result = "";

	eval {
		local $SIG{'__DIE__'} = "DEFAULT";
		local $SIG{'ALRM'} = sub { die "Timeout Alarm" };
		&ld_debug(4, "Timeout is $$v{checktimeout}");
		&ld_debug(2, "Starting Check");
		alarm $$v{checktimeout};

		&ld_debug(2, "Starting Radius");
		$radius = new Authen::Radius(Host => "$$r{server}:$port",
					     Secret=>$$v{secret},
					     TimeOut=>$$v{negotiatetimeout},
					     Errmode=>'die');
		$result = $radius->check_pwd($$v{login}, $$v{passwd});
		&ld_debug(2, "Finished Radius");
		alarm 0; # Cancel the alarm
	};
	if ($result eq "") {
		&service_set($v, $r, "down", {do_log => 1});
		&ld_debug(3, "Deactivated service $$r{server}:$$r{port}: $@");
		&ld_debug(3, "Radius Error: ".$radius->get_error);
		return $SERVICE_DOWN;
	} else {
		&service_set($v, $r, "up", {do_log => 1});
		&ld_debug(3, "Activated service $$r{server}:$$r{port}");
		return $SERVICE_UP;
	}
}

sub check_mysql
{
	return check_sql(@_, "mysql", "database");
}

sub check_pgsql
{
	return check_sql(@_, "Pg", "dbname");
}

sub check_sql_log_errstr
{
	my ($prefix, $errstr) = (@_);

	for $_ (split /\n/, $errstr) {
		&ld_debug(4, "$prefix $_\n");
	}

}

sub check_oracle
{
	return check_sql(@_, "Oracle", "sid");
}

sub check_sql
{
	require DBI;
	my ($v, $r, $dbd, $dbname) = @_;
	my $port = ld_checkport($v, $r);
	my ($dbh, $sth, $query, $rows, $result);
	$result = $SERVICE_DOWN;
	$query = $$r{request};
	$query =~ s#^/##;
	unless ($$v{login} && $query) {
		&ld_log("Error: Must specify a login and request string " .
			"for MySQL, Oracle and PostgreSQL checks. " .
			"Not adding $$r{server}.\n");
		goto err_down;
	}
	$result=2;   # Set result flag.  Only ok if ends up at zero.
	&ld_debug(2, "Checking $$v{server} server=$$r{server} port=$port\n");
	$dbh = DBI->connect("dbi:$dbd:$dbname=$$v{database};" .
			    "host=$$r{server};port=$port", $$v{login},
			    $$v{passwd});
	unless ($dbh) {
		&ld_debug(2, "Failed to bind to $$r{server} with DBI->errstr\n");
		check_sql_log_errstr("Failed to bind to $$r{server} with",
				     DBI->errstr);
		goto err_down;
	}
	$result--;
	$sth = $dbh->prepare($query);
	unless ($sth) {
		&ld_debug(2, "Error preparing statement: $dbh->errstr\n");
		check_sql_log_errstr("Error preparing statement:",
				     $dbh->errstr);
		goto err_disconect;
	}

	# Test to see if any errors are returned
	$sth->execute;
	if ($dbh->err) {
		&ld_debug(2, "Error executing statement: $dbh->errstr : $dbh->err\n");
		check_sql_log_errstr("Error executing statement:",
				     $dbh->errstr, $dbh->err);
		goto err_finish;
	}

	# On error "execute" will return undef.
	#
	# Assuming you're using 'SELECT' you will get the number of rows
	# returned from the db when running execute: the 'rows' method is
	# only used when doing something that is NOT a select.  I cannot
	# imagine that you would ever want to insert or update from a
	# regular polling on this system, so we will assume you are using
	# SELECT here.
	#
	# Ideally you will do something like this: 'select * from
	# director_slave where enabled=1' This way you can have, say, a
	# MEMORY table in MySQL where you insert a value into a row
	# (enabled) that says whether or not you want to actually use this
	# in the pool from nsdirectord / ipvs, and disable them without
	# actually turning off your sql server.
	
	$sth->execute;
	if ($dbd eq "Oracle") { $sth->fetchrow_hashref() }
	unless ($rows = $sth->rows) {
		check_sql_log_errstr("Error executing statement:",
				     $dbh->errstr, $dbh->err);
		goto err_finish;
	}

	# Actually look to see if there was data returned in this statement,
	# else disable node
	if($rows > 0) {
		goto out;
	} else {
		goto err_finish;
	}

out:
	$result = $SERVICE_UP;
err_finish:
	$sth->finish();
err_disconnect:
	$dbh->disconnect();
err_down:
	service_set($v, $r, $result == $SERVICE_UP ? "up" : "down", {do_log => 1});
	return $result;
}

sub check_connect
{
	my ($v, $r) = @_;
	my $port = ld_checkport($v, $r);

	eval {
		local $SIG{'__DIE__'} = "DEFAULT";
		local $SIG{'ALRM'} = sub { die "Timeout Alarm" };
		&ld_debug(4, "Timeout is $$v{checktimeout}");
		alarm $$v{checktimeout};
		my $sock = &ld_open_socket($$r{server}, $port, $$v{protocol});
		if ($sock) {
			close($sock);
		} else {
			alarm 0; # Cancel the alarm
			die("Socket Connect Failed");
		}
		&ld_debug(3, "Connected to $$r{server} (port $port)");
		alarm 0; # Cancel the alarm
	};
	if ($@) {
		&service_set($v, $r, "down", {do_log => 1});
		&ld_debug(3, "Deactivated service $$r{server}:$$r{port}: $@");
		return $SERVICE_DOWN;
	} else {
		&service_set($v, $r, "up", {do_log => 1});
		&ld_debug(3, "Activated service $$r{server}:$$r{port}");
		return $SERVICE_UP;
	}
}

sub check_external
{
	my ($v, $r) = @_;
	my $v_server;

	if (defined $$v{server}) {
		$v_server = $$v{server};
	} else {
		$v_server = $$v{fwm};
	}

	my $result = system_timeout($$v{checktimeout},
				    $$v{checkcommand}, $v_server, $$v{port},
				    $$r{server}, $$r{port});

	if ($result) {
		&service_set($v, $r, "down", {do_log => 1});
		&ld_debug(3, "Deactivated service $$r{server}:$$r{port}: " .
			  "$@ after calling $$v{checkcommand} with result " .
			  "$result");
		return 0;
	} else {
		&service_set($v, $r, "up", {do_log => 1});
		&ld_debug(3, "Activated service $$r{server}:$$r{port}");
		return 1;
	}
}

sub check_external_perl
{
	my ($v, $r) = @_;
	my $result;
	my $v_server;

	eval {
		local $SIG{'__DIE__'} = "DEFAULT";
		local $SIG{'ALRM'} = sub { die "Timeout Alarm" };
		&ld_debug(4, "Timeout is $$v{checktimeout}");
		alarm $$v{checktimeout};
		if (defined $$v{server}) {
			$v_server = $$v{server};
		} else {
			$v_server = $$v{fwm};
		}
		my $cmdfunc = $check_external_perl__funcs{$$v{checkcommand}};
		if (!defined($cmdfunc)) {
			open(CMDFILE, "<$$v{checkcommand}") || die "cannot open external-perl checkcommand file: $$v{checkcommand}";
			$cmdfunc = eval("sub { \@ARGV=\@_; " . join("", <CMDFILE>) . " }");
			close(CMDFILE);
			$check_external_perl__funcs{$$v{checkcommand}} = $cmdfunc;
		}
		no warnings 'redefine';
		local *CORE::GLOBAL::exit = sub {
			$result = shift;
			goto external_exit;
		};
		$cmdfunc->($v_server, $$v{port}, $$r{server}, $$r{port});
		external_exit:
		alarm 0;
	};
	if ($@ or $result != 0) {
		&service_set($v, $r, "down");
		&ld_debug(3, "Deactivated service $$r{server}:$$r{port}: " .
			  "$@ after calling (external-perl) $$v{checkcommand} with result " .
			  "$result");
		return 0;
	} else {
		&service_set($v, $r, "up");
		&ld_debug(3, "Activated service $$r{server}:$$r{port}");
		return 1;
	}
}

sub check_sip
{
	my ($v, $r) = @_;
	my $sip_d_port = ld_checkport($v, $r);

	&ld_debug(2, "Checking sip server=$$r{server} port=$sip_d_port");


	eval {
		use Socket;

		local $SIG{'__DIE__'} = "DEFAULT";
		local $SIG{'ALRM'} = sub { die "Timeout Alarm" };
		&ld_debug(4, "Timeout is $$v{checktimeout}");
		alarm $$v{negotiatetimeout};

		my $sock = &ld_open_socket($$r{server}, $sip_d_port,
					$$v{protocol});
		unless ($sock) {
			alarm 0;
			die("Socket Connect Failed");
		}

		my ($sip_s_addr_str, $sip_s_port) = &ld_get_addrport($sock);

		&ld_debug(3, "Connected from $sip_s_addr_str:$sip_s_port to " .
			$$r{server} . ":$sip_d_port");

		select $sock;
		$|=1;
		select STDOUT;

		my $request =
		"OPTIONS sip:" . $$v{login} . " SIP/2.0\r\n" .
		"Via: SIP/2.0/UDP $sip_s_addr_str:$sip_s_port;" .
			"branch=z9hG4bKhjhs8ass877\r\n" .
		"Max-Forwards: 70\r\n" .
		"To: <sip:" . $$v{login} . ">\r\n" .
		"From: <sip:" . $$v{login} . ">;tag=1928301774\r\n" .
		"Call-ID: " . (join "", map { unpack "H*", chr(rand(256)) } 1..8) . "\r\n" .
		"CSeq: 63104 OPTIONS\r\n" .
		"Contact: <sip:" . $$v{login} . ">\r\n" .
		"Accept: application/sdp\r\n" .
		"Content-Length: 0\r\n\r\n";

		print "Request:\n$request";
		print $sock $request;

		my $ok;
		my $reply;
		while (<$sock>) {
			chomp;
			$/="\r";
			chomp;
			$/="\n";

			last if ($_ eq "");

			if (!defined $ok) {
				# Check status
				$ok = $_;
				if ($ok !~ m/^SIP\/2.0 200 OK/) {
					alarm 0; # Cancel the alarm
					close($sock);
					die "$ok\n";
				}
				next;
			}
			$reply .= "$_\n";

			# Add more checks here as desired
		}
		alarm 0; # Cancel the alarm
		close($sock);

		if (!defined $ok) {
			die "No OK\n";
		}

		print "Reply:\n$ok\n$reply\n";
	};

	if ($@) {
		&service_set($v, $r, "down", {do_log => 1});
		&ld_debug(3, "Deactivated service $$r{server}:$$r{port}: $@");
		return $SERVICE_DOWN;
	} else {
		&service_set($v, $r, "up", {do_log => 1});
		&ld_debug(3, "Activated service $$r{server}:$$r{port}");
		return $SERVICE_UP;
	}
}

sub check_simpletcp
{
	my ($v, $r) = @_;
	my $d_port = ld_checkport($v, $r);

	&ld_debug(2, "Checking simpletcp server=$$r{server} port=$d_port");

	eval {
		use Socket;

		local $SIG{'__DIE__'} = "DEFAULT";
		local $SIG{'ALRM'} = sub { die "Timeout Alarm" };
		&ld_debug(4, "Timeout is $$v{checktimeout}");
		alarm $$v{negotiatetimeout};

		my $sock = &ld_open_socket($$r{server}, $d_port,
					$$v{protocol});
		unless ($sock) {
			alarm 0;
			die("Socket Connect Failed");
		}

		my ($s_addr_str, $s_port) = &ld_get_addrport($sock);

		&ld_debug(3, "Connected from $s_addr_str:$s_port to " .
			$$r{server} . ":$d_port");

		select $sock;
		$|=1;
		select STDOUT;

		my $request = substr($$r{request}, 1);
		$request =~ s/\\n/\n/g ;

		&ld_debug(2, "Checking simpletcp server=$$r{server} port=$d_port request:\n$request");
		print $sock $request;
		shutdown($sock, SHUT_WR);

		my $ok;
		my $reply;
		while (<$sock>) {
			&ld_debug(2, "Checking simpletcp server=$$r{server} port=$d_port receive=" . $$r{receive} ." got: $_\n");
			if ( $_ =~ /$$r{receive}/ ) {
				$ok = 1;
				last;
			}
		}
		alarm 0; # Cancel the alarm
		close($sock);

		if (!defined $ok) {
			die "No OK\n";
		}
	};

	if ($@) {
		&service_set($v, $r, "down", {do_log => 1});
		&ld_debug(3, "Deactivated service $$r{server}:$$r{port}: $@");
		return $SERVICE_DOWN;
	} else {
		&service_set($v, $r, "up", {do_log => 1});
		&ld_debug(3, "Activated service $$r{server}:$$r{port}");
		return $SERVICE_UP;
	}
}

sub check_ftp
{
	require Net::FTP;
	my ($v, $r) = @_;
	my $ftp;
	my $memory;
	my $debug = ($DEBUG > 2) ? 1 : 0;
	my $port = ld_checkport($v, $r);

	&ld_debug(2, "Checking ftp server=$$r{server} port=$port");
	&ld_debug(4, "Timeout is $$v{negotiatetimeout}");

	open(TMP,'+>', undef);

	# In some cases Net::FTP dies if there is a timeout
	eval {
		unless ($ftp = Net::FTP->new("$$r{server}:$port",
				Timeout=>$$v{negotiatetimeout},
				Debug=>$debug)) {
			die "Could not connect\n";
		}
		$ftp->login($$v{login}, $$v{passwd});
		$ftp->cwd("/");
		$ftp->binary();
		$ftp->pasv();
		$ftp->get("$$r{request}", *TMP);
		$ftp->quit();
	};
	if ($@) {
		&ld_debug(2, "Warning: $@");
	}

	seek TMP, 0, 0;
	local $/;
	$memory = <TMP>;
	close TMP;

	if ($memory =~ /$$r{receive}/) {
		service_set($v, $r, "up", {do_log => 1});
		return $SERVICE_UP;
	}

	service_set($v, $r, "down", {do_log => 1});
	return $SERVICE_DOWN;
}

sub check_dns
{
	my $res;
	my $query;
	my $rr;
	my $request;
	my $server;
	my ($v,$r) = @_;
	{
		# Net::DNS makes unguarded calls to eval
		# which throw a fatal exception if they fail
		# Needless to say, this is completely stupid.
		local $SIG{'__DIE__'} = "DEFAULT";
		require Net::DNS;
	}
	$res = new Net::DNS::Resolver;
	if($DEBUG > 2) {
		$res->debug(1);
	}

	$$r{"request"} =~ m/^\/?(.*)/;
	$request=$1;
	
	$server = &ld_strip_brackets($$r{server});

	&ld_debug(2, "Checking dns: request=\"$request\" receive=\""
		. $$r{"receive"} . "\"\n");

	eval {
		local $SIG{'__DIE__'} = "DEFAULT";
		local $SIG{'ALRM'} = sub { die "timeout\n"; };
		alarm($$v{negotiatetimeout});
		$res->nameservers($server);
		if ($$v{"protocol"} eq "tcp") {
			$res->usevc(1);
		}
		$query = $res->search($request);
		alarm(0);
	};

	if (@$ eq "timeout\n" or ! $query) {
		service_set($v, $r, "down", {do_log => 1}, "Connection timed out");
		return $SERVICE_DOWN;
	}

	foreach $rr ($query->answer) {
		if (($rr->type eq "A" and $rr->address eq $$r{"receive"}) or
		    ($rr->type eq "PTR" and $rr->ptrdname eq $$r{"receive"})) {
			service_set($v, $r, "up", {do_log => 1}, "Success");
			return $SERVICE_UP;
		}
	}

	service_set($v, $r, "down", {do_log => 1}, "Response mismatch");
	return $SERVICE_DOWN;
}

sub check_ping
{
	use Net::Ping;

	my ($v,$r) = (@_);

	&ld_debug(2, "Checking ping: " .  "host=\"" .  $$r{server} .
		"\" checktimeout=\"" . $$v{"checktimeout"} .
		"\" checkcount=\"" . $$v{"checkcount"} . "\"\n");

	my $p = Net::Ping->new("icmp","1","64");
	for (my $attempt = 0; $attempt < $$v{"checkcount"}; $attempt++) {
		if ($p->ping($$r{server}, $$v{"checktimeout"})) {
			&ld_debug(2, "pong from $$r{server}\n");
			service_set($v, $r, "up", {do_log => 1});
			return $SERVICE_UP;
		}
		&ld_debug(2, "ping to $$r{server} timed out " .
					"(attempt " .  ($attempt + 1) . "/" .
					$$v{"checkcount"} . ")\n");
	}

	service_set($v, $r, "down");
	return $SERVICE_DOWN;
}

# check_none
# Dummy function to check service if service type is none.
# Just activates the real server
sub check_none
{
	my ($v, $r) = @_;

	&ld_debug(2, "Checking none");

	service_set($v, $r, "up", {do_log => 1});
	return $SERVICE_UP;
}

# service_set
# Used to bring up and down real servers.
# This is the function you should call if you want to bring a real
# server up or down.
# This function is safe to call regardless of the current state of a
# real server.
# Do _not_ call _service_up or _service_down directly.
# pre: v: virtual that the real service belongs to
#         Only used to determine the protocol of the service
#      r: real server to take down
#      state: up or down
#             up to bring the real service up
#             down to bring the real service up
#      flags: hash with the following (optional) keys:
#             force => 1  - force setting of the specified state
#             do_log => 1 - log the state to the monitorfile
#                           (when called as the result of a check)
# post: The real server is brought up or down for each virtual service
#       it belongs to.
# return: none
sub service_set
{
	my ($v, $r, $state, $flags, $log_msg) = @_;

	my ($real, $virtual, $virt, $now);

	if ($$flags{'do_log'}) {
		$now = localtime();

		if (!defined($log_msg)) {
			$log_msg = "-";
		}

		# URI-escape special log characters ('|' and newlines)
		$log_msg =~ s/([%|\r\n])/sprintf("%%%.2x", ord($1))/eg;
	}

	# Find the real server in @REAL
	foreach $real (@REAL) {
		if($real->{"real"} eq get_real_id_str($r, $v)) {
			$virtual = $real->{"virtual"};
			last;
		}
	}
	return unless (defined($virtual));

	# Check each virtual service for the real server and make
	# changes as necessary
	foreach $v (@VIRTUAL){
		# Use found rather than relying on tmp_id being
		# set when we leave the foreach loop. There
		# seems to some weirdness in Perl (5.6.0 on Redhat 7.2)
		my $found = 0;
		my $tmp_id;
		my $virtual_id = get_virtual_id_str($v);
		my $real_id = get_real_id_str($r, $v);
		my $log_str = "real server=$real_id" .
			      " (virtual=$virtual_id)";
		foreach $tmp_id (@$virtual) {
			if($virtual_id eq $tmp_id) {
				$found = 1;
				last;
			}
		}
		if ($found == 1) {
			if ($state=~/up/i) {
				_service_up($v, $r, $$flags{"force"});
				&ld_debug(2, "Enabled  $log_str");
			} elsif ($state=~/down/i) {
				_service_down($v, $r, $$flags{"force"});
				&ld_debug(2, "Disabled $log_str");
			}

			if ($$v{"monitorfile"} and $$flags{"do_log"}) {
				my $real_log_msg = $real_id;
				$real_log_msg =~ tr/:/ /s;
				$real_log_msg =~ s/\\//g;
				unless(
					open(CHECKLOG, ">>$$v{monitorfile}") and
					print CHECKLOG "[$now] [$$] $real_log_msg [$state] $log_msg\n" and
					close(CHECKLOG)
				) { die("Error writing to monitorfile '$$v{monitorfile}': $!"); }
			}
		}
	}
}

# _remove_service
# Remove a real server by either making it quiescent or deleting it
# Should be called by _service_down or fallback_off
# I.e. If you want to change the state of a real server call service_set.
#      If you call this function directly then nsdirectord will lose track
#      of the state of real servers.
# If the real server exists (which it should) make it quiescent or
# delete it, depending on the global and per virtual service quiescent flag.
# If it # doesn't exist, just leave it as it will be added by the
# _service_up code as appropriate.
# pre: v: reference to virtual service to with the real server belongs
#      rservice: service to restore. Of the form server:port for a tcp or
#                udp service. Of the form fwmark for a fwm service.
#      rforw: Forwarding mechanism of service. Sould be one of "-g" "-i" or
#             "-m"
#      tag: Tag to use for logging. Should be either "real" or "fallback"
# post: real service is taken up from the respective virtual service
#       if it is inactive
# return: none
sub _remove_service
{
	my ($v, $rservice, $rforw, $tag) = (@_);
	my $l_reals = $v->{'real'};
	
	my($l_domain, ) = split(/\:/, &get_virtual($v), 2);
	my($l_ip, ) = split(/\:/, $rservice, 2);
	my $l_real_backet;
	
	foreach my $l_real(@$l_reals)
	{
		if($l_real->{server} eq $l_ip)
		{
			if (exists($v->{backets}))
			{
				$l_real_backet = $l_real->{backet};
			}
			else
			{
				$l_real_backet = "LB";
			};

			last;
		};
	};
	
	my $l_execcmd = "$PY_NSUPDATE $CONTROLPOINT -f rmv_domain_backet_ip $l_domain $l_real_backet $l_ip";
	&system_wrapper($l_execcmd);
}

# _restore_service
# Make a retore a real server. The opposite of _quiescent_server.
# Should be called by _service_up or fallback_on
# I.e. If you want to change the state of a real server call service_set.
#      If you call this function directly then nsdirectord will lose track
#      of the state of real servers.
# If the real server exists (which it should) make it quiescent. If it
# doesn't exist, just leave it as it will be added by the _service_up code
# as appropriate.
# pre: v: reference to virtual service to with the real server belongs
#      rservice: service to restore. Of the form server:port for a tcp or
#                udp service. Of the form fwmark for a fwm service.
#      rforw: Forwarding mechanism of service. Sould be one of "-g" "-i" or
#             "-m"
#      rwght: Weight of service. Sold be of the form "<weight>"
#             e.g. "1"
#      tag: Tag to use for logging. Should be either "real" or "fallback"
# post: real service is taken up from the respective virtual service
#       if it is inactive
# return: none
sub _restore_service
{
	my ($v, $rservice, $rforw, $rwght, $tag) = (@_);
	my $l_reals = $v->{'real'};

	my($l_domain, ) = split(/\:/, &get_virtual($v), 2);
	my($l_ip, ) = split(/\:/, $rservice, 2);
	my $l_real_backet;
	
	foreach my $l_real(@$l_reals)
	{
		if($l_real->{server} eq $l_ip)
		{
			if (exists($v->{backets}))
			{
				$l_real_backet = $l_real->{backet};
			}
			else
			{
				$l_real_backet = "LB";
			};
		
			last;
		};
	};

 	my $l_execcmd = "$PY_NSUPDATE $CONTROLPOINT -f add_domain_backet_ip $l_domain $l_real_backet $l_ip";
	&system_wrapper($l_execcmd);
}

# Check the status of a server
# Should only be called from _status_up, _status_down,
# _service_up, or _service_down
# Returns 1 if the server is up, 0 if down
sub _status_check
{
	my ($v, $r, $is_fallback) = (@_);

	my $virtual_id = get_virtual_id_str($v);
	my $real_id = get_real_id_str($r, $v);

	if (defined($is_fallback)) {
		if (defined($v->{real_status}) or
				(defined($v->{fallback_status}) and
				$v->{fallback_status}->{"$real_id"})) {
			return 1;
		}
	}
	else {
		if (defined ($v->{real_status}) and
				$v->{real_status}->{"$real_id"}) {
			return 1;
		}
	}
	return 0;
}

# Set the status of a server as up
# Should only be called from _service_up or _ld_start
sub _status_up
{
	my ($v, $r, $is_fallback) = (@_);

	my $virtual_id = get_virtual_id_str($v);
	my $real_id = get_real_id_str($r, $v);

	return undef if(_status_check($v, $r, $is_fallback));

	$r->{virtual_status}->{"$virtual_id"} = 1;
	if (defined $is_fallback) {
		$v->{fallback_status}->{"$real_id"} = 1;
	}
	else {
		$v->{real_status}->{"$real_id"} = 1;
	}

	return 1;
}

# Set the status of a server as down
# Should only be called from _service_down or ld_stop
sub _status_down
{
	my ($v, $r, $is_fallback) = (@_);

	my $virtual_id = get_virtual_id_str($v);
	my $real_id = get_real_id_str($r, $v);

	return undef if (!_status_check($v, $r, $is_fallback));

	if (defined($is_fallback)) {
		delete $v->{fallback_status}->{"$real_id"};
		if (! %{$v->{fallback_status}}) {
			$v->{fallback_status} = undef;
		}
	}
	else {
		delete $v->{real_status}->{"$real_id"};
		if (! %{$v->{real_status}}) {
			$v->{real_status} = undef;
		}
	}

	delete $r->{virtual_status}->{"$virtual_id"};
	if (! %{$r->{virtual_status}}) {
		$r->{virtual_status} = undef;
	}

	return 1;
}

# _service_up
# Bring a real service up if it is down
# Should be called by service_set only
# I.e. If you want to change the state of a real server call service_set.
#      If you call this function directly then nsdirectord will lose track
#      of the state of real servers.
# pre: v: reference to virtual service to with the real server belongs
#      r: reference to the real server to take down
# post: real service is taken up from the respective virtual service
#       if it is inactive
# return: none
sub _service_up
{
	my ($v, $r, $force) = (@_);

	if ($r->{failcount} > 0) {
		ld_log("Resetting soft failure count: " . $r->{server} . ":" .
		       $r->{port} . " (" . get_virtual_id_str($v) . ")");
	}

	$r->{failcount} = 0;

	if (! _status_up($v, $r) and ! defined($force)) {
		return;
	}

	&_restore_service($v, $r->{server} . ":" . $r->{port},
			  $r->{forw}, $r->{weight}, "real");
	&fallback_off($v);
}

# _service_down
# Bring a real service down if it is up
# Should be called by service_set only
# I.e. if you want to change the state of a real server call service_set.
#      If you call this function directly then nsdirectord will lose track
#      of the state of real servers.
# pre: v: reference to virtual service to with the real server belongs
#      r: reference to the real server to take down
# post: real service is taken down from the respective virtual service
#       if it is active
# return: none
sub _service_down
{
	my ($v, $r, $force) = @_;

	if (!_status_check($v, $r) and !defined($force)) {
		return;
	}

	$r->{failcount}++;

	if (!defined($force) and _status_check($v, $r) and
	     ($r->{failcount} < $v->{failurecount})) {
		ld_log("Soft failure real server: " . $r->{server} . ":" .
		       $r->{port} . " (" . get_virtual_id_str($v) .
		       ") failure " . $r->{failcount} . "/" . $v->{failurecount});
		return;
	}

	_status_down($v, $r);

	&_remove_service($v, $r->{server} . ":" . $r->{port},
			 $r->{forw}, "real");

	&fallback_on($v);
}

# fallback_on
# Turn on the fallback server for a virtual service if it is inactive
# pre: v: virtual to turn fallback service on for
# post: fallback server is turned on if it was inactive
# return: none
sub fallback_on
{
	my ($v, $force) = (@_);

	my $fallback=&fallback_find($v);

	if (defined($fallback) and (_status_up($v, $fallback, "fallback")
			or defined($force))) {
		&_restore_service($v, $fallback->{server} . ":" . $fallback->{port},
				  get_forward_flag($fallback->{forward}),
				  "1", "fallback");
	}

	if (!defined ($v->{real_status})) {
		&do_fallback_command($v, "start");
	}
}

# fallback_off
# Turn off the fallback server for a virtual service if it is active
# pre: v: virtual to turn fallback service off for
# post: fallback server is turned off if it was active
# return: none
sub fallback_off
{
	my ($v, $force) = (@_);

	my $fallback=&fallback_find($v);

	if (defined($fallback) and (_status_down($v, $fallback, "fallback")
			or defined($force))) {
		&_remove_service($v, $fallback->{server} . ":" .  $fallback->{port},
				 get_forward_flag($fallback->{forward}),
				 "fallback");
	}

	if (defined ($v->{real_status})) {
		&do_fallback_command($v, "stop");
	}
}

# fallback_find
# Determine the fallback for a virtual service
# pre: virtual: reference to a virtual service
# post: none
# return: $virtual->{"fallback"} if defined
#         else $FALLBACK->{$virtual->{"protocol"}} if defined
#         else undef
sub fallback_find
{
	my ($virtual) = (@_);

	my($global_fallback_ptr);	# fallback pointer
	my $ipv6p = $virtual->{server} =~ /[\[\]]/ ? 1 : 0;

	if( defined $virtual->{"fallback"} ) {
		return($virtual->{"fallback"});
	} elsif ( not defined($FALLBACK) and not $ipv6p ) {
		return undef;
	} elsif ( not defined($FALLBACK6) and $ipv6p ) {
		return undef;
	}

	if ($ipv6p) {	# IPv6
		$global_fallback_ptr = $FALLBACK6;
	} else {
		$global_fallback_ptr = $FALLBACK;
	}

	# If the global fallback has a port, it can be used as is
	if (defined($global_fallback_ptr->{$virtual->{"protocol"}}->{"port"})) {
		return $global_fallback_ptr->{$virtual->{"protocol"}};
	}

	# Else create an anonymous fallback
	my %anon_fallback = %{$global_fallback_ptr->{$virtual->{"protocol"}}};
	$anon_fallback{"port"} = $virtual->{"port"};

	return \%anon_fallback;
}

# fallback_command
# Execute the fallback command with the given status if it wasn't executed
# with this status already for the supplied virtual service.
sub do_fallback_command
{
	my ($v, $status) = (@_);

	if (defined $v->{fallbackcommand_status} and $v->{fallbackcommand_status} eq $status) {
		return;
	}

	$v->{fallbackcommand_status} = $status;

	if (defined($v->{fallbackcommand})) {
		&system_wrapper($v->{fallbackcommand} . " " . $status);
	} elsif (defined($FALLBACKCOMMAND)) {
		&system_wrapper($FALLBACKCOMMAND . " " . $status);
	}
}

# Used during stop, start and reload to remove stale real servers from LVS
sub purge_untracked_service
{
	my ($v, $rservice, $tag) = (@_);

	my $log_arg = "Purged real server ($tag): $rservice (" .
		      &get_virtual($v) . ")";

	my $l_reals = $v->{'real'};	
	my($l_domain, ) = split(/\:/, &get_virtual($v), 2);
	my($l_ip, ) = split(/\:/, $rservice, 2);
	my $l_real_backet;
	
	foreach my $l_real(@$l_reals)
	{
		if($l_real->{server} eq $l_ip)
		{
			if (exists($v->{backets}))
			{
				$l_real_backet = $l_real->{backet};
			}
			else
			{
				$l_real_backet = "LB";
			};

			last;
		};
	};
	
	my $l_execcmd = "$PY_NSUPDATE $CONTROLPOINT -f add_domain_backet_ip $l_domain $l_real_backet $l_ip";
	&system_wrapper($l_execcmd);

	&ld_log($log_arg);
	&ld_emailalert_send($log_arg, $v, $rservice, 0);
}

# Used during stop, start and reload to remove stale real servers from LVS
sub purge_service
{
	my ($v, $r, $tag) = (@_);

	purge_untracked_service($v, "$r->{server}:$r->{port}", $tag);
	_status_down($v, $r);
}

# Used during stop, start and reload to remove stale virtual services from LVS
sub purge_virtual
{
	my ($v, $tag) = (@_);
	my($l_domain, ) = split(/\:/, &get_virtual($v), 2);

	my $l_execcmd = "$PY_NSUPDATE $CONTROLPOINT -f rmv_domain $l_domain";
	&system_wrapper($l_execcmd);

	&ld_log("Purged virtual server ($tag): " .  &get_virtual($v));
}

sub check_cfgfile
{
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
		$size, $atime, $mtime) = stat($CONFIG);
	my ($status);
	return if ($stattime==$mtime);
	$stattime = $mtime;
	use Digest::MD5 qw(md5 md5_hex);
	my $ctx = Digest::MD5->new;
	unless (open(CFGFILE, "<$CONFIG")) {
		&config_warn(0, "can not open file $CONFIG for checking");
		return 0;
	}
	$ctx->addfile(*CFGFILE);
	close(CFGFILE);
	my $digest = $ctx->hexdigest;
	if (defined $checksum && $checksum ne $digest) {
		&ld_log("Configuration file '$CONFIG' has changed on disk");
		if ($AUTOCHECK eq "yes") {
			&ld_log(" - reread new configuration");
			&reread_config();
		} else {
			&ld_log(" - ignore new configuration\n");
		}
		if (defined($CALLBACK) and -x $CALLBACK) {
			&system_wrapper("$CALLBACK $CONFIG");
		}
		$status = 1;
	}
	$checksum = $digest;

	return $status;
}

# ld_openlog
# Open logger
# make log rotation work
# pre: none
# post: If logger is a file, it opened and closed again as a test
#       If logger is syslog, it is opened so it can be used without
#       needing to be opened again.
#       Otherwise, nothing is done.
# return: 0 on success
#         1 on error
sub ld_openlog
{
	if ($opt_d or $SUPERVISED eq "yes") {
		# Instantly do nothing
		return(0);
	}
	if( $LDIRLOG =~ /^\/(.*)/ ) {
		# Open and close the file as a test.
		# We open the file each time we want to log to it
		unless (open(LOGFILE, ">>$LDIRLOG") and close(LOGFILE)) {
			return 1;
		}
	}
	else
	{
		# Assume LDIRLOG is a logfacility, log to syslog
		setlogsock( "unix" );
		openlog( "nsdirectord", "pid", "$LDIRLOG" );
	}
	return(0);
}

# ld_log
# Log a message.
# pre: message: Message to write
# post: message and timetsamp is written to loged
#       If logger is a file, it is opened and closed again as a
#       primitive means to make log rotation work
# return: 0 on success
#         1 on error
sub ld_log
{
	my ($message) = (@_);

	my $now = localtime();

	&ld_debug(2, $message);
	chomp $message;
	if ($opt_d) {
		print STDERR "$message\n";
	} elsif ($SUPERVISED eq "yes") {
		print "[$now] $message\n";
	} elsif ( $LDIRLOG =~ /^\/(.*)/ ) {
		unless (open(LOGFILE, ">>$LDIRLOG")
				and print LOGFILE "[$now|$CFGNAME|$$] $message\n"
				and close(LOGFILE)) {
			print STDERR "$message\n";
			return 1;
		}
	}
	else {
		# Assume LDIRLOG is a logfacility, log to syslog
		syslog( "info", "$message" );
	}
	return(0);
}

sub daemon_status_str
{
	if ($DAEMON_STATUS == $DAEMON_STATUS_STARTING) {
		return "starting";
	}
	elsif ($DAEMON_STATUS == $DAEMON_STATUS_RUNNING) {
		return "running";
	}
	elsif ($DAEMON_STATUS == $DAEMON_STATUS_STOPPING) {
		return "stopping";
	}
	elsif ($DAEMON_STATUS == $DAEMON_STATUS_RELOADING) {
		return "reloading";
	}
	return "UNKNOWN";
}

# ld_emailalert_send
# Send email alerts per virtual server
# pre: message: Message to email
# post: message is emailed if emailalert defined for virtualserver
# return: 0 on success
#         1 on error
sub ld_emailalert_send
{
	my ($subject, $v, $rserver, $currenttime) = (@_);
	my $status = 0;
	my $to_addr;
	my $frequency;
	my $virtual_str;
	my $id;
	my $statusfilter;
	my $smtp_server;

	$frequency = defined $v->{emailalertfreq} ?  $v->{emailalertfreq} :
				$EMAILALERTFREQ;

	$virtual_str = &get_virtual($v);
	$id = "$rserver ($virtual_str)";

	if ($currenttime == 0 or $frequency == 0) {
		delete $EMAILSTATUS{"$id"};
	}
	else {
		$EMAILSTATUS{$id}->{v} = $v;
		$EMAILSTATUS{$id}->{alerttime} = $currenttime;
	}

	$statusfilter = defined $v->{emailalertstatus} ?
			$v->{emailalertstatus} : $EMAILALERTSTATUS;
	if (($DAEMON_STATUS & $statusfilter) == 0) {
		return 0;
	}

	$to_addr = defined $v->{emailalert} ? $v->{emailalert} : $EMAILALERT;
	if ($to_addr eq "") {
		return 0;
	}

	$smtp_server = defined $v->{smtp} ? $v->{smtp} :
				$SMTP;

	&ld_log("emailalert: $subject");
	if (defined $smtp_server) {
		$status = &ld_emailalert_net_smtp($smtp_server, $to_addr, $subject);
	}
	else {
		$status = &ld_emailalert_mail_send($to_addr, $subject);
	}

	return($status);
}

# ld_emailalert_net_smtp
# Send email alerts via SMTP server
# pre: smtp: SMTP server defined
# post: message is emailed if SMTP server is valid and working
# return: 0 on success
#	  1 on error
sub ld_emailalert_net_smtp
{
	my ($smtp_server, $to_addr, $subject) = (@_);
	my $status = 0;

	use Net::SMTP;
	use Sys::Hostname;

	my $hostname = hostname;

	my $smtp = Net::SMTP->new($smtp_server);

	if ($smtp) {
		$smtp->mail("$ENV{USER}\@$hostname");
		$smtp->to($to_addr);
		$smtp->data();
		if($EMAILALERTFROM) {
			$smtp->datasend("From: $EMAILALERTFROM\n");
		} else {
			$smtp->datasend("From: $ENV{USER}\@$hostname\n");
		}
		$smtp->datasend("To: $to_addr\n");
		$smtp->datasend("Subject: $subject\n\n");
		$smtp->datasend("nsdirectord host: $hostname\n" .
				"Log-Message: $subject\n" .
				"Daemon-Status: " .
				&daemon_status_str() . "\n");
		$smtp->dataend();
		$smtp->quit;
	} else {
		&ld_log("failed to send SMTP email message\n");
		$status = 1;
	}

	return($status);
}

# ld_emailalert_mail_send
# Send email alerts via Mail::Send
# pre: smtp: SMTP server not defined
# post: message is emailed if one of the Mail::Send methods works
# return: 0 on success
#	  1 on error
sub ld_emailalert_mail_send
{
	my ($to_addr, $subject) = (@_);
	my $emailmsg;
	my $emailfh;
	my $status = 0;

	use Mail::Send;

	$emailmsg = new Mail::Send Subject=>$subject, To=>$to_addr;
	$emailmsg->set('From', $EMAILALERTFROM) if ($EMAILALERTFROM);
	$emailfh = $emailmsg->open;
	print $emailfh "nsdirectord host: " . hostname() . "\n" .
		       "Log-Message: $subject\n" .
		       "Daemon-Status: " . &daemon_status_str() . "\n";
	unless ($emailfh->close) {
		&ld_log("failed to send email message\n");
		$status = 1;
	}

	return($status);
}

# ld_emailalert_resend
# Resend email alerts as necessary
# pre: none
# post: EMAILSTATUS array is updated and alerts are sent as necessary
# return: none
sub ld_emailalert_resend
{
	my $currenttime = time();
	my $es;
	my $id;
	my $rserver;
	my $frequency;

	foreach $id (keys %EMAILSTATUS) {
		$es = $EMAILSTATUS{$id};
		$frequency = defined $es->{v}->{emailalertfreq} ?
					$es->{v}->{emailalertfreq} :
					$EMAILALERTFREQ;
		$id =~ m/(.*) /;
		$rserver = $1;
		if ($currenttime - $es->{alerttime} < $frequency) {
			next;
		}
		&ld_emailalert_send("Inaccessible real server: $id",
				    $es->{v}, $rserver, $currenttime);
	}
}

# ld_debug
# Log a message to a STDOUT.
# pre: priority: priority of message
#      message: Message to write
# post: message is written to STDOUT if $DEBUG >= priority
# return: none
sub ld_debug
{
	my ($priority, $message) = (@_);

	if ( $DEBUG >= $priority ) {
		chomp $message;
		print STDERR "DEBUG${priority}: $message\n";
	}
}

# system_wrapper
# Wrapper around system() to log errors
#
# WARNING: Do not use alarm() together with this function.  A internal
# pipe will not be reclaimed (at least with Perl 5.8.8).  This can
# cause nsdirectord to run out of file handles.
#
# pre: LIST: arguments to pass to system()
# post: system() is called and if it returns non-zero a failure
#       message is logged
# return: return value of system()
sub system_wrapper
{
	my (@args)=(@_);

	my $status;

	&ld_log("Running system(@args)") if $DEBUG>2;
	$status = system(@args);
	if($status != 0) {
		&ld_log("system(@args) failed: $!");
	}

	return($status)
}

# system_timeout
# Emulate system() with timeout via fork(), exec(), and waitpid() and
# TERMinate the child on timeout.  Set an alarm() for the timeout.
#
# This function does not suffer the deficiencies of system_wrapper()
# of leaving pipes unreclaimed.  Zombies are reaped by ld_handler_chld
# and the related code.
#
# pre: timeout: timeout in seconds
#      LIST: arguments to pass to exec()
# return: >= 0 exit status of the child process
#          127 exec failed
#           -1 timeout
#           -2 fork failed
sub system_timeout
{
	my $timeout = shift;
	my (@args) = (@_);
	my $status;

	&ld_log("Running system_timeout($timeout, @args)") if $DEBUG>2;

	my $childpid = fork();
	if (!defined($childpid)) {
		&ld_log("fork failed: $!");
		return(-2);
        }
	elsif ($childpid) {
		# parent
		eval {
			local $SIG{'ALRM'} = sub { die "timeout\n"; };
			alarm $timeout;
			waitpid($childpid, 0);
			$status = $? >> 8;
			# When die()-ing in the SIGALRM handler we
			# will never reach this point.  Child/Zombie
			# is left behind.  The grim reaper
			# (ld_handler_chld + ld_process_chld) will
			# take care of the zombie.
		};
		alarm 0;
		if ($@) {
			# timeout
			if ($@ ne "timeout\n") {
				# log unexpected errors
				&ld_log("system_timeout($timeout, @args) " .
					"unexpected error: $@");
			}
			else {
				&ld_log("system_timeout($timeout, @args) " .
					"timed out, kill -TERM child");
			}

			# TERMinate child
			kill 15, $childpid;
			return(-1);
		}
		else {
			# did not timeout
			return($status);
		}
	}
	else {
		# child
        	exec(@args) or &ld_exit(127, "exec(@args) failed: $!");
		die "ld_exit() broken?, stopped";
        }
}

# exec_wrapper
# Wrapper around exec() to log errors
# pre: LIST: arguments to pass to exec()
# post: exec() is called and if it returns non-zero a failure
#       message is logged
# return: return value of exec() on failure
#         does not return on success
sub exec_wrapper
{
	my (@args)=(@_);

	my $status;

	&ld_log("Running exec(@args)") if $DEBUG>2;
	$status = exec(@args) or &ld_log("exec(@args) failed");
	return($status)
}

# ld_rm_file
# Remove a file, symink, or anything that isn't a directory
# and exists
# pre: filename: file to delete
# post: If filename does not exist or is a directory an
#       error state is reached
#       Else filename is delete
#       If $DEBUG >=2 errors are logged
# return: 0 on success
#         -1 on error
sub ld_rm_file
{
	my ($filename)=(@_);

	my ($status);

	if(-d "$filename"){
		&ld_debug(2, "ld_rm_file: $filename is a directory, skipping");
		return(-1);
	}
	if(! -e "$filename"){
		&ld_debug(2, "ld_rm_file: $filename doesn't exist, skipping");
		return(-1);
	}
	$status = unlink($filename);
	if($status!=1){
		&ld_debug(2, "ld_rm_file: Error deleting: $filename: $!");
	}
	return(($status==1)?0:-1)
}

# is_octet
# See if a number is an octet, that is >=0 and <=255
# pre: alleged_octet: the octet to test
# post: alleged_octet is checked to see if it is valid
# return: 1 if the alleged_octet is an octet
#         0 otherwise
sub is_octet
{
	my ($alleged_octet)=(@_);

	if($alleged_octet<0){ return 0; }
	if($alleged_octet>255){ return 0; }

	return(1);
}

# is_ip
# Check that a given string is an IP address
# pre: alleged_ip: string representing ip address
# post: alleged_ip is checked to see if it is valid
# return: 1 if alleged_ip is a valid ip address
#         0 otherwise
sub is_ip
{
	my ($alleged_ip)=(@_);

	if ($alleged_ip =~ /:/) {
		unless(inet_pton(AF_INET6,$alleged_ip)){ return 0; }
		return(1);
	}

	#If we don't have four, . delimited numbers then we have no hope
	unless($alleged_ip=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) { return 0; }

	#Each octet mist be >=0 and <=255
	unless(&is_octet($1)){ return 0; }
	unless(&is_octet($2)){ return 0; }
	unless(&is_octet($3)){ return 0; }
	unless(&is_octet($4)){ return 0; }

	return(1);
}

# ip_to_int
# Turn an IP address given as a dotted quad into an integer
# pre: ip_address: string representing IP address
# post: post ip_address is converted to an integer
# return: -1 if an error occurs
#         integer representation of IP address otherwise
sub ip_to_int
{
	my ($ip_address)=(@_);

	unless(&is_ip($ip_address)){ return(-1); }
	unless($ip_address=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/){ return(-1); }

	return(((((($1 << 8)+$2) << 8)+$3) << 8)+$4);
}

# int_to_ip
# Turn an IP address given as a dotted quad into an integer
# pre: ip_address: string representing IP address
# post: Decimal is converted to a dotted quad
# return: -1 if an error occurs
#        integer representation of IP address otherwise
sub int_to_ip
{
	my ($ip_address)=(@_);

	my $result = "";

	return(sprintf(
		"%d.%d.%d.%d",
		($ip_address>>24)&255,
		($ip_address>>16)&255,
		($ip_address>>8)&255,
		$ip_address&255
	));
}

# get_virtual
# Get the service for a virtual
# pre: nv: virtual to get the service for
# post: none
# return: fwmark of service if it is a fwm service
#         ip_address:port otherwise
sub get_virtual
{
	my ($nv) = (@_);

	if ($nv->{"protocol"} eq "fwm"){
		return $nv->{"fwm"};
	} else {
		return $nv->{"server"} . ":" . $nv->{"port"};
	}
}

# get_virtual_option
# Get the ipvsadm option corresponding to a virtual service
# pre: nv: virtual to get the service for
# post: none
# return: fwmark of service if it is a fwm service
#         fwmark of service + "-6" if it is a fwm service and the address family is AF_INET6
#         ip_address:port otherwise
sub get_virtual_option
{
	my ($nv) = (@_);

	my ($cmdline) = &get_virtual($nv);

	if ($nv->{"protocol"} eq "fwm" && $nv->{addressfamily} == AF_INET6) {
		$cmdline .=  " -6";
	}
	
	return $cmdline;
}

# get_real_id_str
# Get an id string for a real server
# pre: r: Real service.
#      protocol: protocol of the real service
#                tcp or udp
#      service: type of service
# post: none
# return: Id string for the real server
sub get_real_id_str
{
	my ($r, $v) = (@_);

	my $request = "";
	my $receive = "";
	my $checkport = "";
	my $virtualhost = "";
	my $check;
	my $real;

	if(defined($r->{"request"})) {
		$request = $r->{"request"};
	}
	else {
		$request = $v->{"request"};
	}

	if(defined($r->{"receive"})) {
		$receive = $r->{"receive"};
	}
	else {
		$receive = $v->{"receive"};
	}

	if($v->{"checktype"} eq "negotiate" or
			$v->{"checktype"} eq "combined") {
		$check = $v->{"checktype"} . ":" . $v->{"service"};
	}
	elsif($v->{"checktype"} eq "external" or
			$v->{"checktype"} eq "external-perl") {
		$check = $v->{"checktype"} . ":" . $v->{"checkcommand"};
	}
	else {
		$check = $v->{"checktype"};
	}

	if(defined($v->{"checkport"})) {
		$checkport = $v->{"checkport"};
	}

	if(defined($v->{"virtualhost"})) {
		$virtualhost = $v->{"virtualhost"};
	}

	$real    = $check . ":" . $v->{"protocol"} . ":"
		 . $r->{"server"} . ":" . $r->{"port"} . ":"
		 . $virtualhost . ":" . $checkport . ":"
		 . $r->{"weight"} . ":" . $r->{"forward"} . ":"
		 . quotemeta($request) . ":" . quotemeta($receive);
}

# get_virtual_id_str
# Get an id string for a virtual service
# pre: v: Virtual service
# post: none
# return: Id string for the virtual service
sub get_virtual_id_str
{
	my ($v) = (@_);

	return $v->{"protocol"} . ":" .  &get_virtual($v);
}

# get_forward_flag
# Get the ipvsadm flag corresponding to a forwarding mechanism
# pre: forward: Name of forwarding mechanism. u
#               Should be one of ipip, masq or gate
# post: none
# return: ipvsadm flag corresponding to the forwarding mechanism
#         " " if $forward is unknown
sub get_forward_flag
{
	my ($forward) = (@_);

	unless(defined($forward)) {
		return(" ");
	}

	if ($forward eq "masq") {
		return("-m");
	}
	elsif ($forward eq "gate") {
		return("-g");
	}
	elsif ($forward eq "ipip") {
		return("-i");
	}

	return(" ");
}

# ld_exit
# Exit and log a message
# pre: exit_status: Integer exit status to exit with
#                   0 will be used if parameter is omitted
#      message: Message to log when exiting. May be omitted
# post: If exit_status is non-zero or $DEBUG>2 then
#       message logged.
#       Programme exits with exit_status
# return: does not return
sub ld_exit
{
	my ($exit_status, $message)=(@_);
	unless(defined($exit_status)) { $exit_status=0; }
	unless(defined($message)) { $message=""; }

	if ($exit_status!=0 or $DEBUG>2) {
		&ld_log("Exiting with exit_status $exit_status: $message");
	}
	exit($exit_status);
}

# ld_open_socket
# Open a socket connection
# pre: remote: IP address as a dotted quad of remote host to connect to
#      port: port to connect to
#      protocol: Protocol to use. Should be either "tcp" or "udp"
# post: A Socket connection is opened to the remote host
# return: Open socket
#         undef on error
sub ld_open_socket
{
	my ($remote, $port, $protocol) = @_;
	my ($iaddr, $paddr, $pro, $result, $pf);
	local *SOCK;

	$remote = &ld_strip_brackets($remote);
	if (inet_pton(AF_INET6,$remote)) {
		$iaddr = inet_pton(AF_INET6,$remote);
		$paddr = pack_sockaddr_in6($port, $iaddr);
		$pf = PF_INET6;
	} else {
		$iaddr = inet_aton($remote) || die "no host: $remote";
		$paddr = sockaddr_in($port, $iaddr);
		$pf = PF_INET;
	}
	$pro = getprotobyname($protocol);
	if ($protocol eq "udp") {
		socket(SOCK, $pf, SOCK_DGRAM, $pro) || die "socket: $!";
	}
	else {
		socket(SOCK, $pf, SOCK_STREAM, $pro) || die "socket: $!";
	}
	$result = connect(SOCK, $paddr);
	unless ($result) {
		return undef;
	}
	return *SOCK;
}

# daemon
# Close and fork to become a daemon.
#
# Notes from unix programmer faq
# http://www.landfield.com/faqs/unix-faq/programmer/faq/
#
# Almost none of this is necessary (or advisable) if your daemon is being
# started by `inetd'.  In that case, stdin, stdout and stderr are all set up
# for you to refer to the network connection, and the `fork()'s and session
# manipulation should *not* be done (to avoid confusing `inetd').  Only the
# `chdir()' step remains useful.
#
# Gratuitously over documented, because it can be
#
# Written by Horms, horms@verge.net.au for an unrelated project while
# working for Zip World, http://www.zipworld.com.au/, 1997-1999.
sub ld_daemon
{
	# `fork()' so the parent can exit, this returns control to the command
	# line or shell invoking your program.  This step is required so that
	# the new process is guaranteed not to be a process group leader. The
	# next step, `setsid()', fails if you're a process group leader.
	&ld_daemon_become_child();

	# setsid()' to become a process group and session group leader. Since a
	# controlling terminal is associated with a session, and this new
	# session has not yet acquired a controlling terminal our process now
	# has no controlling terminal, which is a Good Thing for daemons.
	if(POSIX::setsid()<0){
		&ld_exit(1, "ld_daemon: Could not setsid");
	}

	# fork()' again so the parent, (the session group leader), can exit.
	# This means that we, as a non-session group leader, can never regain a
	# controlling terminal.
	&ld_daemon_become_child();

	# `chdir("/")' to ensure that our process doesn't keep any directory in
	# use. Failure to do this could make it so that an administrator
	# couldn't unmount a filesystem, because it was our current directory.
	if(chdir("/")<0){
		&ld_exit(1, "ld_daemon: Could not chdir");
	}

	# `close()' fds 0, 1, and 2. This releases the standard in, out, and
	# error we inherited from our parent process. We have no way of knowing
	# where these fds might have been redirected to. Note that many daemons
	# use `sysconf()' to determine the limit `_SC_OPEN_MAX'.  `_SC_OPEN_MAX'
	# tells you the maximum open files/process. Then in a loop, the daemon
	# can close all possible file descriptors. You have to decide if you
	# need to do this or not.  If you think that there might be
	# file-descriptors open you should close them, since there's a limit on
	# number of concurrent file descriptors.
	close(STDIN);
	close(STDOUT);
	close(STDERR);

	# Establish new open descriptors for stdin, stdout and stderr. Even if
	# you don't plan to use them, it is still a good idea to have them open.
	# The precise handling of these is a matter of taste; if you have a
	# logfile, for example, you might wish to open it as stdout or stderr,
	# and open `/dev/null' as stdin; alternatively, you could open
	# `/dev/console' as stderr and/or stdout, and `/dev/null' as stdin, or
	# any other combination that makes sense for your particular daemon.
	#
	# This code used to open /dev/console for STDOUT and STDERR,
	# but that was changed to /dev/null to stop the code hanging in
	# the case where /dev/console is unavailable for some reason
	# http://www.osdl.org/developer_bugzilla/show_bug.cgi?id=1180
	if(open(STDIN, "</dev/null")<0){
		&ld_exit(1, "ld_daemon: Could not open /dev/null");
	}
	if(open(STDOUT, ">>/dev/null")<0){
		&ld_exit(-1, "ld_daemon: Could not open /dev/null");
	}
	if(open(STDERR, ">>/dev/null")<0){
		&ld_exit(-1, "ld_daemon: Could not open /dev/null");
	}
}

# ld_daemon_become_child
# Fork, kill parent and return child process
# pre: none
# post: process forks and parent exits
#       All process exit with exit status -1 if an error occurs
# return: parent: exits
#         child: none  (this is the process that returns)
# Written by Horms, horms@verge.net.au for an unrelated project while
# working for Zip World, http://www.zipworld.com.au/, 1997-1999.
sub ld_daemon_become_child
{
	my($status);

	$status = fork();

	if ($status<0){
		&ld_exit(-1, "ld_daemon_become_child: Could not fork: $!");
	}
	if ($status>0){
		&ld_exit(0,
			"ld_daemon_become_child: Parent exiting as it should");
	}
}

# ld_gethostbyname
# Wrapper to gethostbyname. Look up the/an IP address of a hostname
# If an IP address is given is it returned
# pre: name: Hostname of IP address to lookup
#      af: Address Family: AF_INET etc..
# post: gethostbyname is called to find an IP address for $name
#       This is converted to a string
# return: IP address
#         undef on error
sub ld_gethostbyname
{
	my ($name, $af)=(@_);

	if ($name =~ /\[(.*)\]/) {
		$name = $1;
	}
	my @host = getaddrinfo($name, 0, $af);
	if (!defined($host[3])) {
		return undef;
	}
	my @ret = getnameinfo($host[3], NI_NUMERICHOST | NI_NUMERICSERV);
	if ($host[0] == AF_INET6) {
		return "[$ret[0]]";
	}
	else {
		return $ret[0];
	}
}

# ld_gethostbyaddr
# Wrapper to gethostbyaddr. Look up the hostname from an IP address.
# If no reverse DNS record is found, return undef
# pre: ip: IP address of host to lookup
# post: gethostbyaddr is called to find a hostname for IP $ip
# return: hostname
#         undef on error
sub ld_gethostbyaddr
{
	my ($ip)=(@_);

	$ip = &ld_strip_brackets($ip);
	my @host = getaddrinfo($ip,0);
	if (!defined($host[3])) {
		return undef;
	}
#	my @ret = getnameinfo($host[3], NI_NAMEREQD);
#	return undef unless(scalar(@ret) == 2);
#	return $ret[0];
}

# ld_getservbyname
# Wrapper for getservbyname. Look up the port for a service name
# If a port is given it is returned.
# pre: name: Port or Service name to look up
# post: if $name is a number
#         if 0<=$name<=65536 $name is returned
#         else undef is returned
#       else getservbyname is called to look up the port for the service
# return: Port
#         undef on error
sub ld_getservbyname
{
	my ($name, $protocol)=(@_);

	if($name=~/^[0-9]+$/){
		return(($name>=0 and $name<65536)?$name:undef);
	}

	my @serv=getservbyname($name, $protocol);

	return((@serv and defined($serv[2]))?$serv[2]:undef);
}

# ld_getservhostbyname
# Wrapper for ld_gethostbyname and ld_getservbyname. Given a server of the
# form ip_address|hostname[:port|servicename] return ip_address[:port]
# pre: hostserv: Servver of the form ip_address|hostname[:port|servicename]
#      protocol: Protocol for service. Should be either "tcp" or "udp"
#      af: Address Family: AF_INET etc..
# post: lookups performed as per ld_getservbyname and ld_gethostbyname
# return: ip_address[:port]
#         undef on error
sub ld_gethostservbyname{
	my ($hostserv, $protocol, $af) = (@_);

	my $ip;
	my $port;
	
	if ($hostserv =~ /(:(\d+|[A-Za-z0-9-_]+))?$/) {
		$port = $2;
		$ip = $hostserv;
		$ip =~ s/(:(\d+|[A-Za-z0-9-_]+))?$//;
	} else {
		$ip = $hostserv;
	};

	if(defined($port)){
		$port=&ld_getservbyname($port, $protocol);
		if (defined($port)) {
			return("$ip:$port");
		} else {
			return(undef);
		}
	}
	return($ip);
}

# ld_find_cmd_path
# Find executable in path
# pre: cmd: command to find
#      path: ':' delimited paths to check
#      relative: if set, allow cmd to be a relative path,
#                which is checked first
# return: path to command
#         undef if not found
sub ld_find_cmd_path
{
	my ($cmd, $path, $relative) = (@_);

	if (defined $relative  and $relative and -f "$cmd" ) {
		return $cmd;
	}
	if ($cmd =~ /^\// and -x "$cmd" ) {
		return $cmd;
	}
	if ($cmd =~ /\//) {
		return undef;
	}

	for my $p (split /:/, $path) {
		if ( -x "$p/$cmd" ) {
			return "$p/$cmd";
		}
	}
	return undef;
}

# ld_find_cmd_path
# Find executable in $ENV{'PATH'}
# pre: cmd: command to find
#      relative: if set, allow cmd to be a relative path,
#                which is checked first
# return: path to command
#         undef if not found
sub ld_find_cmd
{
	return ld_find_cmd_path($_[0], $ENV{'PATH'}, $_[1]);
}

# ld_get_addrport
# Get address string and port number from a given socket.
# pre: socket
# return: (address, port)
#         undef if cannot get
sub ld_get_addrport
{
	my($sock) = @_;

	my ($s_addr_str, $s_port, $s_addr, $len);

	my $s_sockaddr = getsockname($sock);
	$len = length($s_sockaddr);
	if ($len == 28) {	# IPv6
		($s_port, $s_addr) = unpack_sockaddr_in6($s_sockaddr);
		$s_addr_str = inet_ntop(AF_INET6, $s_addr);
		$s_addr_str = "[$s_addr_str]";
	}
	elsif ($len == 16) {	# IPv4
		($s_port, $s_addr) = unpack_sockaddr_in($s_sockaddr);
		$s_addr_str = inet_ntop(AF_INET, $s_addr);
	}
	else {
		die "unexpected length of sockaddr\n";
	}

	return ($s_addr_str, $s_port);
}

# ld_strip_brackets
# Strip brackets in the string
# pre: string
# return: string
sub ld_strip_brackets
{
	my($str) = @_;

	$str =~ s/[\[\]]//g;

	return $str;
}
