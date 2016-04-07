#!/usr/bin/perl

# written by Orkun Karaduman (orkunkaraduman@gmail.com)



if (defined $ARGV[0])
{
  $oper = lc($ARGV[0]);
} else
{
  $oper = 'disk';
}

# give disk dmname, returns Proxmox VM name
sub get_vmname_by_id
{
  $vmname=`cat /etc/qemu-server/$_[0].conf | grep name | cut -d \: -f 2`;
  $vmname =~ s/^\s+//; #remove leading spaces
  $vmname =~ s/\s+$//; #remove trailing spaces
  return $vmname;
}

$first = 1;
print "{\n";
print "\t\"data\":[\n\n";

for (`lsblk -iblo KNAME,TYPE,MAJ:MIN,SIZE,FSTYPE`)
{
  ($disk,$type,$major,$minor,$size,$fstype) = m/^\s*(\S+)\s+(\S+)\s+([^\s:]+):([^\s:]+)\s+(\S+)\s+(\S+)?\s*$/;
  next if ($disk eq 'KNAME' && $type eq 'TYPE');
  if ('disk' eq $oper)
  {
    next if ($type ne 'disk');
  } elsif ('fs' eq $oper)
  {
    next if (not defined $fstype);
  }

#  $dmnamefile = "/sys/block/$disk/dm/name";
  $dmnamefile = "/sys/dev/block/$major:$minor/dm/name";
  $vmid= "";
  $vmname = "";
  $dmname = $disk;
  $diskdev = "/dev/$disk";

  # Find DM name
  if (-e $dmnamefile)
  {
    $dmname = `cat $dmnamefile`;
    $dmname =~ s/\n$//; #remove trailing \n
    $diskdev = "/dev/mapper/$dmname";
    # VM name and ID
    if ($dmname =~ m/^.*--([0-9]+)--.*$/)
    {
      $vmid = $1;
      $vmname = get_vmname_by_id($vmid);
    }
  }

  print "\t,\n" if not $first;
  $first = 0;

  print "\t{\n";
  print "\t\t\"{#DISK}\":\"$disk\",\n";
  print "\t\t\"{#DISKDEV}\":\"$diskdev\",\n";
  print "\t\t\"{#DMNAME}\":\"$dmname\",\n";
  print "\t\t\"{#SIZE}\":\"$size\",\n";
  print "\t\t\"{#FSTYPE}\":\"$fstype\",\n";
  print "\t\t\"{#VMNAME}\":\"$vmname\",\n";
  print "\t\t\"{#VMID}\":\"$vmid\"\n";
  print "\t}\n";
}

print "\n\t]\n";
print "}\n";
