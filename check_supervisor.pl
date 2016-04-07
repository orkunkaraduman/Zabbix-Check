#!/usr/bin/perl


$aname = $ARGV[0];

if (not defined $aname)
{
  $first = 1;
  print "{\n";
  print "\t\"data\":[\n\n";
}

for (`/usr/bin/supervisorctl status`)
{
  ($name, $status) = m/^\s*(\S+)\s+(\S+)\s+.*$/;

  if (not defined $aname)
  {
    print "\t,\n" if not $first;
    $first = 0;

    print "\t{\n";
    print "\t\t\"{#NAME}\":\"$name\"\n";
    print "\t}\n";
  } elsif ($aname eq $name)
  {
    print "$status\n";
    last;
  }
}

if (not defined $aname)
{
  print "\n\t]\n";
  print "}\n";
}
