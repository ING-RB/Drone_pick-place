classdef OptionAliasStore
    %

    %   Copyright 2015-2023 The MathWorks, Inc.

    properties (Constant)

        OldNames = getOldNames;
        NewNames = getNewNames;

        % Hidden properties that are also aliases 
        HiddenNewNames = {'InitialSwarmMatrix'; 'CheckGradients'};

        AlgsWithFunctionTolerance = {'active-set'; ...
            'trust-region';'trust-region-reflective';...
            'trust-region-dogleg';'levenberg-marquardt';...
            'quasi-newton'};

        GlobalSolvers = {'ga';'gamultiobj';'patternsearch';'particleswarm';'simulannealbnd'};
        
        NoAliasSolvers = {'paretosearch','surrogateopt','coneprog'}
        
        JacobianSolvers = {'lsqnonlin', 'lsqcurvefit', 'fsolve'};

        TimeLimitSolvers = {'ga';'gamultiobj';'patternsearch';'simulannealbnd'};
        
        % Used to check if solvers are Global/MATALB solvers when creating
        % options
        AllGlobalSolvers = {'patternsearch';'surrogateopt';'paretosearch';'gamultiobj';'particleswarm';'ga';'simulannealbnd'}

        MATLABSolvers = {'fminsearch';'fzero';'fminbnd';'lsqnonneg'}
    end


    methods (Static)
        function name = getAlias(name, solver, optionStruct)
            if any(strcmp(solver, optim.options.OptionAliasStore.NoAliasSolvers))
                return
            end
            idx = strcmp(name, optim.options.OptionAliasStore.NewNames);
            if any(idx)
                if (strcmp(name, 'SpecifyObjectiveGradient') && ...
                   any(strcmp(solver, optim.options.OptionAliasStore.JacobianSolvers))) || ...
                   (strcmp(name, 'HessianApproximation') && strcmp(solver, 'fminunc'))
                    idx = find(idx);
                    name = optim.options.OptionAliasStore.OldNames{idx(2)};
                elseif strcmp(name, 'SubproblemAlgorithm') && nargin > 2 && ...
                        isfield(optionStruct, 'Algorithm') && strcmp(solver, 'fmincon') && ...
                        strcmp(optionStruct.Algorithm, 'interior-point')
                    name = 'SubproblemAlgorithm';
                elseif strcmp(name, 'OutputFcn') && ~any(strcmp(solver, optim.options.OptionAliasStore.GlobalSolvers))
                    name = 'OutputFcn';
                elseif strcmp(name, 'MaxTime') && ~any(strcmp(solver, optim.options.OptionAliasStore.TimeLimitSolvers))
                    name = 'MaxTime';
                else
                    name = optim.options.OptionAliasStore.OldNames{idx};
                end
            end
        end

        function value = mapOptionFromStore(name, optsStruct)
            % This function does the mapping for the "get" equivalent
            % We only really have to care about Hessian* and
            % SubproblemAlgorithm settings

            % TODO: add logicals
            if strcmp(name, 'HessianApproximation')
                if any(strcmp({'fin-diff-grads','off'}, optsStruct.Hessian))
                    value = 'finite-difference';
                else
                    value = optsStruct.Hessian;
                end
            elseif strcmp(name, 'SubproblemAlgorithm')
                if isfield(optsStruct,'Algorithm') && ...
                   any(strcmp(optim.options.OptionAliasStore.AlgsWithFunctionTolerance, optsStruct.Algorithm)) || ...
                   ~isfield(optsStruct, 'SubproblemAlgorithm')
               % For solvers that have an Algorithm, check if they have a
               % trust-region-reflective variant. If so, set
               % PrecondBandWidth.
               %
               % A special case, though, is for solvers that have a TRR
               % variant AND another algorithm that uses
               % SubproblemAlgorithm directly (e.g. fmincon). Make sure
               % that we set the correct option:
               % - PrecondBandWidth for TRR
               % - SubproblemAlgorithm for others

                    if isinf(optsStruct.PrecondBandWidth)
                        value = 'factorization';
                    else
                        value = 'cg';
                    end
                else % Algorithm is interior-point fmincon
                    % Caller wants the actual SubproblemAlgorithm
                    if strcmp(optsStruct.SubproblemAlgorithm,'ldl-factorization')
                        value = 'factorization';
                    else
                        value = optsStruct.SubproblemAlgorithm;
                    end
                end
            end
        end

        function [oldName, oldValue] = mapOptionToStore(newName, newValue, optsStruct)
        % This function does the mapping for the "set" equivalent

            % Look up old option name
            idx = strcmp(newName, optim.options.OptionAliasStore.NewNames);
            if any(idx)
                oldName = optim.options.OptionAliasStore.OldNames{idx};
            else
                % If not in the map, then use the oldName and decide below
                oldName = newName;
            end
            oldValue = newValue;

            if strcmp(newName, 'TolFun')
                if isfield(optsStruct,'Algorithm') && ...
                   isfield(optsStruct,'TolFunValue')
                    oldName = {'TolFunValue'; 'TolFun'};
                    oldValue = {newValue; newValue};
                end
            elseif any(strcmp(newName, {'CheckGradients', 'AccelerateMesh', ...
                    'SpecifyConstraintGradient', 'UseVectorized', 'ScaleMesh', ...
                    'UseCompletePoll', 'UseCompleteSearch'}))
                % Map true/fasle to 'on'/'off'
                if newValue
                    oldValue = 'on';
                else
                    oldValue = 'off';
                end
            elseif strcmp(newName,'MaxTime') && isfield(optsStruct,'MaxTime')
                oldName = newName;
            elseif strcmp(newName, 'SpecifyObjectiveGradient')
                if isfield(optsStruct, 'Jacobian')
                    oldName = 'Jacobian';
                else
                    oldName = 'GradObj';
                end
                if newValue
                    oldValue = 'on';
                else
                    oldValue = 'off';
                end
            elseif strcmp(newName, 'HonorBounds')
                % Map AlwaysHonorConstraints to HonorBounds
                if newValue
                    oldValue = 'bounds';
                else
                    oldValue = 'none';
                end
            elseif strcmp(oldName, 'ScaleProblem')
                if islogical(newValue)
                    if newValue
                        oldValue = 'obj-and-constr';
                    else
                        oldValue = 'none';
                    end
                else
                    oldValue = newValue;
                end
            elseif strcmp(oldName, 'ScaleMesh')
                if islogical(newValue)
                    if newValue
                        oldValue = 'on';
                    else
                        oldValue = 'off';
                    end
                else
                    oldValue = newValue;
                end
            elseif strcmp(newName,'HessianApproximation')
                if strcmp(newValue, 'finite-difference')
                    if isfield(optsStruct,'Algorithm') && ...
                       any(strcmp(optim.options.OptionAliasStore.AlgsWithFunctionTolerance, optsStruct.Algorithm))
                        oldValue = 'off';
                    else
                        oldValue = 'fin-diff-grads';
                    end
                end
            elseif strcmp(newName, 'SubproblemAlgorithm')
                if isfield(optsStruct,'Algorithm') && ...
                        strcmp(optsStruct.Algorithm, 'interior-point')
                    % As of R2016a, only fmincon interior-point will not
                    % map SubproblemAlgorithm back to PrecondBandWidth.
                    % fmincon interior-point is the only interior-point
                    % algorithm with a SubproblemAlgorithm.
                    oldName = 'SubproblemAlgorithm';
                    if strcmp(newValue,'factorization')
                        oldValue = 'ldl-factorization';
                    else
                        oldValue = newValue;
                    end
                else
                    % If the user sets SubproblemAlgorithm for a solver
                    % that has a trust-region-reflective (or trust-region)
                    % algorithm and this is not fmincon
                    % interior-point, we need to map back to
                    % PrecondBandWidth.
                    oldName = 'PrecondBandWidth';
                    if any(strcmp({'factorization', 'ldl-factorization'},newValue))
                        oldValue = Inf;
                    else
                        oldValue = 0;
                    end
                end
            elseif (strcmpi(newName, 'OutputFcn') && isfield(optsStruct, 'OutputFcn'))
                oldName = newName;
                oldValue = newValue;
            end

        end

        function newValue = convertToLogical(oldValue, trueStr)

            newValue = strcmp(oldValue, trueStr);

        end

        function name = getNameFromAlias(name)
            idx = strcmp(name, optim.options.OptionAliasStore.OldNames);
            idx = find(idx);
            if isempty(idx)
                name = {name};
            else
                numNames = length(idx);
                name = cell(numNames, 1);
                for i = 1:numNames
                    name{i} = optim.options.OptionAliasStore.NewNames{idx(i)};
                end
            end
        end

    end

