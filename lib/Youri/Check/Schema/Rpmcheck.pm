# $Id$
package Youri::Check::Schema::Rpmcheck;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('rpmcheck');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    error => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    rpm_id => {
        data_type         => 'integer',
        is_auto_increment => 0,
    }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(
    'rpm_id' => 'Youri::Check::Schema::RPM'
);

1;
