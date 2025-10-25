function obj = subsasgn(obj, S, b)
%SUBSASGN indexed assignment for tall
%   A = SUBSASGN(A, S, B) is the functional form of assignment for a tall
%   array A.
%
%   The supported forms of assignment are:
%   A(L, SUBS...) = B
%   where: A is a tall array with a non-empty second dimension
%          L is a logical tall selecting slices of A
%          SUBS... is zero or more non-tall trailing subscripts
%          B is a non-tall scalar value
%   A(:, SUBS...) = B
%   where: A is a tall array with a non-empty second dimension
%          The subscript in the tall dimension is ':'
%          SUBS... is zero or more non-tall trailing subscripts
%          B is a non-tall scalar value
%   A(L, SUBS...) = B
%   where: L is a logical tall selecting slices of A
%          SUBS... is zero or more non-tall trailing subscripts
%          B is a tall array derived from A(L, SUBS...)
%   A(L, SUBS...) = []
%   where: L is a logical tall selecting slices of A
%          SUBS... is zero or more non-tall trailing subscripts
%   A(:, SUBS...) = []
%   where: The subscript in the tall dimension is ':'
%          Any other combination of subscripts
%
%   See also subsasgn, tall.

%   Copyright 2015-2019 The MathWorks, Inc.

try
    obj = iSubsasgn(obj, S, b);
catch E
    throwAsCaller(E);
end
end

function obj = iSubsasgn(obj, S, b)
% Internal implementation of tall/subsasgn.

% This prevents this frame and anything below it being added to the gather
% error stack.
markerFrame = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

% Make sure S is a valid substruct
S = checkTallSubs(S, mfilename, 'MATLAB:bigdata:array:SubsasgnInvalidTallSubscript');

creating = isnumeric(obj) && isequal(obj, []);
if creating
    error(message('MATLAB:bigdata:table:CreateUnsupported'));
end

deleting = isnumeric(b) && builtin('_isEmptySqrBrktLiteral',b) ...
    && (isscalar(S) || ((length(S) == 2) && isequal(S(2).type,'()')));

isBraceIndexing = isequal(S(1).type, '{}');

sz = size(obj);
if deleting && ~isBraceIndexing % no deleting form of brace indexing
    switch S(1).type
        case '()'
            method = @subsasgnParensDeleting;
        case '.'
            method = @subsasgnDotDeleting;
    end
    obj = method(obj.Adaptor, obj.ValueImpl, sz.ValueImpl, S);
else
    switch S(1).type
        case '()'
            method = @subsasgnParens;
        case '{}'
            method = @subsasgnBraces;
        case '.'
            method = @subsasgnDot;
    end
    obj = method(obj.Adaptor, obj.ValueImpl, sz.ValueImpl, S, b);
end
end