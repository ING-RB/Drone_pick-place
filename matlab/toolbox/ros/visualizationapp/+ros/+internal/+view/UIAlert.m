classdef UIAlert < handle
% Class wrapper for uialert dialog

%   Copyright 2022 The MathWorks, Inc.

    methods
        function [selected] = run(~, varargin)
             uialert(varargin{:});
             %uialert does not have any output, returning empty
             selected = [];
        end
    end
end