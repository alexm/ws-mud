package WSMud::Player;

sub new
{
  my $class = shift;
  my $self = {
    name        => shift,
    world       => shift,
    connection  => shift,
  };
  
  bless $self, $class;   
   
  $self->{world}->join($self) == 0 ?
    $self->init_connection:  
    $self->emergency_exit("This user is active, please choose another one."); 
  
  return $self;
}

sub init_connection
{
  my $self        = shift;
  # For closure purposes.
  my $player      = $self;
  
  $self->{connection}->on(message =>
    sub {$player->do_action($_[1])}
  );

  $self->{connection}->on(finish =>
    sub {$player->exit}
  );
}

sub notify
{ 
  my ($self, %attrs) = @_;

  my $notification = WSMud::Notification->new(%attrs);
  $self->{connection}->send($notification->encode);
}


sub do_action
{
  my $self    = shift;  
  my $msg     = shift;      
  
  $self->{world}->notify(tpye => 'message', text => "$self->{name} says: $msg");
  $self->notify(tpye => 'message', text => "You say: $msg");    
}

sub emergency_exit
{
  my $self = shift;
  my $text = shift;
  
  $self->notify(tpye => 'message', text => $text);
  $self->{connection}->on(finish => sub {return 0});
  $self->{connection}->finish;
}

sub exit
{
  my $self = shift;
  
  $self->notify(tpye => 'message', text => "Goodbye");
  $self->{world}->left($self);   
  $self->{connection}->finish;
}

1;
