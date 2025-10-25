function varargout = textread(varargin)

narginchk(1,inf);
if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end
varargin{1} = reshape(varargin{1}', 1, numel(varargin{1}));
if (noargname(@exist,varargin{1}) ~= 2 || noargname(@exist,fullfile(cd,varargin{1})) ~= 2) ...
        && ~isempty(noargname(@which,varargin{1}))
    varargin{1} = noargname(@which,varargin{1});
end

nRet = noargname(@exist,varargin{1});
if  nRet ~= 2 && nRet ~= 4
    error(message('MATLAB:textread:FileNotFound'));
end

if nargout == 0
    nlhs = 1;
else
    nlhs = nargout;
end

[varargout{1:nlhs}]=dataread('file',varargin{:}); %#ok<REMFF1>
end

% Execute the function handle f in a context that has
% no variable with the name 'f' or 'arg'. We assume
% only one return argument.
%
function arg = noargname(f,arg)
if strcmpi(arg,'f')
    tmp = f;
    clear f;
    arg = tmp(arg);
elseif strcmpi(arg,'arg')
    tmp = arg;
    clear arg;
    arg = f(tmp);
else
    arg = f(arg);
end
end

%   Copyright 1984-2024 The MathWorks, Inc.