%IndexingOperation  Describe indexing expression for overloaded indexing
%   An array of matlab.indexing.IndexingOperation objects describes an
%   indexing expression. Methods of overloaded indexing classes
%   (RedefinesParen, RedefinesDot, and RedefinesBrace) receive arrays of
%   IndexingOperation objects. The length of the array corresponds to the
%   number of indexing operations in the expression.
%
%   Each IndexingOperation in an array has a Type property corresponding to
%   the indexing being performed. The Type can be Paren, ParenDelete, Dot,
%   or Brace. The IndexingOperation also has either a Name property (when
%   the Type is Dot) or an Indices property (when the Type is not Dot). For
%   example, for an indexing expression like A(1,2).Property{3}, the
%   corresponding IndexingOperation "indexOp" will have length 3. The three
%   individual elements of indexOp are:
%       Element 1:
%           Type: Paren
%           Indices: {[1]  [2]}
%       Element 2:
%           Type: Dot
%           Name: "Property"
%       Element 3:
%           Type: Brace
%           Indices: {[3]}
%
%   The Type property of the first element of an IndexingOperation array
%   always corresponds to the first indexing operation performed and the
%   method called by MATLAB to perform indexing. In parenReference or
%   parenAssign, for example, the first element of the IndexingOperation
%   array has the Type Paren.
%
%   The Name property of the IndexingOperation is the argument to a dot
%   indexing operation. It is often a string.
%
%   The Indices property of the IndexingOperation is a cell array
%   containing the indices used in a parentheses or brace indexing
%   operation.
%
%   A class that overloads indexing may need to delegate the handling of
%   part of an indexing expression to another object. Container classes
%   frequently do this to allow indexing into contained objects. This is
%   known as forwarding an indexing operation.
%
%   Forwarding uses the same syntax as dynamic field reference, with an
%   IndexingOperation in place of the field name. Forwarding an
%   IndexingOperation causes MATLAB to apply the indexing contained in the
%   IndexingOperation to the target. The class that forwards the indexing
%   does not need to interpret or process the contents of the
%   IndexingOperation.
% 
%   For example, given the IndexingOperation "indexOp" described previously
%   then
%       obj.(indexOp)
%   is equivalent to the following indexing expression.
%       obj(1,2).Property{3}
%   Similarly,
%       obj.PrivateProperty.(indexOp(2:end)) = val;
%   is equivalent to the following assignment statement.
%       obj.PrivateProperty.Property{3} = val;
%   The IndexingOperation being forwarded must contain at least one
%   element.
%   Forwarding must be the final indexing operation in an expression. In
%   the following expression:
%       obj.(idx1).(idx2)
%   idx2 may be an IndexingOperation, but idx1 may not.
%     
%   When forwarding an IndexingOperation, dot indexing operations maintain
%   the access permissions of the line of code where the indexing
%   originated. MATLAB uses the access permission of the originating line
%   of code to determine whether a property or method is accessible when
%   forwarding.
%     
%   For example, consider a class that overloads parentheses indexing,
%   defines a private property PrivateProperty, and has the following
%   parenReference method.
%       function out = parenReference(obj, indexOp)
%           out = obj.(indexOp(2));
%       end
%   Outside the class:
%       obj.PrivateProperty issues an error because PrivateProperty is
%         inaccessible.
%       obj(1).PrivateProperty calls parenReference. The value
%         indexOp(2) is an IndexingOperation with Type property Dot and
%         Name property "PrivateProperty", and the access permissions of
%         outside the class. This issues the same error as
%         obj.PrivateProperty.
%   Inside the class:
%       obj.PrivateProperty returns the value of the private property.
%       obj(1).PrivateProperty calls parenReference. The value
%         indexOp(2) is the same as before but has the access permissions
%         of inside the class. This statement returns the value of the
%         private property.
%     
%   An IndexingOperation array is created by MATLAB as a result of indexing
%   into a class that overloads indexing. Concatenating, reshaping, or
%   modifying elements of an IndexingOperation array is not supported.
%   
%   IndexingOperation properties:
%       Type     - IndexingOperationType describing the indexing performed
%       Name     - Argument of a dot indexing operation
%       Indices  - Cell array of indices for paren or brace indexing 
%  
%   See also matlab.mixin.indexing.RedefinesParen,
%            matlab.mixin.indexing.RedefinesDot,
%            matlab.mixin.indexing.RedefinesBrace,
%            matlab.indexing.IndexingOperationType

%   Copyright 2021 The MathWorks, Inc.

%{
properties
     %Type  IndexingOperationType describing the indexing performed
     %   The enumerated type matlab.indexing.IndexingOperationType
     %   has members Paren, ParenDelete, Dot, and Brace.
     Type;

     %Name  Argument of a dot indexing operation
     %   When the Type of an IndexingOperation is Dot then it also has a
     %   Name property. For an expression like 
     %       obj.prop
     %   the IndexingOperation is a scalar object with Type Dot and the
     %   Name property set to the string "prop". For an expression like
     %       obj.(idx)
     %   the IndexingOperation is a scalar object with Type Dot and the
     %   Name property set to the value of idx. In cases like this the Name
     %   is not necessarily a string.
     Name;

     %Indices  Cell array of indices for paren or brace indexing 
     %   When the Type of an IndexingOperation is Paren, ParenDelete, or
     %   Brace, then it also has an Indices property. For an expression 
     %   like
     %       obj(idx,idy)
     %   the IndexingOperation is a scalar object with Type Paren and the
     %   Indices property set to the cell array {idx, idy}. 
     Indices;
end
%}
