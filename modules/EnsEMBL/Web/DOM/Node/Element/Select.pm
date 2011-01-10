package EnsEMBL::Web::DOM::Node::Element::Select;

use strict;

use base qw(EnsEMBL::Web::DOM::Node::Element);

sub node_name {
  ## @overrides
  return 'select';
}

sub form {
  ## Returns a reference to the form object that contains the input
  return shift->get_ancestor_by_tag_name('form');
}

sub selected_index {
  ## Sets or returns the index of the selected option in a dropdown list
  ## If intended to set index in a dropdown that allows multiple selections, all previous selections will be unselected before selecting the given index
  ## @param index or ArrayRef of indices to be set if intended to set selection. -1 (or any invalid index) will deselect all
  ## @return index or ArrayRef of indices of new selections
  my $self    = shift;
  my @options = $self->options;
  my $multi   = $self->multiple;

  if (@_) {
    my $indices = shift;
    $indices    = [ $indices ] if ref($indices) ne 'ARRAY';
    $indices    = [ shift @$indices ] unless $multi;
    foreach my $i (0..$#options) {
      $options[$i]->selected((grep {$_ == $i} @{$indices}) ? 1 : 0);
    }
  }
  my $indices = [];
  $options[$_]->selected and push @$indices, $_ for 0..$#options;
  return $multi ? $indices : shift @$indices;
}

sub options {
  ## Getter of all the option element objects of the select
  my $self = shift;
  
  my $options = [];
  for (@{$self->{'_child_nodes'}}) {
    push @{$options}, $_ if $_->node_name eq 'option';
    push @{$options}, @{$_->{'_child_nodes'}} if $_->node_name eq 'optgroup';
  }
  return $options;
}

sub add {
  ## Adds an option object to the select object
  ## Alias for append_child/insert_before
  my $self = shift;
  my $option = shift;
  return $self->insert_before($option, shift) if @_;
  return $self->append_child($option);
}

sub remove_option {
  ## Removes the option object(s) with given value
  ## @return ArrayRef of Option objects removed
  my ($self, $value) = shift;
  my $return = [];
  $_->get_attribute('value') eq $value and push @$return, $_->remove for @{$self->options};
  return $return;
}

sub disabled {
  ## Accessor for disabled attribute
  return shift->_access_attribute('disabled', @_);
}

sub multiple {
  ## Accessor for multiple attribute
  return shift->_access_attribute('multiple', @_);
}

sub w3c_appendable {
  ## @overrides
  my ($self, $child) = @_;
  return $child->node_name =~ /^(option|optgroup)$/ ? 1 : 0;
}

1;