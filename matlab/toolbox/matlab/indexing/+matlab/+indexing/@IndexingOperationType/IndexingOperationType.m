%IndexingOperationType  Enumeration specifying kind of indexing operation
%   MATLAB uses an array of matlab.indexing.IndexingOperation objects to
%   describe an overloaded indexing expression. Each element of the array
%   has a Type property whose value is the member of the enumeration
%   matlab.indexing.IndexingOperationType that corresponds to the type of
%   indexing requested. The members of this enumeration are Paren,
%   ParenDelete, Dot, and Brace.
%
%   For example, when A overloads dot indexing, the statement
%       A.label(idx) = val;
%   generates an IndexingOperation array with two elements. The Type
%   property of the first is IndexingOperationType.Dot, and the Type
%   property of the second is IndexingOperationType.Paren.
%
%   When an assignment statement ends in a parentheses deletion operation,
%   the last element of the IndexingOperation array has Type property
%   IndexingOperationType.ParenDelete.
%   For example, when A overloads parentheses indexing, the statement
%       A(idx) = [];
%   generates an IndexingOperation array with a single element whose Type
%   property is ParenDelete.
%   When A overloads dot indexing, the statement
%       A.label(idx) = [];
%   generates an IndexingOperation array with two elements. The Type
%   property of the first is IndexingOperationType.Dot, and the Type
%   property of the second is IndexingOperationType.ParenDelete.
%
%   See also matlab.indexing.IndexingOperation.

%   Copyright 2021 The MathWorks, Inc.

%{
enumeration
    %Paren  Parentheses reference or assignment
    %    x(idx)         Parentheses reference
    %    x(idx) = val;  Parentheses assignment
    Paren;
    %ParenDelete  Parentheses deletion
    %    x(idx) = [];
    ParenDelete;
    %Dot  Dot reference or assignment
    %    x.label        Dot reference
    %    x.label = val; Dot assignment
    Dot;
    %Brace  Brace reference or assignment
    %    x{idx}         Brace reference
    %    x{idx} = val;  Brace assignment
    Brace;
end
%}