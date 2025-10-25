classdef UnrollAndJam < coder.internal.loop.transforms.OneLoopTransform
%
% This is an internal class for code generation.
%

%#codegen
%   Copyright 2021-2023 The MathWorks, Inc.
    properties
       unrollFactor (1,1) {mustBePositive, mustBeInteger, coder.mustBeConst(unrollFactor, 'Coder:loopControl:NotConstantUnrollFactor')} = 2;
    end
    methods (Access = ?coder.loop.Control)
        function obj = UnrollAndJam(prevTransform, varargin)
            obj = obj@coder.internal.loop.transforms.OneLoopTransform(prevTransform, varargin{:});
            if nargin > 2
                obj.unrollFactor = varargin{2};
            else
                obj.unrollFactor = 2; % need this assignment for inference 
                % to succeed, otherwise we get a nontunable property  
                % mismatch error
            end
        end
    end
    
    methods
        function [scheduleString, codeInsightToReport, loopIds] = validate(self, loopIds)
            [scheduleString, codeInsightToReport, loopIds] = validate@coder.internal.loop.transforms.OneLoopTransform(self, loopIds, 'unrollAndJam');
            scheduleString = [scheduleString, num2str(self.unrollFactor), ','];
        end
    end
 end
