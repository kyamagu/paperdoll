function bdb_test()
%BDB_TEST Test functionality of the bdb library.

  tests = {...
    @test_functional_1, ...
    @test_functional_2, ...
    @test_functional_3, ...
    @test_functional_4 ...
    };
  for i = 1:numel(tests)
    try
      tests{i}();
      fprintf('PASS: %s\n', func2str(tests{i}));
    catch e
      fprintf('FAIL: %s\n', func2str(tests{i}));
      fprintf('%s\n', e.getReport);
    end
  end

end

function test_functional_1()
%TEST_FUNCTIONAL_1

  filename = fullfile(get_test_dir, '_functional_1.bdb');
  
  function cleanup(filename)
  %CLEANUP
    bdb.close();
    if exist(filename, 'file')
      delete(filename);
    end
  end
  
  bdb.open(filename);
  try
    bdb.put('foo', 'bar');
    assert(strcmp(bdb.get('foo'), 'bar'));
    assert(bdb.exist('foo'));
    bdb.delete('foo');
    bdb.compact();
    assert(~bdb.exist('foo'));
    assert(isempty(bdb.get('foo')));
    assert(isstruct(bdb.stat));
    assert(isempty(bdb.keys));
    assert(isempty(bdb.values));
  catch e
    cleanup(filename);
    rethrow(e);
  end
  cleanup(filename);

end

function test_functional_2()
%TEST_FUNCTIONAL_2

  filename = fullfile(get_test_dir, '_functional_2.bdb');
  
  function cleanup(db_id, filename)
  %CLEANUP
    bdb.close(db_id);
    if exist(filename, 'file')
      delete(filename);
    end
  end
  
  db_id = bdb.open(filename);
  try
    bdb.put(db_id, 'foo', 'bar');
    assert(strcmp(bdb.get(db_id, 'foo'), 'bar'));
    assert(bdb.exist(db_id, 'foo'));
    bdb.delete(db_id, 'foo');
    bdb.compact(db_id);
    assert(~bdb.exist(db_id, 'foo'));
    assert(isempty(bdb.get(db_id, 'foo')));
    assert(isstruct(bdb.stat(db_id)));
    assert(isempty(bdb.keys(db_id)));
    assert(isempty(bdb.values(db_id)));
  catch e
    cleanup(db_id, filename);
    rethrow(e);
  end
  cleanup(db_id, filename);

end

function test_functional_3()
%TEST_FUNCTIONAL_3

  filename = fullfile(get_test_dir, '_functional_3.bdb');
  
  function cleanup(db_id, filename)
  %CLEANUP
    bdb.close(db_id);
    if exist(filename, 'file')
      delete(filename);
    end
  end
  
  db_id = bdb.open(filename);
  try
    bdb.put(db_id, 1, 'foo');
    bdb.put(db_id, 2, 'bar');
    cursor = bdb.cursor_open(db_id);
    assert(bdb.cursor_next(cursor));
    [key, value] = bdb.cursor_get(cursor);
    assert(key == 1 || key == 2);
    assert(strcmp(value, 'foo') || strcmp(value, 'bar'));
    assert(bdb.cursor_next(cursor));
    [key, value] = bdb.cursor_get(cursor);
    assert(key == 1 || key == 2);
    assert(strcmp(value, 'foo') || strcmp(value, 'bar'));
    assert(bdb.cursor_prev(cursor));
    assert(bdb.cursor_next(cursor));
    assert(~bdb.cursor_next(cursor));
    bdb.cursor_close(cursor);
  catch e
    cleanup(db_id, filename);
    rethrow(e);
  end
  cleanup(db_id, filename);

end

function test_functional_4()
%TEST_FUNCTIONAL_4
  home_dir = fullfile(get_test_dir, 'test_functional_4');
  if ~exist(home_dir, 'dir'), mkdir(home_dir); end
  function cleanup(home_dir)
    if exist(home_dir, 'dir'), rmdir(home_dir, 's'); end
  end

  try
    env_id = bdb.env_open(home_dir);
    db_id = bdb.open('test_functional_4.bdb');
    bdb.put(1, 'foo');
    transaction = bdb.begin();
    bdb.put(2, 'bar');
    bdb.put(db_id, 3, 'baz', 'Transaction', transaction);
    bdb.commit();
    bdb.close(db_id);
    bdb.env_close(env_id);
  catch e
    bdb.abort();
    cleanup(home_dir);
    rethrow(e);
  end
  cleanup(home_dir);
end

function test_dir = get_test_dir()
  test_dir = fileparts(mfilename('fullpath'));
end