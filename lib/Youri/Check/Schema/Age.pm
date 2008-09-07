# $Id$
package Youri::Check::Schema::Age;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('age');
__PACKAGE__->add_columns(
    buildtime => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    package_file_id => {
        data_type         => 'id',
        is_auto_increment => 0,
    },
);
__PACKAGE__->belongs_to(
    'package_file_id' => 'Youri::Check::Schema::PackageFile'
);

1;
