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

	my $sth = $self->dbh->prepare($queryText);
    $sth->execute();

# create an initialData array
    my (@initialData, @columnNames);
    $result->{initialData} = \@initialData;
    $result->{columnNames} = \@columnNames;
    $result->{totalCount}=$sth->rows();

	push @columnNames, @{$sth->{NAME}};

    # grab all of the rows
	# There is a reason arrayref is not used - if it is, 
	#the pointer is reused and only the last element gets added, though many times.
    while (my @array = $sth->fetchrow_array) 
    {
        # add each row to the initial data array
        push @initialData, \@array;
    }	

    $result->{cursor}=1;
    $result->{version}=1;
    $result->{serviceName}='PageableResultSet';
    $result->{serverinfo}=undef;
    $result->{id}=undef;
    #$result->{_explicitType}='RecordSet';

    return $result;
}

1;
