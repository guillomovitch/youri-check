# $Id$
package Youri::Check::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/
    TestRun
    Section
    Maintainer
    Package
    RPM
/);

1;
