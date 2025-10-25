function [yi,varargout] = TensorSplineInterp(varargin)

%   Copyright 2022 The MathWorks, Inc.
%#codegen


nd = (nargin - 1)/2;
outtype = coder.internal.scalarEg(varargin{1:nd+1});
outsize = output_size(nd, varargin{(nd + 1):end});

% Transpose sample value to support spline function
vsize = value_size(nd, varargin{1:nd+1});
if( numel(vsize) > nd)
    vi = coder.nullcopy(zeros(vsize, 'like', varargin{nd+1}));
    ycols = coder.internal.indexInt(coder.internal.prodsize(vi,'above',numel(vsize) - nd));
    yrows = numel(vi)/ycols;
    k = 1;
    for i = 1:ycols
        for j = 0:yrows-1
            vi(k) = varargin{nd+1}(i + ycols*j);
            k = k+1;
        end
    end
else
    vi = varargin{nd+1};
end

varargout{nd} = vi;

for k = coder.unroll(nd:-1:2)
    
    xx = varargin{k};
    xxi = varargin{k + nd + 1};
    nxxi = numel(xxi);
    ppk = spline(xx,varargout{k});
    sv = intermediate_size(varargout{k},varargin{k + nd + 1});
    varargout{k-1} = zeros(sv,'like',outtype);
    % Evaluate ppk so that the output is already "transposed"
    for j = 1:nxxi
        vkj = ppval(ppk,cast(xxi(j),'like',outtype));
        for i = 1:numel(vkj)
            varargout{k-1}(j + (i - 1)*nxxi) = vkj(i);
        end
    end
end
% Do last interpolation to produce the output.
xx = varargin{1};
xxi = varargin{nd + 2};
nxxi = numel(xxi);
ppk = spline(xx,varargout{1});
yi = zeros(outsize,'like',outtype);
% Evaluate ppk so that the output is already "transposed"
for j = 1:nxxi
    vkj = ppval(ppk,cast(xxi(j),'like',outtype));
    for i = 1:numel(vkj)
        yi(j + (i - 1)*nxxi) = vkj(i);
    end
end

%---------------------------------------------------------------------------

function sz = intermediate_size(a,b)
sz = size(a);
sz(1) = numel(b);
for k = 2:numel(sz)
    sz(k) = size(a,k - 1);
end
    
%---------------------------------------------------------------------------

function sz = output_size(nd, varargin)
sz = size(varargin{1});
for k = 1:nd
    sz(k) = numel(varargin{k+1});
end

%---------------------------------------------------------------------------

function sz = value_size(nd, varargin)
sz = size(varargin{end});
j = numel(sz);
for k = nargin-2:-1:1
    sz(j) = numel(varargin{k});
    j = j - 1;
end
vsz = size(varargin{end});
for k = 1:(numel(sz)-nd)
    sz(k) = vsz(k+nd);
end

%---------------------------------------------------------------------------