package EnsEMBL::Web::Component::UserData::SelectRemote;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::UserData);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  
  my $current_species = $object->species_path($object->data_species);
  my $form = $self->modal_form('select_url', "$current_species/UserData/AttachRemote", {'wizard' => 1, 'back_button' => 0});
  my $user = $object->user;
  my $sitename = $object->species_defs->ENSEMBL_SITETYPE;

  # URL-based section
  my @attachable = @{$object->species_defs->USERDATA_FILE_FORMATS};
  push @attachable, @{$object->species_defs->USERDATA_REMOTE_FORMATS};
  my @all_formats = sort {lc($a) cmp lc($b)} @attachable;
  my $formats = join(', ', @all_formats);

  $form->add_notes({
    'heading' => 'Tip',
    'text'    => qq(
                    Accessing data via a URL can be slow unless you use an indexed format such as BAM. However it has the advantage that you always see the same data as the file on your own machine.<br /><br />
                    We currently accept attachment of the following formats: $formats.
                    VCF files must be indexed prior to attachment.)
  });

  $form->add_field([{
    'type'      => 'url',
    'name'      => 'url',
    'label'     => 'File URL',
    'size'      => '30',
    'value'     => $object->param('url') || '',
    'notes'     => '( e.g. http://www.example.com/MyProject/mydata.gff )'
  }, {
    'type'      => 'dropdown',
    'name'      => 'format',
    'label'     => "Data format",
    'values'    => [{'caption' => '-- Choose --', 'value' => ''}, map {{'caption' => $_, 'value' => uc $_}} @all_formats ],
    'select'    => 'select',
    'disabled'  => scalar @all_formats ? 0 : 1,
  }, {
    'type'      => 'string',
    'name'      => 'name',
    'label'     => 'Name for this track',
    'size'      => '30',
  }, $user && $user->id ? {
    'type'      => 'checkbox',
    'name'      => 'save',
    'label'     => 'Save URL to my account',
    'notes'     => 'N.B. Only the file address will be saved, not the data itself',
  } : ()]);

  return $form->render;
}

1;
