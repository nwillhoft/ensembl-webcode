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

package EnsEMBL::Web::File::User;

use strict;

use Archive::Tar;

use EnsEMBL::Web::Constants;
use EnsEMBL::Web::IOWrapper;

use parent qw(EnsEMBL::Web::File);

### Replacement for EnsEMBL::Web::TmpFile::Text, specifically for
### content generated by the user, either uploaded to the website
### or generated deliberately via a tool or export interface

### Path structure: /base_dir/YYYY-MM-DD/user_identifier/XXXXXXXXXXXXXXX_filename.ext

sub new {
### @constructor
  my ($class, %args) = @_;

  $args{'output_drivers'} = ['IO']; ## Always write to disk
  return $class->SUPER::new(%args);
}

sub set_category {
### Set the category of file: typically either temporary or persistent
  my ($self, $category) = @_;

  unless ($category) {
    $category = $self->hub->user ? 'persistent' : 'temporary';
  }

  $self->{'category'} = $category;
  return $self->{'category'};
}

### Wrappers around E::W::File::Utils::IO methods

sub preview {
### Get n lines of a file, e.g. for a web preview
### @param Integer - number of lines required (default is 10)
### @return Arrayref (n lines of file)
  my ($self, $limit) = @_;
  my $result = {};

  foreach (@{$self->{'output_drivers'}}) {
    my $method = 'EnsEMBL::Web::File::Utils::'.$_.'::preview_file';
    my $args = {
                'hub'     => $self->hub,
                'nice'    => 1,
                'limit'   => $limit,
                };

    eval {
      no strict 'refs';
      $result = &$method($self, $args);
    };
    last unless $result->{'error'};
  }
  return $result;
}

sub write_line {
### Write (append) a single line to a file
### @param String
### @return Hashref
  my ($self, $line) = @_;

  my $result = {};

  foreach (@{$self->{'output_drivers'}}) {
    my $method = 'EnsEMBL::Web::File::Utils::'.$_.'::append_lines';
    my $args = {
                'hub'     => $self->hub,
                'nice'    => 1,
                'lines'   => [$line],
                };

    eval {
      no strict 'refs';
      $result = &$method($self, $args);
    };
    last unless $result->{'error'};
  }
  return $result;
}

