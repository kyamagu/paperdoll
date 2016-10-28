classdef EMat < handle
%EMAT Embedded Matlab templating
%
%   EMat class provides a templating system in Matlab like Ruby's ERB
%   system. Matlab code can be embedded inside any text document to
%   easily control the document generation flow.
%
%   A simple example is illustrated here:
%     >> x = 42;
%     >> tmpl = '    The value of x is <%= x %>';
%     >> obj = EMat(tmpl);
%     >> disp(obj.render);
%         The value of x is 42
% 
% Synopsis:
%
%   obj = EMat( S )
%   obj = EMat( file_path )
%   obj = EMat( S, 'property', value, ... )
%   obj = EMat( file_path, 'property', value, ... )
%
%   S = obj.render()
%   obj.render( file_path )
%
%   obj = EMat(...) creates an new EMat object from template. EMat
%   accepts a template string either by string variable S or by
%   specifying a path to the template text file_path. EMat takes
%   optional arguments to specify properties. See below for available
%   options.
%
%   S = obj.render() returns a string of the rendered document.
%   obj.render(file_path) instead renders output to a file specified
%   by the file_path.
%
% Properties:
%
%        errchk:  logical flag to enable/disable syntax check
%                 (default: true)
%          trim:  logical flag to enable/disable whitespace trim when
%                 suppresseing newline at the end (default: true)
%
% Template format:
%   
%   Any text document can embed matlab code with the following syntax.
%   
%   <%  stmt  %> matlab statement
%   <%  stmt -%> matlab statement with newline suppression at the end
%   <%= expr  %> matlab expression with rendering
%   <%# comt  %> comment line
%   <%# comt -%> comment line with newline suppression at the end
%   <%% %%>      escape to render '<%' or '%>', respectively
%
%   <%= expr %> renders output of the matlab expression to the output.
%   Note that numeric variables will be converted to string by
%   NUM2STR(). When -%> is specified at the end of the line in
%   statement or comment, a following newline will be omitted from the
%   rendering. Any other texts appearing outside of these special
%   brackets are rendered as is. When trim property is set true,
%   leading whitespace in the template is also removed from the output
%   with newline suppression syntax.
%
% Example:
%
%   <!-- template.html.emat -->
%   <html>
%   <head><title><%= t %></title></head>
%   <body>
%   <%# this is a comment line -%>
%   <p><%= a %></p>
%   <ul>
%   <% for i = 1:3 -%>
%     <li><%= i %></li>
%   <% end -%>
%   </ul>
%   </body>
%   </html>
%
%   % In your matlab code
%   % Prepare variables used in the template
%   t = 'My template document';
%   a = 10;
%   
%   % Create an EMat object
%   obj = EMat('/path/to/template.html.emat');
%   
%   % Render to a file
%   obj.render('/path/to/rendered.html');
%
%   <!-- rendered.html -->
%   <html>
%   <head>
%   <title>My template document</title>
%   </head>
%   <body>
%   <p>a = 10</p>
%   <ul>
%     <li>1</li>
%     <li>2</li>
%     <li>3</li>
%   </ul>
%   </body>
%   </html>
%
% See also NUM2STR, FPRINTF

% Revision 0.1   July 28, 2011
% Revision 0.2   August 10, 2011
% Revision 0.3   August 11, 2011
% Revision 0.4   August 12, 2011
% Revision 0.5   December 22, 2011
% Revision 0.6   January 4, 2012
%
% You may redistribute this software under BSD license
% Copyright (c) 2011 Kota Yamaguchi

properties (Constant, Hidden)
  SPLIT_REGEXP = '<%%|%%>|<%=|<%#|<%|-%>|%>|\n'
  FID = 1        % Default file id: 1=stdout
end

properties (Access = protected, Hidden)
  stag    = ''
  last    = ''
  content = ''
  stmts   = {}
  script  = ''
  out     = ''
end

properties (SetAccess = protected, Hidden)
  src    = ''
  tmpl_path = ''
end

properties
  trim   = true % Default: true
  errchk = true % Default: true
end

methods (Static, Hidden)
  function [ file_id ] = fid(file_id)
    %FID pseudo class variable to hold file id
    %  This method is called when the compiled src is executed as
    %  a place holder of file id in fprintf statements; i.e.,
    %  fprintf(EMat.fid,'...'). Since this function is called in
    %  evalc, it must be a public method.
    persistent id;
    if isempty(id), id = EMat.FID; end
    if nargin > 0, id = file_id; end
    file_id = id;
  end
end

methods
  function [ obj ] = EMat(input, varargin)
    %EMat create a new EMat object from template

    % Error check
    error(nargchk(1, 5, nargin, 'struct'));
    if ~ischar(input)
      error('EMat:set:invalidInput',...
            'Input argument must be a path or a string');
    end

    % Set options
    for i = 1:2:numel(varargin)
      switch varargin{i}
        case 'trim', 	obj.trim = varargin{i+1};
        case 'errchk', 	obj.errchk = varargin{i+1};
      end
    end

    % Load input file if a pathname specified
    if exist(input,'file')
      obj.tmpl_path = input;
      f = fopen(input,'r');
      tmpl = fscanf(f,'%c',inf);
      fclose(f);
    else
      tmpl = input; % template is given as char
    end

    % Compile the template
    obj.src = obj.compile(tmpl);

    % Check syntax error
    if obj.errchk, obj.syntax_check(obj.src); end
  end

  function [ s ] = render(obj, output)
    %RENDER render document

    % Error check
    error(nargchk(1, 2, nargin, 'struct'));
    if nargin > 1 && nargout > 0
      warning('EMat:render:unsupported',...
              'output to string is unsupported when exporting to a file');
    end

    % Set fid if optional output path specified
    if nargin > 1 && ischar(output)
      f = fopen(output,'w');
      obj.fid(f);
    end

    try
      % Render compiled template in the caller context
      s = evalc('evalin(''caller'',obj.src);');
    catch e
      if nargin > 1 && ischar(output)
        fclose(f);
        obj.fid(obj.FID); % reset to default
      end
      rethrow(e);
    end

    if nargin > 1 && ischar(output)
      fclose(f);
      obj.fid(obj.FID); % reset to default
    end
  end

  function [] = set.errchk(obj, value)
    %SET.ERRCHK set errchk flag
    if ~isscalar(value)
      error('EMat:error','Invalid argument');
    end
    obj.errchk = logical(value);
  end

  function [] = set.trim(obj, value)
    %SET.TRIM set trim flag
    if ~isscalar(value)
      error('EMat:error','Invalid argument');
    end
    obj.trim = logical(value);
  end
