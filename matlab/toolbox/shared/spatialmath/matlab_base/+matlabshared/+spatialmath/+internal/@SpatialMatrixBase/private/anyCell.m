function v = anyCell(varargin)
%   This function is for internal use only. It may be removed in the future.

%ANYCELL True if any of varargin is a cell array
%   anyCell is computed at codegen compile time because of the coder.unroll

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    v = false;
    for k = coder.unroll(1:nargin)
        if iscell(varargin{k})
            v = true;
            return
        end
    end
end
