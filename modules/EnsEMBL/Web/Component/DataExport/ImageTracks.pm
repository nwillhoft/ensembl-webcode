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

  my $form = $self->new_form({'id' => 'export', 'action' => $hub->url({'action' => 'Tracks',  'function' => '', '__clear' => 1}), 'method' => 'post'});

  ## We should encourage users to download zipped data if the region is large
  my $location = $hub->param('r');
  my ($region, $start, $end) = split(':|-', $location);
  my $should_zip = $end - $start > '500000' ? 1 : 0;

  ## First, the radio buttons for selection data type
  my $datatype_fieldset = $form->add_fieldset({'class' => 'form-intro'});
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

  ## Hidden fields needed for redirection to image output
  ## Just pass everything, on the assumption that the button only passes useful params
  foreach my $p ($hub->param) {
    $datatype_fieldset->add_hidden({'name' => $p, 'value' => $hub->param($p)});
  }

  ## Sequence sub-form
  my $seq_fieldset  = $form->add_fieldset({'legend' => 'Download sequence (FASTA)', 'class' => '_stt_sequence hidden'});
  $self->add_subhead($seq_fieldset, 'Region');

  $seq_fieldset->add_field({
                            'label' => 'Coordinates',
                            'type'  => 'NoEdit',
                            'name'  => 'region',
                            'value' => $hub->param('r'),
                          });

  $seq_fieldset->add_field({
                            'label' => "5' flank",
                            'type'  => 'Int',
                            'name'  => 'flank5',
                            'value' => '0',
                          });

  $seq_fieldset->add_field({
                            'label' => "3' flank",
                            'type'  => 'Int',
                            'name'  => 'flank3',
                            'value' => '0',
                          });

  $self->add_subhead($seq_fieldset, 'Output options');
  my $masking = [
                  {'value' => 'none', 'caption' => 'None'},
                  {'value' => 'soft', 'caption' => 'Repeat masked (soft)'},
                  {'value' => 'hard', 'caption' => 'Repeat masked (hard)'},
                ];
  $seq_fieldset->add_field({
                            'label'   => 'Masking',
                            'type'    => 'Dropdown',
                            'values'  => $masking,
                            'value'   => 'none',
                          });

  $seq_fieldset->add_field({
                            'label'     => 'File name',
                            'type'      => 'String',
                            'value'     => $self->default_file_name,
                            'shortnote' => '.fa',
                          });

  $seq_fieldset->add_field({
                            'label'     => 'Compressed (gzip)',
                            'name'      => 'compression',
                            'type'      => 'Checkbox',
                            'value'     => 1,
                            'selected'  => $should_zip ? 'selected' : '',
                            'shortnote' => 'We recommend zipping your file if the region is large',
                          });

  $seq_fieldset->add_button('type' => 'Submit', 'name' => 'submit', 'value' => 'Download', 'class' => 'download');

  ## Features sub-form
  my $feats_fieldset = $form->add_fieldset({'legend' => 'Download features', 'class' => 'track-list _stt_features hidden'});
  $self->add_subhead($feats_fieldset, 'Tracks to export');

  my $track_count = $self->add_active_tracks($feats_fieldset);
  if ($track_count) {
    $self->add_subhead($feats_fieldset, 'File options');

    my $formats     = []; #{'value' => '', 'caption' => '-- Choose --'}];
    my $format_info = EnsEMBL::Web::Constants::USERDATA_FORMATS;
    foreach my $key (sort keys %$format_info) {
      my $info = $format_info->{$key};
      next unless $info->{'image_export'};
      my $label = $info->{'label'};
      $label = 'GTF' if $label =~ /GTF/;
      push @$formats, {'value' => $key, 'caption' => $label};
    }

    $feats_fieldset->add_field({
                                'name'    => 'format',
                                'label'   => 'File format',
                                'type'    => 'Dropdown',
                                'values'  => $formats,
                                'value'   => 'bed',
                              });

    $feats_fieldset->add_field({
                                'name'      => 'name',
                                'label'     => 'File name',
                                'type'      => 'String',
                                'value'     => $self->default_file_name.'.bed',
                              });

    $feats_fieldset->add_field({
                                'label'     => 'Compressed (gzip)',
                                'name'      => 'compression',
                                'type'      => 'Checkbox',
                                'value'     => 1,
                                'selected'  => $should_zip ? 'selected' : '',
                                'shortnote' => 'We recommend zipping your file if the region is large',
                              });

    $feats_fieldset->add_button('type' => 'Submit', 'name' => 'submit', 'value' => 'Download', 'class' => 'download');
  }
  else {
    my $div = $feats_fieldset->append_child('div');
    $div->append_child('p', { inner_HTML => 'You do not have any exportable tracks turned on.'});
    
  }

  ## Tip for features fieldset
  my $div = $feats_fieldset->append_child({'node_name' => 'div', 'class' => 'info-box box-centred'});
  $div->append_child('p', { inner_HTML => 'Want more tracks? Add them to your image and try again.'});

  ## Big data sub-form
  my $bigdata_fieldset = $form->add_fieldset({'class' => '_stt_bigdata hidden'});

  my $ftp_base = sprintf '%s/release-%s', $hub->species_defs->ENSEMBL_FTP_URL, $hub->species_defs->ENSEMBL_VERSION;
  my $species = lc($hub->species_defs->SPECIES_URL);
  my $text = sprintf '<h2>Large datasets</h2>
