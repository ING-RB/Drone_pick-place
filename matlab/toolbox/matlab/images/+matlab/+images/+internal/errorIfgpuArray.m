function errorIfgpuArray(varargin)
% errorIfgpuArray Error if any input is of gpuArray class.
%
%    errorIfgpuArray(varargin) checks if any input is of a gpuArray class
%    and terminates execution and throws an errors as the function does not
%    support gpuArray processing yet.

%    Copyright 2019 The MathWorks, Inc.

% Specializing the helper for functions with 1-4 input arguments for
% better performance as cellfun is slow.

if nargin == 1
    flag = isa(varargin{1},'gpuArray');
elseif nargin == 2
    flag = isa(varargin{1},'gpuArray') || ...
           isa(varargin{2},'gpuArray');
elseif nargin == 3
    flag = isa(varargin{1},'gpuArray') || ...
           isa(varargin{2},'gpuArray') || ...
           isa(varargin{3},'gpuArray');
elseif nargin == 4
    flag = isa(varargin{1},'gpuArray') || ...
           isa(varargin{2},'gpuArray') || ...
           isa(varargin{3},'gpuArray') || ...
           isa(varargin{4},'gpuArray');
else
    flag = any(cellfun(@(x)isa(x,'gpuArray'), varargin));
end

if flag
    error(message('images:validate:gpuArrayUnsupported'));
end
end
