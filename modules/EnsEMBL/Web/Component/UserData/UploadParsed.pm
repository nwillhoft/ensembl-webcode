# $Id$

package EnsEMBL::Web::Component::UserData::UploadParsed;

use strict;

use EnsEMBL::Web::Text::FeatureParser;
use EnsEMBL::Web::TmpFile::Text;
use EnsEMBL::Web::Tools::Misc qw(get_url_content);

use base qw(EnsEMBL::Web::Component::UserData);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $hub  = $self->hub;
  my $url  = $self->ajax_url('ajax', 1) . ';r=' . $hub->referer->{'params'}->{'r'}[0] 
                . ';code=' .  $hub->param('code') . ';type=' . $hub->param('type')
                . ';update_panel=1';

  return qq{<div class="ajax"><input type="hidden" class="ajax_load" value="$url" /></div><div class="modal_reload"></div>};
}

sub content_ajax {
  my $self    = shift;
  my $hub     = $self->hub;
  my $session = $hub->session;
  my $type = $hub->param('type') || 'upload';
  my $data  = $session->get_data('type' => $type, 'code' => $hub->param('code'));
  
  my $parser  = new EnsEMBL::Web::Text::FeatureParser($hub->species_defs, $hub->param('r'));
  my $html;
  
  if ($data) {
    my $size = int($data->{'filesize'} / (1024 ** 2));
    
    if ($size > 10) {
      $html .= "<p>Your uncompressed file is over $size MB, which may be very slow to parse and load. Please consider uploading a smaller dataset.</p>";
    } else {
      my $content;

      if ($type eq 'url') {
        my $response = get_url_content($data->{'url'});
        $content = $response->{'content'};
      }
      elsif ($type eq 'upload') {
        my $file = new EnsEMBL::Web::TmpFile::Text(filename => $data->{'filename'}, extension => $data->{'extension'});
        $content = $file->retrieve;
      }

      if ($content) {      
        $parser->parse($content, $data->{'format'});
      
        $data->{'format'}  = $parser->format unless $data->{'format'};
        $data->{'style'}   = $parser->style;
        $data->{'nearest'} = $parser->nearest;
        warn '>>> STYLE '.$data->{'style'};
      
        $session->set_data(%$data);
      
        $html .= sprintf '<p class="space-below"><strong>Total features found</strong>: %s</p>', $parser->feature_count;
      
        if ($parser->nearest) {
          $html .= sprintf '<p class="space-below"><strong>Go to %s region with data</strong>: ', $hub->referer->{'params'}{'r'} ? 'nearest' : 'first';
          $html .= sprintf '<a href="%s/Location/View?r=%s">%s</a></p>', $hub->species_path($data->{'species'}), $parser->nearest, $parser->nearest;
          $html .= '<p class="space-below">or</p>';
        }
      }
      
      $html .= '<p>Close this window to return to current page</p>';
    }
  }

  return $html;
}

1;
