function tf = isCharString(s,allowEmpty)  %#codegen
%ISCHARSTRING True for a string
%   T = ISCHARSTRING(S) returns true if S is a 1xN character vector
%   for N >= 0, or the 0x0 char array ''.
%
%   T = ISCHARSTRING(S,FALSE) returns true only if S is a non-empty
%   character vector.

%   Copyright 2019-2020 The MathWorks, Inc.

if nargin < 2 || allowEmpty
    % '' can be 0x0 or 1x0 depending on whether it was obtained from MATLAB or
    % create in codegen. So we explicitly check if size is 0x0 and the 1x0 case
    % will be handled by isrow(s).
    tf = ischar(s) && ((coder.internal.isConst(size(s,1)) && isrow(s)) || ...
        (coder.internal.isConst(size(s)) && isequal(size(s),[0 0])));
else
    tf = ischar(s) && (coder.internal.isConst(size(s,1)) && isrow(s)) && ~all(isspace(s));
end
