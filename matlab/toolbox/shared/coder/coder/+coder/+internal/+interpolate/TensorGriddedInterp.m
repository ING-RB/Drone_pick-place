function [yi,varargout] = TensorGriddedInterp(f, varargin)
%MATLAB Code Generation Private Function

%   Copyright 2022 The MathWorks, Inc.
%#codegen

% yi = TensorLinearInterp(x_1,x_2,x_3,...,x_nd,v,xi_1,xi_2,...,xi_nd)

nd = (nargin - 2)/2;
varargout{1} = varargin{nd + 1};
outtype = coder.internal.scalarEg(varargin{1:nd+1});
outsize = output_size(varargin{(nd + 1):end});
for k = 1:nd
    xx = varargin{k};
    xxi = varargin{k + nd + 1};
    sv = intermediate_size(nd,varargout{k},varargin{k + nd + 1});
    varargout{k+1} = zeros(sv,'like',outtype);
    % Interpolate so that ouput is 'transposed' and can be directly used in next call
    if f == coder.internal.interpolate.interpMethodsEnum.LINEAR
        varargout{k+1} = coder.internal.interpolate.TensorLinearLoopBody(varargout{k},xxi,varargout{k+1},xx);
    elseif f == coder.internal.interpolate.interpMethodsEnum.CUBIC
        varargout{k+1} = coder.internal.interpolate.TensorCubicLoopBody(varargout{k},xxi,varargout{k+1},xx);
    elseif f == coder.internal.interpolate.interpMethodsEnum.NEAREST
        varargout{k+1} = coder.internal.interpolate.TensorNearestLoopBody(varargout{k},xxi,varargout{k+1},xx);
    end

end

% Reshape so that multiple data sets are pushed to the back
yi = coder.nullcopy(zeros(outsize, 'like', outtype));
if(numel(outsize) > nd)
    ycols = coder.internal.indexInt(coder.internal.prodsize(yi,'above',nd));
    yrows = numel(yi)/ycols;
    k = 1;
    for i = 1:ycols
        for j = 0:yrows-1
            yi(k) = varargout{nd+1}(i + ycols*j);
            k = k+1;
        end
    end
else
    yi = reshape(varargout{nd+1}, outsize);
end
%---------------------------------------------------------------------------

function sz = intermediate_size(nd,a,b)
coder.internal.prefer_const(nd);
sz = size(a);
for k = 2:numel(sz)
    sz(k-1) = size(a,k);
end
sz(end) = numel(b);    
%---------------------------------------------------------------------------

function sz = output_size(varargin)
coder.internal.prefer_const(varargin)
sz = size(varargin{1});
for k = coder.unroll(2:nargin)
    sz(k-1) = numel(varargin{k});
end

%---------------------------------------------------------------------------