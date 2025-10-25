function [s, maxVarLen, lostWidth] = alignTabularContents(s, lostWidth)
% When the variables in a table are strings or chars, there is a
% possibility for them to be misaligned. For instance, strings
% containing hyperlinks will show up on the command window as
% possibly a different character width than what strlength()
% returns. Same for <strong> text. International characters also
% pose this problem, since the widths of Unicode characters cannot
% be guaranteed to be the same, usually causing strings containing
% international characters to be wider than ASCII text with the
% same number of characters.

% The purpose of alignTabularContents is to check for these
% potential cases of misalignment and adjust the strings properly
% so they are as close to even as possible. wrappedLength() is used
% to accurately obtain the display width of each line of text. For
% the case of international characters, it is impossible to line
% them up exactly due to them being non-integral character lengths.
% Thus, the remainder is tracked to ensure they are aligned within
% 1 character of other ASCII lines.

% alignTabularContents is used to align table variables that are
% nx1 strings or multi-column table variables to ensure that each
% sub-column of a table variable is aligned properly, before that
% variable is aligned with other variables in the table.

import matlab.internal.tabular.display.containsRegexp;
import matlab.internal.tabular.display.vectorizedWrappedLength;
import matlab.internal.tabular.display.alignTabularVar;

if nargin < 2
    [rows, cols] = size(s);
    lostWidth = zeros(rows,1);
else
    %rows = size(s,1);
    cols = 1;
end

tagged = containsRegexp(s,'<a\s+href\s*=|<strong>');
varLengthM = strlength(s);
for idx = 1:numel(s)
    tagged(idx) = tagged(idx) || any(s{idx} > char(128));
end
varLengthM(tagged) = vectorizedWrappedLength(s(tagged));
for c=1:cols
    varLength = varLengthM(:,c);
    [s(:,c),maxVarLen,lostWidth] = alignTabularVar(s(:,c),lostWidth,varLength);
end
end