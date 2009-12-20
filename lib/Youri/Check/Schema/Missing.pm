# $Id$
package Youri::Check::Schema::Missing;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('missing');
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
    'rpm' => 'Youri::Check::Schema::RPM', 'rpm_id'
);

1;
