# ======================================================================
#
# Copyright (C) 2000-2003 Paul Kulchenko (paulclinger@yahoo.com)
# SOAP::Lite is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# $Id: Server.pm,v 1.3 2004/10/22 22:24:26 byrnereese Exp $
#
# ======================================================================

=pod

=head1 NAME

SOAP::Server - provides the basic framework for the transport-specific server classes to build upon

=head1 DESCRIPTION

The SOAP::Server class provides the basic framework for the transport-specific server classes to build upon. Note that in none of the code examples provided with SOAP::Lite is this class used directly. Instead, it is designed to be a superclass within more specific implementation classes. The methods provided by SOAP::Server itself are: 

=head1 METHODS

=over

=item new(optional key/value pairs)

    $server = SOAP::Server->new(%options);

Creates a new object of the class. Various default instance values are set up, and like many of the constructors in this module, most of the class methods described here may be passed in the construction call by giving the name followed by the parameter (or an array reference if there are multiple parameters).

=item action(optional new value)

    $action = $server->action

Retrieves or sets the value of the action attribute on the server object. This attribute is used when mapping the request to an appropriate namespace or routine. For example, the HTTP library sets the attribute to the value of the SOAPAction header when processing of the request begins, so that the find_target method described later may retrieve the value to match it against the server's configuration. Returns the object itself when setting the attribute.

=item myuri(optional new value)

    $server->myuri("http://localhost:9000/SOAP");

Gets or sets the myuri attribute. This specifies the specific URI that the server is answering requests to (which may be different from the value specified in action or in the SOAPAction header).

=item serializer(optional new value)

=item deserializer(optional new value)

    $serializer = $server->serializer;
    $server->deserializer($new_deser_obj);

As with the client objects, these methods provide direct access to the serialization and deserialization objects the server object uses to transform input and output from and to XML. There is generally little or no need to explicitly set these to new values.

=item options(optional new value)

    $server->options({compress_threshold => 10000});

Sets (or retrieves) the current server options as a hash-table  reference. At present, only one option is used within the SOAP::Lite libraries themselves:

=over

=item compress_threshold

The value of this option is expected to be a numerical value. If set, and if the Compress::Zlib library is available to use, messages whose size in bytes exceeds this value are compressed for transmission. Both
ends of the conversation have to support this and have it enabled.

=back 

Other options may be defined and passed around using this mechanism. Note that setting the options using this accessor requires a full hash reference be passed. To set just one or a few values, retrieve the current reference value and use it to set the key(s).

=item dispatch_with(optional new value)

    $server->dispatch_with($new_table);

Represents one of two ways in which a SOAP::Server (or derived) object may specify mappings of incoming requests to server-side subroutines or namespaces. The value of the attribute is a hash-table reference. To set the attribute, you must pass a new hash reference. The hash table's keys are URI strings (literal URIs or the potential values of the SOAPAction header), and the corresponding values are one of a class name or an object reference. Requests that come in for a URI found in the table are routed to the specified class or through the specified object.

=item dispatch_to(optional list of new values)

    $server->dispatch_to($dir, 'Module', 'Mod::meth');

This is the more traditional way to specify modules and packages for routing requests. This is also an accessor, but it returns a list of values when called with no arguments (rather than a single one). Each item in the list of values passed to this method is expected to be one of four things:

=over

=item I<Directory path>

If the value is a directory path, all modules located in that path are available for remote use.

=item I<Package name>

When the value is a package name (without including a specific method name), all routines within the package are available remotely.

=item I<Fully qualified method name>

Alternately, when the value is a package-qualified name of a subroutine or method, that specific routine is made available. This allows the server to make selected methods available without opening the entire package.

=item I<Object reference>

If the value is an object reference, the object itself routes the request.

The list of values held by the dispatch_to table are compared only after the URI mapping table from the dispatch_with attribute has been consulted. If the request's URI or SOAPAction header don't map to a specific configuration, the path specified by the action header (or in absence, the URI) is converted to a package name and compared against this set of values.

=back

=item objects_by_reference(optional list of new values)

    $server->objects_by_reference(qw(My:: Class));

This also returns a list of values when retrieving the current attribute value,
as opposed to a single value.

This method doesn't directly specify classes for request routing so much as it
modifies the behavior of the routing for the specified classes. The classes that
are given as arguments to this method are marked to be treated as producing
persistent objects. The client is given an object representation that contains
just a handle on a local object with a default persistence of 600 idle seconds.
Each operation on the object resets the idle timer to zero. This facility is
considered experimental in the current version of SOAP::Lite.

A global variable/"constant" allows developers to specify the amount of time
an object will be persisted. The default value is 600 idle seconds. This value
can be changed using the following code:

  $SOAP::Constants::OBJS_BY_REF_KEEPALIVE = 1000;

