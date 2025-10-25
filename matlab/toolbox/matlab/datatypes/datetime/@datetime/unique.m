function [a,i,j] = unique(a,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

[rows,sorted] = setMembershipFlags(varargin{:});

if isa(a,"datetime")
    % ensure an all-zero imag part is dropped
    aData = a.data + 0;
    
    % call unique with appropriate output args for optimal performance
    if nargout == 1
        aData = unique(aData,varargin{:});
    elseif nargout == 2
        [aData,i] = unique(aData,varargin{:});
    else 
        [aData,i,j] = unique(aData,varargin{:});
    end
    
    if sorted
        if nargout == 1
            aData = setMembershipSort(aData,rows);
        elseif nargout == 2
            [aData,i] = setMembershipSort(aData,i,rows);
        else % nargout == 3
            [aData,i,reord] = setMembershipSort(aData,i,rows);
            ireord(reord) = 1:length(reord);
            j(:) = ireord(j);
        end
    end
    a.data = aData;
else
    [a,i,j] = matlab.internal.datatypes.fevalFunctionOnPath("unique",a,varargin{:});
end