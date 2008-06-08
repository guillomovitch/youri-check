# $Id$
package Youri::Check::Schema::Package;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('packages');
__PACKAGE__->add_columns(
    name => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    section => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    maintainer => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    }
);
__PACKAGE__->set_primary_key('name');

1;
