Matlab BDB
==========

Persistent key-value storage for matlab.

Matlab BDB is yet another storage for Matlab. It is a key-value storage for
matlab value objects, and suitable for storing a lot of small to medium
sized data. The implementation is based on Berkeley DB.

Contents
--------

The package contains following files.

    +bdb/          API functions.
    +bdb/private/  Internal driver functions.
    src/           C++ source files.
    test/          Optional functions to check the functionality.
    README.md      This file.

Prerequisites
-------------

The prerequisites are:

 * libdb
 * zlib

Have these libraries installed in the system. For example, in Debian/Ubuntu
Linux,

    $ apt-get install libdb-dev libz-dev

In macports,

    $ port install db53 zlib

Build
-----

The `bdb.make` function builds necessary dependent files. Check `bdb.make` for
the detail of compile-time options.

Example: build with the default library:

    >> bdb.make;

Example: build with additional path:

    >> bdb.make('-I/opt/local/include/db53','-L/opt/local/lib/db53');

API
---

Currently following functions are available from matlab. Check `help` for the
detail of each function.

### Database API

    bdb.open     Open a Berkeley DB database.
    bdb.close    Close the database.
    bdb.put      Store a key-value pair.
    bdb.get      Retrieve a value given key.
    bdb.delete   Delete an entry for a key.
    bdb.keys     Return a list of keys in the database.
    bdb.values   Return a list of values in the database.
    bdb.stat     Get a statistics of the database.
    bdb.exist    Check if an entry exists.
    bdb.compact  Free unused blocks and shrink the database.
    bdb.sessions Return a list of open session ids.

### Environment API

    bdb.env_open  Open an environment.
    bdb.env_close Close an environment.
    bdb.begin     Begin a transaction.
    bdb.commit    Commit a transaction.
    bdb.abort     Abort a transaction.

### Cursor API

    bdb.cursor_open   Open a new cursor.
    bdb.cursor_close  Close a cursor.
    bdb.cursor_next   Move forward a cursor.
    bdb.cursor_prev   Move back a cursor.
    bdb.cursor_get    Retrieve a key and a value from a cursor.

Example
-------

Here is a quick usage example.

    bdb.open('test.bdb');   % Open a database.
    bdb.put('foo', 'bar');  % Store a key-value pair.
    bdb.put(2, magic(4));   % Store a key-value pair.
    a = bdb.get('foo');     % Retrieve a value.
    b = bdb.get(2);         % Retrieve a value.
    flag = bdb.exist(3);    % Check if a key exists.
    bdb.delete('a');        % Delete an entry.
    keys = bdb.keys();      % All keys at once.
    values = bdb.values();  % All values at once.
    bdb.close();            % Finish the session.

To open multiple sessions, use the session id returned from `bdb.open`.

    id = bdb.open('test.bdb');
    bdb.put(id, 'a', 'bar');
    a = bdb.get(id, 'a');
    bdb.close(id);

To use a database from conccurrent processes, open a database in an
environment. Note that you need to create an environment directory if not
existing. This will enable transactional protection.

    mkdir('/path/to/test_db_env');
    bdb.env_open('/path/to/test_db_env');
    bdb.open('test_db.bdb');
    bdb.begin();
    bdb.put(1, 'foo');
    bdb.put(2, 'bar');
    bdb.commit();
    bdb.close();
    bdb.env_close();

Cursor API allows iteration over the table.

    cursor = bdb.cursor_open(id);
    while bdb.cursor_next(cursor)
      [key, value] = bdb.cursor_get(cursor);
    end
    bdb.cursor_close(cursor);

Some functions accept options in key-value arguments. Logical options may omit
a value to specify `true`.

    environment_id = bdb.env_open('/path/to/env');
    bdb.open('test.bdb', 'Create', true, ...
                         'Truncate', true, ...
                         'Type', 'hash', ...
                         'Environment', environment_id);
    bdb.open('test2.bdb', 'Create', ...
                          'Truncate', ...
                          'Type', 'hash', ...
                          'Environment', environment_id);

Notes
-----

### Data compression

Data compression is enabled by default to save storage space. It is possible
to disable data compression at compile time with `--enable_zlib` option.

    >> bdb.make('--enable_zlib', false)

Compression leads to smaller storage size with the cost of slower speed. In
general, when data contain regular patterns, such as when data are all-zero,
compression makes the biggest effect. However, if data are close to random,
there is no advantage in the resulting storage size.

### Undocumented functions

The implementation uses undocumented matlab mex functions `mxSerialize` and
`mxDeserialize`. The behavior of these functions are not guaranteed to work in
all versions of matlab, and may change in the future matlab release.

License
-------

The code may be redistributed under BSD 3-clause license.
