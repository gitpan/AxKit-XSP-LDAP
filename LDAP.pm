######################################################################
### AxKit::XSP::LDAP
######################################################################
###
######################################################################

package AxKit::XSP::LDAP;

$VERSION = "0.1";

use AxKit 1.5;
use Apache::AxKit::Language::XSP::TaglibHelper;
use Net::LDAP;
use AxKit::XSP::WebUtils;

$NS = 'http://www.apache.org/2000/LDAP';

@ISA = qw(Apache::AxKit::Language::XSP::TaglibHelper);
@EXPORT_TAGLIB=(
    'execute_query($server_url,$query;$search_base,$scope,$deref_link,$count_limit,$attributes,$time_limit,$doc_element,$entry_element,$id_attribute):as_xml=1',
);

use strict;

sub execute_query {

    my($server_url,$query,$search_base,$scope,$deref_link,
       $count_limit,$attributes,$time_limit,$doc_element,
       $entry_element,$id_attribute) = @_;

	$server_url =~ s|^ldap://||i;
	
	my $ldap = Net::LDAP->new($server_url) or die "$@ URL = >$server_url<";

	$ldap->bind ;    # an anonymous bind

        if (($deref_link eq "true") || ($deref_link == 1)) {
          $deref_link = "find";
        } elsif (($deref_link eq "false") || ($deref_link == 0)) {
          $deref_link = "never";
        } 

        $scope = "sub" unless $scope;
        $deref_link = "find" unless $deref_link;
        $count_limit = 0 unless $count_limit;
        $time_limit = 0 unless $time_limit;
	$attributes = "*" unless $attributes;
	$doc_element = "ldapresults" unless $doc_element;
	$entry_element = "searchresult" unless $entry_element;
	$id_attribute = "ID" unless $id_attribute;

        my @attrs = split(/,/,$attributes);

	my $mesg = $ldap->search (  # perform a search
                       base   => $search_base,
                       filter => $query,
		       scope  => $scope,
		       sizelimit => $count_limit,
		       timelimit => $time_limit,
		       attrs => \@attrs,
                      );

	my $ret = $mesg->as_struct;
        my $return="<$doc_element>\n";
 
	foreach my $key (sort keys %$ret) {
          $return .= "   <$entry_element $id_attribute=\"$key\">\n";

	   my $inner = $ret->{$key};

	   foreach my $innerkey (sort keys %$inner) {
             foreach my $arrval (@{$ret->{$key}->{$innerkey}}) {
	       $return .= "      <$innerkey>$arrval</$innerkey>\n";
             }
	   }
	   $return .= "   </$entry_element>\n";
	}
        $return .= "</$doc_element>\n";
	return $return;

}

1;

__END__
=head1 NAME

AxKit::XSP::LDAP - LDAP tag library for AxKit eXtensible Server Pages.

=head1 SYNOPSIS

Add the ldap: namespace to your XSP <xsp:page> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:ldap="http://www.apache.org/2000/LDAP"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::LDAP


=head1 DESCRIPTION

This tag library provides support for retrieving records from LDAP servers
from within XSP. This tag library is based on the Coccon LDAP taglib
described at http://opensource.socialchange.net.au/ldaptaglib/docs/ Several
parts of the Java taglib are not relevant in perl. They are noted below.

=head1 TAG DESCRIPTIONS

Note that below we use the ldap: prefix as a convention, however you can
use whatever prefix you like provided it is mapped to the appropriate
namespace.

=over 4

=item <ldap:execute-query>

This is the required 'wrapper' element that declares your connection. All
of the following tags will be children of this tag.

=item <ldap:server-url>

This defines the URL of the server to connect to. This is currently only
used to get the hostname. 

Specifying a server-url of...

   <ldap:server-url>ldap://ldap.openldap.org/</ldap:server-url>

will direct the system to ldap.openldap.org port 389 for requests.

The current version of this taglib does not implement extended URL
information such as specifying the port, or trailing the base DN after the
hostname. These will be implemented in a future release.

=item <ldap:query>

This defines the query to send to the remote LDAP server.

   <ldap:query>(cn=Thompson)</ldap:query>

Will pull back all records (limited by <ldap:count-limit> below) with a cn
entry of Thompson.

LDAP queries use the & character to denote a logical AND of search strings.

   <ldap:query>(&(cn=Thompson) (ou=Development))</ldap:query>

This is, of course, bad XML, as it will try to make the & into an entity. In
this case you should escape the & as &amp; such as...

   <ldap:query>(&amp;(cn=Thompson) (ou=Development))</ldap:query>

=item <ldap:scope>

This sets the LDAP search scope. Valid values are "base", "sub" and "one".

This defaults to "sub" if not included.

=item <ldap:deref-link>

This determines whether the LDAP server is asked to dereference alias and
referrals. Valid values are "true" and "false". The default value is "true".

=item <ldap:driver>

This tag is ignored, and is included for completeness of the Java spec.

=item <ldap:search-base>

This tag sets the base entry for the query.

=item <ldap:count-limit>

This tag sets a limit on the number of records returned by the server. 
If set to 0, all matching records are returned. The default is 0.

