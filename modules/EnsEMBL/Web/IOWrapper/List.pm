=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2018] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::IOWrapper::List;

### The list format is a simple list of feature IDs, one per line
### and therefore does not need any fancy parsing

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::File::Utils::IO qw(read_file);

use parent qw(EnsEMBL::Web::IOWrapper);

sub open {
  my ($file, %args) = @_;

  my $result = EnsEMBL::Web::File::Utils::IO::read_file($file->absolute_write_path, {'nice' => 1});
  use Data::Dumper;
  warn Dumper($result);

  my $wrapper;
  if ($result->{'content'}) {
    $wrapper = EnsEMBL::Web::IOWrapper::List->new({
                              'parser' => undef,
                              'file'   => $file,
                              'format' => 'List',
                              %args,
                              });
  }

  return $wrapper;
}

sub validate {
  my $self = shift;
  my $file = $self->file;
  my $message;

  my $result = EnsEMBL::Web::File::Utils::IO::read_file($file->absolute_write_path, {'nice' => 1});
  
  if ($result->{'content'}) {
    foreach my $line (split '\n', $result->{'content'}) {
      ## Content should be a comma-separated list or a single column of identifiers
      my @ids = split(',', $line);
      foreach my $id (@ids) {
        if ($id !~ /^\w+$/) {
          $message = 'File did not validate as format '.$self->format;
          last;
        }
      }
    }
  }

  return $message;
}

1;
