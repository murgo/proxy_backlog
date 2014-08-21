# this script is still experimental, don't expect it to work as expected :)
use Irssi;
use Irssi::TextUI;

$VERSION = "0.0.1";
%IRSSI = (
  authors         => "Wouter Coekaets, Lauri Härsilä",
  contact         => "coekie@irssi.org, murgo@iki.fi",
  name            => "proxy_backlog",
  url             => "https://github.com/murgo/proxy_backlog",
  description     => "sends backlog from irssi to clients connecting to irssiproxy",
  license         => "GPL",
  changed         => "2014-08-21"
);

sub sendbacklog {
  my ($server) = @_;
  Irssi::print("Sending backlog to proxy client for " . $server->{'tag'});
  Irssi::signal_add_first('print text', 'stop_sig');
  Irssi::signal_emit('server incoming', $server,':proxy NOTICE * :Sending backlog');
  foreach my $channel ($server->channels) {
    my $window = $server->window_find_item($channel->{'name'});
    for (my $line = $window->view->get_lines; defined($line); $line = $line->next) {
      my $text = $line->get_text(0);
      if ($text =~ /----/) { next; }
      Irssi::signal_emit('server incoming', $server,':proxy NOTICE ' . $channel->{'name'} .' :' . $text);
    }
  }
  Irssi::signal_emit('server incoming', $server,':proxy NOTICE * :End of backlog');
  Irssi::signal_remove('print text', 'stop_sig');
}

sub stop_sig {
  Irssi::signal_stop();
}

Irssi::signal_add('message irc own_ctcp', sub {
  my ($server, $cmd, $data, $target) = @_;
  print ("cmd:$cmd data:$data target:$target");
  if ($cmd eq 'IRSSIPROXY' && $data eq 'BACKLOG SEND' && $target eq '-proxy-') {
    sendbacklog($server);
  }
});

Irssi::signal_add('proxy client connected', sub {
  my ($client) = @_;
  Irssi::timeout_add_once(2000, \&sendbacklog, $client->{server});
});
