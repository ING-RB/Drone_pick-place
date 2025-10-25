classdef EmptyTransform < coder.internal.loop.transforms.LoopTransform
%
% This is an internal class for code generation.
%

%#codegen
%   Copyright 2022-2023 The MathWorks, Inc.
    methods (Access = ?coder.loop.Control)
        function obj = EmptyTransform(~)
        end
    end

    methods
        function [scheduleString, codeInsightToReport, loopIds] = validate(~, loopIds)
             scheduleString = '';
             codeInsightToReport = '';
        end
    end
end