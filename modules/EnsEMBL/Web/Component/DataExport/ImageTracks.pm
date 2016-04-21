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

package EnsEMBL::Web::Component::DataExport::ImageTracks;

### Interface for exporting tracks from a standard horizontal region image

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::DataExport);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 0 );
}

sub content {
  my $self  = shift;
  my $hub   = $self->hub;

  my $form = $self->new_form({'id' => 'export', 'action' => $hub->url({'action' => 'SelectInterface',  'function' => '', '__clear' => 1}), 'method' => 'post'});

  ## First, the radio buttons for selection data type
  my $datatype_fieldset = $form->add_fieldset;
  my $datatypes = [
                    {'value' => 'sequence', 'class' => '_stt', 'caption' => 'Sequence'},
                    {'value' => 'features', 'class' => '_stt', 'caption' => 'Features (genes, variants, etc)'},
                    {'value' => 'bigdata',  'class' => '_stt', 'caption' => 'Data for multiple or large regions (e.g. whole chromosomes)'},
                  ];
  $datatype_fieldset->add_field({
                'label'   => 'Type of data to export',
                'type'    => 'Radiolist',
                'name'    => 'datatype',
                'values'  => $datatypes,
                });

  ## Sequence sub-form

  ## Features sub-form

  ## Big data sub-form

  return $form->render;
}

sub default_file_name {
  my $self = shift;
  my $name = $self->hub->species_defs->SPECIES_COMMON_NAME;

  my $location = $self->hub->param('r');
  if ($location) {
    $location =~ s/:|-/_/g;
    $name .= '_'.$location;
  }

  return $name;
}

1;
