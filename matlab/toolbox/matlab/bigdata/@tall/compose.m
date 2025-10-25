function s = compose(format,varargin)
%COMPOSE Fill holes in string with formatted data.
%   S = COMPOSE(TXT)
%   S = COMPOSE(FORMAT,A)
%   S = COMPOSE(FORMAT,A1,...,AN)
%
%   For tall data A, FORMAT must be a non-tall string.
%
%   See also COMPOSE, TALL/STRING.

%   Copyright 2016-2020 The MathWorks, Inc.

if nargin==1
    % Simply act element-wise (strings only)
    format = tall.validateType(format, mfilename, {'string'}, 1);
    s = elementfun(@compose, format);
    s = setKnownType(s, 'string');
else
    % First input must be a non-tall string/char/cellstr.
    tall.checkNotTall(upper(mfilename), 0, format);
    format = tall.validateType(format, mfilename, {'char','cellstr','string'}, 1);
    
    % COMPOSE can consume multiple columns, so is slice-wise
    s = slicefun(@(varargin) compose(format,varargin{:}), varargin{:});
    if ischar(format)
        s = setKnownType(s, 'cell');
    else
        s = setKnownType(s, class(format));
    end
end
end


