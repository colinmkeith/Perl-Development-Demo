Demo-Poller v0.0.2
===========

This is a demonstration of my Perl development work as much of my existing work
is proprietary.

This is a simple module which polls SNMP servers for the uptime data. It is a
fabricated module to demonstrate that I can develop Perl modules.

It makes use of the following:

* Module::Starter (using Module::Stater::PBP)

* Developing a Perl module

* Using Object Oriented style Perl.

* Using POD for inline documentation.

* perlcritic to ensure good coding practices, including checking POD.


INSTALLATION
------------

There is no application, just the tests

	perl Makefile.PL
	make
	make test TEST_VERBOSE=1


DEPENDENCIES
------------

Net::SNMP


COPYRIGHT AND LICENCE
---------------------

Copyright (C) 2013, Colin Keith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
