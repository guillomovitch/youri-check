# $Id$
package Youri::Check::Schema::Maintainer;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('maintainers');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    name => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(
    'packages' => 'Youri::Check::Schema::Package', 'maintainer_id'
);

1;
