classdef (Abstract) LoopTransform
%
% This is an internal class for code generation.
%

%#codegen
%   Copyright 2021-2023 The MathWorks, Inc.
    properties
       transformSchedule;
    end
    methods(Static)
       function props = matlabCodegenNontunableProperties(~)
         props = {'transformSchedule'};
       end
    end
    methods
        function obj = LoopTransform(transform)
            if nargin > 0
                obj.transformSchedule = transform;
            else
                obj.transformSchedule = [];
            end
        end
        
        function [scheduleString, codeInsightToReport, outLoopIds] = validate(self, loopIds)
           if isempty(self.transformSchedule)
             scheduleString = '';
             outLoopIds = loopIds;
             codeInsightToReport = '';
           else
             [scheduleString, codeInsightToReport, outLoopIds] = self.transformSchedule.validate(loopIds);
             scheduleString = [scheduleString,';'];
           end
        end
    end
    
    methods(Static)
        function found = isLoopIdFound(loopId, loopIds)
            found = false;
            if ~isempty(loopId)
                for i = 1:numel(loopIds)
                    if string(loopId) == string(coder.const(loopIds{i}))
                        found = true;
                        break;
                    end
                end
            else
                found = true;
            end
        end 
    end
 end