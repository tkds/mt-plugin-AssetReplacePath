package AssetReplacePath::Plugin;
use strict;
use warnings;

sub _asset_relative_url {
    my ($eh, $app, $param, $tmpl) = @_;
    my $blog_id = $app->blog ? $app->blog->id : 0;
    my ( $search, $replace ) = __get_config( $app, $blog_id );

    $search = quotemeta( $search );
    return if $search eq '';
    $param->{'upload_html'} =~ s!$search!$replace!g;
}

# Code from https://github.com/alfasado/mt-plugin-admin-screen-replace-link
sub _asset_list {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $object_loop = $param->{ object_loop };
    my @new_loop;
    for my $obj ( @$object_loop ) {
        for my $key ( keys( %$obj ) ) {
            my $blog_id = $obj->{ blog_id };
            if ( ( $key eq 'metadata_json' ) || ( $key =~ /url$/ ) ) {
                my ( $search, $replace ) = __get_config( $app, $blog_id );
                $search = quotemeta( $search );
                my $col = $obj->{ $key };
                $col =~ s/$search/$replace/g;
                $obj->{ $key } = $col;
            }
        }
        push ( @new_loop, $obj );
    }
    $param->{ object_loop } = \@new_loop;
}

sub __get_config {
    my ( $app, $blog_id ) = @_;
    my $plugin = MT->component( 'AssetReplacePath' );
    my ( $search, $replace );
    my $blog;
    if ( $blog_id ) {
        $blog = MT::Blog->load( $blog_id );
    } else {
        if ( $blog = $app->blog ) {
            $blog_id = $blog->id;
        }
    }
    if ( $blog ) {
        $search  = $plugin->get_config_value( 'assetreplacepath_search', 'blog:' . $blog->id );
        $replace = $plugin->get_config_value( 'assetreplacepath_replace', 'blog:' . $blog->id );
        if ( (! $search ) && (! $replace ) ) {
            if ( $blog->class eq 'blog' ) {
                $search  = $plugin->get_config_value( 'assetreplacepath_search', 'blog:' . $blog->parent_id );
                $replace = $plugin->get_config_value( 'assetreplacepath_replace', 'blog:' . $blog->parent_id );
            }
        }
    }
    if ( (! $search ) && (! $replace ) ) {
        $search  = $plugin->get_config_value( 'assetreplacepath_search' );
        $replace = $plugin->get_config_value( 'assetreplacepath_replace' );
    }
    return ( $search, $replace );
}

sub doLog {
    my ($msg, $class) = @_;
    return unless defined($msg);

    require MT::Log;
    my $log = new MT::Log;
    $log->message($msg);
    $log->level(MT::Log::DEBUG());
    $log->class($class) if $class;
    $log->save or die $log->errstr;
}

1;