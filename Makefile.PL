######################################################################
# Makefile.PL for Net::Google::Drive::Simple
# 2012, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 
                'http://github.com/mschilli/net-google-drive-simple.git',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Net::Google::Drive::Simple',
    'VERSION_FROM' => 'lib/Net/Google/Drive/Simple.pm', # finds $VERSION
    'PREREQ_PM'    => {
      'LWP::UserAgent'   => 6.02,
      'Sysadm::Install'  => 0.39,
      'YAML'             => 0.71,
      'JSON'             => 2.53,
      'Test::MockObject' => 1.09,
      'Log::Log4perl'    => 1,
      'Mojolicious'      => 1.16,
      'Pod::Usage'       => 1.36,
    }, # e.g., Module::Name => 1.1
    EXE_FILES           => ["eg/google-drive-init"],
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Net/Google/Drive/Simple.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);