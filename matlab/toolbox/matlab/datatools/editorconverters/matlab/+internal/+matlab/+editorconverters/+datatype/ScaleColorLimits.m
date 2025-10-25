classdef ScaleColorLimits
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Copyright 2017-2023 The MathWorks, Inc.

    properties(Access = private)
        Limits;
    end

    properties
        ColorsPropName (1,1) string = "ScaleColors";
        ColorLimitsPropName (1,1) string = "ScaleColorLimits";
    end

    methods
        function this = ScaleColorLimits(limits, options)
            arguments
                limits

                % Define the Colors property name.  By default this is
                % ScaleColors
                options.ColorsPropName (1,1) string

                % Define the Color Limits property name.  By default this
                % is ScaleColorLimits
                options.ColorLimitsPropName (1,1) string
            end
            this.Limits = limits;

            if isfield(options, "ColorsPropName")
                this.ColorsPropName = options.ColorsPropName;
            end

            if isfield(options, "ColorLimitsPropName")
                this.ColorLimitsPropName = options.ColorLimitsPropName;
            end
        end

        function v = getLimits(this)
            v = this.Limits;
        end
    end
end
