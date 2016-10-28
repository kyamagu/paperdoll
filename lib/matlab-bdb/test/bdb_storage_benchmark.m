function bdb_storage_benchmark
%BDB_STORAGE_BENCHMARK Measure storage performance of bdb against matfile.

  datasize = 1024 * 16;
  chunksize = 1024 * 2;
  fprintf('Datasize = %d, Chunk size = %d\n', datasize, chunksize);

  datagen = {@rand, @zeros};
  for i = 1:numel(datagen)
    fprintf('== Data load %d ==\n', i);
    % Set up data.
    x = datagen{i}(1,chunksize);
    
    % BDB performance.
    bdb.open('_benchmark.db');
    tic;
    for i = 1:datasize
      bdb.put(i, x);
    end
    fprintf('bdb write: %f seconds.\n', toc);
    tic;
    for i = 1:datasize
      bdb.get(i);
    end
    fprintf('bdb read: %f seconds.\n', toc);
    bdb.close;
    file = dir('_benchmark.db');
    fprintf('bdb size: %d bytes.\n', file.bytes);
    delete('_benchmark.db');

    % Matfile performance.
    mkdir('_benchmark');
    tic;
    for i = 1:datasize
      save(sprintf('_benchmark/%06d.mat',i), 'x');
    end
    fprintf('matfile write: %f seconds.\n', toc);
    tic;
    for i = 1:datasize
      x = load(sprintf('_benchmark/%06d.mat',i), 'x');
    end
    fprintf('matfile read: %f seconds.\n', toc);
    files = dir('_benchmark/*.mat');
    fprintf('matfile size: %d bytes.\n', sum([files.bytes]));
    rmdir('_benchmark', 's');
  end

end
