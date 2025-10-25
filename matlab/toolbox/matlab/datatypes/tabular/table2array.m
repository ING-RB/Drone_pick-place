function a = table2array(t,varargin)  %#codegen
%

%   Copyright 2012-2024 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    a = matlab.internal.coder.table2array(t, varargin{:});
    return
end

if ~isa(t,'tabular')
    error(message('MATLAB:table2array:NonTable'))
end

a = t{:,:};
