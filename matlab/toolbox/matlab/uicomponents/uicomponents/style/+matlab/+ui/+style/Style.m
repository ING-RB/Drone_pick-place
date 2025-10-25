classdef Style < matlab.ui.style.internal.Stylable
    %

    % Do not remove above white space
    % Copyright 2019 The MathWorks, Inc.

    methods
        function obj = Style(varargin)
            obj = obj@matlab.ui.style.internal.Stylable(varargin{:});
        end
    end
end