function [tf,txt] = isText(txtIn, varargin)  %#codegen
%ISTEXT True for an array containing text values

%   Copyright 2018-2020 The MathWorks, Inc.

narginchk(1,3)

if isstring(txtIn)
    % FORBIDCHAR has no impact on string inputs
    % ALLOWEMPTYORMISSING needs to be checked only if false
    if nargin < 3 || varargin{2}
        tf = true;
        txt = txtIn;
    else  % nargin == 3 && ~varargin{2}
        % Require all strings to be non-empty and non-missing.
        if any(ismissing(txtIn))
            tf = false;
            if nargout > 1
                txt = txtIn([]);
            end
        elseif matlab.internal.datatypes.anyIsAllWhitespace(txtIn)
            tf = false;
            if nargout > 1
                txt = txtIn([]);
            end
        else
            tf = true;
        end
    end    
else
    if nargout < 2
        tf = matlab.internal.coder.datatypes.isCharStrings(txtIn, varargin{:});
    else
        [tf,txt] = matlab.internal.coder.datatypes.isCharStrings(txtIn, varargin{:});
    end
end
