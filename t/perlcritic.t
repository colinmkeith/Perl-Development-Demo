#!perl

if ($ENV{SKIP_PERL_CRITIC}) {
    Test::More::plan(
        skip_all => 'Skipping Perl::Critic testing per env var SKIP_PERL_CRITIC'
    );
}

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

Test::Perl::Critic::all_critic_ok();
