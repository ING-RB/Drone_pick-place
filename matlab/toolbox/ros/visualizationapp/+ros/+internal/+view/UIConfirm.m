classdef UIConfirm < handle
% Class wrapper for uiconfirm dialog

%   Copyright 2023 The MathWorks, Inc.

    methods(Static)
        function selection = run(varargin)
             selection = uiconfirm(varargin{:});           
        end
    end
end