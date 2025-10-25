classdef Vectorize < coder.internal.loop.transforms.OneLoopTransform
%
% This is an internal class for code generation.
%

%#codegen
%   Copyright 2021-2024 The MathWorks, Inc.
    properties
        mode {mustBeTextScalar, coder.mustBeConst(mode)} = 'auto';
    end
    methods (Access = ?coder.loop.Control)
        function obj = Vectorize(prevTransform, arg1, arg2)
            if nargin == 1
                loopId = '';
                mode = 'auto';
            end
            if nargin == 2
                if arg1 == "never"
                    loopId = '';
                    mode = char(arg1);
                else
                    loopId = char(arg1);
                    mode = 'auto';
                end
            end
            if nargin > 2
                if arg2 == "never"
                    coder.internal.assert(arg1 ~= "never", 'Coder:loopControl:LoopScheduleRepeatedMode', "vectorize");
                    mode = char(arg2);
                    loopId = char(arg1);
                else
                    coder.internal.assert(arg1 == "never", 'Coder:loopControl:LoopScheduleRepeatedLoopId',"vectorize",arg1,arg2);
                    mode = char(arg1);
                    loopId = char(arg2);
                end
            end
            obj = obj@coder.internal.loop.transforms.OneLoopTransform(prevTransform, loopId);
            obj.mode = mode;
        end
    end

    methods
        function [scheduleString, codeInsightToReport, loopIds] = validate(self, loopIds)
            [scheduleString, codeInsightToReport, loopIds] = validate@coder.internal.loop.transforms.OneLoopTransform(self, loopIds, 'vectorize');
            self.checkConflictingModes(scheduleString, self.getLoopIdToUse(loopIds));
            scheduleString = [scheduleString, self.mode, ','];
        end
    end
    methods(Access=private)
        function checkConflictingModes(self, str, loopIdToUse)
            if self.mode == "never"               
                 modeToFind = 'auto';
             else
                modeToFind = 'never';
            end
            coder.internal.assert(~contains(str, ['vectorize,',loopIdToUse,',',modeToFind]), 'Coder:loopControl:LoopScheduleModeConflict',...
                "vectorize",loopIdToUse);
        end
    end
 end
