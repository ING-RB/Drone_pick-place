classdef (Abstract, HandleCompatible) RedefinesDotProperties < ...
        matlab.mixin.internal.indexing.ModularIndexingBase
    %
    %   RedefinesDotProperties   Internal Modular Indexing class that allows users to override public properties.
    %   This class is for internal use only.
    %   It might be changed or removed without notice in a future version.
    %

    %   Copyright 2024 The MathWorks, Inc.

    methods
        function obj = RedefinesDotProperties()
            if isa(obj, 'matlab.mixin.indexing.OverridesPublicDotMethodCall')
                errID = 'MATLAB:index:cannot_inherit_from_class';
                error(message(errID,"RedefinesDotProperties", "OverridesPublicDotMethodCall"));
            end

            if isa(obj, 'matlab.mixin.indexing.RedefinesDot')
                errID = 'MATLAB:index:cannot_inherit_from_class';
                error(message(errID,"RedefinesDotProperties", "RedefinesDot"));
            end
			
            if isa(obj, 'dynamicprops')
                errID = 'MATLAB:index:cannot_inherit_from_class';
                error(message(errID,"RedefinesDotProperties", "dynamicprops"));
            end			
        end
    end


    methods (Abstract, Access = protected)
        varargout = dotReference(obj,indexingOperation)
        n = dotListLength(obj,indexingOperation,indexingContext)
        obj = dotAssign(obj,indexingOperation,rhs)

    end
    methods (Access = protected)
        function obj = parenDotAssign(obj, indexOp, varargin)
            %parenDotAssign Overload compound parentheses indexing
            %               assignment
            %    obj = parenDotAssign(obj, indexOp, varargin) is called by
            %    MATLAB for compound indexed assignments that begin with
            %    parentheses when obj inherits from RedefinesDotProperties but does
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
            %    accessible method, it does not call
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
