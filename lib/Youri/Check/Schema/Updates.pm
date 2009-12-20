# $Id$
package Youri::Check::Schema::Updates;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('updates');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    current => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    available => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    source => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    url => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    package_id => {
        data_type         => 'integer',
        is_auto_increment => 0,
    }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(
    'package' => 'Youri::Check::Schema::Package', 'package_id'
);

1;
