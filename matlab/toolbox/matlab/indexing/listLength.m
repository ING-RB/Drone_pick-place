%listLength  Length of comma-separated list for indexing
%   n = listLength(A, indexingOperation, indexingContext) returns the
%   number of values in a comma-separated list associated with an indexing
%   expression. This function is typically called inside a class that
%   overloads indexing to ask MATLAB how many values an indexing expression
%   will produce given an indexee A.
%
%   The indexingOperation argument is an array of type
%   matlab.indexing.IndexingOperation that describes the indexing being
%   requested.
% 
%   The indexingContext argument is a member of the enumeration
%   matlab.indexing.IndexingContext that tells MATLAB how the indexing
%   occurs. The members of this enumeration are Assignment, Expression, and
%   Statement.
%
%   Given an IndexingOperation with Type field Dot and Name field having
%   the value "field", then
%       n = listLength(A, indexingOperation, ...
%                      matlab.indexing.IndexingContext.Assignment)
%   will return the number of values expected in the comma-separated list
%   on the left-hand side of an assignment statement involving A like the
%   following:
%       [ A.field ] = ...
%
%   In a similar way
%       n = listLength(A, indexingOperation, ...
%                      matlab.indexing.IndexingContext.Statement)
%   will return the number of values returned as a comma-separated list
%   when the indexing on A is performed by itself as a statement like the
%   following:
%       A.field;
%
%   Finally
%       n = listLength(A, indexingOperation, ...
%                      matlab.indexing.IndexingContext.Expression)
%   will return the number of values returned as a comma-separated list
%   when the indexing on A is performed as the argument to a function, like
%   the following:
%       func(A.field)
%
%   Classes that overload indexing must implement a helper method that is
%   called by listLength. For example, when a class overloads brace
%   indexing by inheriting from RedefinesBrace, the class must implement
%   the braceListLength method to tell MATLAB how many values the class
%   expects to return or receive during indexing. Similarly, classes that
%   overload parentheses indexing must implement parenListLength, and
%   classes that overload dot indexing must implement dotListLength.
%
%   In most situations, MATLAB built-in classes return the same value,
%   regardless of the value of IndexingContext. The enumeration is provided
%   to help classes that are overloading indexing determine the way in
%   which indexing is being performed in their class.
%
%   See also matlab.indexing.IndexingOperation, 
%            matlab.indexing.IndexingContext,
%            matlab.mixin.indexing.RedefinesBrace,
%            matlab.mixin.indexing.RedefinesDot,
%            matlab.mixin.indexing.RedefinesParen

%   Copyright 2021 The MathWorks, Inc.
%   Built-in function.
