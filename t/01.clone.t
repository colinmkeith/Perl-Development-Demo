use Test::More tests => 12;
use Net::SNMP qw(:translate);
my $pkg;

BEGIN {
  $pkg = 'Demo::Poller';
  use_ok($pkg);
  use_ok('Try::Tiny');
}

diag("Testing $pkg $Demo::Poller::VERSION");

my($host, $communityStr) = qw(test.net-snmp.org demopublic);
my %OIDs = (
  sysUpTime => '1.3.6.1.2.1.1.3.0',
  sysName   => '1.3.6.1.2.1.1.5.0',
);

my $poller = Demo::Poller->new();
isa_ok($poller, $pkg, "ISA $pkg");
is($poller->timeout(),       5,     'Correctly set default values');
is($poller->hostname($host), $host, 'Testing AUTOLOAD working as Setter');
is($poller->hostname(),      $host, 'Testing AUTOLOAD working as Getter');
is_deeply($poller->getLastData(), {}, 'Last Data is empty');
$poller->debug(1);

$poller->community($communityStr);

# $poller->debug(0x02 | 0x04 | 0x08 | 0x10 | 0x20);
$poller->oids([values(%OIDs)]);

try {
  my $res = $poller->pollNode();
  is(ref($res), 'HASH', 'pollNode() did not throw a connection error');
}
catch {
  fail("pollNode() threw a connection error: $_");
};

my %lastData = %{$poller->getLastData()};
my @oidsUsed = @{$poller->oids()};
my $oidCount = 0 + @oidsUsed;
my $resCount = 0 + keys(%lastData);

is($resCount, $oidCount, "Polled $oidCount OIDs. Got $resCount results");
is(
  join('', sort(keys(%lastData))),
  join('', sort(@oidsUsed)),
  "OIDs in results are those we requested (Phew)"
);

for my $name (keys(%OIDs)) {
  diag("OID $name (oid=$OIDs{$name}) = $lastData{$OIDs{$name}}");
}
$poller->session()->close();
$poller->session(0);

diag('Now polling without translate');
$poller->translate(0);

$poller->pollNode();

%lastData = %{$poller->getLastData()};
my $upTimeAsInt = $lastData{$OIDs{sysUpTime}};
like($upTimeAsInt, qr/^[0-9]+$/, 'Uptime was sent as INT(32)');

for my $name (keys(%OIDs)) {
  diag("OID $name (oid=$OIDs{$name}) = $lastData{$OIDs{$name}}");
}

diag('2 sec sleep to let uptime counter increment ... Please wait.');
sleep(2);

$poller->pollNode();

my %newData = %{$poller->getLastData()};
my $upTimeAsInt2 = $newData{$OIDs{sysUpTime}};

ok($upTimeAsInt2 > $upTimeAsInt, 'Remote uptime correctly incremented');
