package Flash::FLAP::IO::Serializer;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)

=head1 NAME
    Flash::FLAP::IO::Deserializer
    Translated from PHP Remoting v. 0.5b from the -PHP project.        
        
==head1 DESCRIPTION    

    #Class used to convert physical perl objects into binary data.

==head1 CHANGES

Sun Mar  9 18:20:16 EST 2003
Function writeObject should return the same as writeHash. This assumes that all meaningful data
are stored as hash keys.
    
=cut


use strict;

# holder for the data
my $data;

sub new
{	
    my ($proto, $stream) = @_;
    # save
    my $self={};
    bless $self, $proto;
    $self->{out} = $stream;
    return $self;
}

sub serialize
{
    my ($self, $d) = @_;
    $self->{amfout} = $d;
    # write the version ???
    $self->{out}->writeInt(0);
    
    # get the header count
    my $count = $self->{amfout}->numHeader();
    # write header count
    $self->{out}->writeInt($count);
    
    for (my $i=0; $i<$count; $i++)
    {
        $self->writeHeader($i);
    }
        
    $count = $self->{amfout}->numBody();
    # write the body count
    $self->{out}->writeInt($count);
    
    for (my $i=0; $i<$count; $i++)
    {
        # start writing the body
        $self->writeBody($i);
    }
}

sub writeHeader
{
    my ($self, $i)=@_;

    
    # for all header values
    # write the header to the output stream
    # ignoring header for now
}

sub writeBody
{
    my ($self, $i)=@_;
    my $body = $self->{amfout}->getBodyAt($i);
    # write the responseURI header
    $self->{out}->writeUTF($body->{"target"});
    # write null, haven't found another use for this
    $self->{out}->writeUTF($body->{"response"});
    # always, always there is four bytes of FF, which is -1 of course
    $self->{out}->writeLong(-1);
    # write the data to the output stream
    $self->writeData($body->{"value"}, $body->{"type"});

}

# writes a boolean
sub writeBoolean
{
    my ($self, $d)=@_;
    # write the boolean flag
    $self->{out}->writeByte(1);
    # write the boolean byte
    $self->{out}->writeByte($d);
}
# writes a string under 65536 chars, a longUTF is used and isn't complete yet
sub writeString
{
    my ($self, $d)=@_;
    # write the string code
    $self->{out}->writeByte(2);
    # write the string value
    #$self->{out}->writeUTF(utf8_encode($d));
    $self->{out}->writeUTF($d);
}

sub writeXML
{
    my ($self, $d)=@_;
    $self->{out}->writeByte(15);
    #$self->{out}->writeLongUTF(utf8_encode($d));
    $self->{out}->writeLongUTF($d);
}

# must be used PHPRemoting with the service to set the return type to date
# still needs a more in depth look at the timezone
sub writeDate
{
    my ($self, $d)=@_;
    # write date code
    $self->{out}->writeByte(11);
    # write date (milliseconds from 1970)
    $self->{out}->writeDouble($d);
    # write timezone
    # ?? this is wierd -- put what you like and it pumps it back into flash at the current GMT ?? 
    # have a look at the amf it creates...
    $self->{out}->writeInt(0); 
}

# write a number formatted as a double with the bytes reversed
# this may not work on a Win machine because i believe doubles are
# already reversed, to fix this comment out the reversing part
# of the writeDouble method
sub writeNumber
{
    my ($self, $d)=@_;
    # write the number code
    $self->{out}->writeByte(0);
    # write the number as a double
    $self->{out}->writeDouble($d);
}
# write null
sub writeNull
{
    my ($self)=@_;
    # null is only a 0x05 flag
    $self->{out}->writeByte(5);
}

# write array
# since everything in php is an array this includes arrays with numeric and string indexes
sub writeArray
{
    my ($self, $d)=@_;

    # grab the total number of elements
    my $len = scalar(@$d);

    # write the numeric array code
    $self->{out}->writeByte(10);
    # write the count of items in the array
    $self->{out}->writeLong($len);
    # write all of the array elements
    for(my $i=0 ; $i < $len ; $i++)
    {
        $self->writeData($d->[$i]);
    }
}
    
sub writeHash
{
    my ($self, $d) = @_;
    # this is an object so write the object code
    $self->{out}->writeByte(3);
    # write the object name/value pairs	
    $self->writeObject($d);
}
# writes an object to the stream
sub writeObject
{
    my ($self, $d)=@_;
    # loop over each element
    while ( my ($key, $data) = each %$d)
    {	
        # write the name of the object
        $self->{out}->writeUTF($key);
        # write the value of the object
        $self->writeData($data);
    }
    # write the end object flag 0x00, 0x00, 0x09
    $self->{out}->writeInt(0);
    $self->{out}->writeByte(9);
}

