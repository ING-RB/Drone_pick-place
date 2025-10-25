function validateTextInCell(in, srcName)
%VALIDATETEXTINCELL Validates cell arrays that contain purely text data
%   VALIDATETEXTINCELL(IN, SRCNAME) ensures that cell array IN containing
%   only text data do not contain discouraged patterns. These include:
%   1. Cell arrays containing only strings
%   2. Cell arrays containing only a mix of character vectors and strings
%   Both of these can be represented as string matrices or cell array of
%   character vectors.

%   Author: Dinesh Iyer
%   Copyright 2017 The MathWorks Inc.

if ~iscell(in) || iscellstr(in)
    return;
end

messagePrefix = 'MATLAB:imagesci:stringSupport';

% We do not want to support cell arrays containing only strings.
if all(cellfun(@(x) isscalar(x) && isstring(x), in))
    m = message([messagePrefix ':cellOfStringsNotSupported']);
    throwException(m, srcName);
end

% We do not want to support cell arrays that containing only char
% arrays and strings
if numel( find( cellfun(@(x) ischar(x), in) | ...
                    cellfun(@(x) isscalar(x) && isstring(x), in) ) ) == numel(in)
    m = message([messagePrefix ':cellOfStringsAndCharsNotSupported']);
    throwException(m, srcName);
end


function throwException(m, srcName)

errorID = regexprep(m.Identifier, 'stringSupport', srcName);
ME = MException(errorID, getString(m));
throw(ME);
