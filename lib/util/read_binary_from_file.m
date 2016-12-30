function output = read_binary_from_file( filename )
%READ_BINARY_FROM_FILE Read binary data from a file.
  try
    fid = fopen(filename, 'r');
    output = fread(fid, inf, 'uint8=>uint8');
    fclose(fid);
  catch exception
    if fid ~= -1
      fclose(fid);
    end
    rethrow(exception);
  end
end

