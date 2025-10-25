function s = substruct(type,subs,varargin)
%substruct Create structure argument for subsref or subsasgn.
%   substruct is a convenient way to create a structure with the fields
%   required for calls to the subsref or subsasgn functions.
%
%   Syntax
%     S = substruct(type1, subscript1, type2, subscript2, ...)
%
%   Input Arguments
%     The input arguments must occur in pairs. Each pair consists of a type
%     and a subscript.
%       type       type of indexing performed
%                  Must be a character vector or string scalar with one of
%                  the values '()', '.', or '{}'.
%
%       subscript  If the corresponding type is '.', the value of this
%                  argument must be a character vector containing the name
%                  used for dot-indexing. If the corresponding type is '()'
%                  or '{}', the value of this argument must be a cell array
%                  containing the indices.
%
%   Output Arguments
%     Structure array with two fields, type and subs. Each element of the
%     array contains one pair of the input arguments and corresponds to a
%     different dot, brace, or paren operation within the indexing
%     expression.
%
%   Example
%     To call subsref with arguments equivalent to the following syntax:
%       B = A(3,5).field;
%     Use the following commands:
%       S = substruct('()',{3,5},'.','field'); B = subsref(A, S);
%     The substruct S is an array with two elements, one for each operation
%     within the indexing expression. In this case there are two operations
%     within the indexing expression, paren and dot.
%
%   See also subsref, subsasgn, numArgumentsFromSubscript.

% Copyright 1984-2024 The MathWorks, Inc.

nlevels = nargin / 2;
if nlevels < 1
    error(message('MATLAB:substruct:nargin'))
elseif rem(nlevels,1)
    error(message('MATLAB:substruct:narginOdd'))
end

s.type = type;
s.subs = subs;
if nlevels > 1
    s(2:nlevels) = struct('type',varargin(1:2:end),'subs',varargin(2:2:end));
end