# write a RecordSet object
sub writeRecordSet
{	
    my ($self, $rs)=@_;
    # create the RecordSet object
    my $RecordSet = {};
    # create the serverInfo array
    $RecordSet->{"serverInfo"} = {};
    # create the id field --> i think this is used for pageable recordsets
    $RecordSet->{"serverInfo"}->{"id"} = "FLAP";
    # get the total number of records
    $RecordSet->{"serverInfo"}->{"totalCount"} = $rs->{numRows};
    # save the initial data into the RecordSet object
    $RecordSet->{"serverInfo"}->{"initialData"} = $rs->{initialData};
    $RecordSet->{"serverInfo"}->{"cursor"} = 1; # maybe the current record ????
    $RecordSet->{"serverInfo"}->{"serviceName"} = "doStuff"; # in CF this is PageAbleResult not here
    $RecordSet->{"serverInfo"}->{"columnNames"} = $rs->{columnNames};
    # versioning
    $RecordSet->{"serverInfo"}->{"version"} = 1;
    # write the custom package code
    $self->{out}->writeByte(16);
    # write the package name
    $self->{out}->writeUTF("RecordSet");
    # write the packagees data
    $self->writeObject($RecordSet);                        
}


# main switch for dynamically determining the data type
# this may prove to be inadequate because perl isn't a typed
# language and some confusion may be encountered as we discover more data types
# to be passed back to flash

#All scalars are assumed to be strings, not numbers.
#Regular arrays and hashes are prohibited, as they are indistinguishable outside of perl context
#Only arrayrefs and hashrefs will work

# were still lacking dates, xml, and strings longer than 65536 chars
sub writeData
{
    my ($self, $d, $type)=@_;
    $type = "unknown" unless $type;

#    **************** TO DO **********************
#    Since we are now allowing the user to determine
#    the datatype we have to validate the user's suggestion
#    vs. the actual data being passed and throw an error
#    if things don't check out.!!!!
#    **********************************************

    # get the type of the data by checking its reference name
    #if it was not explicitly passed
    if ($type eq "unknown")
    {
        my $myRef = ref $d;
        if (!$myRef or $myRef =~ "SCALAR")
        {
            $type = "string";
        }
        elsif ($myRef =~ "ARRAY")
        {
            $type = "array";
        }
        elsif ($myRef =~ "HASH")
        {
            $type = "hash"; 
        }
        else
        {
            $type = "object";
        }
    }
    
    #BOOLEANS
    if ($type eq "boolean")
    {
        $self->writeBoolean($d);
    }
    #STRINGS
    elsif ($type eq "string")
    {
        $self->writeString($d);
    }
    # DOUBLES
    elsif ($type eq "double")
    {
        $self->writeNumber($d);
    }
    # INTEGERS
    elsif ($type eq "integer")
    {
        $self->writeNumber($d);
    }
    # OBJECTS
    elsif ($type eq "object")
    {
        $self->writeHash($d);
    }
    # ARRAYS
    elsif ($type eq "array")
    {
        $self->writeArray($d);
    }
    # HASHAS
    elsif ($type eq "hash")
    {
        $self->writeHash($d);
    }
    # NULL
    elsif ($type eq "NULL")
    {
        $self->writeNull();
    }
    # UDF's
    elsif ($type eq "user function")
    {
    
    }
    elsif ($type eq "resource")
    {
        my $resource = get_resource_type($d); # determine what the resource is
        $self->writeData($d, $resource); # resend with $d's specific resource type
    }
    # XML
    elsif (lc($type) eq "xml")
    {
        $self->writeXML($d);
    }
    # Dates
    elsif (lc($type) eq "date")
    {
        $self->writeDate($d);
    }
    # mysql recordset resource
    elsif (lc($type) eq "mysql result") # resource type
    {
        # load in the mysqlRecordSet package
        include_once("sql/mysqlRecordSet.php");
        # create a new recordset object
        my $recordSet = new mysqlRecordSet($d); # returns formatted recordset
        # write the record set to the output stream
        $self->writeRecordSet($recordSet); # writes recordset formatted for Flash
    }		
    else
    {
        print STDERR "Unsupported Datatype $type in FLAP::IO::Serializer";
        die;
    }
    
    }
1;
