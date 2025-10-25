classdef MlappDiffNoGUIProvider < comparisons.internal.DiffNoGUIProvider
    %

    %   Copyright 2022 The MathWorks, Inc.

    methods
        function bool = canHandle(obj, first, second, options)
            import comparisons.internal.dispatcherutil.isTypeCompatible
            import appdesigner.internal.comparison.isMlapp
        
            bool = isTypeCompatible(options.Type, obj.getType()) &&...
                isMlapp(first.Path) && isMlapp(second.Path);
        end

        function out = handle(~, first, second, ~)   
            [diffResult, model] = comparisons.internal.mlapp.mcosDiff(first.Path, second.Path);
            out = comparisons.MlappComparison(diffResult, model, first, second);
        end

        function priority = getPriority(~, ~, ~, ~)
            % set 15 for mlapp file diff tool provider
            priority = 15;
        end

        function type = getType(~)
            type = "OpcPackageMlapp";
        end

        function str = getDisplayType(~)
            str = message("appdesigner:comparison:comparison:DisplayType").string();
        end
    end

end
