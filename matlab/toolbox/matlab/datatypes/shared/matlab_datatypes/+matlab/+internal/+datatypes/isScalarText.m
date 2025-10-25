function tf = isScalarText(txt,allowEmptyOrMissing)
%ISSCALARTEXT True for a scalar text value
%   TF = ISSCALARTEXT(TXT) returns true if TXT is a scalar text value, i.e.
%      * a scalar string
%      * a 1xN character vector
%      * the 0x0 char array ''
%
%   TF = ISSCALARTEXT(TXT,FALSE) returns true only if TXT is a non-empty,
%   non-missing text value, i.e.
%      * a scalar string not equal to "", all whitespace, or <missing>
%      * a 1xN character vector for N > 0, not all whitespace
%   
%   Note that ISSCALARTEXT returns FALSE for a scalar cellstr.
%
%   See also MATLAB.INTERNAL.DATATYPES.ISTEXT, ISSPACE, STRINGS.

%   Copyright 2017 The MathWorks, Inc.

if nargin < 2 || allowEmptyOrMissing % allow empty or missing
    if ischar(txt)
        tf = (isrow(txt) || isequal(txt,'')); % empty and missing same for char
    elseif isstring(txt)
        tf = isscalar(txt);
    else
        tf = false;
    end
else % do not allow empty or missing
    if ischar(txt)
        tf = isrow(txt) && ~all(isspace(txt)); % ~all(isspace(txt)) catches 1x0
    elseif isstring(txt)
        tf = isscalar(txt) && ~ismissing(txt) && ~all(isspace(txt));
    else
        tf = false;
    end
end
