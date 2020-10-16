# NAME

Net::Google::Drive::Simple - Simple modification of Google Drive data

# SYNOPSIS

```perl
use feature 'say';
use Net::Google::Drive::Simple;

# requires a ~/.google-drive.yml file with an access token,
# see description below.
my $gd = Net::Google::Drive::Simple->new();

my $children = $gd->children( "/" ); # or any other folder /path/location

foreach my $item ( @$children ) {

    # item is a Net::Google::Drive::Simple::Item object

    if ( $item->is_folder ) {
        say "** ", $item->title, " is a folder";
    } else {
        say $item->title, " is a file ", $item->mimeType;
        eval { # originalFilename not necessary available for all files
          say $item->originalFilename(), " can be downloaded at ", $item->downloadUrl();
        };
    }
}
```

# DESCRIPTION

Net::Google::Drive::Simple authenticates with a user's Google Drive and
offers several convenience methods to list, retrieve, and modify the data
stored in the 'cloud'. See `eg/google-drive-upsync` as an example on how
to keep a local directory in sync with a remote directory on Google Drive.

## GETTING STARTED

To get the access token required to access your Google Drive data via
this module, you need to run the script `eg/google-drive-init` in this
distribution.

Before you run it, you need to register your 'app' with Google Drive
and obtain a client\_id and a client\_secret from Google:

```
https://developers.google.com/drive/web/enable-sdk
```

Click on "Enable the Drive API and SDK", and find "Create an API project in
the Google APIs Console". On the API console, create a new project, click
"Services", and enable "Drive API" (leave "drive SDK" off). Then, under
"API Access" in the navigation bar, create a client ID, and make sure to
register a an "installed application" (not a "web application"). "Redirect
URIs" should contain "http://localhost". This will get you a "Client ID"
and a "Client Secret".

Then, replace the following lines in `eg/google-drive-init` with the
values received:

```perl
  # You need to obtain a client_id and a client_secret from
  # https://developers.google.com/drive to use this.
my $client_id     = "XXX";
my $client_secret = "YYY";
```

Then run the script. It'll start a web server on port 8082 on your local
machine.  When you point your browser at http://localhost:8082, you'll see a
link that will lead you to Google Drive's login page, where you authenticate
and then allow the app (specified by client\_id and client\_secret above) access
to your Google Drive data. The script will then receive an access token from
Google Drive and store it in ~/.google-drive.yml from where other scripts can
pick it up and work on the data stored on the user's Google Drive account. Make
sure to limit access to ~/.google-drive.yml, because it contains the access
token that allows everyone to manipulate your Google Drive data. It also
contains a refresh token that this library uses to get a new access token
transparently when the old one is about to expire.

# METHODS

- `new()`

    Constructor, creates a helper object to retrieve Google Drive data
    later.

- `my $children = $gd->children( "/path/to" )`

    Return the entries under a given path on the Google Drive as a reference
    to an array. Each entry
    is an object composed of the JSON data returned by the Google Drive API.
    Each object offers methods named like the fields in the JSON data, e.g.
    `originalFilename()`, `downloadUrl`, etc.

    Will return all entries found unless `maxResults` is set:

    ```perl
    my $children = $gd->children( "/path/to", { maxResults => 3 } )
    ```

    Due to the somewhat capricious ways Google Drive handles its directory
    structures, the method needs to traverse the path component by component
    and determine the ID of each directory to get to the next level. To speed
    up subsequent lookups, it also returns the ID of the last component to the
    caller:

    ```perl
    my( $children, $parent ) = $gd->children( "/path/to" );
    ```

    If the caller now wants to e.g. insert a file into the directory, its
    ID is available in $parent.

    Each child comes back as a files#resource type and gets mapped into
    an object that offers access to the various fields via methods:

    ```perl
    for my $child ( @$children ) {
        print $child->kind(), " ", $child->title(), "\n";
    }
    ```

    Please refer to

    ```
    https://developers.google.com/drive/v2/reference/files#resource
    ```

    for details on which fields are available.

- `my $files = $gd->files( )`

    Return all files on the drive as a reference to an array.
    Will return all entries found unless `maxResults` is set:

    ```perl
    my $files = $gd->files( { maxResults => 3 } )
    ```

    Note that Google limits the number of entries returned by default to
    100, and seems to restrict the maximum number of files returned
    by a single query to 3,500, even if you specify higher values for
    `maxResults`.

    Each file comes back as an object that offers access to the Google
    Drive item's fields, according to the API (see `children()`).

- `my $id = $gd->folder_create( "folder-name", $parent_id )`

    Create a new folder as a child of the folder with the id `$parent_id`.
    Returns the ID of the new folder or undef in case of an error.

