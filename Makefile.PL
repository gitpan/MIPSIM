
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Kang-min Liu (gugod@gugod.org)',
    ABSTRACT            => 'MIPS Simulator',
    NAME                => 'MIPSIM',
    VERSION             => '0.01',
    DISTNAME            => 'MIPSIM',
    EXE_FILES           => [
	'bin/mipsim-basic',
	'bin/mipsim-pipeline'
	],
    PREREQ_PM           => {
        'Spoon'   => '0.14',
	'Perl6::Form' => 0,
	'YAML'    => 0,
    },
    dist                => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
    },
);