end


function oldNames = getOldNames

oldNames = {...
    'AlwaysHonorConstraints'
    'BranchingRule'
    'CompletePoll'
    'CompleteSearch'
    'CutGenMaxIter'
    'DerivativeCheck'
    'FinDiffRelStep'
    'FinDiffType'
    'Generations'
    'GoalsExactAchieve'
    'GradConstr'
    'GradObj'
    'Hessian'
    'HessFcn'
    'HessMult'
    'HessUpdate'
    'InitialPopulation'
    'InitialScores'
    'InitialSwarm'
    'InitialSwarm'
    'IPPreprocess'
    'Jacobian'
    'JacobMult'
    'LPMaxIter'
    'MaxFunEvals'
    'MaxNumFeasPoints'
    'MaxIter'
    'MeshAccelerator'
    'MeshContraction'
    'MeshExpansion'
    'MinAbsMax'
    'MinFractionNeighbors'
    'NonlinConAlgorithm'
    'OutputFcns'
    'PlotFcns'
    'PollingOrder'
    'PopInitRange'
    'RelObjThreshold'
    'RootLPAlgorithm'
    'RootLPMaxIter'
    'SearchMethod'
    'SelfAdjustment'
    'SocialAdjustment'
    'StallGenLimit'
    'StallIterLimit'
    'StallTimeLimit'
    'TimeLimit'
    'TolCon'
    'TolFun'
    'TolFunValue'
    'TolFunLP'
    'TolGapAbs'
    'TolGapRel'
    'TolInteger'
    'TolMesh'
    'TolX'
    'Vectorized'
    'ScaleProblem'
    'PrecondBandWidth'};

