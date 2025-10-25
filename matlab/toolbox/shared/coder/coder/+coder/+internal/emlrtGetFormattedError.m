function [id, msg] = emlrtGetFormattedError(varargin)
%

%   Copyright 2009-2015 The MathWorks, Inc.

id = '';
msg = '';
try
    error(varargin{:});
catch ME
    id = ME.identifier;
    msg = ME.message;
end