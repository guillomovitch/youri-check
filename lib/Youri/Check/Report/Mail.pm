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

sub _init {
    my $self = shift;
    my %options = (
        from     => '', # mail from header
        to       => '', # mail to header
        reply_to => '', # mail reply-to header
        mta      => '', # mta path
        noempty  => 1,  # don't generate empty reports
        formats  => {},
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
        eval {
            push(
                @{$self->{_formats}},
                create_instance(
                    'Youri::Check::Report::Mail::Format',
                    id        => $id,
                    test      => $options{test},
                    verbose   => $options{verbose},
                    %{$options{formats}->{$id}}
                )
            );
        };
        print STDERR "Failed to create format $id: $@\n" if $@;
    }

    croak "no formats created" unless @{$self->{_formats}};
}

sub _global_report {
    my ($self, $resultset, $type, $descriptor) = @_;

    foreach my $format (@{$self->{_formats}}) {
        my $iterator = $resultset->get_iterator(
            $type,
            [ 'package' ]
        );

        return if $self->{_noempty} && ! $iterator->has_results();

        my $content = $format->get_report(
            $self->{_time},
            "$type global report",
            $iterator,
            $type,
            $descriptor,
            undef
        );

        $self->_send_mail(
            $format->type(),
            $self->{_to},
            "$type global report",
            $content,
        );
    }
}

sub _individual_report {
    my ($self, $resultset, $type, $descriptor, $maintainer) = @_;

    foreach my $format (@{$self->{_formats}}) {
        my $iterator = $resultset->get_iterator(
            $type,
            [ 'package' ],
            { maintainer => [ $maintainer ] }
        );

        return if $self->{_noempty} && ! $iterator->has_results();

        my $content = $format->get_report(
            $self->{_time},
            "$type individual report for $maintainer",
            $iterator,
            $type,
            $descriptor,
            $maintainer
        );

        $self->_send_mail(
            $format->type(),
            $maintainer,
            "$type individual report for $maintainer",
            $content,
        );
    }

}

sub _send_mail {
    my ($self, $type, $to, $subject, $content) = @_;

    return unless $content;

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
        open(MAIL, "| $self->{_mta} -t -oi -oem") or die "Can't open MTA program: $!";
        $mail->print(\*MAIL);
        close MAIL;
    }
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006, YOURI project

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