- `my $id = $gd->file_create( "folder-name", "mime-type", $parent_id )`

    Create a new file with the given mime type as a child of the folder with the id `$parent_id`.
    Returns the ID of the new file or undef in case of an error.

    Example to create an empty google spreadsheet:

    ```perl
    my $id = $gd->file_create( "Quarter Results", "application/vnd.google-apps.spreadsheet", "root" );
    ```

- `$gd->file_upload( $file, $dir_id )`

    Uploads the content of the file `$file` into the directory with the ID
    $dir\_id on Google Drive. Uses `$file` as the file name.

    To overwrite an existing file on Google Drive, specify the file's ID as
    an optional parameter:

    ```
    $gd->file_upload( $file, $dir_id, $file_id );
    ```

- `$gd->rename( $file_id, $name )`

    Renames the file or folder with `$file_id` to the specified `$name`.

- `$gd->download( $item, [$local_filename] )`

    Downloads an item found via `files()` or `children()`. Also accepts
    the downloadUrl of an item. If `$local_filename` is not specified,
    `download()` will return the data downloaded (this might be undesirable
    for large files). If `$local_filename` is specified, `download()` will
    store the downloaded data under the given file name.

    ```perl
    my $gd = Net::Google::Drive::Simple->new();
    my $files = $gd->files( { maxResults => 20 }, { page => 0 } );
    for my $file ( @$files ) {
        my $name = $file->originalFilename();
        print "Downloading $name\n";
        $gd->download( $file, $name ) or die "failed: $!";
    }
    ```

    Be aware that only documents like PDF or png can be downloaded directly. Google Drive Documents like spreadsheets or (text) documents need to be exported into one of the available formats.
    Check for "exportLinks" on a file given. In case of a document that can be exported you will receive a hash in the form:

    ```perl
    {
        'format_1' => 'download_link_1',
        'format_2' => 'download_link_2',
        ...
    }
    ```

    Choose your download link and use it as an argument to the download() function which can also take urls directly.

    ```perl
    my $gd = Net::Google::Drive::Simple->new();
    my $children = $gd->children( '/path/to/folder/on/google/drive' );
    for my $child ( @$children ) {
        if ($child->can( 'exportLinks' )){
            my $type_chosen;
            foreach my $type (keys %{$child->exportLinks()}){
                # Take any type you can get..
                $type_chosen = $type;
                # ..but choose your preferred format, opendocument here:
                last if $type =~/oasis\.opendocument/;
            }
            my $url = $child->exportLinks()->{$type_chosen};

            $gd->download($url, 'my/local/file');

        }
    }
    ```

- `my $files = $gd->search( )`

    ```perl
    my $children= $gd->search({ maxResults => 20 },{ page => 0 },
                              "title contains 'Futurama'");
    ```

    Search files for attributes. See
    [https://developers.google.com/drive/web/search-parameters](https://developers.google.com/drive/web/search-parameters)
    for a definition of the attributes.

    To list all available files, those on the drive, those directly shared
    with the user, and those generally available to the user, use an
    empty search:

    ```perl
    my $children= $gd->search({},{ page => 0 },"");
    ```

- `$gd->file_delete( file_id )`

    Delete the file with the specified ID from Google Drive.

- `$gd->drive_mvdir( "/gdrive/path/to/file", "/path/to/new/folder" )`

    Move an existing file to a new folder. Removes the file's "parent"
    setting (pointing to the old folder) and then adds the new folder as a
    new parent.

- `my $metadata_hash_ref = $gd->file_metadata( file_id )`

    Return metadata about the file with the specified ID from Google Drive.

- `api_test`

    Used at init time to check that the connection is correct.

- `children_by_folder_id`
- `data_factory`
- `error`
- `file_mime_type`
- `file_mvdir`
- `file_url`
- `http_delete`
- `http_json`
- `http_loop`
- `http_put`
- `init`

    Internal initialization to setup the connection.

- `item_iterator`
- `path_resolve`

# Error handling

In case of an error while retrieving information from the Google Drive
API, the methods above will return `undef` and a more detailed error
message can be obtained by calling the `error()` method:

```
print "An error occurred: ", $gd->error();
```

# LOGGING/DEBUGGING

Net::Google::Drive::Simple is Log4perl-enabled.
To find out what's going on under the hood, turn on Log4perl:

```perl
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
```

# LEGALESE

Copyright 2012-2019 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

# AUTHOR

2019, Nicolas R. <cpan@atoomic.org>
2012-2019, Mike Schilli <cpan@perlmeister.com>
