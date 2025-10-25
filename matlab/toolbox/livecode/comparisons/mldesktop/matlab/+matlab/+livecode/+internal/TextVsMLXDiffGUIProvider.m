classdef TextVsMLXDiffGUIProvider < comparisons.internal.DiffGUIProvider
%

%   Copyright 2021-2023 The MathWorks, Inc.

    methods

        function bool = canHandle(obj, first, second, options)
            import comparisons.internal.dispatcherutil.isTypeCompatible

            bool = isTypeCompatible(options.Type, obj.getType()) ...
                   && oneMLXOneText(first.Path, second.Path);
        end

        function app = handle(obj, first, second, options)
            import comparisons.internal.dispatcherutil.sanitizeFiles
            import comparisons.internal.merge.DisableMerge
            import comparisons.internal.text.TextDiffGUIProvider
            [first, second, options] = sanitizeFiles(first, second, options, @sanitizeImpl);
            options.Type = obj.getType();
            options.MergeConfig = DisableMerge;
            app = TextDiffGUIProvider().handle(MLX2tempM(first), MLX2tempM(second), options);
        end

        function priority = getPriority(~, ~, ~, ~)
            priority = 8;
        end

        function type = getType(~)
            type = "Text";
        end

        function str = getDisplayType(~)
            str = message("comparisons:textdiff:DisplayType").string();
        end
    end

end

function bool = oneMLXOneText(firstPath, secondPath)
    import comparisons.internal.text.isTextFileHeuristic
    import matlab.livecode.internal.isMLXFile
    bool = (isMLXFile(firstPath) && isTextFileHeuristic(secondPath)) || ...
           (isTextFileHeuristic(firstPath) && isMLXFile(secondPath));
end

function m = MLX2tempM(mlx)
    import comparisons.internal.makeFileSource
    import comparisons.internal.fileutil.makeTempDir

    [~, name, ext] = fileparts(mlx.Path);
    if strcmp(ext, '.mlx')
        tmpdir = makeTempDir;
        tmp = fullfile(tmpdir, [name, '.m']);
        export(mlx.Path, tmp);
        props = mlx.Properties;
        props(end + 1) = struct('name', getString(message('comparisons:textdiff:MLXResavedToM')), ...
                                'value', mlx.Path);
        m = makeFileSource(...
            tmp, ...
            Title=mlx.Title, ...
            TitleLabel=mlx.TitleLabel, ...
            Properties=props, ...
            Guard=tmpdir);
    else
        m = mlx;
    end
end

function source = sanitizeImpl(source)
    import matlab.livecode.internal.isMLXFile
    if ~isMLXFile(source.Path)
        % No need to sanitize
        return;
    end
    source = comparisons.internal.fileutil.sanitize(...
        source, NeedsValidName=false, TargetExt='mlx');
end
