function S = charRows2string(C,convert0by0ToMissing)
%charRows2string Convert N-D array of char rows to N-D string array
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
% Convert char array to string. Convert blank rows ' ' to <missing> string.
% size(S,2) is 1.
%
% Used inside ismissing and standardizeMissing when:
%   (1) C is a char table variable, or
%   (2) C is a missing indicator.

%   Copyright 2016-2018 The MathWorks, Inc.

% For empty C that are table variables, we want to preserve the size of C
% when calling D = string2charRows(charRows2string(C)). D should equal C.
% We don't use the string(C) constructor because it changes the empty size.

% Don't convert empties to missing strings. We don't need to convert ''
% (and other empties) in ismissing('',...), standardizeMissing('',...), 
% ismissing(table(''),...), or standardizeMissing(table(''),...).
if nargin < 2
    convert0by0ToMissing = false;
end
if isempty(C) && ~(convert0by0ToMissing && isequal(C,''))
    S = string.empty(size(C));
    return
end
% Only convert '' to missing if we explicitly asked for it. This is needed
% only in ismissing(table,'') and standardizeMissing(table,'') where ''
% is used as a missing value indicator.

if ismatrix(C)
    S = string(C);
else
    % We cannot use string because it converts an m-by-n-by-p ND char array
    % into m-by-p string array. We need an m-by-1-by-p string array.
    sizeS = size(C);
    sizeS(2) = 1;
    S = reshape(string(C),sizeS);
end
blankRow = string(repmat(' ',1,size(C,2)));
S(S == blankRow) = string(NaN);
