package Flash::FLAP::Sql::MysqlRecordSet;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the AMF-PHP project (http://amfphp.sourceforge.net/)

=head1 NAME
    Flash::FLAP::Sql;:MysqlRecordSet
    Translated from PHP Remoting v. 0.5b from the -PHP project.        
        
==head1 DESCRIPTION    

    Encode the information returned by a Mysql query into the AMF RecordSet format.
    
==head1 CHANGES
Sun May 11 18:22:33 EDT 2003
Since Serializer now supports generic AMFObjects, made sure we conform.
We need to have the _explicitType attribute...

Sun Apr  6 14:24:00 2003
Created after AMF-PHP, but something is not working yet...
	
=cut

use strict;
use Flash::FLAP::Util::Object;

sub new
{
	my ($proto, $dbh) = @_;
	my $self = {};
	bless $self, $proto;
	$self->dbh($dbh);
	return $self;
}

sub dbh
{
    my ($self, $val) = @_;
    $self->{dbh} = $val if $val;
    return $self->{dbh};
}

sub query
{
    my ($self, $queryText) = @_;

    my $result = new Flash::FLAP::Util::Object;
    # create the serverInfo array
    $result->{"serverInfo"} = {};

	my $sth = $self->dbh->prepare($queryText);
    $sth->execute();

# create an initialData array
    my (@initialData, @columnNames);
    $result->{serverInfo}->{initialData} = \@initialData;
    $result->{serverInfo}->{columnNames} = \@columnNames;
    $result->{serverInfo}->{totalCount}=$sth->rows();

	push @columnNames, @{$sth->{NAME}};

    # grab all of the rows
	# There is a reason arrayref is not used - if it is, 
	#the pointer is reused and only the last element gets added, though many times.
    while (my @array = $sth->fetchrow_array) 
    {
        # add each row to the initial data array
        push @initialData, \@array;
    }	

    # create the id field --> i think this is used for pageable recordsets
    $result->{"serverInfo"}->{"id"} = "FLAP"; 
    $result->{"serverInfo"}->{"cursor"} = 1; # maybe the current record ????
    $result->{"serverInfo"}->{"serviceName"} = "doStuff"; # in CF this is PageAbleResult not here   
    # versioning
    $result->{"serverInfo"}->{"version"} = 1;

    $result->{_explicitType}='RecordSet';

    return $result;
}

1;
