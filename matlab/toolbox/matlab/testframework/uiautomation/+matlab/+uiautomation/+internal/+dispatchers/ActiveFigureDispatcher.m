classdef ActiveFigureDispatcher < matlab.uiautomation.internal.dispatchers.DispatchDecorator
    % This class is undocumented and subject to change in a future release

    % Copyright 2024 The MathWorks, Inc.

    methods
        function dispatch(decorator, model, varargin)
            decorator.ensureFigureIsActive(model);
            dispatch@matlab.uiautomation.internal.dispatchers.DispatchDecorator( ...
                decorator, model, varargin{:});
        end
    end

    methods(Access=protected, Hidden)
        function ensureFigureIsActive(~, component)
            % Accommodate docked & tabbed figures
            fig = ancestor(component(1), "figure");
            if ~isempty(fig) && fig.WindowStyle == "docked"
                figure(fig);
            end
        end
    end
end
