function varargout = size(this, varargin)
%MATLAB Code Generation Private Method

%   Copyright 2017-2023 The MathWorks, Inc.
%#codegen
coder.inline('always');
coder.internal.prefer_const(varargin);
if nargin >= 2
    if nargin > 2
        numDims = nargin-1;
        outArr = coder.nullcopy(zeros(1, numDims));
        for i = 1:numDims
           coder.internal.assert(isscalar(varargin{i}), 'Coder:toolbox:scalarSizeDims', i);
           coder.internal.assert(legitDim(varargin{i}), 'MATLAB:getdimarg:dimensionMustBePositiveInteger');
           outArr(i) = getSize(this, varargin{i});
        end
    else%nargin==2
        %matlab uses a different error message in this syntax than the
        %other one, so we match them
        dims = varargin{1};
        coder.internal.assert(legitDim(dims),'MATLAB:size:invalidDim');
        numDims = numel(dims);
        outArr = coder.nullcopy(zeros(1, numDims));
        coder.unroll(coder.internal.isConst(numDims));
        for i=1:numDims
            outArr(i) = getSize(this,dims(i));
        end
    end
    if nargout < 2
        varargout{1} = outArr;
    else
        %this error message is technically incorrect, but is what matlab
        %uses for this case
        coder.internal.assert(numDims == (nargout), 'MATLAB:size:NumOutNotEqualNumDims')
        for i = 1:nargout
            varargout{i} = outArr(i);
        end
    end
else
    % [...] = size(a)
    if nargout <= 1
        varargout{1} = double([this.m, this.n]);
    else
        varargout{1} = double(this.m);
        varargout{2} = double(this.n);
        for k = 3:nargout
            varargout{k} = double(ONE);
        end
    end
end

%--------------------------------------------------------------------------

function legit = legitDim(dim)
   legit = (coder.internal.isBuiltInNumeric(dim)...
        && isvector(dim)...
        && all(dim > 0)...
        && coder.internal.isFiniteInteger(dim))...
        || (islogical(dim) && isvector(dim) && all(dim));
    
%--------------------------------------------------------------------------

function out = getSize(this, dim)
coder.internal.prefer_const(dim);
switch dim
    case 1
        out = double(this.m);
    case 2
        out = double(this.n);
    otherwise
        out= double(ONE);
end

% LocalWords:  getdimarg
