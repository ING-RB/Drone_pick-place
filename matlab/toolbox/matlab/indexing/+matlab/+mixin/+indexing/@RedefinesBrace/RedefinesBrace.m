%RedefinesBrace  Interface class for overloading brace indexing
%   matlab.mixin.indexing.RedefinesBrace defines an interface that allows
%   subclasses to overload brace indexing. Brace indexing on an instance
%   obj of a subclass of RedefinesBrace has the following behavior:
%       obj{idx}           calls braceReference
%       obj{idx} = val     calls braceAssign
%       [obj{idx}] = val   calls braceAssign
%   Class authors must define the braceReference, braceAssign, and
%   braceListLength methods to provide the desired brace indexing behavior
%   for a class. 
%
%   When a class inherits from RedefinesBrace, compound indexing 
%   expressions that start with brace also call braceReference and 
%   braceAssign. For example:
%       obj{idx}.label             calls braceReference
%       obj{idx}.label = val       calls braceAssign
%       [obj{idx}.label] = val     calls braceAssign
%       obj{idx1}(idx2) = []       calls braceAssign
%   Class authors can often handle compound indexing expressions by
%   forwarding some or all of the later indexing operations to another
%   object. For more information, look for 'forwarding indexing' in the
%   documentation.
%
%   Inheriting from RedefinesBrace does not change the behavior of built-in
%   parentheses indexing (which indexes into an array of objects) or of
%   built-in dot indexing (which refers to class properties and methods).
%   Redefining these behaviors is possible by inheriting from
%   RedefinesParen, RedefinesDot, or ForbidsPublicDotMethodCall in addition
%   to RedefinesBrace.
%
%   Subclasses of RedefinesBrace must not define subsref, subsasgn,
%   or numArgumentsFromSubscript.
%
%   matlab.mixin.indexing.RedefinesBrace methods:
%        braceAssign     - Overload brace indexing assignment
%        braceListLength - Length of comma-separated list for brace
%                          indexing
%        braceReference  - Overload brace indexing reference
%
%   See also RedefinesParen, RedefinesDot, ForbidsPublicDotMethodCall,
%            matlab.indexing.IndexingOperation

%   Copyright 2020-2021 The MathWorks, Inc.


classdef (Abstract, HandleCompatible) RedefinesBrace < ...
        matlab.mixin.internal.indexing.ModularIndexingBase

    methods (Abstract, Access = protected)
        %braceReference  Overload brace indexed reference
        %    varargout = braceReference(obj, indexOp) is called by MATLAB
        %    for indexed reference expressions that begin with brace.
        %    Classes that inherit from RedefinesBrace must implement this
        %    protected method. The braceReference method must interpret the
        %    IndexingOperation argument indexOp and return the correct
        %    number of requested outputs as varargout.
        %
        %    In a simple statement such as 
        %        y = obj{idx};
        %    MATLAB calls braceReference with the object obj and an
        %    IndexingOperation with a single element whose Type property is
        %    Brace and whose Indices property is a cell array containing
        %    idx.
        %
        %    In a compound reference statement such as
        %        [y1, y2, y3] = obj{idx}.prop; 
        %    MATLAB calls braceReference with an IndexingOperation array
        %    whose two elements have Type properties Brace and Dot, and
        %    requests three outputs.
        %
        %    Class authors can often handle compound indexing expressions
        %    by forwarding some or all of the later indexing operations to
        %    another object. For more information, look for 'forwarding
        %    indexing' in the documentation.
        %
        %    See also braceAssign, braceListLength,
        %             matlab.indexing.IndexingOperation
        varargout = braceReference(obj, indexOp)

        %braceAssign  Overload brace indexed assignment
        %    obj = braceAssign(obj, indexOp, varargin) is called by MATLAB
        %    for indexed assignment statements that begin with brace.
        %    Classes that inherit from RedefinesBrace must implement this
        %    protected method. The braceAssign method must interpret the
        %    IndexingOperation argument indexOp, modify the obj argument
        %    based on the right-hand side values in varargin, and return
        %    the modified object.
        %
        %    In a simple assignment such as
        %        obj{idx} = val;
        %    MATLAB calls braceAssign with the object obj and an
        %    IndexingOperation with a single element whose Type property is
        %    Brace and Indices property is a cell array containing idx. The
        %    third input argument to braceAssign is the right-hand side
        %    value val.
        %
        %    In a compound comma-separated list assignment such as
        %        [obj{idx1,idx2}.prop{:}] = rhs{:};
        %    MATLAB first calls braceListLength on obj to determine how
        %    many inputs the object expects to receive in braceAssign.
        %    Assuming that the right-hand side provides enough values,
        %    braceAssign will be called with an IndexingOperation with
        %    three elements describing the Brace, Dot, and Brace indexing
        %    in the statement. The values from the right-hand side are
        %    passed to braceAssign as varargin.
        %
        %    Class authors can often handle compound indexing expressions
        %    by forwarding some or all of the later indexing operations to
        %    another object. For more information, look for 'forwarding
        %    indexing' in the documentation.
        %
        %    See also braceListLength, braceReference,
        %             matlab.indexing.IndexingOperation
        obj = braceAssign(obj, indexOp, varargin)

        %braceListLength  Length of comma-separated list for brace indexing
        %    n = braceListLength(obj, indexOp, indexContext) is called
        %    when MATLAB needs to determine the number of
        %    expected inputs to braceAssign or the number of expected
        %    outputs from braceReference for classes that overload brace
        %    indexing. Classes that inherit from RedefinesBrace must
        %    implement this protected method. It must return a non-negative
        %    integer value.
        %
        %    For example, in an assignment like the following, where obj
        %    overloads brace indexing
        %        [obj{:}.label] = ...
        %    MATLAB calls braceListLength to determine the number of values
        %    being assigned. In this case indexOp is an IndexingOperation
        %    with elements describing the Brace and Dot operations in the
        %    expression, and indexContext is the value
        %    matlab.indexing.IndexingContext.Assignment. The return value
        %    is the number of inputs the class expects to receive for this
        %    expression.
        %
        %    In an expression like the following, where 'func' is the name
        %    of some MATLAB function, MATLAB calls braceListLength to
        %    determine the number of outputs of the brace indexing
        %    expression.
        %        func(obj{idx1,idx2})
        %    In this case indexOp is an IndexingOperation describing the
        %    Brace operation and indexContext is the value
        %    matlab.indexing.IndexingContext.Expression. The return value
        %    is the number of outputs the class expects to produce in this
        %    situation.
        %
        %    In a statement like the following, MATLAB calls
        %    braceListLength to determine the number of outputs of
        %    the brace indexing statement.
        %        obj{idx1,idx2}
        %    In this case indexOp is an IndexingOperation describing the
        %    Brace operation and indexContext is the value
        %    matlab.indexing.IndexingContext.Statement. The return value is
        %    the number of outputs the class expects to produce in this
        %    situation.
        %
        %    In situations where MATLAB can determine the number of input
        %    or output arguments, it does not call braceListLength.
        %
        %    If no possible sub-indexing expression on a class can produce
        %    multiple output values nor require multiple input values, then
        %    braceListLength can return 1. Class authors can often handle
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
        %    See also listLength, braceAssign, braceReference,
        %             matlab.indexing.IndexingOperation
        n = braceListLength(obj, indexOp, indexContext)
    end
end
