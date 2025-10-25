classdef (Abstract) Factory
    % Factory class used to create specific instances of
    % matlab.internal.optimfun.plotfcns.AbstractPlotFunction classes.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2023 The MathWorks, Inc.

    methods (Static, Access = public)

        %% base matlab
        function h = optimplotfunccount(optimValues)
            tag = "optimplotfunccount";
            h = matlab.internal.optimfun.plotfcns.Factory.shared_funccount(tag, optimValues);
        end

        function h = optimplotfval(optimValues)

            % Check for optimValues field to plot
            if isfield(optimValues, "fval")
                dataFieldName = "fval";
            else
                dataFieldName = "residual";
            end

            % Plot may be a scalar value or vector value
            tag = "optimplotfval";
            if isscalar(optimValues.(dataFieldName))
                [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", dataFieldName]);
                h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues);
            else
                [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, dataFieldName);
                h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues, ...
                    "TitleText", getString(message("MATLAB:optimfun:funfun:optimplots:TitleCurrentFunctionValues")), ...
                    "XLabelText", getString(message("MATLAB:optimfun:funfun:optimplots:LabelFunctionValueNumber")), ...
                    "YLabelText", getString(message("MATLAB:optimfun:funfun:optimplots:LabelFunctionValue")));
            end
        end

        function h = optimplotx(optimValues)
            tag = "optimplotx";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "x");
            h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues);
        end

        %% optim toolbox
        function h = optimplotconstrviolation(optimValues)
            tag = "optimplotconstrviolation";
            h = matlab.internal.optimfun.plotfcns.Factory.shared_constrviolation(tag, optimValues);
        end

        function h = optimplotfirstorderopt(optimValues)
            tag = "optimplotfirstorderopt";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "firstorderopt"]);
            isSupported = isSupported && ~isempty(optimValues.firstorderopt);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleFirstOrderOpt", ...
                "YLabelText", getString(message("optim:optimplot:YlabelFirstOrderOpt")));
        end

        function h = optimplotfvalconstr(tag, dataFieldName, optimValues)
            if strcmp(dataFieldName, "fval")
                [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", dataFieldName]);
                h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                    "TitleMessageCatalogID", "optim:optimplot:TitleBestFunVal");
            else % fieldname is constrviolation
                h = matlab.internal.optimfun.plotfcns.Factory.shared_constrviolation(tag, optimValues);
            end
        end

        function h = optimplotresnorm(optimValues)
            tag = "optimplotresnorm";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "resnorm"]);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleNormResid", ...
                "YLabelText", getString(message("optim:optimplot:YlabelNormResid")));
        end

        function h = optimplotstepsize(optimValues)
            tag = "optimplotstepsize";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "stepsize"]);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleStepSize", ...
                "YLabelText", getString(message("optim:optimplot:YlabelStepSize")));
        end

        %% ga
        function h = gaplotbestf(tag, optimValues)
            if strcmp(tag, "gaplotbestf")
                calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcBestScore(optimValues);
            else % gaplotmean
                calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcAverageScore(optimValues);
            end
            h = matlab.internal.optimfun.plotfcns.Factory.shared_bestfitness(tag, calculationFcn, optimValues);
        end

        function h = gaplotbestfun(optimValues)
            tag = "gaplotbestfun";
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcBestScore(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.shared_bestfitness(tag, calculationFcn, optimValues);
        end

        function h = gaplotbestindiv(optimValues)
            tag = "gaplotbestindiv";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "Population") && ...
                matlab.internal.optimfun.plotfcns.Factory.isGaSingleObjective(optimValues);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcBestIndividual(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues, ...
                "TitleText", getString(message("globaloptim:gaplotcommon:TitleBestIndividual")), ...
                "YLabelText", getString(message("globaloptim:gaplotcommon:LabelBestIndividual")));
        end

        function h = gaplotexpectation(optimValues)
            tag = "gaplotexpectation";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "Expectation") && ...
                matlab.internal.optimfun.plotfcns.Factory.isGaSingleObjective(optimValues);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcExpectationData(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scatter(tag, isSupported, calculationFcn, optimValues);
        end

        %% ga and gamultiobj
        function h = gaplotdistance(optimValues)
            tag = "gaplotdistance";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["Generation", "Score", "Population"]);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcAverageDistance(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "globaloptim:gaplotcommon:TitleAvgDistance", ...
                "XLabelText", getString(message("globaloptim:gaplotcommon:LabelGeneration")), ...
                "YLabelText", getString(message("globaloptim:gaplotcommon:LabelAvgDistance")));
        end

        function h = gaplotmaxconstr(optimValues)
            tag = "gaplotmaxconstr";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["Generation", "NonlinIneq", "NonlinEq"]) || ...
                matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["Generation", "C", "Ceq"]);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcGaMaxConstraint(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleMaxConstrViol", ...
                "XLabelText", getString(message("globaloptim:gaplotcommon:LabelGeneration")), ...
                "YLabelText", getString(message("optim:optimplot:YlabelConstrViol")));
        end

        function h = gaplotscores(optimValues)
            tag = "gaplotscores";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "Score");
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcFirstObjectiveScore(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues, ...
                "TitleText", getString(message("globaloptim:gaplotcommon:TitleFitnessEachIndividual")), ...
                "XLabelText", getString(message("globaloptim:gaplotcommon:LabelIndividual")), ...
                "YLabelText", getString(message("globaloptim:gaplotcommon:LabelFitnessValue")));
        end

        function h = gaplotselection(optimValues)
            tag = "gaplotselection";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "Selection");
            optimValues.Selection = matlab.internal.optimfun.plotfcns.AbstractPlotFunction.EmptyData;
            h = matlab.internal.optimfun.plotfcns.Factory.histogram(tag, isSupported, calculationFcn, optimValues, ...
                "TitleText", getString(message("globaloptim:gaplotcommon:TitleSelectionFcn")), ...
                "XLabelText", getString(message("globaloptim:gaplotcommon:LabelIndividual")), ...
                "YLabelText", getString(message("globaloptim:gaplotcommon:LabelNumChildren")));
        end

        function h = gaplotstopping(optimValues)
            tag = "gaplotstopping";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["Generation", "StartTime"]);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcGaStoppingCriteria(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.stoppingCriteria(tag, isSupported, calculationFcn, optimValues);
        end

        %% gamultiobj
        function h = gaplotpareto(optimValues)
            tag = "gaplotpareto";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.isGaMultiObjective(optimValues);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcGaParetoData(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.pareto(tag, isSupported, calculationFcn, optimValues);
        end

        function h = gaplotparetodistance(optimValues)
            tag = "gaplotparetodistance";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "Distance");
            h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues, ...
                "TitleText", getString(message("globaloptim:gaplotcommon:TitleDistanceIndividuals")), ...
                "XLabelText", getString(message("globaloptim:gaplotcommon:LabelIndividual")), ...
                "YLabelText", getString(message("globaloptim:gaplotcommon:LabelDistance")));
        end

        function h = gaplotrankhist(optimValues)
            tag = "gaplotrankhist";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "Rank");
            h = matlab.internal.optimfun.plotfcns.Factory.histogram(tag, isSupported, calculationFcn, optimValues);
        end

        function h = gaplotspread(optimValues)
            tag = "gaplotspread";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["Generation", "Spread"]);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcAverageSpread(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "globaloptim:gaplotcommon:TitleAvgSpread", ...
                "XLabelText", getString(message("globaloptim:gaplotcommon:LabelGeneration")), ...
                "YLabelText", getString(message("globaloptim:gaplotcommon:LabelAvgSpread")));
        end

        %% GlobalSearch/MultiStart
        function h = gsplotbestf(optimValues)
            tag = "gsplotbestf";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["localrunindex", "bestfval"]);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcGSbestf(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleBestFunVal", ...
                "XLabelText", getString(message("globaloptim:gsplotcommon:LabelLocalSolverCall")));
        end

        function h = gsplotfunccount(optimValues)
            tag = "gsplotfunccount";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["localrunindex", "funccount"]);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcFuncCount(optimValues, "localrunindex");
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "MATLAB:optimfun:funfun:optimplots:TitleTotalFunctionEvaluations", ...
                "XLabelText", getString(message("globaloptim:gsplotcommon:LabelLocalSolverCall")), ...
                "YLabelText", getString(message("MATLAB:optimfun:funfun:optimplots:LabelEvaluations")));
        end

        %% patternsearch
        function h = psplotbestf(optimValues)
            tag = "psplotbestf";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "fval"]);
            isSupported = isSupported && matlab.internal.optimfun.plotfcns.Factory.isSingleObjective(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleBestFunVal");
        end

        function h = psplotbestx(optimValues)
            tag = "psplotbestx";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "x");
            isSupported = isSupported && matlab.internal.optimfun.plotfcns.Factory.isSingleObjective(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues, ...
                "TitleText", getString(message("globaloptim:psplotcommon:BestPointTitle")),...
                "YLabelText", getString(message("globaloptim:psplotcommon:BestPointLabel")));
        end

        function h = psplotfuncount(optimValues)
            tag = "psplotfuncount";
            h = matlab.internal.optimfun.plotfcns.Factory.shared_funccount(tag, optimValues);
        end

        function h = psplotmaxconstr(optimValues)
            tag = "psplotmaxconstr";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "iteration") && ...
                (matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "nonlinineq") || ...
                matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "nonlineq"));
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcPsMaxConstraint(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleMaxConstrViol", ...
                "XLabelText", getString(message("MATLAB:optimfun:funfun:optimplots:LabelIteration")), ...
                "YLabelText", getString(message("optim:optimplot:YlabelConstrViol")));
        end

        function h = psplotmeshsize(optimValues)
            tag = "psplotmeshsize";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "meshsize"]);
            isSupported = isSupported && matlab.internal.optimfun.plotfcns.Factory.isSingleObjective(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "globaloptim:psplotcommon:CurrentMeshSizeTitle", ...
                "YLabelText", getString(message("globaloptim:psplotcommon:MeshSizeLabel")));
        end

        %% paretosearch
        function h = psplotdistance(optimValues)
            tag = "psplotdistance";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "averagedistance"]);
            isSupported = isSupported && matlab.internal.optimfun.plotfcns.Factory.isMultiObjective(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "globaloptim:psplotcommon:distanceTitle",...
                "YLabelText", getString(message("globaloptim:psplotcommon:distanceYLabel")));
        end

        function h = psplotparetof(optimValues)
            tag = "psplotparetof";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.isMultiObjective(optimValues);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcNothing(optimValues, "fval");
            h = matlab.internal.optimfun.plotfcns.Factory.pareto(tag, isSupported, calculationFcn, optimValues);
        end

        function h = psplotparetox(optimValues)
            tag = "psplotparetox";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "x");
            isSupported = isSupported && matlab.internal.optimfun.plotfcns.Factory.isMultiObjective(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.pareto(tag, isSupported, calculationFcn, optimValues, ...
                "TitleText", getString(message("globaloptim:psplotcommon:xParamTitle")), ...
                "AxesLabelMessageCatalogID", "globaloptim:psplotcommon:paramAxisLabelDefault");
        end

        function h = psplotspread(optimValues)
            tag = "psplotspread";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "spread"]);
            isSupported = isSupported && matlab.internal.optimfun.plotfcns.Factory.isMultiObjective(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "globaloptim:psplotcommon:spreadTitle",...
                "YLabelText", getString(message("globaloptim:psplotcommon:spreadYLabel")));
        end

        function h = psplotvolume(optimValues)
            tag = "psplotvolume";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "volume"]);
            isSupported = isSupported && matlab.internal.optimfun.plotfcns.Factory.isMultiObjective(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "globaloptim:psplotcommon:volumeTitle",...
                "YLabelText", getString(message("globaloptim:psplotcommon:volumeYLabel")));
        end

        %% particleswarm
        function h = pswplotbestf(optimValues)
            tag = "pswplotbestf";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "bestfval"]);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleBestFunVal");
        end

        %% simulannealbnd
        function h = saplotbestf(optimValues)
            tag = "saplotbestf";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "bestfval"]);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleBestFunVal");
        end

        function h = saplotbestx(optimValues)
            tag = "saplotbestx";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "bestx");
            h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues, ...
                "TitleText", getString(message("globaloptim:psplotcommon:BestPointTitle")),...
                "YLabelText", getString(message("globaloptim:psplotcommon:BestPointLabel")));
        end

        function h = saplotf(optimValues)
            tag = "saplotf";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "fval"]);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues);
        end

        function h = saplotstopping(optimValues)
            tag = "saplotstopping";
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "funccount");
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcSaStoppingCriteria(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.stoppingCriteria(tag, isSupported, calculationFcn, optimValues, ...
                "YTickLabelText", string({getString(message("globaloptim:gaplotcommon:LabelTime")), ...
                getString(message("MATLAB:optimfun:funfun:optimplots:LabelIteration")), ...
                getString(message("globaloptim:saplotcommon:LabelEvalCount"))}));
        end

        function h = saplottemperature(optimValues)
            tag = "saplottemperature";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "temperature");
            h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues, ...
                "TitleText", getString(message("globaloptim:saplotcommon:TitleCurrentTemp")),...
                "YLabelText", getString(message("globaloptim:saplotcommon:LabelCurrentTemp")));
        end

        function h = saplotx(optimValues)
            tag = "saplotx";
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, "x");
            h = matlab.internal.optimfun.plotfcns.Factory.bar(tag, isSupported, calculationFcn, optimValues);
        end
    end

    methods (Static, Access = protected)

        %% shared methods
        function h = shared_funccount(tag, optimValues)
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["iteration", "funccount"]);
            calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcFuncCount(optimValues, "iteration");
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "MATLAB:optimfun:funfun:optimplots:TitleTotalFunctionEvaluations", ...
                "YLabelText", getString(message("MATLAB:optimfun:funfun:optimplots:LabelEvaluations")));
        end

        function h = shared_constrviolation(tag, optimValues)
            [isSupported, calculationFcn] = matlab.internal.optimfun.plotfcns.Factory.getDefaultInputs(optimValues, ["iteration", "constrviolation"]);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "optim:optimplot:TitleMaxConstrViol", ...
                "YLabelText", getString(message("optim:optimplot:YlabelConstrViol")));
        end

        function h = shared_bestfitness(tag, calculationFcn, optimValues)
            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "Generation") && ...
                matlab.internal.optimfun.plotfcns.Factory.isGaSingleObjective(optimValues);
            h = matlab.internal.optimfun.plotfcns.Factory.scalarScatter(tag, isSupported, calculationFcn, optimValues, ...
                "TitleMessageCatalogID", "globaloptim:gaplotcommon:TitleBestFitness", ...
                "XLabelText", getString(message("globaloptim:gaplotcommon:LabelGeneration")), ...
                "YLabelText", getString(message("globaloptim:gaplotcommon:LabelFitnessValue")));
        end

        %% plot fcns
        function h = bar(tag, isSupported, calculationFcn, optimValues, setupData)

            arguments

                % Required positional arguments
                tag (1, 1) string
                isSupported (1, 1) logical
                calculationFcn (1, 1) function_handle
                optimValues (1, 1) struct

                % NV-Pairs to create setupData struct. Use optimplotx defaults
                setupData.TitleText (1, 1) string = getString(message("MATLAB:optimfun:funfun:optimplots:TitleCurrentPoint"));
                setupData.XLabelText (1, 1) string = getString(message("MATLAB:optimfun:funfun:optimplots:LabelVariableNumber"));
                setupData.YLabelText (1, 1) string = getString(message("MATLAB:optimfun:funfun:optimplots:LabelCurrentPoint"));
            end

            % Call constructor
            h = matlab.internal.optimfun.plotfcns.BarPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end

        function h = histogram(tag, isSupported, calculationFcn, optimValues, setupData)

            arguments

                % Required positional arguments
                tag (1, 1) string
                isSupported (1, 1) logical
                calculationFcn (1, 1) function_handle
                optimValues (1, 1) struct

                % NV-Pairs to create setupData struct. Use gaplotrankhist defaults
                setupData.BinMethod (1, 1) string = "integers";
                setupData.TitleText (1, 1) string = getString(message("globaloptim:gaplotcommon:TitleRankHistogram"));
                setupData.XLabelText (1, 1) string = getString(message("globaloptim:gaplotcommon:LabelRank"));
                setupData.YLabelText (1, 1) string = getString(message("globaloptim:gaplotcommon:LabelNumIndividuals"));
            end

            % Call constructor
            h = matlab.internal.optimfun.plotfcns.HistogramPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end

        function h = pareto(tag, isSupported, calculationFcn, optimValues, setupData)

            arguments

                % Required positional arguments
                tag (1, 1) string
                isSupported (1, 1) logical
                calculationFcn (1, 1) function_handle
                optimValues (1, 1) struct

                % NV-Pairs to create setupData struct. Use psplotparetof defaults
                setupData.TitleText (1, 1) string = getString(message('globaloptim:psplotcommon:fvalTitle'));
                setupData.AxesLabelMessageCatalogID (1, 1) string = "globaloptim:psplotcommon:objAxisLabelDefault";
            end

            % Determine whether the plot data is 3D
            setupData.Is3D = false;
            if isSupported
                data = calculationFcn(optimValues);
                setupData.Is3D = size(data, 2) >= 3;
            end

            % Set axes labels from message catalog id
            setupData.XLabelText = getString(message(setupData.AxesLabelMessageCatalogID, 1));
            setupData.YLabelText = getString(message(setupData.AxesLabelMessageCatalogID, 2));
            setupData.ZLabelText = getString(message(setupData.AxesLabelMessageCatalogID, 3));

            % Call constructor
            h = matlab.internal.optimfun.plotfcns.ParetoPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end

        function h = scalarScatter(tag, isSupported, calculationFcn, optimValues, setupData)

            arguments

                % Required positional arguments
                tag (1, 1) string
                isSupported (1, 1) logical
                calculationFcn (1, 1) function_handle
                optimValues (1, 1) struct

                % NV-Pairs to create setupData struct. Use optimplotfval defaults
                setupData.TitleMessageCatalogID = "MATLAB:optimfun:funfun:optimplots:TitleCurrentFunctionValue";
                setupData.XLabelText (1, 1) string = getString(message("MATLAB:optimfun:funfun:optimplots:LabelIteration"));
                setupData.YLabelText (1, 1) string = getString(message("MATLAB:optimfun:funfun:optimplots:LabelFunctionValue"));
            end

            % Set initial title text
            setupData.TitleText = getString(message(setupData.TitleMessageCatalogID, ...
                sprintf("%g", matlab.internal.optimfun.plotfcns.AbstractPlotFunction.EmptyData)));

            % Call constructor
            h = matlab.internal.optimfun.plotfcns.ScalarScatterPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end

        function h = scatter(tag, isSupported, calculationFcn, optimValues, setupData)

            arguments

                % Required positional arguments
                tag (1, 1) string
                isSupported (1, 1) logical
                calculationFcn (1, 1) function_handle
                optimValues (1, 1) struct

                % NV-Pairs to create setupData struct. Use gaplotexpectation defaults
                setupData.TitleText (1, 1) string = getString(message("globaloptim:gaplotcommon:LabelFitnessScaling"));
                setupData.XLabelText (1, 1) string = getString(message("globaloptim:gaplotcommon:LabelRawScore"));
                setupData.YLabelText (1, 1) string = getString(message("globaloptim:gaplotcommon:LabelExpectation"));
            end

            % Call constructor
            h = matlab.internal.optimfun.plotfcns.ScatterPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end

        function h = stoppingCriteria(tag, isSupported, calculationFcn, optimValues, setupData)

            arguments

                % Required positional arguments
                tag (1, 1) string
                isSupported (1, 1) logical
                calculationFcn (1, 1) function_handle
                optimValues (1, 1) struct

                % NV-Pairs to create setupData struct. Use gaplotstopping defaults
                setupData.TitleText (1, 1) string = getString(message("globaloptim:gaplotcommon:TitleStoppingCriteria"));
                setupData.XLabelText (1, 1) string = getString(message("globaloptim:gaplotcommon:LabelPctCriteriaMet"));
                setupData.YLabelText (1, 1) string = getString(message("globaloptim:gaplotcommon:LabelCriterion"));
                setupData.YTickLabelText (1, :) string = string({getString(message("globaloptim:gaplotcommon:LabelGeneration")), ...
                    getString(message("globaloptim:gaplotcommon:LabelTime")), ...
                    getString(message("globaloptim:gaplotcommon:LabelStallGen")), ...
                    getString(message("globaloptim:gaplotcommon:LabelStallTime"))});
            end

            % Call constructor
            h = matlab.internal.optimfun.plotfcns.StoppingCriteriaPlotFunction(tag, isSupported, calculationFcn, optimValues, setupData);
        end

        %% Validation functions
        function tf = hasFields(optimValues, dataFieldNames)
            % Verify specific fields in the optimValues struct all exist
            tf = all(isfield(optimValues, dataFieldNames));
        end

        function tf = isSingleObjective(optimValues)
            % Verify single-objective
            tf = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "fval") && size(optimValues.fval, 2) == 1;
        end

        function tf = isMultiObjective(optimValues)
            % Verify multi-objective
            tf = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, "fval") && size(optimValues.fval, 2) > 1;
        end

        function tf = isGaSingleObjective(optimValues)
            % Verify single-objective using ga optimValues names
            tf = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["Best", "Score"]) && size(optimValues.Score, 2) == 1;
        end

        function tf = isGaMultiObjective(optimValues)
            % AVerify multi-objective using ga optimValues names
            tf = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, ["Rank", "Score"]) && size(optimValues.Score, 2) > 1;
        end

        %% Calculation functions
        function data = calcNothing(optimValues, dataFieldName)
            % Data to plot already exists in optimValues struct, just
            % return the specified fieldname
            data = optimValues.(dataFieldName);
        end

        function data = appendScalars(optimValues, dataFieldNames)
            % Append scalar data that already exists in optimValues struct
            data = nan(1, numel(dataFieldNames));
            for ct = 1:numel(dataFieldNames)
                data(ct) = optimValues.(dataFieldNames(ct));
            end
        end

        function data = calcFuncCount(optimValues, xDataFieldName)

            % The funccount field of the optimValues struct contains the total number
            % of function evaluations across all iterations. To plot the number of
            % function evaluations at the current iteration, all previous iteration
            % funccounts needs to be subtracted.
            persistent prevFuncCount

            data(1) = optimValues.(xDataFieldName);
            if data(1) == 0
                prevFuncCount = 0;
            end
            data(2) = optimValues.funccount - prevFuncCount;
            prevFuncCount = optimValues.funccount;

            % Include a 3rd element in data vector for value to print with title
            data(3) = optimValues.funccount;
        end

        function data = calcBestScore(optimValues)

            % Calculate best score across all generations
            data(1) = optimValues.Generation;
            if data(1) == 0
                data(2) = optimValues.Best(1);
            else
                data(2) = optimValues.Best(data(1));
            end
        end

        function data = calcAverageScore(optimValues)

            % Calculate the average of optimValues.Score
            data(1) = optimValues.Generation;
            score = optimValues.Score;
            nans = isnan(score);
            score(nans) = 0;
            n = sum(~nans);
            n(n==0) = NaN; % prevent divideByZero warnings
            % Sum up non-NaNs, and divide by the number of non-NaNs.
            data(2) = sum(score) ./ n;
        end

        function data = calcBestIndividual(optimValues)

            % Calculate the best individual
            genNumAndBestScore = matlab.internal.optimfun.plotfcns.Factory.calcBestScore(optimValues);
            bestScore = genNumAndBestScore(2);
            row = find(optimValues.Score(:, 1) == bestScore, 1);
            data = double(optimValues.Population(row, :));
        end

        function data = calcAverageDistance(optimValues)

            % Determine the average distance for this generation
            data(1) = optimValues.Generation;
            samples = 20;
            popSize = size(optimValues.Score, 1);
            choices = ceil(sum(popSize) * rand(samples, 2));
            population = optimValues.Population;
            distance = 0;
            for ct = 1:samples
                d = population(choices(ct, 1), :) - population(choices(ct, 2), :);
                distance = distance + sqrt(sum(d.*d));
            end
            data(2) = distance/samples;
        end

        function data = calcExpectationData(optimValues)

            % We have to store scores because the expectation in optimValues
            % are for the last generation and the scores are for the next generation.
            persistent scores
            if strcmp(optimValues.flag, "init")
                scores = optimValues.Score;
                setData(scores, zeros(size(scores)));
            else
                % This is a safeguard when population size is reduced at run time.
                if numel(optimValues.Score) ~= numel(optimValues.Expectation)
                    scores = optimValues.Score(numel(optimValues.Score) - numel(optimValues.Expectation)+1:end);
                end
                setData(scores, optimValues.Expectation);
                scores = optimValues.Score;
            end

            function setData(x, y)
                % Ensure x and y are column vectors
                data = [x(:), y(:)];
            end
        end

        function data = calcGaMaxConstraint(optimValues)

            % Calculate maximum constraint violation
            data(1) = optimValues.Generation;
            maxConstr = 0;
            if isfield(optimValues, "NonlinIneq") % GA
                maxConstr = max([maxConstr; optimValues.NonlinIneq(:); abs(optimValues.NonlinEq(:))]);
            else % GAMULTIOBJ
                maxConstr = max([maxConstr; optimValues.C(:); abs(optimValues.Ceq(:))]);
            end
            data(2) = maxConstr;
        end

        function data = calcGaParetoData(optimValues)

            % Calculate for individuals from first front
            minRank = 1;
            data = optimValues.Score((optimValues.Rank == minRank), :);
        end

        function data = calcFirstObjectiveScore(optimValues)

            % Only plot scores for the first objective
            data = optimValues.Score(:, 1);
        end

        function data = calcAverageSpread(optimValues)

            % Calculate the average spread for this generation
            data(1) = optimValues.Generation;
            data(2) = mean(optimValues.Spread(end, :));
        end

        function data = calcGaStoppingCriteria(optimValues)

            % Calculate fraction of 'doneness' for each criterion and return as percentage
            data(1) = optimValues.Generation / optimValues.options.MaxGenerations;
            data(2) = toc(optimValues.StartTime) / optimValues.options.MaxTime;
            if isfield(optimValues, "LastImprovement")
                data(3) = (optimValues.Generation - optimValues.LastImprovement) / optimValues.options.MaxStallGenerations;
            end
            if isfield(optimValues, "LastImprovementTime")
                data(4) = toc(optimValues.LastImprovementTime) / optimValues.options.MaxStallTime;
            end
            data = 100 * data;
        end

        function data = calcGSbestf(optimValues)

            % It is possible for optimValues.bestfval to be empty
            data(1) = optimValues.localrunindex;
            if isempty(optimValues.bestfval)
                data(2) = matlab.internal.optimfun.plotfcns.AbstractPlotFunction.EmptyData;
            else
                data(2) = optimValues.bestfval;
            end
        end

        function data = calcPsMaxConstraint(optimValues)

            % Calculate maximum constraint violation
            data(1) = optimValues.iteration;
            maxConstr = 0;
            if isfield(optimValues, "nonlinineq") && ~isempty(optimValues.nonlinineq)
                maxConstr = max([maxConstr; optimValues.nonlinineq(:)]);
            end
            if isfield(optimValues, "nonlineq") && ~isempty(optimValues.nonlineq)
                maxConstr = max([maxConstr; abs(optimValues.nonlineq(:))]);
            end
            data(2) = maxConstr;
        end

        function data = calcSaStoppingCriteria(optimValues)

            % Calculate fraction of 'doneness' for each criterion and return as percentage
            func = optimValues.funccount / optimValues.options.MaxFunctionEvaluations;
            iter = optimValues.iteration / optimValues.options.MaxIterations;
            time = toc(optimValues.t0) / optimValues.options.MaxTime;
            data = 100 * [time, iter, func];
        end

        %% Convenience function for a common pattern in isSupported and calculationFcn inputs
        function [isSupported, calculationFcn] = getDefaultInputs(optimValues, dataFieldNames)

            isSupported = matlab.internal.optimfun.plotfcns.Factory.hasFields(optimValues, dataFieldNames);
            if numel(dataFieldNames) > 1
                calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.appendScalars(optimValues, dataFieldNames);
            else
                calculationFcn = @(optimValues) matlab.internal.optimfun.plotfcns.Factory.calcNothing(optimValues, dataFieldNames);
            end
        end
    end
end
