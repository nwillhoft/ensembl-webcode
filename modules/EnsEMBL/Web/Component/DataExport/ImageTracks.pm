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

  ## We should encourage users to download zipped data if the region is large
  my $location = $hub->param('r');
  my ($region, $start, $end) = split(':|-', $location);
  my $should_zip = $end - $start > '500000' ? 1 : 0;

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
  my $seq_fieldset = $form->add_fieldset({'legend' => 'Download sequence (FASTA)'});

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

  my $masking = [
                  {'value' => 'none', 'label' => 'None'},
                  {'value' => 'soft', 'label' => 'Repeat masked (soft)'},
                  {'value' => 'hard', 'label' => 'Repeat masked (hard)'},
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
                            'type'      => 'Checkbox',
                            'value'     => 1,
                            'selected'  => $should_zip ? 'selected' : '',
                            'shortnote' => 'We recommend zipping your file if the region is large',
                          });

  ## Features sub-form
  my $feats_fieldset = $form->add_fieldset({'legend' => 'Download features'});

  ## Big data sub-form
  my $bigdata_fieldset = $form->add_fieldset;

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
