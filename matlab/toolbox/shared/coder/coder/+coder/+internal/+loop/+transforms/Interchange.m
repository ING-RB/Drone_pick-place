classdef Interchange < coder.internal.loop.transforms.OneLoopTransform
%
% This is an internal class for code generation.
%

%#codegen
%   Copyright 2021-2023 The MathWorks, Inc.
    properties
       otherLoopId {mustBeTextScalar, coder.mustBeConst(otherLoopId, 'Coder:loopControl:NotConstantLoopIdToTransform')} = '';
    end
    methods (Access = ?coder.loop.Control)
        function obj = Interchange(prevTransform, loopId, otherLoopId)
            coder.internal.assert(nargin > 2, 'Coder:loopControl:InterchangeMissingLoopIDs');
            obj = obj@coder.internal.loop.transforms.OneLoopTransform(prevTransform, loopId);
            obj.otherLoopId = char(otherLoopId);
        end
    end
    
    methods
        function [scheduleString, codeInsightToReport, loopIds] = validate(self, loopIds)
            [scheduleString, codeInsightToReport, loopIds] = validate@coder.internal.loop.transforms.OneLoopTransform(self, loopIds, 'interchange');
            found = coder.internal.loop.transforms.LoopTransform.isLoopIdFound(self.otherLoopId, loopIds);
            coder.internal.assert(found == true, 'Coder:loopControl:TransformInvalidLoopID',...
                self.otherLoopId, 'interchange');
            scheduleString = [scheduleString, self.otherLoopId, ','];
        end
    end
 end
