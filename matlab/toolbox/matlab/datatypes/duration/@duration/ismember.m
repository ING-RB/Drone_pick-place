function [lia,locb] = ismember(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[amillis,bmillis] = duration.compareUtil(a,b);

if nargout < 2
    lia = ismember(amillis,bmillis,varargin{:});
else
    [lia,locb] = ismember(amillis,bmillis,varargin{:});
end
