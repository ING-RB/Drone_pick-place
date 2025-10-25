function [m,f,c] = mode(a,dim)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText
import matlab.internal.datatypes.isValidDimArg

if nargin < 2
    needDim = true; % let the core functions handle this case
else
    if ~isValidDimArg(dim)
        error(message('MATLAB:datetime:InvalidVecDim'));
    end
    needDim = false;
end
aData = a.data;

% Because of the way complex sorts by default (on the magnitude, then the
% angle), if the datetimes have high precision and there are multiple tied
% values, the built-in mode will actually return the datetime closest to 1970
% rather than the earliest. Fix that by looking at the third output when any
% of the data have a low-order part and are pre-1970.
getThirdOutput = ~isreal(aData(:)) && any(aData(:) < 0); % < only looks at real part

if nargout < 3 && ~getThirdOutput
    if needDim
        [mData,f] = mode(aData);
    else
        [mData,f] = mode(aData,dim);
    end
else
    if needDim
        [mData,f,c] = mode(aData);
    else
        [mData,f,c] = mode(aData,dim);
    end
    for i = 1:numel(c)
        c_i_data = c{i};
        if ~isscalar(c_i_data) && any(c_i_data < 0) % only sort if necessary
            c_i_data = sort(c_i_data,'ComparisonMethod','real'); % sort as double-doubles
            mData(i) = c_i_data(1); % return smallest double-double
        end
        c_i = a;
        c_i.data = c_i_data;
        c{i} = c_i;
    end
end
m = a;
m.data = mData;
