# $Id$
package Youri::Check::Schema::Package;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
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
    version => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    release => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    section_id => {
        data_type         => 'integer',
        is_auto_increment => 0,
    },
    maintainer_id => {
        data_type         => 'integer',
        is_auto_increment => 0,
        is_nullable       => 1
    }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(
    'files' => 'Youri::Check::Schema::RPM', 'package_id'
);
__PACKAGE__->belongs_to(
    'section' => 'Youri::Check::Schema::Section', 'section_id'
);
__PACKAGE__->belongs_to(
    'maintainer' => 'Youri::Check::Schema::Maintainer', 'maintainer_id'
);

1;
