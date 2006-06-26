package EnsEMBL::Web::Factory::Feature;
                                                                                   
use strict;
use warnings;
no warnings "uninitialized";
                                                                                   
use EnsEMBL::Web::Factory;
use EnsEMBL::Web::Proxy::Object;
                                                                                   
our @ISA = qw(  EnsEMBL::Web::Factory );

sub createObjects { 
  my $self   = shift;
  my $db        = $self->param('db')  || 'core';
  my ($identifier, $fetch_call, $featureobj, $dataobject);

  ## Are we inputting IDs or searching on a text term?
  if ($self->param('xref_term')) {
    my @exdb = $self->param('xref_db');
    $featureobj = $self->search_Xref($db, \@exdb, $self->param('xref_term'));

    $dataobject    = EnsEMBL::Web::Proxy::Object->new( 'Feature', $featureobj, $self->__data );

    if( $dataobject ) {
      $dataobject->feature_type( 'Xref' );
      $self->DataObjects( $dataobject );
    }
  }
  else {
    my $feature_type  = $self->param('type') || 'OligoProbe';
    $feature_type = 'OligoProbe' if $feature_type eq 'AffyProbe'; ## catch old links

    ## deal with xrefs
    my $subtype;
    if ($feature_type =~ /^Xref_/) {
      ## Don't use split here - external DB name may include underscores!
      ($subtype = $feature_type) =~ s/Xref_//; 
      $feature_type = 'Xref';
    }

    my $create_method = "create_$feature_type";
    $featureobj    = defined &$create_method ? $self->$create_method($db, $subtype) : undef;

    $dataobject    = EnsEMBL::Web::Proxy::Object->new( 'Feature', $featureobj, $self->__data );

    if( $dataobject ) {
      $dataobject->feature_type( $feature_type );
      $dataobject->feature_id( $self->param( 'id' ));
      $self->DataObjects( $dataobject );
    }
  }
  
}

#---------------------------------------------------------------------------

sub create_OligoProbe {
    # get Oligo hits plus corresponding genes
    my $probe = $_[0]->_generic_create( 'OligoProbe', 'fetch_all_by_probeset', $_[1] );
    my $probe_genes = $_[0]->_generic_create( 'Gene', 'fetch_all_by_external_name', $_[1],undef, 'no_errors' );
    my %features = ('OligoProbe' => $probe);
    $features{'Gene'} = $probe_genes if $probe_genes;
    return \%features;
}

sub create_DnaAlignFeature {
  return {'DnaAlignFeature' => $_[0]->_generic_create( 'DnaAlignFeature', 'fetch_all_by_hit_name', $_[1] ) }; 
}

sub create_ProteinAlignFeature {
  return {'ProteinAlignFeature' => $_[0]->_generic_create( 'ProteinAlignFeature', 'fetch_all_by_hit_name', $_[1] ) };
}

sub create_Gene {
  return {'Gene' => $_[0]->_generic_create( 'Gene', 'fetch_all_by_external_name', $_[1] ) }; 
}

# For a Regulatory Factor ID display all the RegulatoryFeatures
sub create_RegulatoryFactor {
  my ( $self, $db, $id ) = @_;
  $id ||= $self->param( 'id' );

  my $db_adaptor  = $self->database(lc($db));
  unless( $db_adaptor ){
    $self->problem( 'Fatal', 'Database Error', "Could not connect to the $db database." );
    return undef;
  }
  my $reg_feature_adaptor = $db_adaptor->get_RegulatoryFeatureAdaptor;
  my $reg_factor_adaptor = $db_adaptor->get_RegulatoryFactorAdaptor;

  my $features = [];
  foreach my $fid ( ($id=~/\s/?$id:()), split /\s+/, $id ) {
    my $t_features;
    eval {
      $t_features = $reg_feature_adaptor->fetch_all_by_factor_name($fid);
    };
     if( $t_features ) {
      foreach( @$t_features ) { $_->{'_id_'} = $fid; }
      push @$features, @$t_features;
    }
  }
  my $feature_set = {'RegulatoryFactor' => $features};
  return $feature_set;

  return $features if $features && @$features; # Return if we have at least one feature
  # We have no features so return an error....
  $self->problem( 'no_match', 'Invalid Identifier', "Regulatory Factor $id was not found" );
  return undef;
}


