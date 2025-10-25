%legacyComplexToReal  Complex to real transform for legacy solver options objects

%    Copyright 2024 MathWorks, Inc.
function obj = legacyOptionsComplexToReal(obj,ODE)
% Transform legacy solver options objects from complex to real. At present
% this only requires modifying the OutputFcn and OutputSelection, if
% present.
if ~isempty(obj.OutputFcn)
    if ~isa(obj.OutputFcn,'function_handle')
        obj.OutputFcn = str2func(obj.OutputFcn);
    end
    if isempty(obj.OutputSelection)
        nz = numel(ODE.InitialValue);
    else
        nz = numel(obj.OutputSelection);
        idx = obj.OutputSelection(:).'*2;
        idx = [idx-1;idx];
        obj.OutputSelection = idx(:);
    end
    obj.OutputFcn = @(t,y,flag,varargin)callComplexOutputFcn(obj.OutputFcn,nz,t,y,flag,varargin{:});
end
end

function status = callComplexOutputFcn(f,nz,t,y,flag,varargin)
% f is the user's output function, which possibly expects complex y. nz is
% the number of complex components to output. When real and imaginary parts
% are split, size(y,1) = 2*nz. Note that y is empty when flag is 'done'.
ny = size(y,1);
if nargin(f) == 3
    parms = {};
else
    parms = varargin;
end
if ny == 2*nz
    status = f(t,typecast(y,'like',complex(y)),flag,parms{:});
else
    % Lets y = [] pass through unaltered.
    status = f(t,y,flag,parms{:});
end
end

