classdef MLXDiffGUIProvider < comparisons.internal.DiffGUIProvider
%

%   Copyright 2021-2024 The MathWorks, Inc.

    methods

        function bool = canHandle(obj, first, second, options)
            import comparisons.internal.dispatcherutil.isTypeCompatible
            import matlab.livecode.internal.isMLXFile
            import matlab.livecode.internal.isRichMFile
            bool = isTypeCompatible(options.Type, obj.getType()) ...
                && ((isRichMFile(first.Path) && isRichMFile(second.Path)) ...
                || (isMLXFile(first.Path) && isMLXFile(second.Path)));
        end

        function app = handle(obj, first, second, options)
            import comparisons.internal.dispatcherutil.sanitizeFiles
            [first, second, options] = sanitizeFiles(first, second, options, @sanitizeImpl);

            import comparisons.internal.isMOTW
            if useNoJava()
                options = comparisons.internal.dispatcherutil.extractTwoWayOptions(options);
                app = matlab.livecode.internal.diff(first, second, options);
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
            type = "MLX";
        end

        function str = getDisplayType(~)
            str = message("livecodecomparison:livecodecomparison:DisplayType").string();
        end
    end

end

function bool = useNoJava()
    valueOverride = settings().comparisons.NoJavaVisdiff.ActiveValue;
    if(isempty(valueOverride))
        bool = settings().comparisons.livecode.UseNoJava.ActiveValue;
    else
        bool = valueOverride;
    end
end

function source = sanitizeImpl(source)
    import matlab.livecode.internal.isMLXFile
    if isMLXFile(source.Path)
        source = comparisons.internal.fileutil.sanitize(...
            source, NeedsValidName=false, TargetExt='mlx');
    else
        source = comparisons.internal.fileutil.sanitize(...
            source, NeedsValidName=false, TargetExt='m');
    end
end