=item <ldap:time-limit>

This tag sets a time limit on the query in milliseconds.
If set to 0, no limit is set. The default is 0.

=item <ldap:attributes>

This tag specifies a comma separated list of attributes to return from the
LDAP server. For example...

   <ldap:attributes>cn,ou,mail,sn,title</ldap:attributes>

Will return the cn, ou, mail, sn, and title attributes for any records which
match the query. The default value for this is '*', which will cause the
LDAP server to return it's default set of attributes, as defined on the
server side by whatever LDAP schema it uses.

=item <ldap:binary-attributes>

This tag is currently unimplemented and will be available in the next
release. It will be blissfully ignored.  

=item <ldap:relative-dn>

This tag is currently unimplemented and will be available in the next
release. It will be blissfully ignored.

=item <ldap:result-format>

This tag is currently unimplemented and may be available in a future
release. It will be blissfully ignored.

=item <ldap:doc-element>

This tag is used to set the name of the tag which will wrap the result set.
The default value is "ldapsearch"

=item <ldap:entry-element>

This tag is used to set the name of the tag which will wrap each record
retrieved from the server.
The default value is "searchresult"

=item <ldap:id-attribute>

This tag is used to set the name of the attribute which will be used in
every entry-element tag in the result set.

The default value is "ID"

Assuming you haven't changed the name of the entry-element, a record
retrieved from the server will look like...

   <ldapsearch>
      <searchresult ID="...record DN...">
        ... Data ...
      </searchresult>
   </ldapsearch>

Giving the tag...

   <ldap:id-attribute>foo</ldap:id-attribute>

would make the second line of that example read...

   <searchresult foo="...record DN...">

=item <ldap:error-element>

This tag is currently unimplemented and may be available in a future
release. It will be blissfully ignored.

=item <ldap:debug>

This tag is currently unimplemented and may be available in a future
release. It will be blissfully ignored.

=back

=head1 EXAMPLE

If an LDAP server has the following data...

    dn: cn=Bob Smith, ou=People, dc=server,dc=com
    cn: Bob Smith
    cn: Robert J. Smith
    sn: Smith
    mail: bob.smith@server.com
    title: Manager
    telephoneNumber: +1 202 555 5252
    facsimileTelephoneNumber: +1 202 555 2329
    objectClass: top
    objectClass: person
    objectClass: organizationalPerson
    objectClass: inetOrgPerson
    
    dn: cn=Barney Smith, ou=People, dc=server,dc=com
    cn: Barney Smith
    cn: Barney Q. Smith
    sn: Smith
    title: Janitor
    mail: barney.smith@server.com
    telephoneNumber: +1 202 555 5050
    facsimileTelephoneNumber: +1 202 555 2020
    objectClass: top
    objectClass: person
    objectClass: organizationalPerson
    objectClass: inetOrgPerson

You can query for all records with sn=Smith (sn is LDAP for surname). 

    <?xml version="1.0" encoding="ISO-8859-1" ?> 
    <xsp:page language="Perl"
      xmlns:xsp="http://www.apache.org/1999/XSP/Core" 
      xmlns:ldap="http://www.apache.org/2000/LDAP"
    >
    <page>
       <ldap:execute_query>
          <ldap:server_url>ldap://ldap.server.com</ldap:server_url>
          <ldap:query>(sn=Smith)</ldap:query>
          <ldap:doc-element>demoresults</ldap:doc-element>
          <ldap:id-attribute>UserDNE<lt>/ldap:id-attribute>
          <ldap:scope>sub</ldap:scope>
          <ldap:deref_link>true</ldap:deref_link>
          <ldap:count_limit>1</ldap:count_limit>
          <ldap:attributes>cn,title,mail</ldap:attributes>
       </ldap:execute_query>
    </page>
    </xsp:page>
    
    The resulting XML will look like
    
    <?xml version="1.0" encoding="UTF-8"?>
    <page>
    <demoresults>
       <searchresult UserDN="cn=Bob Smith, ou=People, dc=server,dc=com">
          <cn>Bob Smith</cn>
          <cn>Robert J. Smith</cn>
          <mail>bob.smith@server.com</mail>
          <title>Manager</title>
       </searchresult>
       <searchresult UserDN="cn=Barney Smith, ou=People, dc=server,dc=com">
          <cn>Barney Smith</cn>
          <cn>Barney Q. Smith</cn>
          <mail>barney.smith@server.com</mail>
          <title>Janitor</title>
       </searchresult>
    </demoresults>
    </page>
    

=head1 DISCLAIMER

I make no claims at being an XSP or LDAP expert. This is very much a work in
progress. 

=head1 AUTHOR

Chris Thompson, chris@logimeta.com.

Original Cocoon taglib by Alain Ketterlin and Jeff Turner.

=head1 COPYRIGHT

Copyright 2002 Christopher A. Thompson. You may use this module under the same
terms as Perl itself.

=head1 SEE ALSO

http://logimeta.com/software/xsp/LDAP/

L<AxKit>, L<Net::LDAP>, L<Apache::AxKit::Language::XSP>, the AxKit.org pages at
http://axkit.org/.

=cut

