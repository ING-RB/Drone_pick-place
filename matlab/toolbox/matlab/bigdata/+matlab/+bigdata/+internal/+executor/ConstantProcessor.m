%ConstantProcessor
% Data Processor that simply returns a set of constants.
%
% See LazyTaskGraph for a general description of input and outputs.
% Specifically, this does not expect to receive any inputs and will emit a
% 1 x NumConstants cell array where each cell contains a constant from the
% Constants property.
%

%   Copyright 2015-2018 The MathWorks, Inc.

classdef (Sealed) ConstantProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = false(0,1);
    end
    
    properties (Access = private)
        % The single chunk to be emitted by this data processor.
        Outputs;
    end
    
    methods (Static)
        function dataProcessor = buildEmptyProcessor(numInputs, numOutputs)
            % Build a DataProcessor that emits a single UnknownEmptyArray.
            outputs = repelem({matlab.bigdata.internal.UnknownEmptyArray.build()}, numOutputs);
            dataProcessor = matlab.bigdata.internal.executor.ConstantProcessor(outputs, numInputs);
        end
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function out = process(obj, ~, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            out = obj.Outputs;
            obj.Outputs = [];
            obj.IsFinished = true;
        end
    end
    
    methods
        function obj = ConstantProcessor(outputs, numInputs)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            if nargin < 2
                numInputs = 0;
            end
            obj.IsMoreInputRequired = false(numInputs, 1);
            obj.NumOutputs = numel(outputs);
            obj.Outputs = outputs;
        end
    end
end
