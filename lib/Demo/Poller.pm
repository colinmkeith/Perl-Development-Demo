# vim: set foldmethod=marker filetype=perl:
package Demo::Poller;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');

our $AUTOLOAD;

use Net::SNMP;

# {{{ new([argpairs...])
sub new {
  my($class, @args) = @_;

  my $self = {
    timeout    => 5,
    version    => 2,
    retries    => 3,
    community  => 'public',
    _dataStore => {},
  };

  # Given arg pairs? Then merge over defaults;
  for(my $i=0; $i<@args; $i+=2) {
    my $k = $args[$i];
    $k =~ s/^-//;
    $self->{$k} = $args[$i+1];
  }

  bless($self, $class);
  return $self;
}    # }}}

# {{{ AUTOLOAD()
# wanted a quick way to get lots of vars without assuming data in hashref;
sub AUTOLOAD {
  my($this, $val) = @_;
  my $key = substr($AUTOLOAD, length(__PACKAGE__) + 2);    # XX::help => help

  # setter E.g. $poller->host();
  defined($val) && return $this->{$key} = $val;

  # Avoid auto-vivification
  return exists($this->{$key}) ? $this->{$key} : undef;
}    # }}}

# {{{ pollNode()
sub pollNode {
  my($this) = @_;
  my $snmp = $this->session();

  if(!$snmp) {
    my $err;

    # {{{ NOTE: In anon-block as no strict 'refs' & %params only needed here.
    {
      ## no critic  # because I know why I'm doing this
      no strict 'refs';
      ## use critic

      # Turn param list into hash of key-val pairs
      my %args = map { $_ => $this->$_(); } qw(
       hostname port localaddr localport nonblocking version domain timeout
       retries maxmsgsize translate debug community username
       authkey authpassword authprotocol privkey privpassword privprotocol
      );

      %args = (
        map  { $_ => $args{$_} }
        grep { defined($args{$_}) }
        keys(%args)
      );

      if($this->debug()) {
        require Data::Dumper;
        warn Data::Dumper->Dump([\%args], [qw(*args)]);
      }

      # Only pass those that actually have a value;
      ($snmp, $err) = Net::SNMP->session(%args);
    } # }}}

    $snmp || confess($err);
    $this->session($snmp);
  }

  my $resRef = $snmp->get_request(-varbindlist => $this->oids());

  defined($resRef)
   || confess('No results. Error from SNMP: ' . $snmp->error());
  $this->lastUpdated(time());
  return $this->storeData($resRef);
}    # }}}

# {{{ storeData(\%data)
sub storeData {
  my($this, $dataRef) = @_;

  # create new ref to data to avoid caller zapping reference
  return $this->{_dataStore} = \%{$dataRef};
}    # }}}

# {{{ getLastData()
sub getLastData {
  my($this) = @_;
  return $this->{_dataStore} || {};
}    # }}}

# {{{ oids([oidsToSet])
sub oids {
  my($this, @oids) = @_;
  @oids && ($this->{_oids} = ref($oids[0]) ? [@{$oids[0]}] : [@oids]);
  return $this->{_oids} || [];
}    # }}}

# {{{ DESTROY() - Close open sessions nicely
sub DESTROY {
  my($this) = @_;
  my $snmp = $this->session();
  $snmp && $snmp->close();
  return;
}    # }}}

1;   # Magic true value required at end of module
__END__

=head1 NAME

Demo::Poller - Poll SNMP services for specified oid.


=head1 VERSION

This document describes Demo::Poller version 0.0.1


=head1 SYNOPSIS

    use Demo::Poller;

    my $poller = Demo::Poller->new();
    $poller->host('test.net-snmp.org');
    $poller->community('password');
    $poller->oids([qw(sysDescr.0)]);
    $poller->pollNode();

=head1 DESCRIPTION

This is a demo module which does a quick poll of a target device for the given
OIDs and lets the caller query the data.

=head1 INTERFACE

=over 4

=item new

Instantiates a new Demo::Poller object with the default values of:

    timeout   => 5,
    version   => 2,
    retries   => 3,
    community => 'public',

Over ride the defaults and add any other connection info by passing
arg pairs. E.g.

    my $poller = Demo::Poller->new(
      -host      => 'test.net-snmp.org',
      -community => 'password',
      -oids      => [qw(sysDescr.0)]
    );

Alternatively

    my $poller = Demo::Poller->new();
    $poller->host('test.net-snmp.org');
    $poller->community('password');
    $poller->oids([qw(sysDescr.0)]);
    $poller->pollNode();

=item pollNode

Connects to the server specified in the object and polls the data for the
specified OIDs from it. The results are stored internally to be polled via
C<getLastData()>.

    $node->pollNode();

=item storeData

Stores the results for a SNMP-GET request for a given set of OIDs.

    $this->storeData(\%results)

=item getLastData()

Retrieves the results of the last SNMP-GET request.

    $node->getLastData();

=item oids([oidsToSet])

If passed an array, or array ref, of OIDs to set, stores the given OIDs in the
object.

Returns the current OIDs as an array ref. If setting, sets first then returns
what you just set.


=item All Other Methods

Demo::Poller allows you to call any method, except those listed above, to
get/set the appropriate key/key-value. So for example:

Setter:

    $node->host('test.net-snmp.org');

Getter:

    $node->host();

=back


=head1 DIAGNOSTICS

In the event of errors, Demo::Poller C<die>s the error reported by Net::SNMP.
It is therefore recommended that you use Try::Tiny to enclose the polling and
thus be able to catch the exceptions.

=head1 CONFIGURATION AND ENVIRONMENT

Demo::Poller requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Net-SNMP|Net::SNMP>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Colin Keith  C<< <ckeith@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Colin Keith C<< <ckeith@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<Perl Artistic License|perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
