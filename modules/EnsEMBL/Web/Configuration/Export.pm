# $Id$

package EnsEMBL::Web::Configuration::Export;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub populate_tree {
  my $self = shift; 
  
  foreach ('Location', 'Gene', 'Transcript', 'LRG', 'Variation') {
    $self->create_node("Configure/$_",  '', [ 'configure',   'EnsEMBL::Web::Component::Export::Configure'  ]);
    $self->create_node("Form/$_",       '', [], { command => 'EnsEMBL::Web::Command::Export::Form'         });  # redirecting the form to the right url so that it can go to formats below
    $self->create_node("Formats/$_",    '', [ 'formats',     'EnsEMBL::Web::Component::Export::Formats'    ]);
    $self->create_node("Alignments/$_", '', [ 'alignments',  'EnsEMBL::Web::Component::Export::Alignments' ]) unless $_ eq 'Transcript';
    $self->create_node("Output/$_",     '', [ 'export',      'EnsEMBL::Web::Component::Export::Output'     ]);    
  }

  $self->create_node('HaploviewFiles/Location',      '', [], { command => 'EnsEMBL::Web::Command::Export::HaploviewFiles'      });
  $self->create_node('LDExcelFile/Location',         '', [], { command => 'EnsEMBL::Web::Command::Export::LDExcelFile'         });
  $self->create_node('LDFormats/Location',           '', [ 'ld_formats',  'EnsEMBL::Web::Component::Export::LDFormats'         ]);
  $self->create_node('PopulationFormats/Transcript', '', [ 'pop_formats', 'EnsEMBL::Web::Component::Export::PopulationFormats' ]);
}

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  
  $page->remove_body_element('tabs');
  $page->remove_body_element('navigation');
}

1;
