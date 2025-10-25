function [lia,locb] = ismember(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[aData,bData] = datetime.compareUtil(a,b);

if nargout < 2
    lia = ismember(aData,bData,varargin{:});
else
    [lia,locb] = ismember(aData,bData,varargin{:});
end
