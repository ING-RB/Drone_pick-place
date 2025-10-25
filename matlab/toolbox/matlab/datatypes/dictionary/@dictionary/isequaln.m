function tf = isequaln(varargin)

    narginchk(2, inf);
    
    tf = matlab.internal.dictionary.isequalImpl(true, varargin{:});
end
%   Copyright 2021-2023 The MathWorks, Inc.
