classdef IndexingContext
%IndexingContext  Enumeration specifying context in which indexing occurs
%   Use a member of this enumeration as an argument to the listLength
%   function to specify the context in which indexing occurs. The members
%   of this enumeration are Assignment, Expression, and Statement.
%    
%   Assignment specifies that the indexing occurs on the left-hand side of
%   an assignment statement. For example,
%       [ obj.a ] = ...
% 
%   Expression specifies that the indexing occurs as the argument to a
%   function, or another reference context in which multiple outputs from
%   the expression will be used as inputs to another expression. For
%   example,
%       func(obj.a)
% 
%   Statement specifies that the indexing occurs by itself on a line. For
%   example,
%       obj.a;
%
%   When a class uses a mixin to overload indexing, MATLAB passes an
%   instance of this enumeration as an argument to the object's
%   braceListLength, dotListLength, or parenListLength method. The
%   particular method called depends on the type of indexing being
%   performed.
% 
%   When a class uses subsref, subsasgn and numArgumentsFromSubscript to
%   overload indexing, MATLAB passes the indexing context as an argument to
%   the object's numArgumentsFromSubscript method.
%
%   See also listLength, numArgumentsFromSubscript.
%
%   Note: matlab.mixin.util.IndexingContext is the older name for
%   matlab.indexing.IndexingContext with exactly the same behavior,
%   members, and implementation, and continues to be supported. 

%   Copyright 2021 The MathWorks, Inc.

    enumeration
        %Statement Indexed reference occurs by itself
        %   For example, obj.a;
        Statement

        %Expression Indexed reference in an expression
        %   For example, func(obj.a)
        Expression

        %Assignment Indexing on left-hand side of assignment
        %   For example, [ obj.a ] = ...
        Assignment
    end
end
