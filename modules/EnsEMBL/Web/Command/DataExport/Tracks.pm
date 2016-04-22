=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Command::DataExport::Tracks;

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::Constants;

use parent qw(EnsEMBL::Web::Command);

sub process {
  my $self       = shift;
  my $hub        = $self->hub;

  my $error;
  my $format = $hub->param('format');

  my ($file, $filename, $extension, $compression);
  my $data_info   = EnsEMBL::Web::Constants::USERDATA_FORMATS;
  my $format_info = $data_info->{lc($format)};

  ## Make filename safe
  ($filename = $hub->param('name')) =~ s/ |-/_/g;

  ## Compress file by default
  $extension   = $format_info->{'ext'};
  $compression = $hub->param('compression');

  if (!$format_info) {
    $error = 'Format not recognised';
  }
  else {
    ## Create the component we need to get data from 
    my $component;
    ($component, $error) = $self->object->create_component;

    if ($error) {
      warn ">>> ERROR CREATING COMPONENT: $error";
    }
    else {
      $component->content;
      my $path = $hub->param('file') || '';
      my $controller = 'Download';

      my $params = {
                    'filename'  => $filename,
                    'format'    => $format,
                    'file'      => $path,
                    '__clear'   => 1,
                    };

      $self->ajax_redirect($hub->url('Download', $params), undef, undef, 'download');
    }
  } 
}

1;
