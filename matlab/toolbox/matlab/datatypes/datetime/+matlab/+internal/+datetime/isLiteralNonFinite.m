function [tf,varargout] = isLiteralNonFinite(text,literals,includeEmptyStr)
% ISLITERALNONFINITE Find non-finite literals in a text array.
%   TF = ISLITERALNONFINITE(TEXT,LITERALS) returns a logical array the same size
%   as TEXT, containing TRUE where TEXT contains one of the text values in
%   LITERALS. LITERALS is a string array or a cell array of char row vectors,
%   containing values such as 'Inf', 'NaN', or 'NaT'. ISLITERALNONFINITE looks
%   for case-insensitive matches, and also tries to matches against each literal
%   prepended with a +/- sign (*except for 'NaT -- datetimes are not signed'*).
%   TEXT is a string array or a cell array of char row vectors. TEXT may also be
%   a char row vector, treated as the corresponding cellstr.
%   
%   [TF,TF_1,TF_2,...,TF_N] = ISLITERALNONFINITE(TEXT,LITERALS) also returns N
%   logical arrays the same size as TEXT, one for each of the N elements in
%   LITERALS. TF_I contains TRUE where TEXT contains the text value in the I-th
%   element of LITERALS. You may request fewer than N+1 outputs.
%
%   TF = ISLITERALNONFINITE(TEXT,LITERALS,INCLUDEEMPTYSTR) also looks for the
%   empty string ("" or '') when INCLUDEEMPTYSTR is TRUE. FALSE is the default
%   for INCLUDEEMPTYSTR.
%
%   [TF,...,TF_EMPTY] = ISLITERALNONFINITE(TEXT,LITERALS,INCLUDEEMPTYSTR)
%   returns an (N+1)st logical array, TF_EMPTY, the same size as TEXT,
%   containing TRUE where TEXT contains the empty string ("" or '').

% Copyright 2019 The MathWorks, Inc.

if ischar(text)
    tf = false;
else
    tf = false(size(text));
end

nliterals = length(literals);
if nargout > 1, varargout = cell(1,nargout-1); end
% Recognize some special cases that don't support unary +/-.
addSigns = ~matches(literals,"NaT",'IgnoreCase',true);
for i = 1:nliterals
    % Look for each literal in the list, and OR the matches into the accumulated
    % output. Look for NaN and Inf, with and without leading +/- signs, but
    % datetime has no unary +/-, so don't look for NaT with leading +/- sign.
    literal = literals{i};
    if addSigns(i)
        literal = ["" "+" "-"] + literal;
    end
    tf_i = matches(text,literal,'IgnoreCase',true);
    tf = tf | tf_i;
    % Return the matches to the current literal if there's an output for it.
    if nargout > i, varargout{i} = tf_i; end
end

% If the empty strng should be recognized (normally treated as a missing value),
% OR those into the output.
%
lookForEmpty = (nargin > 2) && includeEmptyStr;
wantTFEmpty = (nargout > (nliterals+1));
if lookForEmpty || wantTFEmpty
    tf_empty = (strlength(text) == 0);
    % It would be unusual to ask for the tf_empty output, but to ignore empty
    % text in the first output, but it is allowed.
    if lookForEmpty, tf = tf | tf_empty; end
    % Return the matches to empty text if there's an output for it.
    if wantTFEmpty, varargout{nliterals+1} = tf_empty; end
end
