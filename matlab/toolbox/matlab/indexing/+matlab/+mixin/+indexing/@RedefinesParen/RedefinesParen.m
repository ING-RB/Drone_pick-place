%RedefinesParen  Interface class for overloading parentheses indexing
%   matlab.mixin.indexing.RedefinesParen defines an interface that allows
%   subclasses to overload parentheses indexing. Parentheses indexing on an
%   instance obj of a subclass of RedefinesParen has the following
%   behavior:
%       obj(idx)         calls parenReference
%       obj(idx) = val   calls parenAssign
%       obj(idx) = []    calls parenDelete
%
%   Class authors must define the parenReference, parenAssign, parenDelete,
%   parenListLength, size, cat, and empty methods to provide the desired
%   parentheses indexing behavior for a class. The RedefinesParen class
%   provides additional methods that rely on the abstract ones or error by
%   default. These additional methods can be customized as needed.
%
%   A class that inherits from RedefinesParen is a scalar object that uses
%   overloaded indexing to present itself as an array. 
%
%   When a class inherits from RedefinesParen, compound indexing 
%   expressions that start with parentheses also call class methods.
%   For example:
%       obj(idx).label         calls parenReference
%       obj(idx).label = val   calls parenAssign
%       obj(idx).label = []    calls parenAssign
%   Class authors can often handle compound indexing expressions by
%   forwarding some or all of the later indexing operations to another
%   object. For more information, look for 'forwarding indexing' in the
%   documentation.
%
%   Inheriting from RedefinesParen does not change the behavior of built-in
%   dot indexing (which refers to class properties and methods) or of
%   built-in brace indexing (which issues an error). Redefining these
%   behaviors is possible by inheriting from ForbidsPublicDotMethodCall, 
%   RedefinesDot, or RedefinesBrace in addition to RedefinesParen.
%
%   Subclasses of RedefinesParen must not define subsref, subsasgn, or
%   numArgumentsFromSubscript.
%
%   matlab.mixin.indexing.RedefinesParen methods:
%   Abstract methods:
%       cat             - Concatenate objects
%       empty           - Create empty object of this class
%       parenAssign     - Overload parentheses indexed assignment
%       parenDelete     - Overload parentheses indexed deletion
%       parenListLength - Length of comma-separated list for parentheses
%                         indexing
%       parenReference  - Overload parentheses indexed reference
%       size            - Size of the object
%   Methods implemented using the abstract methods:
%       end             - Compute size in given dimension
%       horzcat         - Horizontal concatenation
%       isempty         - True for empty object
%       length          - Length of vector
%       ndims           - Number of dimensions
%       numel           - Number of elements
%       vertcat         - Vertical concatenation
%   Methods that issue an error by default:
%       ctranspose      - Conjugate transpose
%       reshape         - Reshape object
%       transpose       - Transpose
%
%   See also RedefinesDot, RedefinesBrace, ForbidsPublicDotMethodCall,
%            matlab.indexing.IndexingOperation

%   Copyright 2020-2021 The MathWorks, Inc.

