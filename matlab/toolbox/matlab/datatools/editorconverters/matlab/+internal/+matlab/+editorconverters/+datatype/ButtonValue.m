classdef ButtonValue
    % This is the data type class for editors which just show a button.

    % Copyright 2022 The MathWorks, Inc.

    properties
        Text
        ButtonPushedFcn function_handle
    end

    methods
        function this = ButtonValue(text, buttonPushedFcn)
            arguments
                text {mustBeTextScalar} 
                buttonPushedFcn {mustBeA(buttonPushedFcn, "function_handle")}
            end

            this.Text = text;
            this.ButtonPushedFcn = buttonPushedFcn;
        end
    end
end