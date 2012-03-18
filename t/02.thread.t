use threads;
use Test::More tests => 9;
use Net::SNMP qw(:translate);

my $pkg;

BEGIN {
  $pkg = 'Demo::Poller';
  use_ok($pkg);
}

diag("Testing $pkg $Demo::Poller::VERSION with threads");

our($host, $communityStr) = qw(test.net-snmp.org demopublic);
our %OIDs = (
  sysUpTime => '1.3.6.1.2.1.1.3.0',
  sysName   => '1.3.6.1.2.1.1.5.0',
);

# {{{ pollingThread()
sub pollingThread {
  my($callerID) = @_;
  my $threadID = threads->tid();
  diag("Creating new thread ($callerID, Thread: #$threadID)");

  my $poller = Demo::Poller->new(
    -hostname  => $host,
    -translate => 0,
    -community => $communityStr,
  );
  $poller->oids( [values(%OIDs)] );

  ok($poller->pollNode(), "SNMP polled (Thread #$threadID)");
  diag('done');

  my %lastData = %{$poller->getLastData()};
  my @oidsUsed = @{$poller->oids()}; my $oidCount = 0 + @oidsUsed;
  my $resCount = 0 + keys(%lastData);

  is($resCount, $oidCount, "Got $oidCount/$resCount responses (Thread #$threadID)");
  $poller->session()->close();
  $poller->session(0);

  return $lastData{$OIDs{sysUpTime}};
}    # }}}


for my $threadID (0..2) {
  my $thr = threads->create({context => 'scalar'}, \&pollingThread, $threadID);
  sleep(1); # To stagger them
}

diag('Finished thread creation loop');
for my $thr (threads->list(threads::joinable)) {
  diag('Thread #' . $thr->tid());
  my $uptime = $thr->join();
  like($uptime, qr/^[0-9]+$/, 'Should get an uptime');
};
