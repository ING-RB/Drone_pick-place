%RedefinesDot  Interface class for overloading dot indexing
%   matlab.mixin.indexing.RedefinesDot defines an interface that allows
%   subclasses to overload dot indexing. Dot indexing on an instance obj of
%   a subclass of RedefinesDot has the following behavior:
%       obj.label                calls dotReference
%       obj.(variable)           calls dotReference
%       obj.label = val          calls dotAssign
%       [obj.label] = val        calls dotAssign
%       [obj.(variable)] = val   calls dotAssign
%   Class authors must define the dotReference, dotAssign, and
%   dotListLength methods to provide the desired dot indexing behavior for 
%   a class. 
%
%   Dot indexing with the names of accessible properties and methods is not
%   overloaded, and behaves normally. Dot indexing with public properties 
%   or methods does not call dotReference or dotAssign. When a property is 
%   private or protected, the behavior changes depending on whether the 
%   property is accessible when indexing occurs. 
%   For example, if a subclass of RedefinesDot defines a public property
%   'PublicProperty' then 
%       obj.PublicProperty                      reads the property
%       label = "PublicProperty"; obj.(label)   reads the property
%       obj.PublicProperty(idx)                 indexes into the property
%       obj.PublicProperty = val;               assigns val to the property
%   If the class defines a public method 'publicMethod' with one additional
%   argument, then each of the following calls the method:
%       obj.publicMethod(arg)
%       label = "publicMethod"; obj.(label)(arg)
%   The behavior of public method calls using dot notation can be changed
%   by inheriting from the OverridesPublicDotMethodCall mixin in addition
%   to RedefinesDot.
%   If the class defines a private property PrivateProperty, then inside
%   class methods, obj.PrivateProperty refers to the property and does not
%   call dotReference. Outside class methods, obj.PrivateProperty calls
%   dotReference.
%
%   When a class inherits from RedefinesDot, compound indexing 
%   expressions that start with dot and do not refer to accessible 
%   properties or methods also call dotReference and dotAssign.
%   For example:
%       obj.label(idx)         calls dotReference
%       obj.(var)(idx)         calls dotReference
%       obj.label(idx) = val   calls dotAssign
%       obj.label(idx) = []    calls dotAssign
%   Class authors can often handle compound indexing expressions by
%   forwarding some or all of the later indexing operations to another
%   object. For more information, look for 'forwarding indexing' in the
%   documentation.
%
%   Inheriting from RedefinesDot does not change the behavior of built-in
%   parentheses indexing (which indexes into an array of objects) or of
%   built-in brace indexing (which issues an error). Redefining these 
%   behaviors is possible by inheriting from RedefinesParen or
%   RedefinesBrace in addition to RedefinesDot.
%
%   A class that inherits only from RedefinesDot supports compound
%   assignment statements that begin with parentheses indexing, for example:
%       obj(idx).label = val;
%   If label refers to an accessible property or method, this statement
%   calls built-in indexing. Otherwise, this statement calls the
%   parenDotAssign method. The parenDotAssign method has a default
%   implementation that can be overloaded if desired.
%
%   Subclasses of RedefinesDot must not define subsref, subsasgn,
%   or numArgumentsFromSubscript.
%
%   matlab.mixin.indexing.RedefinesDot methods:
%        dotAssign          - Overload dot indexing assignment
%        dotListLength      - Length of comma-separated list for dot
%                             indexing
%        dotReference       - Overload dot indexing reference
%        parenDotAssign     - Overload compound parentheses indexing 
%                             assignment
%        parenDotListLength - Length of comma-separated list for compound
%                             parentheses indexing
%
%   See also RedefinesParen, RedefinesBrace, OverridesPublicDotMethodCall,
%            matlab.indexing.IndexingOperation

%   Copyright 2020-2022 The MathWorks, Inc.


