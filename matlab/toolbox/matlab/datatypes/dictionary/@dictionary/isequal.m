function tf = isequal(varargin)

    narginchk(2, inf);
    
    tf = matlab.internal.dictionary.isequalImpl(false, varargin{:});
end

%   Copyright 2021-2023 The MathWorks, Inc.
