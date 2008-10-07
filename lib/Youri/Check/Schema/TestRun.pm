# $Id$
package Youri::Check::Schema::TestRun;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('test_runs');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    name => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    count => {
        data_type         => 'integer',
        is_auto_increment => 0,
        default_value     => 0
    },
    date => {
        data_type         => 'timestamp',
        is_auto_increment => 0,
    },
);
__PACKAGE__->set_primary_key('id');

1;