<p>For <b>whole chromosome sequences</b> and <b>complete feature sets</b>, visit our <a href="%s">FTP site</a> for:</p>
<ul>
<li><a href="%s/fasta/%s">FASTA</a> sequences</li>
<li>Gene sets in <a href="%s/gtf/%s">GTF</a> or <a href="%s/gff3/%s">GFF3</a> format</li>
<li>Variants in <a href="%s/variation/vcf/%s">VCF</a> format</li>
</ul>
<p>and much more.</p>',

$ftp_base,
$ftp_base, $species,
$ftp_base, $species,
$ftp_base, $species,
$ftp_base, $species,
;

  if ($hub->species_defs->ENSEMBL_MART_ENABLED) {
    $text .= '<p>For <b>custom datasets in CSV or Excel format</b>, try <a href="/biomart/martview">BioMart</a>.</p>';
  }

  $bigdata_fieldset->add_notes({'text' => $text});

  return '<input type="hidden" class="subpanel_type" value="DataExport_ImageTracks" />'.$form->render;
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

sub add_subhead {
  my ($self, $fieldset, $text) = @_;
  my $div           = $fieldset->append_child('div');
  $div->append_child('h3', { class => 'config_header', inner_HTML => $text});
}

sub add_active_tracks {
  my ($self, $fieldset) = @_;
  my $hub = $self->hub;

  my $vc      = $hub->get_viewconfig({'component' => $hub->param('component'), 
                                      'type'      => $hub->param('data_type')});
  return unless $vc;

  my $image_config = $vc->image_config;
  my $count = 0;
  if ($image_config) {
    my $tree = $image_config->tree;

    foreach my $menu ($tree->nodes) {
      my @tracks;
      foreach my $track ($menu->leaves) {
        ## Skip tracks that are off (including matrix tracks currently set to 'default')
        next if ($track->get('display') && ($track->get('display') eq 'off' || $track->get('display') eq 'default'));
        next unless $track->get('can_export');
        push @tracks, $track;
      }

      if (scalar(@tracks)) {
        $fieldset->append_child('h4', { inner_HTML => $menu->get('caption')}); 
        foreach my $track (@tracks) {
          ## If exporting a single track via the menu, turn everything else off
          my $selected = $hub->param('track') ? 0 : 1;

          my $is_var = $menu eq 'variation' ? 1 : 0;
          my $params = {
                        'name'        => 'track_'.$track->{'id'},
                        'label'       => $track->get('caption'), 
                        'type'        => 'Checkbox',
                        'value'       => 1,
                        'class'       => $is_var ? '_var' : '',
                        'field_class' => 'track-list',
                        'no_colon'    => 1,
                        };
          $params->{'selected'} = 'selected' if $selected;
          $fieldset->add_field($params);
          $count++;
        }
      }
    }
  }

  return $count;
}

1;