classdef (Abstract, HandleCompatible) RedefinesParen < ...
        matlab.mixin.internal.indexing.ModularIndexingBase
    methods (Abstract, Access = protected)
        %parenReference  Overload parentheses indexed reference
        %    varargout = parenReference(obj, indexOp) is called by MATLAB
        %    for indexed reference expressions that begin with parentheses.
        %    Classes that inherit from RedefinesParen must implement this
        %    protected method. The parenReference method must interpret the
        %    IndexingOperation argument indexOp and return the correct
        %    number of requested outputs as varargout.
        %
        %    In a simple statement such as 
        %        y = obj(idx);
        %    MATLAB calls parenReference with the object obj and an
        %    IndexingOperation with a single element whose Type property is
        %    Paren and whose Indices property is a cell array containing
        %    idx.
        %
        %    In a compound reference statement such as
        %        [y1, y2, y3] = obj(idx).prop; 
        %    MATLAB calls parenReference with an IndexingOperation array
        %    whose two elements have Type properties Paren and Dot, and
        %    requests three outputs.
        %
        %    Class authors can often handle compound indexing expressions
        %    by forwarding some or all of the later indexing operations to
        %    another object. For more information, look for 'forwarding
        %    indexing' in the documentation.
        %
        %    See also parenAssign, parenDelete, parenListLength,
        %             matlab.indexing.IndexingOperation
        varargout = parenReference(obj, indexOp)

        %parenAssign  Overload parentheses indexed assignment
        %    obj = parenAssign(obj, indexOp, varargin) is called by MATLAB
        %    for indexed assignment statements that begin with parentheses.
        %    Classes that inherit from RedefinesParen must implement this
        %    protected method. The parenAssign method must interpret the
        %    IndexingOperation argument indexOp, modify the obj argument
        %    based on the right-hand side values in varargin, and return
        %    the modified object.
        %
        %    In a simple assignment such as
        %        obj(idx) = val;
        %    MATLAB calls parenAssign with the object obj and an
        %    IndexingOperation with a single element whose Type property is
        %    Paren and Indices property is a cell array containing idx. The
        %    third input argument to parenAssign is the right-hand side
        %    value val.
        %
        %    In a compound comma-separated list assignment such as
        %        [obj(idx1,idx2).prop{:}] = rhs{:};
        %    MATLAB first calls parenListLength on obj to determine how
        %    many inputs the object expects to receive in parenAssign.
        %    Assuming that the right-hand side provides enough values,
        %    parenAssign will be called with an IndexingOperation with
        %    three elements describing the Paren, Dot, and Brace indexing
        %    in the statement. The values from the right-hand
        %    side are passed to parenAssign as varargin.
        %
        %    Class authors can often handle compound indexing expressions
        %    by forwarding some or all of the later indexing operations to
        %    another object. For more information, look for 'forwarding
        %    indexing' in the documentation.
        %
        %    See also parenDelete, parenListLength, parenReference,
        %             matlab.indexing.IndexingOperation
        obj = parenAssign(obj, indexOp, varargin)

        %parenDelete  Overload parentheses indexed deletion
        %    obj = parenDelete(obj, indexOp) is called by MATLAB
        %    for single-level indexed deletion expressions. Classes that
        %    inherit from RedefinesParen must implement this protected
        %    method. 
        %
        %    For example, given the statement
        %        obj(idx) = [];
        %    parenDelete is called with the object obj and an
        %    IndexingOperation with a single element whose Type property is
        %    ParenDelete and whose Indices property is a cell array
        %    containing idx.
        %
        %    For compound assignment statements that end with delete, the
        %    appropriate assignment method will be called, and the last
        %    element will have Type property ParenDelete. For example, when
        %    obj overloads dot indexing in the following statement
        %        obj.prop(1) = [];
        %    the dotAssign method of obj will be called with an
        %    IndexingOperation with two elements whose Type properties are
        %    Dot and ParenDelete. The empty matrix will be passed as the
        %    right-hand side argument.
        %
        %    See also parenAssign, parenListLength, parenReference,
        %             matlab.indexing.IndexingOperation
        obj = parenDelete(obj, indexOp)

        %parenListLength  Length of comma-separated list for parentheses indexing
        %    n = parenListLength(obj, indexOp, indexContext) is called when
        %    MATLAB needs to determine the number of
        %    expected inputs to parenAssign or the number of expected
        %    outputs from parenReference for classes that overload
        %    parentheses indexing. Classes that inherit from RedefinesParen
        %    must implement this protected method. It must return a
        %    non-negative integer value.
        %
        %    For example, in an assignment like the following, where obj
        %    overloads parentheses indexing
        %        [obj(idx1,idx2).prop{:}] = ...
        %    MATLAB calls parenListLength to determine the number of values
        %    being assigned. In this case indexOp is an IndexingOperation
        %    with elements describing the Paren, Dot, and Brace operations
        %    in the expression, and indexContext is the value
        %    matlab.indexing.IndexingContext.Assignment. The return value
        %    is the number of inputs the class expects to receive for this
        %    expression.
        %
        %    In an expression like the following, where 'func' is the name
        %    of some MATLAB function, MATLAB calls parenListLength to
        %    determine the number of outputs of the parentheses indexing
        %    expression.
        %        func(obj(idx1,idx2).prop)
        %    In this case indexOp is an IndexingOperation describing the
        %    Paren and Dot operations and indexContext is the value
        %    matlab.indexing.IndexingContext.Expression. The return value
        %    is the number of outputs the class expects to produce in this
        %    situation.
        %
        %    In a statement like the following, MATLAB calls
        %    parenListLength to determine the number of outputs of the
        %    parentheses indexing statement.
        %        obj(idx1,idx2).prop
        %    In this case indexOp is an IndexingOperation describing the
        %    Paren and Dot operations and indexContext is the value
        %    matlab.indexing.IndexingContext.Statement. The return value is
        %    the number of outputs the class expects to produce in this
        %    situation.
        %
        %    In situations where MATLAB can determine the number of input
        %    or output arguments in a statement, it does not call
        %    parenListLength. For example, MATLAB expects a simple
        %    parentheses reference like
        %        obj(idx1,idx2)
        %    to return a single value (possibly an array) of the same class
        %    as obj. In such a case it does not call parenListLength.
        %
        %    If no possible sub-indexing expression on a class can produce
        %    multiple output values nor require multiple input values, then
        %    parenListLength can return 1. Class authors can often handle
        %    compound indexing expressions by creating an intermediate
        %    object representing the indexing done by their own class and
        %    calling listLength on that object, passing the remaining
        %    elements of the IndexingOperation.
        %    For example:
        %        if numel(indexOp) > 1
        %            temp = obj.(indexOp(1));
        %            n = listLength(temp, indexOp(2:end), indexContext);
        %        end
        %
        %    See also listLength, parenAssign, parenDelete, parenReference,
        %             matlab.indexing.IndexingOperation
        n = parenListLength(obj, indexOp, indexContext)
    end

    methods (Abstract, Static, Access = public)
        A = empty(varargin)
    end

    methods (Abstract, Access = public)
        varargout = size(obj, varargin)
        C = cat(dim, varargin)
    end

    methods (Access = public)
        B = ctranspose(obj)
        ind = end(obj, k, n)
        C = horzcat(varargin)
        TF = isempty(obj)
        L = length(obj)
        N = ndims(obj)
        n = numel(obj)
        B = reshape(obj, varargin)
        B = transpose(obj)
        C = vertcat(varargin)
    end
end
