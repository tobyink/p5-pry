use 5.008001;
use strict;
use warnings;

package Pry;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001_000';

use Exporter::Shiny our @EXPORT = qw(pry);

# cargo-culted Win32 stuff... untested!
#
BEGIN {
	if ($^O eq 'MSWin32') {
		require Term::ANSIColor;
		require Win32::Console::ANSI;
		Win32::Console::ANSI->import;
	}
};

# a refinement for the Reply class
#
my $_say = sub {
	require Term::ANSIColor;
	shift;
	my ($text, $colour) = (@_, "cyan");
	print Term::ANSIColor::colored($text, "bold $colour"), "\n";
};

our ($Lexicals, $Trace);

# shim to pass lexicals to Reply
#
{
	package #hide
		Pry::_Lexicals;
	our @ISA = qw( Reply::Plugin );
	sub lexical_environment { $Lexicals }
	$INC{'Pry/_Lexicals.pm'} = __FILE__;
}

# the guts
#
sub pry ()
{
	require Devel::StackTrace;
	require Reply;
	require PadWalker;
	
	my ($caller, $file, $line) = caller;
	$Lexicals = PadWalker::peek_my(1);
	$Trace = Devel::StackTrace->new(
		ignore_package => __PACKAGE__,
		message        => "Prying",
	);
	
	my $repl = Reply->new(
		config  => ".replyrc",
		plugins => [ "/Pry/_Lexicals" ],
	);
	$repl->step("package $caller");
	
	$repl->$_say("Prying at $file line $line", "magenta");
	$repl->$_say("Current package:   '$caller'");
	$repl->$_say("Lexicals in scope: @{[ sort keys %$Lexicals ]}");
	$repl->$_say("Ctrl+D to leave REPL", "magenta");
	
	$repl->run;
}

# utils
#
sub Lexicals () { $Lexicals if $] }
sub Trace    () { $Trace    if $] }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Pry - intrude on your code

=head1 SYNOPSIS

   use Pry;
   
   ...;
   pry;
   ...;

=head1 DESCRIPTION

Kind of a bit like a debugger, kind of a bit like a REPL.

This module gives you a function called C<pry> that you can drop into
your code anywhere. When Perl executes that line of code, it will stop
and drop you into a REPL. You can use the REPL to inspect any lexical
variables (and even alter them), call functions and methods, and so on.

All the clever stuff is in the REPL. Rather than writing yet another
Perl REPL, Pry uses L<Reply>, which is an awesome yet fairly small REPL
with support for plugins that can do some really useful stuff, such as
auto-complete of function and variable names.

Once you've finished using the REPL, just hit Ctrl+D and your code will
resume execution.

=head1 UTILITIES

The following functions are provided for your convenience. They cannot
be exported, so you should access them, from the REPL, using their
fully-qualified name.

=over

=item C<< Pry::Lexicals >>

Returns a hashref of your lexical variables.

=item C<< Pry::Trace >>

Returns the stack trace as a L<Devel::StackTrace> object.

=back

=head1 CONFIGURATION

Pry's REPL can be configured in the same way as L<Reply>.

=head1 CAVEATS

I imagine this probably breaks pretty badly in a multi-threaded or
multi-process scenario.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Pry>.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Read–eval–print_loop>,
L<Reply>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

