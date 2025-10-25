function tf = matches(s,varargin)
%MATCHES True if pattern is equal to the text.
%   TF = MATCHES(S,PATTERN)
%   TF = MATCHES(S,PATTERN,'IgnoreCase',IGNORE)
%
%   See also TALL/STRING.

%   Copyright 2019-2023 The MathWorks, Inc.

narginchk(2,4);

% First input must be tall. Rest must not be.
tall.checkNotTall(upper(mfilename), 1, varargin{:});

% This method is string-specific
s = tall.validateType(s, mfilename, {'string'}, 1);

% Result is one logical per string
tf = elementfun(@(x) matches(x,varargin{:}), s);
tf = setKnownType(tf, 'logical');
end
