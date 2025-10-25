function d = NaT(varargin) %#codegen
%

%   Copyright 2015-2024 The MathWorks, Inc.


if nargin == 0
    d = datetime.fromMillis(NaN);
else
    paramsStart = 0;
    for ii = 1:numel(varargin)
        
        if ~isnumeric(varargin{ii}) && (paramsStart == 0)
            paramsStart = ii;
            break
        end
    end
    
    if paramsStart == 0
        d = datetime.fromMillis(NaN(varargin{:}));
    else
        d = datetime(0,0,0,0,0,nan(varargin{1:(paramsStart-1)}),varargin{paramsStart:end});
    end
end
end

