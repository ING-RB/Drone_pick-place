function y = nan(varargin) 
%MATLAB Code Generation Private Function
%
%   Returns nan(varargin{:}) if nonfinites are supported, otherwise 
%   zeros(varargin{:}).

%   Copyright 2006-2019 The MathWorks, Inc.
%#codegen
coder.internal.allowHalfInputs;
coder.inline('always');
if coder.target('MATLAB') || coder.internal.get_eml_option('NonFinitesSupport')
    y = nan(varargin{:});
else
    y = zeros(varargin{:});
end
