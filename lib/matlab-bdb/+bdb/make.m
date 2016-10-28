function make(varargin)
%MAKE Build a driver mex file.
%
%    bdb.make(['optionName', optionValue,] [compiler_flags])
%
% bdb.make builds a mex file for the bdb driver. The make script
% accepts db path option and compiler flags for the mex command.
% See below for the supported build options.
%
% The libdb must be installed in the system. Also, for data compression,
% zlib library is required.
%
% Options:
%
%    Option name     Value
%    --------------- -------------------------------------------------
%    --libdb_path    path to libdb.a. e.g., /usr/lib/libdb.a
%    --libz_path     path to libz.a. e.g., /usr/lib/libz.a
%    --enable_zlib   true or false (default true)
%
% By default, db.make looks for a system library path for dynamic linking.
%
% The enable_zlib flag specifies whether to compress values in the
% database. Compression can significantly save disk space when the data
% consists of repetitive values such as a big zero array. However, when
% data is near random, almost no saving in storage space with slower
% storage access. Note that the database file created with compression
% enabled is not compatible with the driver built without the compression
% flag, or vice versa. By default, compression is turned on.
%
% Example:
%
% Disable ZLIB compression.
%
% >> bdb.make('--enable_zlib', false);
%
% Specifying additional paths.
%
% >> bdb.make('-I/opt/local/include', '-L/opt/local/lib');
%
% Specifying library files.
%
% >> bdb.make('--libdb_path', '/opt/local/lib/libdb.a', ...
%            '-I/opt/local/include');
%
% See also mex

    package_dir = fileparts(mfilename('fullpath'));
    [config, compiler_flags] = parse_options(varargin{:});
    cmd = sprintf(...
        'mex -largeArrayDims%s -outdir %s -output mex_function_ %s %s%s',...
        find_source_files(fullfile(fileparts(package_dir), 'src')),...
        fullfile(package_dir, 'private'),...
        config.db_path,...
        repmat(['-DENABLE_ZLIB ', config.zlib_path], 1, config.enable_zlib),...
        compiler_flags...
        );
    disp(cmd);
    eval(cmd);
end

function [config, compiler_flags] = parse_options(varargin)
%PARSE_OPTIONS Parse build options.
    config.db_path = '-ldb';
    config.zlib_path = '-lz';
    config.enable_zlib = true;
    mark_for_delete = false(size(varargin));
    for i = 1:2:numel(varargin)
        if strcmp(varargin{i}, '--libdb_path')
            config.db_path = varargin{i+1};
            mark_for_delete(i:i+1) = true;
        end
        if strcmp(varargin{i}, '--libz_path')
            config.zlib_path = varargin{i+1};
            mark_for_delete(i:i+1) = true;
        end
        if strcmp(varargin{i}, '--enable_zlib')
            config.enable_zlib = logical(varargin{i+1});
            mark_for_delete(i:i+1) = true;
        end
    end
    compiler_flags = sprintf(' %s', varargin{~mark_for_delete});
end

function files = find_source_files(root_dir)
%SOURCE_FILES List of source files in a string.
    files = dir(root_dir);
    srcs = files(cellfun(@(x)~isempty(x), ...
                 regexp({files.name},'\S+\.(c)|(cc)|(cpp)|(C)')));
    srcs = cellfun(@(x)fullfile(root_dir, x), {srcs.name},...
                   'UniformOutput', false);
    subdirs = files([files.isdir] & cellfun(@(x)x(1)~='.',{files.name}));
    subdir_srcs = cellfun(@(x)find_source_files(fullfile(root_dir,x)),...
                          {subdirs.name}, 'UniformOutput', false);
    files = [sprintf(' %s', srcs{:}), subdir_srcs{:}];
end
