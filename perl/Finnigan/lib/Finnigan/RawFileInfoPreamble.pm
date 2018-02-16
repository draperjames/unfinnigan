package Finnigan::RawFileInfoPreamble;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0207;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');

sub decode {
  my ($class, $stream, $version) = @_;

  my @common_fields = (
                       "method file present"  => ['V',    'UInt32'],
                       year                   => ['v',    'UInt16'],
                       month                  => ['v',    'UInt16'],
                       "day of the week"      => ['v',    'UInt16'],
                       day                    => ['v',    'UInt16'],
                       hour                   => ['v',    'UInt16'],
                       minute                 => ['v',    'UInt16'],
                       second                 => ['v',    'UInt16'],
                       millisecond            => ['v',    'UInt16'],
                      );

  my %specific_fields;
  $specific_fields{8} = [],
  $specific_fields{47} = [
                          "unknown_long[2]"    => ['V',    'UInt32'],
                          "data addr"          => ['V',    'UInt32'],
                          "controller_n[1]"    => ['V',    'UInt32'],
                          "controller_n[2]"    => ['V',    'UInt32'],
                          "unknown_long[5]"    => ['V',    'UInt32'],
                          "unknown_long[6]"    => ['V',    'UInt32'],
                          "run header addr"    => ['V',    'UInt32'],
                          "unknown_long[7]"    => ['V',    'UInt32'],
                          "unknown_long[8]"    => ['V',    'UInt32'],
                          "run header addr[2]" => ['V',    'UInt32'],
                          unknown_area         => ['C744', 'RawBytes'], # 804 - 15 * 4 (804 is the fixed size of RawFileInfoPreamble prior to v.64)
                         ];

  $specific_fields{57} = $specific_fields{47};

  $specific_fields{60} = $specific_fields{57};
  $specific_fields{62} = $specific_fields{57};
  $specific_fields{63} = $specific_fields{57};

  $specific_fields{64} = [
                          "unknown_long[2]"                  => ['V',     'UInt32'],
                          "32-bit data addr (unused)"        => ['V',     'UInt32'],
                          "controller_n[1]"                  => ['V',     'UInt32'],
                          "controller_n[2]"                  => ['V',     'UInt32'],
                          "unknown_long[5]"                  => ['V',     'UInt32'],
                          "unknown_long[6]"                  => ['V',     'UInt32'],
                          "32-bit run header addr (unused)"  => ['V',     'UInt32'],
                          "unknown_area[1]"                  => ['C760',  'RawBytes'],
                          "data addr"                        => ['Q<',    'UInt64'],
                          "unknown_long[7]"                  => ['V',     'UInt32'],
                          "unknown_long[8]"                  => ['V',     'UInt32'],
                          "run header addr"                  => ['Q<',    'UInt64'],
                          "unknown_long[9]"                  => ['V',     'UInt32'],
                          "unknown_long[10]"                 => ['V',     'UInt32'],
                          "run header addr[2]"               => ['Q<',    'UInt64'],
                          "unknown_area[2]"                  => ['C992', 'RawBytes'],
                         ];

  if ($version == 66) {
    $specific_fields{66} = $specific_fields{64};
    $specific_fields{66}->[-1]->[0] = 'C1008'; # unknown_area[2] has been extended
  }

  die "don't know how to parse version $version" unless $specific_fields{$version};
  my $self = Finnigan::Decoder->read($stream, [@common_fields, @{$specific_fields{$version}}]);

  return bless $self, $class;
}

sub timestamp {
  my $self = shift;
  my @dow_abbr = qw/X Mon Tue Wed Thu Fri Sat Sun/;
  my @month_abbr = qw/X Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
  $dow_abbr[$self->{data}->{"day of the week"}->{value}] . " "
    . $month_abbr[$self->{data}->{month}->{value}]
      . " "
        . $self->{data}->{day}->{value}
          . " "
            . $self->{data}->{year}->{value}
              . " "
                . $self->{data}->{hour}->{value}
                  . ":"
                    . $self->{data}->{minute}->{value}
                      . ":"
                        . $self->{data}->{second}->{value}
                          . "."
                            . $self->{data}->{millisecond}->{value}
                              ;
}

sub xmlTimestamp {
  my $self = shift;
  sprintf(
    '%04d-%02d-%02dT%02d:%02d:%02.0fZ',
    $self->{data}->{year}->{value},
    $self->{data}->{month}->{value},
    $self->{data}->{day}->{value},
    $self->{data}->{hour}->{value},
    $self->{data}->{minute}->{value},
    $self->{data}->{second}->{value} + $self->{data}->{millisecond}->{value} / 1000
  );
}

sub run_header_addr {
  my ($self, $index) = @_;
  if (not defined $index or $index == 0) {
    return shift->{data}->{"run header addr"}->{value};
  }
  elsif ($index == 1) {
    return shift->{data}->{"run header addr[2]"}->{value};
  }
  else {
    die "don't know how to find RunHeader " . $index;
  }
}

sub controller {
  my $self = shift;
  [$self->{data}->{"controller_n[1]"}->{value}, $self->{data}->{"controller_n[2]"}->{value}];
}

sub data_addr {
  shift->{data}->{"data addr"}->{value};
}

sub stringify {
  my $self = shift;
  my $rh2 = "";
  $rh2 .= ", " . $self->run_header_addr(1) if $self->{data}->{"controller_n[1]"}->{value} > 1;
  return $self->timestamp
      . "; "
        . "data addr: " . $self->data_addr
          . "; "
            . "countroller: [" . $self->{data}->{"controller_n[1]"}->{value} .  ", " . $self->{data}->{"controller_n[1]"}->{value} . "]"
              . "; "
                . "RunHeader addr: " . $self->run_header_addr . $rh2
                  ;
}

1;
__END__

=head1 NAME

Finnigan::RawFileInfoPreamble -- a decoder for RawFileInfoPreamble, the binary data part of RawFileInfo

=head1 SYNOPSIS

  use Finnigan;
  my $file_info = Finnigan::RawFileInfo->decode(\*INPUT);
  say $file_info->preamble->run_header_addr;
  say $file_info->preamble->data_addr;
  $file_info->preamble->dump;

=head1 DESCRIPTION

This this object decodes the binary preamble to RawFileInfo, which
contains an unpacked representation of a UTC date (apparently, the
file creation date), a set of unknown numbers, and most importantly,
the more modern versions of this structure contain the pointers to the
ScanDataPacket stream and to RunHeader, which stores the pointers
to all other data streams in the file.

The older versions of this structure did not contain anything except
the date stamp.

=head2 METHODS

=over 4

=item decode($stream, $version)

The constructor method

=item timestamp

Get the timestamp in text form: Wkd Mmm DD YYYY hh:mm:ss.ms

=item xmlTimestamp

Get the timestamp in text form, in the format adopted in mzML: YYYY-MM-DDThh:mm:ssZ

=item data_addr

Get the pointer to the first ScanDataPacket

=item controller

Return the pair of "virtual cnontroller" numbers; this is the structure indicating
how many data streams are in the file. It is not clear which one of the two
numbers it returns is the number of controllers and which is the number of
types. In all samples surveyed, these numbers were equal.

=item run_header_addr

Get the pointer to RunHeader (which contains further pointers)

The argument (presently 1 or 2) indicates which RunHeader address to get (when
there are more than one.

=item stringify

Make a concise string representation of the structure

=back

=head1 SEE ALSO

Finnigan::RawFileInfo

L<uf-rfi>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
