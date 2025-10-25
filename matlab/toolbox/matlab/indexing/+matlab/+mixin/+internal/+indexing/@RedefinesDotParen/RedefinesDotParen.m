classdef (Abstract, HandleCompatible, AllowedSubclasses = {?tabular,?hClassRedefinesDotParen}) RedefinesDotParen < ...
        matlab.mixin.internal.indexing.ModularIndexingBase
%
%   RedefinesDotParen   Internal Modular Indexing implementation of dot paren reference. 
%   This class is for internal use only intended to be used only by tabular datatype class.
%   It might be changed or removed without notice in a future version. Do not use this class.
%
%   Copyright 2021 The MathWorks, Inc.

    methods
        function obj = RedefinesDotParen()
            if ~isa(obj, 'matlab.mixin.indexing.RedefinesDot')
                errID = 'MATLAB:index:must_inherit_from_class';
                error(message(errID,"RedefinesDotParen", "RedefinesDot"));
            end
        end
    end
    methods (Abstract, Access = public, Hidden)
        varargout = dotParenReference(obj,fieldName, rowInd,colInd, varargin)

    end
end
