function tf = issorted(this,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},'ComparisonMethod')
        error(message('MATLAB:sort:InvalidAbsRealType',class(this)));
    end
end

if (nargin == 2) && matlab.internal.math.checkInputName(varargin{1},'rows')
    % Use issortedrows because datetime must use 'real' comparison for the
    % complex .data, and issorted(A,'rows') does not support that.
    tf = issortedrows(this.data,'ComparisonMethod','real');
else
    tf = issorted(this.data,varargin{:},'ComparisonMethod','real');
end
