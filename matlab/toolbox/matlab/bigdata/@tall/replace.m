function out = replace(in, oldSubstr, newSubstr)
%REPLACE Replace string with another.
%   MODIFIEDSTR = REPLACE(ORIGSTR,OLDSUBSTR,NEWSUBSTR)
%
%   See also TALL/STRING.

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(3,3);

% First input must be a tall string.
tall.checkIsTall(upper(mfilename), 1, in);
in = tall.validateType(in, mfilename, {'string'}, 1);
% Others must not
tall.checkNotTall(upper(mfilename), 1, oldSubstr, newSubstr);

oldSubstr = iWrapScalarString(oldSubstr, "MATLAB:string:MatchMustBeStringCharOrCellArrayOfChars");
newSubstr = iWrapScalarString(newSubstr, "MATLAB:string:ReplacementMustBeStringCharOrCellArrayOfChars");

% We can operate element-wise so long as we broadcast the look-up data.
out = elementfun(@(x) replace(x, oldSubstr, newSubstr), in);
out = setKnownType(out, 'string');
end


function str = iWrapScalarString(str, errID)
% Make sure char inputs for the substrings are converted to string so that
% they are treated as a single element for elementfun.

if ischar(str)
    % Check for column or matrix char arrays before wrapping
    if ~isempty(str) && ~isrow(str)
        throwAsCaller(MException(message(errID)));
    end
    str = string(str);
end
end