end

function newNames = getNewNames

newNames = {...
    'HonorBounds';
    'BranchRule';
    'UseCompletePoll';
    'UseCompleteSearch';
    'CutMaxIterations';
    'CheckGradients';
    'FiniteDifferenceStepSize';
    'FiniteDifferenceType';
    'MaxGenerations';
    'EqualityGoalCount';
    'SpecifyConstraintGradient';
    'SpecifyObjectiveGradient';
    'HessianApproximation';
    'HessianFcn';
    'HessianMultiplyFcn';
    'HessianApproximation';
    'InitialPopulationMatrix';
    'InitialScoresMatrix';
    'InitialPoints';
    'InitialSwarmMatrix';
    'IntegerPreprocess';
    'SpecifyObjectiveGradient';
    'JacobianMultiplyFcn';
    'LPMaxIterations';
    'MaxFunctionEvaluations';
    'MaxFeasiblePoints';
    'MaxIterations';
    'AccelerateMesh';
    'MeshContractionFactor';
    'MeshExpansionFactor';
    'AbsoluteMaxObjectiveCount';
    'MinNeighborsFraction';
    'NonlinearConstraintAlgorithm';
    'OutputFcn';
    'PlotFcn';
    'PollOrderAlgorithm';
    'InitialPopulationRange';
    'ObjectiveImprovementThreshold';
    'RootLPAlgorithm';
    'RootLPMaxIterations';
    'SearchFcn';
    'SelfAdjustmentWeight';
    'SocialAdjustmentWeight';
    'MaxStallGenerations';
    'MaxStallIterations';
    'MaxStallTime';
    'MaxTime';
    'ConstraintTolerance';
    'OptimalityTolerance';
    'FunctionTolerance';
    'LPOptimalityTolerance';
    'AbsoluteGapTolerance';
    'RelativeGapTolerance';
    'IntegerTolerance';
    'MeshTolerance';
    'StepTolerance';
    'UseVectorized';
    'ScaleProblem';
    'SubproblemAlgorithm'};



end


