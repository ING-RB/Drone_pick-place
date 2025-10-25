classdef OneLoopTransform < coder.internal.loop.transforms.LoopTransform
%
% This is an internal class for code generation.
%

%#codegen
%   Copyright 2021-2023 The MathWorks, Inc.
    properties
       loopId {mustBeTextScalar, coder.mustBeConst(loopId, 'Coder:loopControl:NotConstantLoopIdToTransform')} = '';
    end
    methods (Access = ?coder.internal.loop.transforms.LoopTransform)
        function obj = OneLoopTransform(prevTransform, varargin)
            obj = obj@coder.internal.loop.transforms.LoopTransform(prevTransform);
            if nargin >= 2
              obj.loopId = char(varargin{1});
            else
              obj.loopId = '';
            end
        end

        function loopIdToUse = getLoopIdToUse(self, loopIds)
            if ~isempty(self.loopId) 
                loopIdToUse = self.loopId;
            else
                % in case the loop ID is not specified, we will apply this
                % transform to the adjacent loop. Hence, taking the first
                % element from loopIds as the loop ID for the adjacent loop
                loopIdToUse = loopIds{1};
            end
        end
    end
    
    methods
        function [scheduleString, codeInsightToReport, loopIds] = validate(self, loopIds, transformName)
            [scheduleString, codeInsightToReport, loopIds] = validate@coder.internal.loop.transforms.LoopTransform(self,loopIds);
            scheduleString = [scheduleString, transformName, ','];
            found = coder.internal.loop.transforms.LoopTransform.isLoopIdFound(self.loopId, loopIds);
            coder.internal.assert(found == true, 'Coder:loopControl:TransformInvalidLoopID',...
                self.loopId, transformName); 
            scheduleString = [scheduleString, self.getLoopIdToUse(loopIds), ','];
        end
    end
 end
