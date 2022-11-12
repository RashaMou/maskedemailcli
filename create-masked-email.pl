use strict;
use warnings;
use 5.36.0;
use feature qw(say);
use Data::Dumper::Concise;
use Path::Tiny;
use TOML::Parser;
use LWP::UserAgent;
use JSON::MaybeXS qw(encode_json decode_json);

# get OAuth token from config file
my $configfile = $ENV{MASKED_EMAIL_CONFIG} // '~/.maskedemailcli';
my $path = Path::Tiny::path($configfile);
my $config = TOML::Parser->new->parse($path->slurp);
my $api_token = $config->{jmap_token};

# initialize LWP
my $lwp = LWP::UserAgent->new;
$lwp->default_header(Content_Type => "application/json");
$lwp->default_header(Authorization => "Bearer $api_token");

# get session object
sub get_session {
  my $auth_url = "https://api.fastmail.com/.well-known/jmap";
  my $res = $lwp->get($auth_url);
  if ($res->is_success) {
    return decode_json($res->{_content});
  }
  return $res->status_line;
}

# make masked email create call
sub create_masked_email {
  my $session = get_session;
	my $api_url = $session->{apiUrl};
	my $account_id = $session->{primaryAccounts}->{"https://www.fastmail.com/dev/maskedemail"};

  my $res = $lwp->post(
		$api_url,
		Content_Type => "application/json".
		Authorization => "Bearer $api_token",
		Content => encode_json({
			using => [ "urn:ietf:params:jmap:core", "https://www.fastmail.com/dev/maskedemail" ],
			methodCalls => [
      	[ 'MaskedEmail/set',
        		{
          		accountId => $account_id,
          		create => {
								maskedEmail => {
									description => "thinger",
									state => "enabled",
								}
							}
        		},
        	'a',
      	],
    	],
  	}),
	);

	if ($res->is_success) {
		say Dumper $res->decoded_content;
	} else {
		say "NOP";
		say decode_json($res);
	};
}

create_masked_email;

