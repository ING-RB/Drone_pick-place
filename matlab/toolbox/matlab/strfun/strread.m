function varargout = strread(varargin)
%

%   Copyright 1984-2023 The MathWorks, Inc.

% do some preliminary error checking
if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(1,inf);

if nargout == 0
    nlhs = 1;
else
    nlhs = nargout;
end
num = numel(varargin{1});
if  num < 4095 % 4095 is dataread's buffer limit
    [varargout{1:nlhs}]=dataread('string',varargin{:}); %#ok<REMFF1>
else % Unicode chars are two bytes
    if nargin < 2
         %If format was not passed in, make sure to pass empty one.
        [varargout{1:nlhs}]=dataread('string',varargin{:}, '', 'bufsize',2*num );        %#ok<REMFF1>
    else
        [varargout{1:nlhs}]=dataread('string',varargin{:},'bufsize',2*num ); %#ok<REMFF1>
    end
end
