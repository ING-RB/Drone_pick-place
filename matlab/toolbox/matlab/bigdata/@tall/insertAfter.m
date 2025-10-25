function s = insertAfter(str,pos,text)
%INSERTAFTER Insert text after a specified position.
%   S = INSERTAFTER(STR, POS, TEXT)
%
%   Limitations:
%   If POS is an array of pattern objects, the size of the first dimension
%   of the array must be 1.
%
%   See also INSERTAFTER, TALL/STRING.

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(3,3);

% We require that the first input is the tall array and the others are
% plain strings or similarly sized tall arrays of strings. The POS input
% can also be a number.
tall.checkIsTall(upper(mfilename), 1, str);
str = validateAndMaybeWrap(str, mfilename, 1, {'string', 'cell'});
pos = validateAndMaybeWrap(pos, mfilename, 2, {'string', 'cell', 'numeric', 'pattern'});
text = validateAndMaybeWrap(text, mfilename, 3, {'string', 'cell'});

s = elementfun(@insertAfter, str, pos, text);

% Type is preserved, but size may have changed.
s.Adaptor = copySizeInformation(str.Adaptor, s.Adaptor);
end

function arg = validateAndMaybeWrap(arg, fcnName, argIdx, validTypes)
% Check a string input to make sure it is valid. If a char array, wrap it
% to prevent dimension expansion.

if ~istall(arg) && (ischar(arg) || isa(arg,"pattern"))
    arg = wrapPositionInput(arg, argIdx);
else
    % Check tall or local input against valid types
    arg = tall.validateType(arg, fcnName, validTypes, argIdx);
end
end % validateAndMaybeWrap

