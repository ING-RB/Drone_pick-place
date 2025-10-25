classdef MlappDiffGUIProvider < comparisons.internal.DiffGUIProvider
%

%   Copyright 2021-2023 The MathWorks, Inc.

    methods
        function bool = canHandle(obj, first, second, options)
            import comparisons.internal.dispatcherutil.isTypeCompatible
            import appdesigner.internal.comparison.isMlapp

            bool = isTypeCompatible(options.Type, obj.getType()) &&...
                   isMlapp(first.Path) && isMlapp(second.Path);
        end

        function app = handle(obj, first, second, options)
            import comparisons.internal.dispatcherutil.sanitizeFiles
            [first, second, options] = sanitizeFiles(first, second, options, @sanitizeImpl);

            if useNoJava()
                % call c++ implementation here
                options = comparisons.internal.dispatcherutil.extractTwoWayOptions(options);
                app = comparisons.internal.mlapp.diff(first, second, options);
            else
                if comparisons.internal.isMOTW()
                    error(message('comparisons:comparisons:MOTWNotSupported'));
                end
                options.Type = obj.getType();
                app = comparisons.internal.dispatcherutil.compareJava(first, second, options);
            end
        end

        function priority = getPriority(~, ~, ~, ~)
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

function bool = useNoJava()
    valueOverride = settings().comparisons.NoJavaVisdiff.ActiveValue;
    if(isempty(valueOverride))
        bool = settings().comparisons.mlapp.UseNoJava.ActiveValue;
    else
        bool = valueOverride;
    end
end

function source = sanitizeImpl(source)
    source = comparisons.internal.fileutil.sanitize(...
        source, NeedsValidName=false, TargetExt='mlapp');
end
