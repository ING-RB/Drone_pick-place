function s = extractBetween(str,startStr,endStr,varargin)
%EXTRACTBETWEEN Create a string from part of a larger string.
%   S = EXTRACTBETWEEN(STR, START, END)
%   S = EXTRACTBETWEEN(..., 'Boundaries', B)
%
%   Limitations:
%   EXTRACTBETWEEN on tall string arrays does not support expansion in
%   the first dimension.
%
%   See also TALL/STRING.

%   Copyright 2016-2023 The MathWorks, Inc.

narginchk(3,5);

% First input must be tall string.
tall.checkIsTall(upper(mfilename), 1, str);
str = tall.validateType(str, mfilename, {'string'}, 1);

% Treat all inputs slice-wise, wrapping char arrays if used. We allow
% expansion or contraction in small dimensions, but not the tall dim.
startStr = wrapBoundaryInput(startStr);
endStr = wrapBoundaryInput(endStr);
s = slicefun(@(a,b,c) iSubstring(a,b,c,varargin{:}), str, startStr, endStr);

% The output is the same type as the input. Use the size set up by SLICEFUN.
s.Adaptor = copySizeInformation(str.Adaptor, s.Adaptor);

s = tall.validateVertcatConsistent(s, @iThrowBlocksMustHaveSameNumber);
end


function out = iSubstring(in, varargin)
% Call substring and check that it acted slice-wise.

% Take care over empty partitions. We need to return something that will
% successfully concatenate regardless of how the other partitions expand.
if size(in,1)==0
    out = string.empty(0,0);
    return;
end

try
    out = extractBetween(in, varargin{:});
catch err
    % The original error also includes the position of the element that did
    % not match. As we cannot match this in the tall world, we issue a
    % similar error without the position.
    if err.identifier == "MATLAB:string:MustHaveSameNumberOf"
        iThrowRowsMustHaveSameNumber(in, varargin{1:2});
    end
    rethrow(err);
end

if size(out,1) ~= size(in,1)
    % Tried to change the tall size
    if isscalar(in) && isempty(out)
        % If the input was scalar and there was no match we get a 0x1 empty instead
        % of a 1x0. Fix that now.
        out = reshape(out, [1,0]);
    else
        % If not empty then we must be trying to return multiple matches
        error(message("MATLAB:bigdata:array:MultipleSubstrings"));
    end
end
end

function iThrowRowsMustHaveSameNumber(in, startStr, endStr)
% Throw a MustHaveSameNumberOf as a result of two rows in a block having
% different number of matches.

% Find the difference in number of elements that triggered the error.
numPrev = numel(extractBetween(in(1), startStr(1), endStr(1)));
for ii = 2:numel(in)
    numFound = numel(extractBetween(in(ii), startStr(min(ii, end)), endStr(min(ii, end))));
    if numFound ~= numPrev
        break;
    end
end
iThrowMustHaveSameNumber(numPrev, numFound);
end

function iThrowBlocksMustHaveSameNumber(prevAdaptor, nextAdaptor)
% Throw a MustHaveSameNumberOf as a result of two blocks having different
% small sizes.
numPrev = prevAdaptor.getSizeInDim(2);
numFound = nextAdaptor.getSizeInDim(2);
iThrowMustHaveSameNumber(numPrev, numFound);
end

function iThrowMustHaveSameNumber(numPrev, numFound)
% Throw a MustHaveSameNumberOf error using a tall-specific wrapper.
error("MATLAB:string:MustHaveSameNumberOf", ...
            getString(message("MATLAB:bigdata:array:StringMustHaveSameNumberOf", numFound, numPrev)));
end
