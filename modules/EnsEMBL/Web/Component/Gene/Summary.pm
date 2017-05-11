=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::Summary;

use strict;
use warnings;
no warnings 'uninitialized';

use HTML::Entities qw(encode_entities);
use EnsEMBL::Web::Utils::FormatText qw(helptip);

use base qw(EnsEMBL::Web::Component::Gene);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

# status warnings/hints would be eg out-of-date page, dubious evidence, etc
# which need to be displayed prominently at the top of a page. Only used
# in Vega plugin at the moment, but probably more widely useful.
sub status_warnings { return undef; }
sub status_hints    { return undef; }

sub content {
  my $self = shift;
  my $object = $self->object;
  
  return sprintf '<p>%s</p>', encode_entities($object->Obj->description) if $object->Obj->isa('Bio::EnsEMBL::Compara::Family'); # Grab the description of the object
  return sprintf '<p>%s</p>', 'This identifier is not in the current EnsEMBL database' if $object->Obj->isa('Bio::EnsEMBL::ArchiveStableId');

  my $html = "";

  $html .= $self->status_box;
 
  my @warnings = $self->status_warnings;
  if(@warnings>1 and $warnings[0] and $warnings[1]) {
    $html .= $self->_info_panel($warnings[2]||'warning',
                                $warnings[0],$warnings[1]);
  }
  my @hints = $self->status_hints;
  if(@hints>1 and $hints[0] and $hints[1]) {
    $html .= $self->_hint($hints[2],$hints[0],$hints[1]);
  }
  
  $html .= $self->transcript_table;

  return $html;
}

sub status_box {
  my $self = shift;
  my $html;

  my $obj   = $self->object->Obj;
  my $dxr   = $obj->can('display_xref') ? $obj->display_xref : undef;
  my $label = $dxr ? $dxr->display_id : $obj->stable_id;

  my ($text, $class, $url);
  if ($self->hub->param('open')) {
    $text = 'Hide details';
    $url = $self->hub->url;
  }
  else {
    $text = 'More...';
    $url = $self->hub->url({'open' => 1});
    $class = ' class="hide"';
  }

  my $padding = '&nbsp;' x 20;
  my $star = helptip('<img src="/img/star_disabled.png" />', 'Favourite this gene', 'plain');
  my $bell = helptip('<img src="/img/bell_disabled.png" />', 'Notify me of changes to this gene', 'plain');

  $html = qq(<div class="round-box info-box unbordered float-right">
<h3>What's New in Gene $label $padding $star $bell</h3> 
<p><b>Last updated</b>: Release 88 (March 2017)</p>
<p style="text-align:right"><a href="$url">$text</a></p>
  <div$class>
  <p><img src="/img/bullet_add.png" style="padding-right:8px;vertical-align:middle" /><b>New transcript</b></p>
  <p style="padding-left:24px">$label-013 (Nonsense-mediated decay)</p>
  <p><img src="/img/bullet_remove.png" style="padding-right:8px;vertical-align:middle" /><b>Retired transcript</b></p>
  <p style="padding-left:24px">$label-005 (Protein-coding)</p>
  <p style="text-align:right"><span class="button">View history</span></p>

    
  </div>
</div>);

  return $html;

}

1;
