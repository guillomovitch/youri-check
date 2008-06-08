# $Id$
package Youri::Check::Schema::Age;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('age');
__PACKAGE__->add_columns(
    architecture => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    buildtime => {
        data_type         => 'varchar',
        is_auto_increment => 0,
    },
    package => {
        data_type         => 'integer',
        is_auto_increment => 0,
    },
);
__PACKAGE__->belongs_to(package => 'Youri::Check::Schema::Package');

1;
