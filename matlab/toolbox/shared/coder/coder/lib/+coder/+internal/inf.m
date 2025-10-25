function y = inf(varargin)
%MATLAB Code Generation Private Function
%
%   Returns inf(varargin{:}) if nonfinites are supported, otherwise
%   realmax of the appropriate class and size.

%   Copyright 2006-2019 The MathWorks, Inc.
%#codegen

coder.inline('always');
if coder.target('MATLAB') || coder.internal.get_eml_option('NonFinitesSupport')
    y = inf(varargin{:});
else
    y = coder.nullcopy(zeros(varargin{:}));
    y(:) = realmax(class(y));
end