sub _generic_create {
  my( $self, $object_type, $accessor, $db, $id, $flag ) = @_;
  $db ||= 'core';
                                                                                   
  $id ||= $self->param( 'id' );

  ## deal with xrefs
  my $xref_db;
  if ($object_type eq 'DBEntry') {
    my @A = @$db;
    $db = $A[0];
    $xref_db = $A[1];
  }

  if( !$id ) {
    return undef; # return empty object if no id
  }
  else {
    # Get the 'central' database (core, est, vega)
    my $db_adaptor  = $self->database(lc($db));
    unless( $db_adaptor ){
      $self->problem( 'Fatal', 'Database Error', "Could not connect to the $db database." );
      return undef;
    }
    my $adaptor_name = "get_${object_type}Adaptor";
    my $features = [];
    foreach my $fid ( ($id=~/\s/?$id:()), split /\s+/, $id ) {
      my $t_features;
      if ($xref_db) {
        eval {
         $t_features = [$db_adaptor->$adaptor_name->$accessor($xref_db, $fid)];
        };
      }
      else {
        eval {
         $t_features = $db_adaptor->$adaptor_name->$accessor($fid);
        };
      }
      ## if no result, check for unmapped features
      if ($t_features && ref($t_features) eq 'ARRAY' && !@$t_features) {
        my $uoa = $db_adaptor->get_UnmappedObjectAdaptor;
        $t_features = $uoa->fetch_by_identifier($fid);
      }

      if( $t_features && ref($t_features) eq 'ARRAY') {
        foreach my $f (@$t_features) { 
          $f->{'_id_'} = $fid;
        }
        push @$features, @$t_features;
      }
    }
                                                                                   
    return $features if $features && @$features; # Return if we have at least one feature

    # We have no features so return an error....
    unless ( $flag eq 'no_errors' ) {
      $self->problem( 'no_match', 'Invalid Identifier', "$object_type $id was not found" );
    }
    return undef;
  }

}

sub create_Xref {

  # get OMIM hits plus corresponding Ensembl genes
  my ($self, $db, $subtype) = @_;
  my $t_features = [];
  my ($xrefarray, $genes);

  if ($subtype eq 'MIM') {
    my $mim_g = $self->_generic_create( 'DBEntry', 'fetch_by_db_accession', [$db, 'MIM_GENE'] );
    my $mim_m = $self->_generic_create( 'DBEntry', 'fetch_by_db_accession', [$db, 'MIM_MORBID'] );
    push(@$t_features, @$mim_g) if $mim_g;  
    push(@$t_features, @$mim_m) if $mim_m;  
  }
  else {
    $t_features = $self->_generic_create( 'DBEntry', 'fetch_by_db_accession', [$db, $subtype] );
  }
  if( $t_features && ref($t_features) eq 'ARRAY') {
    ($xrefarray, $genes) = $self->create_XrefArray($t_features, $db);
  }

  my $features = {'Xref'=>$xrefarray};
  $$features{'Gene'} = $genes if $genes;
  return $features;
}

sub search_Xref {
  my ($self, $db, $exdb, $string, $flag) = @_;

  my $db_adaptor  = $self->database(lc($db));
  unless( $db_adaptor ){
    $self->problem( 'Fatal', 'Database Error', "Could not connect to the $db database." );
    return undef;
  }

  my @xref_dbs = @$exdb;
  my ($features, $total_features, $genes);
  foreach my $x (@xref_dbs) {
    my $t_features;
    eval {
     $t_features = $db_adaptor->get_DBEntryAdaptor->fetch_all_by_description('%'.$string.'%', $x);
    };
    if( $t_features && ref($t_features) eq 'ARRAY') {
      push @$total_features, @$t_features;
    }
  }
  ($features, $genes) = $self->create_XrefArray($total_features, $db);

  if ($features && @$features) { ## Return if we have at least one feature
    my %results = ('Xref'=>$features);
    $results{'Gene'} = $genes if $genes;
    return \%results; 
  }

  # We have no features so return an error....
  unless ( $flag eq 'no_errors' ) {
    $self->problem( 'no_match', 'No Match', "No features could be found matching the search term '$string'" );
  }
  return undef;
}

sub create_XrefArray {
  my ($self, $t_features, $db) = @_;
  my (@features, @genes);

  foreach my $t (@$t_features) {
    ## we need to keep each xref and its matching genes together
    my @matches;
    push @matches, $t;
    ## get genes for each xref
    warn "... ",$t;
    my $id = $t->primary_id; 
    my $t_genes = $self->_generic_create( 'Gene', 'fetch_all_by_external_name', $db, $id, 'no_errors' );
    if ($t_genes && @$t_genes) {
      push (@matches, @$t_genes);
      push (@genes, @$t_genes);
    }
    push @features, \@matches;
  }

  return (\@features, \@genes);
}

1;

