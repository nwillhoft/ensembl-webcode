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

package EnsEMBL::Web::Form::ViewConfigMatrixForm;

use strict;
use warnings;

use HTML::Entities qw(encode_entities);

use parent qw(EnsEMBL::Web::Form::ViewConfigForm);

sub render {
  ## @override
  ## Ignore wrapping form tag when returning HTML
  my $self = shift;

  return $self->SUPER::render(@_) =~ s/^[^>]+>|<[^<]+$//gr;
}

sub js_panel {
  ## Panel used by JS
  return 'ConfigMatrixForm';
}

sub build {
  ## Build the html form for both image config and view config
  my ($self, $object, $image_config) = @_;

  my $hub           = $self->view_config->hub;
  my $img_url       = $self->view_config->species_defs->img_url;
  my $tree          = $image_config->tree;
  my $menu          = $hub->param('menu');

  my $menu_node     = $tree->get_node($menu);
  my $matrix_data   = $menu_node->get_data('matrix');
  
  my $html = qq(
    <div class="header_tutorial_wrapper">
      <h1>Regulation data</h1>
    </div>
    <div style="display: flex">
      <div class="track-panel">
        <div class="tabs track-menu">
          <div class="track-tab active" id="browse-tab">Browse tracks<span class="hidden content-id">browse-track</span></div>
          <div class="track-tab" id="search-tab">Search tracks<span class="hidden content-id">search-track</span></div>
          <div class="track-tab" id="config-tab">Track configuration<span class="hidden content-id">track-config</span></div>
          <div class="track-tab" id="help-tab" style="border-right: none;">Help<span class="hidden content-id">help-track</span></div>
        </div>
        
        <div id="browse-track" class="tab-content active">
        </div>

        <div id="search-track" class="tab-content">
          <p>Search tracks....</p>
        </div>
        
        <div id="track-config" class="tab-content">
          <p>Tracks configuration....</p>
        </div>      
        
        <div id="help-track" class="tab-content">
          <p>Please help.....</p>
        </div>      
      </div>
      <div class="result-box">
        <h3>Selected tracks</h3>

        <div class="filter-content">
          <h5 class="result-header">Cell type <span class="error">Please select Cell types</span></h5>
          <div class="result-content" id="cell">
            <ul class="result-list">
              <span class="hidden lhsection-id">cell-type-content</span>
            </ul>
          </div>

          <h5 class="result-header">Experimental data <span class="error">Please select Experimental data</span></h5>
          <div class="result-content" id="experiment">
            <ul class="result-list">
              <span class="hidden lhsection-id">experiment-type-content</span>
            </ul>
          </div>

          <h5 class="result-header">Source</h5>
          <div class="result-content" id="source">
            <ul class="result-list">
              <span class="hidden lhsection-id">source-content</span>
            </ul>
          </div>
        </div>

        <div class="bottom-buttons">
          <span class="fancy-checkbox inactive"></span><text class="save-config">Save configuration</text>
          <button class="filter">Configure track display</button>
        </div>

      </div>
    </div>
  );

  $self->append_child('div', { inner_HTML => $html, class => 'js_panel config_matrix_form', id => "matrix_form" });
}

1;