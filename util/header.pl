#!/usr/bin/perl


my @fields = qw( ts te td sa da sp dp pr flg fwd stos ipkt ibyt opkt obyt in out sas das smk dmk dtos dir nh nhb svln dvln ismc odmc idmc osmc mpls1 mpls2 mpls3 mpls4 mpls5 mpls6 mpls7 mpls8 mpls9 mpls10 ra eng bps pps bpp );

print "nfdump option: \n";
print '%' . join(',%', @fields);
#print '%' . join(' %', @fields);
print "\n";

print "csv/perl split statement:\n";
print join (',', @fields);

print "perl variables:\n";
print '$' . join (',$', @fields);
print "\n";
