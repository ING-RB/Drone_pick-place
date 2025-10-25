classdef (Hidden, HandleCompatible) FilterTuner
%   This class is for internal use only. It may be removed in the
%   future. 
%FILTERTUNER Mixin class for filter autotuner

%   Copyright 2020-2021 The MathWorks, Inc.    


    methods (Static, Hidden, Abstract)

        % GETPARAMSFORAUTOTUNE - return list of parameters for a filter that are allowed to be tuned
        % and a list of ones that are not allowed to be tuned (staticparams)
        [tunerparams, staticparams] = getParamsForAutotune

        % HASMEASNOISE True if a filter uses separate measurement noises
        tf = hasMeasNoise

        % GETMEASNOISEEXEMPLAR example struct of measurement noises
        measNoise = getMeasNoiseExemplar;

        % TUNERFUSE compute cost of fusing sensorData relative to groundTruth at filter parameters params
        cost = tunerfuse(params, sensorData, groundTruth, cfg);
    end

    methods (Hidden)
        % Protected versions of some of the above static methods. Overload for filters
        % which need the instance to complete the method tasks.
        % All methods named the same as above, with the suffix FromInst(ance)
        function [tunerparams, staticparams] = getParamsForAutotuneFromInst(obj)
            % Default implementation : call static method
            [tunerparams, staticparams] = obj.getParamsForAutotune;
        end
        function measNoise = getMeasNoiseExemplarFromInst(obj)
            % Default implementation : call static method
            measNoise = obj.getMeasNoiseExemplar;
        end
        function cost = tunerfuseFromInst(obj, params, sensorData, groundTruth, cfg)
            % Default implementation : call static method
            cost = obj.tunerfuse(params, sensorData, groundTruth, cfg);
        end
    end
    methods (Hidden)
        function p = getDefaultTunableParameters(obj)
            % Default implementation just calls
            % getParamsForAutotuneFromInst.
            % Subclasses can overload. 
            % Called by tunerconfig so Hidden
            p = obj.getParamsForAutotuneFromInst;
        end
    end
    methods (Access = protected)
        function crossValidateInputs(obj, sensorData, groundTruth) %#ok<INUSD>
            % Default implementation is empty.
            % Implement in filter classes if cross-validation between
            % sensorData and groundTruth is needed.
            % MLINT suppressed to document call signature.
        end
        function validateOutputs(obj, nout)
            % Only a measurement noise can be returned and only if 
            % hasMeasNoise is true.
            if obj.hasMeasNoise
                assert(nout == 0 | nout == 1, ...
                    message('shared_positioning:tuner:NumelOutputs', class(obj)))
            else
                assert(nout == 0, ...
                    message('shared_positioning:tuner:NoOutputs', class(obj)))
            end
        end
        function [tc, args] = findconfig(obj, varargin)
            % tunerconfig should be last argument or not present
            % Ensure it's not in the wrong place
            for ii=1:(numel(varargin) -1)
                assert(~isa(varargin{ii}, 'tunerconfig'), ...
                    message('shared_positioning:tuner:ConfigLast'));
            end
            % No tunerconfigs so far. What is the last argument?
            if isa(varargin{end}, 'tunerconfig')
                tc = varargin{end};
                args = varargin(1:end-1);
            else
                % use the default
                tc = tunerconfig(obj);
                args = varargin;
            end
        end
        function [measNoise, sensorData, groundTruth, originalInputs] = processInputs(obj, config, args)
            % Validate and return inputs in separate variables

            if obj.hasMeasNoise
                measNoise = args{1};

                % Validate measNoise struct
                ex = getMeasNoiseExemplarFromInst(obj);
                exfn = fieldnames(ex);
                % check that it is a struct
                assert(isstruct(measNoise), ...
                    message('shared_positioning:tuner:MeasNoiseInput', ...
                    strjoin(exfn, ', ')));
                % check the correct number of fields
                mnfn = fieldnames(measNoise);
                assert(numel(mnfn) == numel(exfn), ...
                    message('shared_positioning:tuner:MeasNoiseInput', ...
                    strjoin(exfn, ', ')));
                % check all the field names are correct
                assert( isempty(setdiff(exfn, mnfn)), ...
                    message('shared_positioning:tuner:MeasNoiseInput', ...
                    strjoin(exfn, ', ')));
                
                % sensorData and groundTruth
                sensorData = args{2};
                groundTruth = args{3};
            else
                % Without alternate syntax
                measNoise = struct();
                sensorData = args{1};
                groundTruth = args{2};
            end
            
            % Capture the original inputs before possibly modifying them in
            % the next step. Original parameters are needed by OutputFcn.
            % Build field-by-field in case they are {} which messes up the
            % struct constructor.
            originalInputs.GroundTruth = groundTruth;
            originalInputs.SensorData = sensorData;
            
            % Validate if not custom. If custom, there are no rules.
            if config.Cost ~= "Custom"
                sensorData = processSensorData(obj, sensorData);
                groundTruth = processGroundTruth(obj, groundTruth);
                crossValidateInputs(obj, sensorData, groundTruth);
                
                % Sort sensorData columns to work with mex build
                % infrastructure - alphabetically.
                sensorData = sensorData(:, sort(sensorData.Properties.VariableNames));

            end
        end
        function [lastmetric, filtparams, sensorData, costfcn, config] = initialMetricComp(obj, filtparams, sensorData, groundTruth, config)
            % Initial metric computation.
            % If we aren't doing a custom costfcn, let's try using Mex in a
            % try-catch. If that doesn't work, fall back to interpreted.
            if config.Cost ~= "Custom"
                costfcn = @(a,b,c) obj.tunerfuseFromInst(a,b,c,config);
                if config.UseMex
                    try
                        % If Using mex, make sure the types all match what
                        % the C-code wants - all doubles or all singles.
                        [fptmp, sdtmp] = fusion.internal.tuner.FilterTuner.unifyTypes(filtparams, sensorData);
                        lastmetric = costfcn(fptmp,sdtmp,groundTruth);
                        % That call worked, so move the temporaries to
                        % permanent.
                        filtparams = fptmp;
                        sensorData = sdtmp;
                    
                    % Catch the exception for interactive debugging.
                    % Suppress MLINT.
                    catch ME %#ok<NASGU>
                        % Mex failed. Try again with interpreted (switch
                        % UseMex to false). This time, let the call error (don't
                        % try-catch) in case the user has passed in bad
                        % inputs or a bad cost function. Subsequent costfcn
                        % calls in the descent algorithm use try-catch.
                        config.UseMex = false;
                        % rebind
                        costfcn = @(a,b,c) obj.tunerfuseFromInst(a,b,c,config);
                        lastmetric = costfcn(filtparams,sensorData,groundTruth);
                    end
                else
                    % Don't use Mex but use RMS cost. Let this error to
                    % detect bad inputs.
                    lastmetric = costfcn(filtparams,sensorData,groundTruth);
                end
            else % Custom, or no mex
                % Let this error (don't try-catch) in case the user
                % has passed in bad inputs or a bad cost function.
                % Subsequent costfcn calls in the descent algorithm
                % use try-catch.
                costfcn = config.CustomCostFcn;
                lastmetric = costfcn(filtparams,sensorData,groundTruth);
            end
        end
    end

    methods (Access = protected, Abstract)
        varargout = makeTunerOutput(obj, info, measNoise); 
        sensorData = processSensorData(obj, sensorData);
        groundTruth = processGroundTruth(obj, groundTruth);
    end
    methods 
        function varargout = tune(obj, varargin)
            validateOutputs(obj, nargout);
            if obj.hasMeasNoise
                narginchk(4,5);
            else
                narginchk(3,4); % Without alternate syntax
            end
            [config, args] = findconfig(obj, varargin{:});
            validate(config); % Make sure everything is setup right
            [measNoise, sensorData, groundTruth, tunerValues] = processInputs(obj, config, args);

            %%%%%%%%%%%%%%%%%%%
            % Main filter stuff
            
            % Unpack config
            iters = config.MaxIterations;
            stepPos = config.StepForward;
            stepNeg = config.StepBackward;
            earlyTerm = config.ObjectiveLimit;
            funTol = config.FunctionTolerance;
            outfcn = config.OutputFcn;
            doOutFcn = ~isempty(outfcn);            
            hasCustomCost = strcmpi(config.Cost, 'custom');

            % Really validate the tunable parameters, including index
            % validation against the filter.
            filtparams = fusion.internal.tuner.makeFilterParameters(obj, measNoise, hasCustomCost);
            validateTunableParamsAndIndices(config, filtparams);
            tunerdata = fusion.internal.tuner.ParameterAlphaData;
            initialize(tunerdata, config.TunableParameters, filtparams);
            numparams = tunerdata.NumParameters;

            % First metric computation
            [lastmetric, filtparams, sensorData, costfcn, config] = obj.initialMetricComp(filtparams, sensorData, groundTruth, config);
            
            % Finish tunerValues
            tunerValues.Cost = lastmetric;
            tunerValues.Iteration = 0;
            tunerValues.Configuration = config;
           
            % Ensure the output of costfcn is a scalar numeric
            assert(isscalar(lastmetric) && isa(lastmetric, 'numeric'), ...
                message('shared_positioning:tuner:CostFcnOutput'));

            % The tunerdata object manages alpha, a stand-in for the gradient.
            % Initialize alpha to 0.1;
            apInit = 0.1;
            initializeAlpha(tunerdata, apInit);
          
            % Preallocate and initialize the info structure.
            % Set all metrics to empty except for first
            maxInfoNumel = iters * numparams;
            info = filtparams;
            info.alpha = makeAlphaLog(tunerdata);
            [info(1:maxInfoNumel).metric] = deal([]);
            info(1).metric = lastmetric;

            % Initialize display object
            d = fusion.internal.tuner.Display(iters, paramStrings(tunerdata), ...
                config.Display);

            % Coordinate Ascent
            breakAll = false;
            for ii=1:iters
                for pp=1:numparams
                    [pvpos, pvneg] = stepCurrentParam(tunerdata, filtparams);
                    posmetric = invoke(costfcn, pvpos, sensorData, groundTruth);
                    negmetric = invoke(costfcn, pvneg, sensorData, groundTruth);
                    
                    % Compare cost in each direction
                    [metric, bestpv] = chooseWinner(posmetric, negmetric, ...
                        pvpos, pvneg);
                   
                    % FunctionTolerance computation
                    breakAll = abs(metric - lastmetric) < funTol;
            
                    % Compare best at this step to lastmetric and update
                    if metric < lastmetric
                        lastmetric = metric;
                        filtparams = bestpv; % update with best guess
                        updateCurrentAlpha(tunerdata, stepPos);
                    else
                        % Both posmetric and negmetric are worse than lastmetric
                        updateCurrentAlpha(tunerdata, stepNeg);
                    end
                   
                    % Update log structure
                    currentinfo = filtparams;
                    currentinfo.metric = lastmetric;
                    currentinfo.alpha = makeAlphaLog(tunerdata); 
                    idx = (ii-1)*(numparams) + pp;
                    info(idx) = currentinfo;
                    
                   
                    % Print to command window
                    d.printRow(ii, currentParamString(tunerdata), lastmetric);

                    % Exit early? 
                    if metric < earlyTerm
                        breakAll = true;
                        break;
                    end

                    next(tunerdata); % move on to the next parameter
                end
                
                % Use the outputFcn
                tunerValues.Iteration = ii;
                tunerValues.Cost = lastmetric;
                if doOutFcn
                    breakAll = breakAll | outfcn(filtparams, tunerValues);
                end
                
                % Exit early?
                if breakAll
                    break;
                end
            end
            % Trim unused info
            ne = arrayfun(@(x)~isempty(x.metric), info);
            infotrimmed = info(ne);
            
            % Add in UsedMex flag
            [infotrimmed.UsedMex] = deal(config.UseMex);
            
            [varargout{1:nargout}] = makeTunerOutput(obj, infotrimmed, measNoise); 
        end
    end
    methods (Static, Hidden)
        function validateTimetableVars(tbl, inputName, inputIdx, varnames)
            assert(istimetable(tbl), ...
                message('shared_positioning:tuner:InputMustBeTimetable', ...
                inputName, inputIdx));
            fusion.internal.tuner.FilterTuner.validateVarNames(tbl, varnames);
        end
        function validateTableVars(tbl, inputName, inputIdx, varnames)
            assert(istable(tbl), ...
                message('shared_positioning:tuner:InputMustBeTable', ...
                inputName, inputIdx));
            fusion.internal.tuner.FilterTuner.validateVarNames(tbl, varnames);
        end
        
        function validateVarNames(tbl, varnames)
            assert(~isempty(tbl), message('shared_positioning:tuner:InputMustBeNonempty'));
            % Check if all variables are present and only those expected
            % are present. Needs match(a,b) and match(b,a)
            vn = tbl.Properties.VariableNames;
            allpresent = all(matches(vn, varnames, 'IgnoreCase', false)) && ...
                all(matches(varnames, vn, 'IgnoreCase', false)) ;
            assert(allpresent, ...
                message('shared_positioning:tuner:TableVars', ...
                strjoin(varnames, ',')));
        end
        
        function validateTableVarAttrs(tbl, varnames, attrs, inname)
            % Validate sizes
            % attrs is a numel(varnames)-by-2 cell array
            vs = string(varnames); % Ensure string to index correctly
            for ii=1:numel(varnames)
                v = tbl.(vs(ii));
                validateattributes(v,attrs{ii,1}, attrs{ii,2}, ...
                    'tune', inname +  "." + varnames(ii));
            end
        end
        function o = validateAndConvertOrientation(tbl, tblname, varname, allowNan)
            if nargin < 4
                allowNan = false;
            end
            
            attr =  {'ncols', 1,  'nonempty'};
            attrRM =  {'nrows', 3, 'ncols', 3, '2d', ...
                        'nonempty', 'nonsparse',  'real'};
            if ~allowNan
                attr = [attr, 'finite', 'nonnan'];
                attrRM = [attrRM, 'finite', 'nonnan'];
            end
            
            o = tbl.(varname);
            if isa(o, 'quaternion')
                validateattributes(o, {'quaternion'}, ...
                    attr, ...
                    'tune', tblname + "." + varname);
           
            elseif iscell(o)%rotation matrix
                for ii=1:numel(o)
                    v = o{ii};
                    validateattributes(v, {'double', 'single'}, ...
                       attrRM,...
                        'tune', tblname + "." + varname + ...
                        "{" + ii + "}");
                end
                % Okay to convert
                o = quaternion(cat(3,o{:}), 'rotmat', 'frame'); 
            else
                error(message(...
                    'shared_positioning:tuner:OneMatPerRow')); 
            end
            % Force quaternion real part to be positive.
            o = fusion.internal.posangle(o);
        end
        function [filtparams, sensorData] = unifyTypes(filtparams, sensorData)
            % Cast filtparams and sensorData to a common type - single or double. 
            % Find the common base type
            %    single if anything is single
            %    otherwise leave as-is (doubles)
            isSingleVar =  @(x)isa(x,'single')||(iscell(x)&&isa(x{1},'single'));
            singleVars = varfun(isSingleVar, sensorData, 'OutputFormat', 'uniform');
            singleData = any(singleVars);
            singleParams = any(structfun(@(x)isa(x, 'single'), filtparams, 'UniformOutput', true));
            anySingle = singleData | singleParams;
            
            % Cast to singles if necessary. Singles infect so if anything
            % is a single, make everything a single.
            if anySingle
                finalType = 'single';
            else
                finalType = 'double';
            end
            vars = sensorData.Properties.VariableNames;
            sensorData = convertvars(sensorData, vars, @(x)castTableCol(x, finalType));
            
            fh = str2func(finalType);
            fn = fieldnames(filtparams);
            for jj=1:numel(fn)
                x = filtparams.(fn{jj});
                if isa(x, 'numeric')
                    filtparams.(fn{jj}) = fh(x);
                end
            end
         
        end
    end
end

function metric = invoke(costfcn, pvtmp, sensorData, groundTruth)
% INVOKE run the cost function safely
try
    metric = costfcn(pvtmp, sensorData, groundTruth);
catch
    metric = inf;
end
end

function newcol = castTableCol(col, type)
%CASTTABLECOL Cast the columns of a table to a new type
%   Correctly handles the case of a column containing a cell array of data (as with rotation matrices).
%   In this case we want to cast the underlying data and leave it as a cell array.
    if iscell( col )
        newcol = cellfun(@(t)cast(t,type), col, 'UniformOutput', false);
    else
        newcol = cast(col, type);
    end
end

function [metric, val] = chooseWinner(posmetric, negmetric, posval, negval)
% CHOOSEWINNER evaluate which metric is best
if posmetric < negmetric
    metric = posmetric;
    val = posval;
else
    metric = negmetric;
    val = negval;
end
end

