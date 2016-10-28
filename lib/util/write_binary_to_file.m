function write_binary_to_file( input, filename )
%WRITE_BINARY_TO_FILE Write binary data to a file.

  try
    fid = fopen(filename, 'w');
    fwrite(fid, cast(input(:), 'uint8'), 'uint8');
    fclose(fid);
  catch exception
    if exist(filename, 'file')
        delete(filename);
    end
    rethrow(exception);
  end

end

