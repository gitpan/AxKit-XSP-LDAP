use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'AxKit::XSP::LDAP',
    'VERSION_FROM'	=> 'LDAP.pm', # finds $VERSION
    'PREREQ_PM'		=> { Net::LDAP => 0.25 }
);
