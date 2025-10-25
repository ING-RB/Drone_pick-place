classdef (Hidden) SliderComponent < ...
        matlab.ui.control.internal.model.mixin.TickComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.OrientableComponent & ...     
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %

    % Do not remove above white space
    % Copyright 2013-2023 The MathWorks, Inc.

    properties (Access = protected, Constant)
        % Implement abstract properties
        ValidOrientations cell = {'horizontal', 'vertical'};
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = SliderComponent(varargin)
            %

            % Do not remove above white space
            obj@matlab.ui.control.internal.model.mixin.TickComponent(varargin{:});

            % Orientation default
            obj.PrivateOrientation = 'horizontal';
        end
    end
end