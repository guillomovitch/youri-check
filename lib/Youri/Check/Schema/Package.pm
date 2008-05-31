# $Id$
package Youri::Check::Schema::Package;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('packages');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
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
__PACKAGE__->set_primary_key('id');

1;
