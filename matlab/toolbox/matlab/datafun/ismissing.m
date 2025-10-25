function IA = ismissing(A,varargin)
% Syntax:
%     IA = ismissing(A)
%     IA = ismissing(A,INDICATORS)
%     IA = ismissing(___,OutputFormat=FORMAT)
%
% For more information, see documentation

%   Copyright 2012-2023 The MathWorks, Inc.

if nargin <= 1
    % syntax: ismissing(A)
    IA = matlab.internal.math.ismissingKernel(A);
elseif nargin == 2
    % syntax: ismissing(A,indicators)
    IA = matlab.internal.math.ismissingKernel(A,varargin{1},false);
else
    if ~istabular(A)
        error(message("MATLAB:ismissing:OutputFormatNonTabular"));
    end
    if rem(nargin-1,2) == 0
        % syntax: ismissing(A,NAME,VALUE)
        fmt = parseNVpair(varargin{:});
        IA = matlab.internal.math.ismissingKernel(A,[],false,[],isequal(fmt,'tabular'));
    else
        % syntax: ismissing(A,indicators,NAME,VALUE)
        fmt = parseNVpair(varargin{2:end});
        IA = matlab.internal.math.ismissingKernel(A,varargin{1},false,1:width(A),isequal(fmt,'tabular'));
    end
end
% --------------------------------------
function fmt = parseNVpair(varargin)
for j = 1:2:length(varargin)
    name = varargin{j};
    if ~((ischar(name) && isrow(name)) || (isstring(name) && isscalar(name) && strlength(name) ~= 0)) || ...
            ~startsWith('OutputFormat',name,'IgnoreCase',true)
        error(message("MATLAB:ismissing:InvalidParameter"))
    end
    fmt = validatestring(varargin{j+1},{'logical','tabular'},'ismissing','OutputFormat');
end