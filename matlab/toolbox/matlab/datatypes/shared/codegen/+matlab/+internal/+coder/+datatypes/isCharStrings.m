function [tf,txtout] = isCharStrings(txtin, rawrequirecell, rawallowempty)  %#codegen
%ISCHARSTRINGS True for a char row vector, or '', or a cell array of same
%   TF = ISCHARSTRINGS(TXT) returns true if TXT is:
%      * a 1xN character vector
%      * the 0x0 char array ''
%      * a cell array containing char row vectors or ''
%   and false otherwise. In particular, ISCHARSTRINGS returns false if TXT is a cell
%   array that contains [] in any element, or if TXT is not a row. Note that
%   the latter is different than how ISCELLSTR behaves.
%
%   TF = ISCHARSTRINGS(TXT,FORBIDCHAR), when FORBIDCHAR is true, returns true only when
%   TXT is a cell array containing char row vectors, and false
%   otherwise. In particular, ISCHARSTRINGS(TXT,TRUE) returns false if TXT is a char
%   row vector. This supports pre-string syntaxes where a function requires a
%   cellstr, and does not accept a raw char row.
%
%   TF = ISCHARSTRINGS(S,FORBIDCHAR,FALSE) returns true only if TXT contains
%   non-empty, non-missing text, i.e. TXT is
%      * a 1xN character vector for N > 0, not all whitespace
%      * a cell array containing non-empty, non-missing char row vectors
%
%   When TXT is a char row vector, [TF,TXT] = ISCHARSTRINGS(TXT,...) also returns
%   {TXT}.  If TXT is a cell array containing char row vectors,
%   ISCHARSTRINGS returns TXT itself.  Otherwise, ISCHARSTRINGS returns a 0x0 cell in TXT.
%
%   See also MATLAB.INTERNAL.DATATYPES.ISSCALARTEXT, ISSPACE, STRINGS.

%   Copyright 2018-2021 The MathWorks, Inc.

if nargin > 1
    coder.internal.prefer_const(rawrequirecell);
    requirecell = matlab.internal.coder.datatypes.validateLogical(rawrequirecell, 'requirecell');
    if nargin > 2
        coder.internal.prefer_const(rawallowempty);
        allowempty = matlab.internal.coder.datatypes.validateLogical(rawallowempty, 'allowempty');
    else
        allowempty = true;
    end
else
    requirecell = false;
    allowempty = true;
end

if iscell(txtin)
    tfcellstr = true;
    % need to unroll for long cellstrs (length > 1024)
    coder.unroll(~coder.target('MATLAB') && ~coder.internal.isHomogeneousCell(txtin));
    for i = 1:numel(txtin)
        if ~(ischar(txtin{i}) && (isrow(txtin{i}) || (allowempty && ...
                isequal(size(txtin{i}), [0 0]))))
            tfcellstr = false;
            break;
        end
    end
else
    tfcellstr = false;
end

if requirecell
    tf = tfcellstr;
else
    tf = tfcellstr || (ischar(txtin) && (isrow(txtin) || (allowempty && ...
        isequal(size(txtin), [0 0]))));  %#ok<*ISCLSTR>
end

if tf
    if ischar(txtin)
        txtout = {txtin};
    else
        txtout = txtin;
    end
else
    txtout = {};
end