sub upload {
### Upload data from a form and save it to a file
  my ($self, %args) = @_;
  my $hub       = $self->hub;

  ## Always get from absolute input path
  $self->{'absolute'} = 1;

  my ($method)  = $args{'method'} || grep $hub->param($_), qw(file url text);
  my $path      = $self->read_location || $hub->param($method);
  my $type      = $args{'type'};

  ## Need the filename (for handling zipped files)
  my @orig_path = split '/', $path;
  my $filename  = $orig_path[-1];
  my $name      = $args{'name'} || $hub->param('name');
  my $f_param   = $hub->param('format');
  my ($error, $format, $full_ext);

  ## Give the track a default name
  unless ($name) {
    if ($method eq 'text') {
      $name = 'Data';
    } else {
      $name = $filename;
    }
  }
  $args{'name'} = $name;

  ## Some uploads shouldn't be viewable as tracks, e.g. assembly converter input
  my $no_attach = $type eq 'no_attach' ? 1 : 0;

  ## Has the user specified a format?
  $format = $f_param || $args{'format'};

  ## Get the compression algorithm, based on the file extension
  ## and, if necessary, try to guess the format from the extension
  if ($method ne 'text') {
    my @parts = split('\.', $filename);
    my $last  = $parts[-1];
    my $extension;
    if ($last =~ /(gz|zip|bz)/i) {
      $args{'compression'}  = lc $1;
      $extension            = $parts[-2];
      ## Save files in uncompressed form
      $args{'uncompress'} = 1;
    }
    else {
      $extension = $last;
    }
    $args{'extension'} = $extension;
    ## Always check compression for file-based data, because users make mistakes!
    $args{'check_compression'} = 1;

    ## This block is unlikely to be called, as the interface _should_ pass a format
    if (!$format) {
      my $format_info = $hub->species_defs->multi_val('DATA_FORMAT_INFO');

      foreach (@{$hub->species_defs->multi_val('UPLOAD_FILE_FORMATS')}) {
        $format = uc $extension if $format_info->{lc($_)}{'ext'} =~ /$extension/i;
      }
    }
  }

  $args{'format'}         = $format; 
  $args{'timestamp_name'} = 1;

  my $url;
  if ($method eq 'url') {
    $url            = $self->read_location || $hub->param('url');
    $args{'file'}   = $url;
    $args{'upload'} = 'url';
  }
  elsif ($method eq 'text') {
    ## Get content straight from CGI, since there's no input file
    my $text = $hub->param('text');
    if ($type eq 'coords') {
      $text =~ s/\s/\n/g;
    }
    $args{'content'} = $text;
  }
  else {
    $args{'file'}   = $hub->input->tmpFileName($hub->param($method));
    $args{'upload'} = 'cgi';
  }

  ## Now we know where the data is coming from, initialise the object and read the data
  $self->init(%args);
  my $result = $self->read;

  ## Add upload to session
  if ($result->{'error'}) {
    $error = $result->{'error'}[0];
  }
  else {
    ## Append an extra newline to the content, because the parser expects
    ## all lines to end in a newline character, including the last
    my $response = $self->write($result->{'content'}."\n");

    if ($response->{'success'}) {

      ## Now validate it using the appropriate parser - 
      ## note that we have to do this after upload, otherwise we can't validate pasted data
      my $iow = EnsEMBL::Web::IOWrapper::open($self, 'hub' => $hub);
      $error = $iow->validate if $iow;

      if ($error) {
        ## If something went wrong, delete the upload
        my $deletion = $self->delete;
        warn '!!! ERROR DELETING UPLOAD: '.$deletion->{'error'}[0] if $deletion->{'error'};
      }
      else {
        my $session = $hub->session;
        my $user    = $hub->user;
        my $md5     = $self->md5($result->{'content'});
        my $code    = join '_', $md5, $session->session_id;
        my $format  = $self->get_format || $hub->param('format');
        my %inputs  = map $_->[1] ? @$_ : (), map [ $_, $hub->param($_) ], qw(filetype ftype style assembly nonpositional assembly);

        $inputs{'format'}    = $format if $format;
        my $species = $hub->param('species') || $hub->species;

        ## Extra renderers for fancy formats
        my $custom = $args{'renderer'}; 
        if ($custom) {
          my $lookup = EnsEMBL::Web::Constants::RENDERERS;
          my $renderers = $lookup->{$custom}{'renderers'} || [];
          if (scalar @$renderers) {
            $inputs{'renderers'}  = ['off', 'Off', @$renderers];
            $inputs{'display'}    = $lookup->{$custom}{'default'};
          }
        }

        ## Attach data species to session
        ## N.B. Use 'write' locations, since uploads are read from the
        ## system's CGI directory
        my $record = {
                      type      => 'upload',
                      file      => $self->write_location,
                      url       => $url || '',
                      filesize  => length($result->{'content'}),
                      code      => $code,
                      md5       => $md5,
                      name      => $args{'name'},
                      species   => $species,
                      format    => $format,
                      no_attach => $no_attach,
                      timestamp => time,
                      assembly  => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
                      site      => $hub->species_defs->ENSEMBL_SERVERNAME,
                      %inputs
                     };

        my $data;
        if ($user) {
          $data = $user->add_to_uploads($record);
        }
        else {
          $data = $session->add_data(%$record);
        }

        $session->configure_user_data('upload', $data);
        ## Store the session code so we can access it later
        $self->{'code'} = $code;
      }
    }
    else {
      $error = $response->{'error'}[0];
    }
  }
  return $error;
}

sub write_tarball {
### Write an array of file contents to disk as a tarball
### N.B. Unlike other methods, this does not use the drivers
### TODO - this method has not been tested!
### @param content ArrayRef
### @param use_short_names Boolean
### @return HashRef
  my ($self, $content, $use_short_names) = @_;
  my $result = {};

  my $tar = Archive::Tar->new;
  foreach (@$content) {
    $tar->add_data(
      ($use_short_names ? $_->{'shortname'} : $_->{'filename'}), 
      $_->{'content'},
    );
  }

  my %compression_flags = (
                          'gz' => 'COMPRESS_GZIP',
                          'bz' => 'COMPRESS_BZIP',
                          );


  $tar->write($self->file_name, $compression_flags{$self->compression}, $self->base_path);

  return $result;
}

sub build_tracks_from_file {
### Parse a file and convert data into drawable objects
  my $self = shift;
  my $tracks = {};

  my $class = 'EnsEMBL::Web::IOWrapper::'.uc($self->format);
  if (EnsEMBL::Root::dynamic_use($class)) {
    my $wrapper = $class->new($self);
    my $parser = $wrapper->parser;
    while ($parser->next) {
      my $key = $parser->get_metadata_value('name') || 'default';
      if ($parser->is_metadata) {
        $tracks->{$key}{'config'}{'description'} = $parser->get_metadata_value('description') unless $tracks->{$key}{'config'}{'description'};
      }
      else {
        my $feature_array = $tracks->{$key}{'features'} || [];

        ## Create feature
        my $feature = $wrapper->get_hash;
        next unless keys %$feature;

        ## Add to track hash
        push @$feature_array, $feature;
        $tracks->{$key}{'features'} = $feature_array unless $tracks->{$key}{'features'};
      }
    }
  }
  return $tracks;
}
1;

