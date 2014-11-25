package EnsEMBL::Web::Tools::RemoteURL;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(chase_redirects);

use LWP::UserAgent;

sub chase_redirects {
  my ($self,$url,$max_follow) = @_;

  $max_follow = 10 unless defined $max_follow;
  my $ua = LWP::UserAgent->new( max_redirect => $max_follow );
  $ua->timeout(10);
  $ua->proxy([qw(http https)], $self->{'hub'}->species_defs->ENSEMBL_WWW_PROXY) if $self->{'hub'}->species_defs->ENSEMBL_WWW_PROXY;

  my $response = $ua->head($url);
  if ($response->is_success) {
    return $response->request->uri->as_string;
  }
  else {
    return {'error' => $response->{'error'} || 'SERVER ERROR: '.$response->status_line};
  }
}

1;

