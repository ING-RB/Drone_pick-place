function [tf,txt] = isText(txt, varargin)
%ISTEXT True for an array containing text values
%   TF = ISTEXT(TXT) returns true if TXT is an array containing text, i.e. TXT is
%      * a string array
%      * a 1xN character vector
%      * the 0x0 char array ''
%      * a cell array containing char row vectors or ''
%   and false otherwise. In particular, ISTEXT returns false if TXT is a cell
%   array that contains [] in any element, or if TXT is not a row. Note that
%   the latter is different than how ISCELLSTR behaves.
%
%   TF = ISTEXT(TXT,FORBIDCHAR), when FORBIDCHAR is true, returns true only when
%   TXT is a string array or a cell array containing char row vectors, and false
%   otherwise. In particular, ISTEXT(TXT,TRUE) returns false if TXT is a char
%   row vector. This supports pre-string syntaxes where a function requires a
%   cellstr, and does not accept a raw char row.
%
%   TF = ISTEXT(S,FORBIDCHAR,FALSE) returns true only if TXT contains
%   non-empty, non-missing text, i.e. TXT is
%      * a string array whose elements not equal to "", all whitespace, or <missing>
%      * a 1xN character vector for N > 0, not all whitespace
%      * a cell array containing non-empty, non-missing char row vectors
%
%   When TXT is a char row vector, [TF,TXT] = ISTEXT(TXT,...) also returns
%   {TXT}.  If TXT is a string array or cell array containing char row vectors,
%   ISTEXT returns TXT itself.  Otherwise, ISTEXT returns a 0x0 cell or string
%   array in TXT.
%
%   See also MATLAB.INTERNAL.DATATYPES.ISSCALARTEXT, ISSPACE, STRINGS.

%   Copyright 2017-2018 The MathWorks, Inc.

import matlab.internal.datatypes.isCharStrings
import matlab.internal.datatypes.anyIsAllWhitespace

narginchk(1,3)

if isstring(txt)
    % FORBIDCHAR has no impact on string inputs
    % ALLOWEMPTYORMISSING needs to be checked only if false
    if nargin < 3 || varargin{2}
        tf = true;
    else  % nargin == 3 && ~varargin{2}
        % Require all strings to be non-empty and non-missing.
        if any(ismissing(txt))
            tf = false;
            if nargout > 1
                txt(1:end) = [];
                txt = reshape(txt,0,0); % faster than string.empty
            end
        elseif anyIsAllWhitespace(txt)
            tf = false;
            if nargout > 1
                txt(1:end) = [];
                txt = reshape(txt,0,0); 
            end
        else
            tf = true;
        end
    end    
else
    if nargout < 2
        tf = isCharStrings(txt, varargin{:});
    else
        [tf,txt] = isCharStrings(txt, varargin{:});
    end
end
