function aout = cat(dim,varargin)  %#codegen
%CAT Concatenate categorical arrays.
%   C = CAT(DIM, A, B, ...) concatenates the categorical arrays A, B, ...
%   along dimension DIM.  All inputs must have the same size except along
%   dimension DIM.  Any of A, B, ... may also be a cell arrays of character
%   vectors or scalar strings.
%
%   If all the input arrays are ordinal categorical arrays, they must have the
%   same sets of categories, including category order.  If none of the input
%   arrays are ordinal, they need not have the same sets of categories.  In this
%   case, C's categories are the union of the input array categories. However,
%   categorical arrays that are not ordinal but are protected may only be
%   concatenated with other arrays that have the same categories.
%
%   See also HORZCAT, VERTCAT.

%   Copyright 2018-2021 The MathWorks, Inc.

aout = categorical.catUtil(dim,false,varargin{:});
