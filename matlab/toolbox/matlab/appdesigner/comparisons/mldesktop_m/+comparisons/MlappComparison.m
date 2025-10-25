classdef MlappComparison < comparisons.Comparison
    %MlappComparison - Comparison of two MLAPP files
    %
    %  MlappComparison properties:
    %     Left - Name of MLAPP file on left of comparison
    %    Right - Name of MLAPP file on right of comparison
    %
    %  See also comparisons.Comparison

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Dependent, GetAccess = public)
        Left
        Right
    end

    properties (Access = private)
        Model
        SequenceDiffResult

        LeftSource
        RightSource
    end

    methods (Hidden)

        function obj = MlappComparison(diffResult, model, leftSource, rightSource)
            arguments
                diffResult  comparisons.text.viewmodel.mfzero.SequenceDiffResult
                model       mf.zero.Model
                leftSource  (1,1) comparisons.internal.FileSource
                rightSource (1,1) comparisons.internal.FileSource
            end

            obj.Model = model;
            obj.SequenceDiffResult = diffResult;
            obj.LeftSource = leftSource;
            obj.RightSource = rightSource;
        end

        function filter(~, ~)
            errorStruct.message = message("comparisons:comparisons:FilterNotSupported").getString;
            errorStruct.identifier = "comparisons:FilterNotSupported";
            error(errorStruct);
        end

    end

    methods
        function leftPath = get.Left(mlappComparison)
            leftPath = mlappComparison.LeftSource.Path;
        end

        function rightPath = get.Right(mlappComparison)
            rightPath = mlappComparison.RightSource.Path;
        end
    end

    methods (Access = public)

        function reportLocation = publish(mlappComparison, varargin)
            import appdesigner.internal.comparison.report.createReport
            import appdesigner.internal.codegeneration.getAppFileCode

            try
                parser = comparisons.internal.api.PublishInputParser(mlappComparison);
                options = parser.parse(varargin{:});
                reportLocation = fullfile(options.OutputFolder, options.Name);

                leftText = getAppFileCode(mlappComparison.Left);
                rightText = getAppFileCode(mlappComparison.Right);

                reportLocation = createReport({mlappComparison.LeftSource, mlappComparison.RightSource},...
                                              options.OutputFolder,...
                                              options.Name,...
                                              options.Format,...
                                              mlappComparison.SequenceDiffResult,...
                                              {leftText, rightText});
            catch exception
                exception = MException(...
                    exception.identifier, '%s', exception.message...
                    );
                exception.throwAsCaller();
            end
        end

    end

end