=item on_action(optional new value)

    $server->on_action(sub { ...new code });

Gets or sets the reference to a subroutine that is used for executing the on_action hook. Where the client code uses this hook to construct the action-request data (such as for a SOAPAction header), the server uses the on_action hook to do any last-minute tests on the request itself, before it gets routed to a final destination. When called, the hook routine is passed three arguments:

=over

=item action

The action URI itself, retrieved from the action method described earlier.

=item method_uri

The URI of the XML namespace the method name is labeled with.

=item method_name

The name of the method being called by the request.

=back

=item on_dispatch(optional new value)

    ($uri, $name) = $server->on_dispatch->($request);

Gets or sets the subroutine reference used for the on_dispatch hook. This hook is called at the start of the request-routing phase and is given a single argument when called:

=over 

=item request

An object of the L<SOAP::SOM> class, containing the deserialized request from the client.

=back

=item find_target

    ($class, $uri, $name) = $server->find_target($req)

Taking as its argument an object of the SOAP::SOM class that contains the deserialized request, this method returns a three-element list describing the method that is to be called. The elements are:

=over

=item class

The class into which the method call should be made. This may come back as either a string or an objectreference, if the dispatching is configured using an object instance.

=item uri

The URN associated with the request method. This is the value that was used when configuring the method routing on the server object.

=item name

The name of the method to call.

=back

=item handle

    $server->handle($request_text);

Implements the main functionality of the serving process, in which the server takes an incoming request and dispatches it to the correct server-side subroutine. The parameter taken as input is either plain XML or MIME-encoded content (if MIME-encoding support is enabled).

=item make_fault

    return $server->makefault($code, $message);

Creates a SOAP::Fault object from the data passed in. The order of arguments is: code, message, detail, actor. The first two are required (because they must be present in all faults), but the last two may be omitted unless needed.

=back

=head2 SOAP::Server::Parameters

This class provides two methods, but the primary purpose from the developer's point of view is to allow classes that a SOAP server exposes to inherit from it. When a class inherits from the SOAP::Server::Parameters class, the list of parameters passed to a called method includes the deserialized request in the form of a L<SOAP::SOM> object. This parameter is passed at the end of the arguments list, giving methods the option of ignoring it unless it is needed.

The class provides two subroutines (not methods), for retrieving parameters from the L<SOAP::SOM> object. These are designed to be called without an object reference in the parameter list, but with an array reference instead (as the first parameter). The remainder of the arguments list is expected to be the list from the method-call itself, including the SOAP::SOM object at the end of the list. The routines may be useful to understand if an application wishes to subclass SOAP::Server::Parameters and inherit from the new class instead. 

=over 

=item byNameOrOrder(order, parameter list, envelope)

    @args = SOAP::Server::Parameters::byNameOrOrder ([qw(a b)], @_);

Using the list of argument names passed in the initial argument as an array reference, this routine returns a list of the parameter values for the parameters matching those names, in that order. If none of the names given in the initial array-reference exist in the parameter list, the values are returned in the order in which they already appear within the list of parameters. In this case, the number of returned values may differ from the length of the requested-parameters list.

=item byName(order, parameter list, envelope)

    @args = SOAP::Server::Parameters::byName ([qw(a b c)], @_);

Acts in a similar manner to the previous, with the difference that it always returns as many values as requested, even if some (or all) don't exist. Parameters that don't exist in the parameter list are returned as undef values.

=back

=head3 EXAMPLE

The following is an example CGI based Web Service that utilizes a Perl module that inherits from the C<SOAP::Server::Parameters> class. This allows the methods of that class to access its input by name.

    #!/usr/bin/perl
    use SOAP::Transport::HTTP;
    SOAP::Transport::HTTP::CGI
      ->dispatch_to('C2FService')
      ->handle;
    BEGIN {
      package C2FService;
      use vars qw(@ISA);
      @ISA = qw(Exporter SOAP::Server::Parameters);
      use SOAP::Lite;
      sub c2f {
        my $self = shift;
        my $envelope = pop;
        my $temp = $envelope->dataof("//c2f/temperature");
        return SOAP::Data->name('convertedTemp' => (((9/5)*($temp->value)) + 32));
      }
    }

=head1 SEE ALSO

L<SOAP::SOM>, L<SOAP::Transport::HTTP>

=head1 ACKNOWLEDGEMENTS

Special thanks to O'Reilly publishing which has graciously allowed SOAP::Lite to republish and redistribute large excerpts from I<Programming Web Services with Perl>, mainly the SOAP::Lite reference found in Appendix B.

=head1 COPYRIGHT

Copyright (C) 2000-2004 Paul Kulchenko. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Paul Kulchenko (paulclinger@yahoo.com)

Randy J. Ray (rjray@blackperl.com)

Byrne Reese (byrne@majordojo.com)

=cut

