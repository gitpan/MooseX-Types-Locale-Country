#line 1
package Module::Load;

$VERSION = '0.12';

use strict;
use File::Spec ();

sub import {
    my $who = _who();

    {   no strict 'refs';
        *{"${who}::load"} = *load;
    }
}

sub load (*;@)  {
    my $mod = shift or return;
    my $who = _who();

    if( _is_file( $mod ) ) {
        require $mod;
    } else {
        LOAD: {
            my $err;
            for my $flag ( qw[1 0] ) {
                my $file = _to_file( $mod, $flag);
                eval { require $file };
                $@ ? $err .= $@ : last LOAD;
            }
            die $err if $err;
        }
    }
    __PACKAGE__->_export_to_level(1, $mod, @_) if @_;
}

### 5.004's Exporter doesn't have export_to_level.
### Taken from Michael Schwerns Test::More and slightly modified
sub _export_to_level {
    my $pkg     = shift;
    my $level   = shift;
    my $mod     = shift;
    my $callpkg = caller($level);

    $mod->export($callpkg, @_);
}

sub _to_file{
    local $_    = shift;
    my $pm      = shift || '';

    my @parts = split /::/;

    ### because of [perl #19213], see caveats ###
    my $file = $^O eq 'MSWin32'
                    ? join "/", @parts
                    : File::Spec->catfile( @parts );

    $file   .= '.pm' if $pm;
    
    ### on perl's before 5.10 (5.9.5@31746) if you require
    ### a file in VMS format, it's stored in %INC in VMS
    ### format. Therefor, better unixify it first
    ### Patch in reply to John Malmbergs patch (as mentioned
    ### above) on p5p Tue 21 Aug 2007 04:55:07
    $file = VMS::Filespec::unixify($file) if $^O eq 'VMS';

    return $file;
}

sub _who { (caller(1))[0] }

sub _is_file {
    local $_ = shift;
    return  /^\./               ? 1 :
            /[^\w:']/           ? 1 :
            undef
    #' silly bbedit..
}


1;

__END__

#line 182