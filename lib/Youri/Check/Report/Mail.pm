# $Id$
package Youri::Check::Report::Mail;

=head1 NAME

Youri::Check::Report::Mail - Report results by mail

=head1 DESCRIPTION

This plugin reports results by mail. Additional subplugins handle specific
formats.

=cut

use warnings;
use strict;
use Carp;
use MIME::Entity;
use Youri::Utils;
use base 'Youri::Check::Report';
use version; our $VERSION = qv('0.1.0');

sub _init {
    my $self = shift;
    my %options = (
        from     => '', # mail from header
        to       => '', # mail to header
        reply_to => '', # mail reply-to header
        mta      => '', # mta path
        noempty  => 1,  # don't generate empty reports
        formats  => undef,
        @_
    );

    croak "no format defined" unless $options{formats};
    croak "formats should be an hashref" unless ref $options{formats} eq 'HASH';

    $self->{_from}       = $options{from};
    $self->{_to}         = $options{to};
    $self->{_reply_to}   = $options{reply_to};
    $self->{_mta}        = $options{mta};
    $self->{_noempty}    = $options{noempty};

    foreach my $id (keys %{$options{formats}}) {
        print "Creating format $id\n" if $options{verbose};
        my $format_conf = $options{formats}->{$id};
        eval {
            push(
                @{$self->{_formats}},
                create_instance(
                    'Youri::Check::Report::Format',
                    $format_conf,
                    {
                        id      => $id,
                        test    => $options{test},
                        verbose => $options{verbose},
                    }
                )
            );
        };
        carp "Failed to create format $id: $@\n" if $@;
    }

    croak "no formats created" unless @{$self->{_formats}};
}

sub _global_report {
    my ($self, $resultset, $type, $descriptor, $filter) = @_;

    my $iterator = $resultset->get_iterator(
        $type,
        [ 'source_package' ],
        $filter
    );

    $self->_report(
        $iterator,
        $descriptor,
        $type,
        "$type global report",
        $self->{_to}
    );
}

sub _individual_report {
    my ($self, $resultset, $type, $descriptor, $filter, $maintainer) = @_;

    my $iterator = $resultset->get_iterator(
        $type,
        [ 'source_package' ],
        {
            ($filter ? %$filter : () ),
            maintainer => [ $maintainer ]
        }
    );

    $self->_report(
        $iterator,
        $descriptor,
        $type,
        "$type individual report for $maintainer",
        $maintainer
    );

}

sub _report {
    my ($self, $iterator, $descriptor, $type, $title, $to) = @_;

    return if $self->{_noempty} && ! $iterator->has_results();

    # initialisation
    foreach my $format (@{$self->{_formats}}) {
        $format->init_report(
            $title,
            $descriptor,
            $type
        );
    }

    # content creation
    my @results;
    while (my $result = $iterator->get_result()) {
        if (@results &&
            $result->{source_package} ne $results[0]->{source_package}
        ) {
            foreach my $format (@{$self->{_formats}}) {
                $format->add_results(\@results);
            }
            @results = ();
        }
        push(@results, $result);
    }
        
    # finalisation
    foreach my $format (@{$self->{_formats}}) {
        $format->add_results(\@results) if @results;

        $format->finish_report();

        $self->_send_mail(
            $format->get_mime_type(),
            $to,
            $title,
            $format->get_content()
        );
    }
}

sub _send_mail {
    my ($self, $type, $to, $subject, $content) = @_;

    my $mail = MIME::Entity->build(
        'Type'     => $type,
        'From'     => $self->{_from},
        'Reply-To' => $self->{_reply_to},
        'To'       => $to,
        'Subject'  => $subject,
        'Data'     => $$content
    );

    if ($self->{_test}) {
        $mail->print(\*STDOUT);
    } else {
        my $command = "$self->{_mta} -t -oi -oem";
        open(my $output, '|-', $command) or croak "Can't run $command: $!";
        $mail->print($output);
        close $output;
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