classdef (Abstract, HandleCompatible) RedefinesDot < ...
        matlab.mixin.internal.indexing.ModularIndexingBase

    methods (Abstract, Access = protected)
        %dotReference  Overload dot indexed reference
        %    varargout = dotReference(obj, indexOp) is called by MATLAB for
        %    indexed reference expressions that begin with dot. Classes
        %    that inherit from RedefinesDot must implement this protected
        %    method. The dotReference method must interpret the
        %    IndexingOperation argument indexOp and return the correct
        %    number of requested outputs as varargout.
        %
        %    In a simple statement such as 
        %        y = obj.label; 
        %    MATLAB calls dotReference with the object obj and an
        %    IndexingOperation with a single element whose Type property is
        %    Dot and whose Name property is the string "label".
        %
        %    In a compound reference statement such as 
        %        [y1, y2, y3] = obj.(var).subprop
        %    MATLAB calls dotReference with an IndexingOperation array with
        %    two elements whose Type properties are each Dot, and requests
        %    three outputs. The Name property of the first element is the
        %    value of the variable "var" and the Name property of the
        %    second element is the string "subprop".
        %
        %    The dotReference method is not called for properties and
        %    methods that are accessible in the present context.
        %
        %    Class authors can often handle compound indexing expressions
        %    by forwarding some or all of the later indexing operations to
        %    another object. For more information, look for 'forwarding
        %    indexing' in the documentation.
        %
        %    See also dotAssign, dotListLength, 
        %             matlab.indexing.IndexingOperation
        varargout = dotReference(obj, indexOp)
         
        %dotAssign  Overload dot indexed assignment
        %    obj = dotAssign(obj, indexOp, varargin) is called by MATLAB
        %    for indexed assignment statements that begin with dot. Classes
        %    that inherit from RedefinesDot must implement this protected
        %    method. The dotAssign method must interpret the
        %    IndexingOperation argument indexOp, modify the obj argument
        %    based on the right-hand side values in varargin, and return
        %    the modified object.
        %
        %    In a simple assignment such as
        %        obj.label = val;
        %    MATLAB calls dotAssign with the object obj and an
        %    IndexingOperation with a single element whose Type property is
        %    Dot and Name property is the string "label". The third input
        %    argument to dotAssign is the right-hand side value val.
        %
        %    In a compound comma-separated list assignment such as
        %        [obj.(var){:}] = rhs{:};
        %    MATLAB first calls dotListLength on obj to determine how many
        %    inputs the object expects to receive in dotAssign. Assuming
        %    that the right-hand side provides enough values, dotAssign
        %    will be called with an IndexingOperation with two elements
        %    describing the Dot and Brace indexing in the statement. The
        %    values from the right-hand side are passed to dotAssign as
        %    varargin.
        %
        %    The dotAssign method is not called for properties and
        %    methods that are accessible in the present context.
        %
        %    Class authors can often handle compound indexing expressions
        %    by forwarding some or all of the later indexing operations to
        %    another object. For more information, look for 'forwarding
        %    indexing' in the documentation.
        %
        %    See also dotListLength, dotReference,
        %             matlab.indexing.IndexingOperation
        obj = dotAssign(obj, indexOp, varargin)

        %dotListLength  Length of comma-separated list for dot indexing
        %    n = dotListLength(obj, indexOp, indexContext) is called when
        %    MATLAB needs to determine the number of
        %    expected inputs to dotAssign or the number of expected
        %    outputs from dotReference for classes that overload dot
        %    indexing. Classes that inherit from RedefinesDot must
        %    implement this protected method. It must return a non-negative
        %    integer value.
        %
        %    For example, in an assignment like the following, where obj
        %    overloads dot indexing
        %        [obj.label{:}] = ...
        %    MATLAB calls dotListLength to determine the number of values
        %    being assigned. In this case indexOp is an IndexingOperation
        %    describing the Dot and Brace operations in the expression, and
        %    indexContext is the value
        %    matlab.indexing.IndexingContext.Assignment. The return value
        %    is the number of inputs the class expects to receive for this
        %    expression.
        %
        %    In an expression like the following, where 'func' is the name
        %    of some MATLAB function, MATLAB calls dotListLength to
        %    determine the number of outputs of the dot indexing
        %    expression.
        %        func(obj.label)
        %    In this case indexOp is an IndexingOperation describing the
        %    Dot operation and indexContext is the value
        %    matlab.indexing.IndexingContext.Expression. The return value
        %    is the number of outputs the class expects to produce in this
        %    situation.
        %
        %    In a statement like the following, MATLAB calls dotListLength
        %    to determine the number of outputs of the dot indexing
        %    statement.
        %        obj.label
        %    In this case indexOp is an IndexingOperation describing the
        %    Dot operation and indexContext is the value
        %    matlab.indexing.IndexingContext.Statement. The return value is
        %    the number of outputs the class expects to produce in this
        %    situation.
        %
        %    In situations where MATLAB can determine the number of input
        %    or output arguments, or where the initial dot operation refers
        %    to an accessible property or method, it does not call
        %    dotListLength.
        %
        %    If no possible sub-indexing expression on a class can produce
        %    multiple output values nor require multiple input values, then
        %    dotListLength can return 1. Class authors can often handle
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
        %    See also listLength, dotAssign, dotReference,
        %             matlab.indexing.IndexingOperation
        n = dotListLength(obj, indexOp, indexContext)
    end

    methods (Access = protected)
        function obj = parenDotAssign(obj, indexOp, varargin)
            %parenDotAssign Overload compound parentheses indexing 
            %               assignment
            %    obj = parenDotAssign(obj, indexOp, varargin) is called by
            %    MATLAB for compound indexed assignments that begin with
            %    parentheses when obj inherits from RedefinesDot but does
            %    not inherit from RedefinesParen. The parenDotAssign method
            %    must interpret the IndexingOperation argument indexOp,
            %    modify the obj argument based on the right-hand side
            %    values in varargin, and return the modified object.
            %
            %    In an assignment such as
            %        obj(idx).label = val;
            %    MATLAB calls parenDotAssign with the object obj and an
            %    IndexingOperation with two elements. The first element has
            %    Type property Paren and Indices property {idx} while the
            %    second element has Type property Dot and Name property
            %    "label". The third input argument to parenDotAssign is the
            %    right-hand side value val.
            %
            %    In a comma-separated list assignment such as
            %        [obj(idx).(var){:}] = rhs{:};
            %    MATLAB first calls parenDotListLength on obj to determine
            %    how many inputs the object expects to receive in
            %    parenDotAssign. Then parenDotAssign is called with an
            %    IndexingOperation with three elements describing the
            %    Paren, Dot, and Brace indexing. The values from the
            %    right-hand side are passed to parenDotAssign as varargin.
            %
            %    The parenDotAssign method is not called for properties and
            %    methods that are accessible in the present context. It is
            %    also not called if the class also inherits from
            %    RedefinesParen. In such a case parenAssign is called
            %    instead.
            %
            %    See also parenDotListLength, dotAssign,
            %             matlab.indexing.IndexingOperation

            % The default implementation of this method effectively splits
            % the assignment into 3 steps. For example, if idx is within
            % the bounds of the array obj, the assignment 
            %     [obj(idx).(var){:}] = rhs{:};
            % is broken down into
            %     temp = obj(idx);
            %     temp = dotAssign(temp, indexOp(2:end), varargin{:});
            %     obj(idx) = temp;
            % The default implementation also allows idx to be outside the 
            % bounds of the array obj. In that case the array temp will
            % contain default-constructed elements of the same class as
            % obj.

            firstLevel = indexOp(1);
            intermediate = matlab.internal.indexing.parenReferenceForAssignment(obj, firstLevel.Indices{:});
            obj.(firstLevel) = dotAssign(matlab.lang.internal.move(intermediate), indexOp(2:end), varargin{:});
        end

        function n = parenDotListLength(obj, indexOp, indexContext)
            % parenDotListLength Length of comma-separated list for
            %                    compound parentheses indexing
            %    n = parenDotListLength(obj, indexOp, indexContext) is
            %    called when MATLAB needs to determine the number of
            %    expected inputs to parenDotAssign for classes that
            %    overload dot indexing but do not overload parentheses
            %    indexing.
            %
            %    For example, in an assignment like the following, where
            %    obj overloads dot indexing but not parentheses indexing,
            %        [obj(idx).label{:}] = ...
            %    MATLAB calls parenDotListLength to determine the number of
            %    values being assigned. In this case indexOp is an
            %    IndexingOperation describing the Paren, Dot, and Brace
            %    operations, and indexContext is the value
            %    matlab.indexing.IndexingContext.Assignment. The return
            %    value is the number of inputs the class expects to receive
            %    for this expression.
            %
            %    In situations where MATLAB can determine the number of
            %    input arguments, or where the dot operation refers to an
            %    accessible property or method, it does not call
            %    parenDotListLength.
            %
            %    See also parenDotAssign, dotListLength,
            %             matlab.indexing.IndexingOperation

            % If idx is within the bounds of the array obj, then for
            %     [obj(idx).label{:}] = ...
            % the default implementation is effectively 
            %     temp = obj(idx);
            %     n = dotListLength(temp, indexOp(2:end), indexContext);
            % The default implementation also allows idx to be outside
            % the bounds of the array obj. In that case the array temp
            % will contain default-constructed elements of the same
            % class as obj.

            intermediate = matlab.internal.indexing.parenReferenceForAssignment(obj, indexOp(1).Indices{:});
            n = dotListLength(matlab.lang.internal.move(intermediate), indexOp(2:end), indexContext);
        end
    end
end
