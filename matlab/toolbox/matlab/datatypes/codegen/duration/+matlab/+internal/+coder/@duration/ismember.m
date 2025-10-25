function [lia,locb] = ismember(a,b,varargin) %#codegen
%ISMEMBER Find durations in one array that occur in another array.

%   Copyright 2020 The MathWorks, Inc.

[amillis,bmillis] = duration.compareUtil(a,b);

if nargout < 2
    lia = ismember(amillis,bmillis,varargin{:});
else
    [lia,locb] = ismember(amillis,bmillis,varargin{:});
end