end

methods (Access = private)        
  function [ s ] = compile(obj, s)
    %COMPILE compile template string
    obj.scan(s);
    if ~isempty(obj.content), obj.push_print; end
    if ~isempty(obj.stmts), obj.cr; end
    s = obj.script;
    obj.clean;
  end

  function [] = scan(obj, s)
    %SCAN scan and tokenize text
    [match,lines] = regexp(s,'\n','match','split');
    lines = strcat(lines, [match,{''}]);
    for i = 1:length(lines)
      line = lines{i};
      [match,tokens] = regexp(line, EMat.SPLIT_REGEXP, 'match','split');
      tokens = [(tokens); [match,{''}]];
      tokens = tokens(:);
      tokens(cellfun(@isempty,tokens)) = [];
      if obj.trim
        % Trim whitespace if the end is '-%>\n'
        if numel(tokens)>2 &&...
           strcmp(tokens{end},char(10)) && ...
           strcmp(tokens{end-1},'-%>')
          ind = 1:find(strcmp(tokens,'<%'),1)-1;
          tokens(ind) = strtrim(tokens(ind));
        end
        tokens(cellfun(@isempty,tokens)) = [];
      end
      for j = 1:numel(tokens)
        obj.process(tokens{j});
      end
    end
  end

  function [] = process(obj, tok)
    %PROCESS parse tokens
    if isempty(obj.stag) % State 1: stag doesn't exist
      switch tok
        case {'<%', '<%=', '<%#'}
          obj.stag = tok;
          if ~isempty(obj.content), obj.push_print; end
          obj.content = '';
        case 10 % '\n'
          if ~strcmp(obj.last,'-%>')
            obj.content = [obj.content,10];
          end
          obj.push_print;
          obj.cr;
          obj.content = '';
        case '<%%'
          obj.content = [obj.content,'<%%'];
        otherwise
          obj.content = [obj.content,tok];
      end
    else % State 2: stag exists
      switch tok
        case {'%>','-%>'}
          switch obj.stag
            case '<%'
              if obj.content(end)==10 % '\n'
                  obj.content(end) = [];
                  obj.push;
                  obj.cr;
              else
                  obj.push;
              end
            case '<%='
              obj.push_insert;
            case '<%#'
              % do nothing
          end
          obj.stag = '';
          obj.content = '';
        case '%%>'
          obj.content = [obj.content,'%%>'];
        otherwise
          obj.content = [obj.content,tok];
      end
    end
    obj.last = tok;
  end

  function [] = push(obj)
    %PUSH add raw stmt
    obj.stmts = [obj.stmts,{obj.content}];
  end

  function [] = push_print(obj)
    %PUSH_PRINT add print stmt
    if ~isempty(obj.content)
      obj.stmts = [obj.stmts,...
          {['fprintf(EMat.fid,',obj.dump(obj.content),')']}];
    end
  end

  function [] = push_insert(obj)
    %PUSH_INSERT add insertion stmt
    obj.stmts = [obj.stmts,...
        {['fprintf(EMat.fid,EMat.str(',obj.content,'))']}];
  end

  function [] = cr(obj)
    %CR flush stmts to script
    s = strtrim(obj.stmts);
    delim = repmat({';'},1,length(obj.stmts));
    % mlint complains about semi-colon after else stmt
    for i = find(strcmp(s,'else')), delim{i} = ' '; end
    s = [s;delim];
    obj.script = [obj.script, [s{:}]];
    obj.stmts = {};
    obj.script = sprintf('%s\n',obj.script);
  end

  function [] = clean(obj)
    %CLEAN reset properties
    obj.stag = '';
    obj.content = '';
    obj.stmts = {};
    obj.script = '';
  end

  function [ inform ] = syntax_check(obj, src)
    %SYNTAX_CHECK export src into tempfile and check error

    % Escape chars
    src = regexprep(src,'\\','\\\\');
    src = strrep(src,'%','%%');

    % Write to tempfile
    file_path = [tempname,'.m'];
    f = fopen(file_path,'w');
    fprintf(f,src);
    fclose(f);

    % Check syntax
    inform = mlint(file_path,'-struct');
    if ~isempty(inform)
      warning('EMat:syntax_check:syntaxWarning','');
      for i = 1:length(inform)
        fprintf('%s:line %d: %s\n',...
                obj.tmpl_path, inform(i).line, inform(i).message);
      end
    end

    % Delete tempfile
    delete(file_path);
  end
end

methods (Static, Hidden)      
  function [ s ] = dump(s)
    %DUMP escape and enclose char
    s = regexprep(s,'''','''''');
    s = regexprep(s,'\\','\\\\');
    s = strrep(s,'%','%%');
    s = strrep(s,char(10),'\n');
    s = ['''',s,''''];
  end

  function [ s ] = str(s)
    %STR string conversion
    if isnumeric(s)
      s = num2str(s);
    else
      s = char(s);
    end
  end
end

end

