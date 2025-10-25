classdef (Abstract, HandleCompatible) CustomIndexer < matlab.mixin.Scalar
%

%   Copyright 2024 The MathWorks, Inc.

    methods(Access = protected)
        function varargout = parenReference(obj, indexOp)
            MException( ...
                "MATLAB:NET:UnsupportedIndexingCustom", ...
                message("MATLAB:NET:UnsupportedIndexingCustom"))...
                .throwAsCaller();
        end

        function obj = parenAssign(obj, indexOp, varargin)
            MException( ...
                "MATLAB:NET:UnsupportedIndexingCustom", ...
                message("MATLAB:NET:UnsupportedIndexingCustom"))...
                .throwAsCaller();
        end
    
        function obj = parenDelete(obj, indexOp)
            MException( ...
                "MATLAB:NET:UnsupportedIndexingCustom", ...
                message("MATLAB:NET:UnsupportedIndexingCustom"))...
                .throwAsCaller();
        end
    
        function n = parenListLength(~, ~, ~)
            % All .NET indexers will return exactly one output
            n = 1;
        end
    
    end

end
