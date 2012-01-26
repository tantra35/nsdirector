use Data::Dumper;

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub parse_backets_str_parse_block_params($)
{
	my $block_params = shift;
	my $retval = {};

	foreach my $l_param_str(split(/\s*\,\s*/, $block_params))
	{
		if ($l_param_str =~ /\:/)
		{
			my($l_pname, $l_pvalue) = split(/\s*\:\s*/, $l_param_str, 2);
			$retval->{$l_pname} = $l_pvalue;
		}
		else
		{
			my $l_pname = $l_param_str;
			$retval->{$l_pname} = 1;
		};
	};
	
	return $retval;
};

sub parse_backets_str($)
{
	my $line = shift;
	my $retval = undef;

	my $l_retval = {};
	my $l_line = ltrim($line);
	my $l_parse_error = 0;

  while (length($l_line))
  {
  	if($l_line =~ /(^([a-z]+)\s*\{([^\{\}]*)\})/)
  	{
  		my $l_block_name = uc($2);
  		my $l_block_params = parse_backets_str_parse_block_params($3);

    	$l_retval->{$l_block_name} = $l_block_params;
  		$l_line = ltrim(substr($l_line, length($1)));
  	}
  	else
  	{
  		$l_parse_error = 1;
  		last;
  	};
  };

  if(!$l_parse_error)
  {
	  $retval = $l_retval;
  };
	  
  return $retval;
};

my $line = "  usa{latitude: -73.68, longtitude:40} eur{latitude:10.68, longtitude:40, default}";
my $l_backets = parse_backets_str($line);

$l_backets or die("12");

