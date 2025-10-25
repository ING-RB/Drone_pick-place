function v = maskExtrap(vExtrap,isnone,v,varargin)

%   Copyright 2022 The MathWorks, Inc.
%#codegen

% Mask out-of-range values with extrapval. The input vi is the unmasked
% interpolation output. varargin{1:nd} are the coordinate vectors of the
% interpolation data. varargin{nd+1:end} are the corresponding coordinates
% of the values in vi. We require that size(varargin{nd+k}) is equal to
% size(vi), k = 1:nd. For example, for 3-D interpolation,
% vi = ApplyConstantExtrapolation(extrapval,vi,x,y,z,xi,yi,zi);
coder.inline('always');
coder.internal.prefer_const(isnone);
nd = (nargin - 3)/2;

ycols = coder.internal.indexInt(coder.internal.prodsize(v,'above',nd));
yrows = numel(v)/ycols;

for k = 1:yrows
    sub = cell(1, nd);
    [sub{:}] = ind2sub(size(v), k);
    overwrite = false;
    for d = 1:nd
        overwrite = overwrite || ...
            varargin{d + nd}(sub{d}) < varargin{d}(1) || ...
            varargin{d + nd}(sub{d}) > varargin{d}(end);
    end
    if overwrite
        for j = 0:ycols-1
            if isnone
                v(k+j*yrows) = coder.const(coder.internal.interpolate.interpNaN(v));
            else
                v(k+j*yrows) = vExtrap(k+j*yrows);
            end
        end
    end
end
