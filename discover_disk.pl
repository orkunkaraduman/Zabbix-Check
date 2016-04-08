#! /usr/bin/perl

=Copyright
    Copyright (C) 2016  Orkun Karaduman <orkunkaraduman@gmail.com>
=GPLv3
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

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
