classdef ParticleFilterInputParser
    %ParticleFilterInputParser Class encapsulating input parsing for ParticleFilter
    
    %   Copyright 2015-2019 The MathWorks, Inc.
    
    %#codegen
    
    %% Input Parsing Methods
    methods
        function [tunableInputs,nontunableInputs] = parseInitializeInputs(obj, ...
                defaultStateOrientation, numParticles, varargin)
            %parseInitializeInputs Parse the inputs to the initialize function
            
            % Assign some default values
            % The structure has to be fully defined for code generation
            tunableInputs = struct;
            tunableInputs.UsesStateBounds = false;
            tunableInputs.NumStateVariables = 0;
            tunableInputs.StateBounds = zeros(1,2);
            tunableInputs.Mean = 0;
            tunableInputs.Covariance = 0;
            tunableInputs.IsStateVariableCircular = false;
            
            % Define some structure elements as variable-sized (for code
            % generation purposes)
            coder.varsize('tunableInputs.StateBounds', [Inf 2]);
            coder.varsize('tunableInputs.Mean', 'tunableInputs.IsStateVariableCircular', [1 Inf]);
            coder.varsize('tunableInputs.Covariance', [Inf Inf]);
            
            validateattributes(numParticles, {'numeric'}, {'scalar', 'integer', 'real', 'positive'}, 'initialize', 'numParticles');
            tunableInputs.NumParticles = double(numParticles);
            
            firstNVIndex = matlabshared.tracking.internal.findFirstNVPair(varargin{:});
            
            coder.internal.errorIf(firstNVIndex==1 || firstNVIndex>3, ...
                'shared_tracking:particle:InitializeInvalidInputs', firstNVIndex-1);            
            
            % Assign some default values
            switch firstNVIndex
                case 2
                    % Syntax: initialize(pf, numParticles, stateBounds, optionalNVPairs)
                    
                    tunableInputs.StateBounds = obj.validateStateBounds(varargin{1});
                    tunableInputs.NumStateVariables = size(tunableInputs.StateBounds, 1);
                    tunableInputs.UsesStateBounds = true;
                    
                case 3
                    % Syntax: initialize(pf, numParticles, initialMean, initialCovariance, optionalNVPairs)
                    
                    tunableInputs.Mean = obj.validateMean(varargin{1});
                    tunableInputs.NumStateVariables = length(tunableInputs.Mean);
                    tunableInputs.Covariance = obj.validateCovariance(varargin{2}, tunableInputs.NumStateVariables);
                    
                otherwise
                    assert(false);
            end
            
            % Parse the optional NVPairs: CircularVariables and StateOrientation
            if isempty(coder.target)  % Simulation
                [circularVariables, stateOrientation] ...
                    = obj.parseInputsSimulation(defaultStateOrientation, tunableInputs.NumStateVariables, varargin{firstNVIndex:end});
            else                      % Codegen
                [circularVariables, stateOrientation] ...
                    = obj.parseInputsCodegen(defaultStateOrientation, tunableInputs.NumStateVariables, varargin{firstNVIndex:end});
            end
            tunableInputs.IsStateVariableCircular = obj.validateNameValuePairCircularVariables(tunableInputs.NumStateVariables, circularVariables);
            % Non-tunable properties must reside in a separate struct
            nontunableInputs = struct('IsStateOrientationColumn',obj.validateNameValuePairStateOrientation(stateOrientation));
            
            % Ensure StateBounds and IsStateVariableCircular are consistent
            if tunableInputs.UsesStateBounds
                tunableInputs.StateBounds = obj.validateStateBoundsLimits(tunableInputs.StateBounds, tunableInputs.IsStateVariableCircular);
            end
        end
    end
    
    methods (Static, Access = {?matlabshared.tracking.internal.ParticleFilterInputParser, ?matlab.unittest.TestCase})
        function validStateBounds = validateStateBounds(stateBounds)
            %validateStateBounds Validate state bounds user input
            %   The state bounds should be defined as an N-by-2 array with
            %   N defining the number of state variables.
            
            validateattributes(stateBounds, {'numeric'}, {'nonempty','finite','nonnan','real','ncols',2}, 'initialize', 'stateBounds')
            validStateBounds = double(stateBounds);
        end
               
        function validMean = validateMean(initialMean)
            %validateMean Validate Gaussian mean user input
            %   The mean is a vector with N elements, with N defining the number
            %   of state variables.
            
            validateattributes(initialMean, {'numeric'}, {'nonempty','vector','finite','nonnan','real'}, 'initialize', 'initialMean')
            % Make sure that mean is always row vector
            validMean = double(initialMean(:)');
        end
        
        function validCovariance = validateCovariance(initialCovariance, numVars)
            %validateCovariance Validate covariance input
            %   The covariance could be given as a scalar (will be expanded
            %   to diagonal covariance matrix), as a vector with NUMVARS elements
            %   (will be use as diagonal in covariance matrix), or as a
            %   NUMVARS-by-NUMVARS full covariance matrix.
            
            validateattributes(initialCovariance, {'numeric'}, {'nonempty','finite','nonnan','real'}, ...
                'initialize', 'initialCovariance');
            
            covTest = double(initialCovariance);
            
            % Handle scalar case (expand to diagonal matrix)
            % All variances have to be non-negative
            if isscalar(covTest)
                validateattributes(covTest, {'double'}, {'nonnegative'}, 'initialize', 'initialCovariance');
                validCovariance = diag(repmat(covTest,numVars,1));
                return;
            end
            
            % Handle vector case (place on diagonal)
            % All variances have to be non-negative
            if isvector(covTest)
                validateattributes(covTest, {'double'}, {'nonnegative','numel',numVars}, 'initialize', 'initialCovariance');
                validCovariance = diag(covTest);
                return;
            end
            
            % Handle matrix case (evaluate as full covariance matrix)
            validateattributes(covTest, {'double'}, {'square', 'size', [numVars numVars]}, 'initialize', 'initialCovariance');
            
            % Validate covariance matrix. Validation already confirmed
            % that matrix is square. Also confirm that it is symmetric
            % and positive semi-definite.
            % numNegEigenValues will be NaN if the input is not symmetric
            % or not square
            % numNegEigenValues will be >0 if the matrix is not positive semi-definite
            [~,numNegEigValues] = matlabshared.tracking.internal.cholcov(covTest);
            
            if isnan(numNegEigValues)
                coder.internal.error('shared_tracking:particle:CovarianceNotSymmetric');
            end
            
            if numNegEigValues > 0
                coder.internal.error('shared_tracking:particle:CovarianceNotPositiveSemiDefinite', ...
                    sprintf('%g', numNegEigValues));
            end
            
            validCovariance = covTest;
        end
        
        function validCircVar = validateNameValuePairCircularVariables(numVars, value)
            %validateNameValuePair Validate circular variable name-value pair
            %   The value needs to be a vector with NUMVARS elements.
            
            validateattributes(value, {'logical','numeric'}, {'vector','numel',numVars,'finite','nonnan','real'}, 'initialize', 'CircularVariables');
            
            % Make sure that value is always row vector
            validCircVar = logical(value(:).');
        end
        
        function isStateOrientationColumn = validateNameValuePairStateOrientation(value)
            %validateNameValuePairStateOrientation Validate state orientation NV pair
            %   It must be 'row' or 'column'
            
            validatestring(value,{'row','column'},'initialize','StateOrientation');
            % extractBefore(value,2) instead of value(1): handles both char and string
            if lower(extractBefore(value,2))=='c'
                isStateOrientationColumn = true(); 
            else
                isStateOrientationColumn = false();
            end
        end
        
        function [circularVariables, stateOrientation] ...
                = parseInputsSimulation(defaultStateOrientation, numStates, varargin)
            % parseInputsCodegen Parse NV pairs for simulation
            
            % Instantiate an input parser
            parser = inputParser;
            
            % Optional parameters
            parser.addOptional('CircularVariables', false(1, numStates));
            parser.addOptional('StateOrientation', defaultStateOrientation);
            
            % Parse parameters
            parse(parser, varargin{:});
            r = parser.Results;
            
            circularVariables = r.CircularVariables;
            stateOrientation = r.StateOrientation;
        end
        
        function [circularVariables, stateOrientation] ...
                = parseInputsCodegen(defaultStateOrientation, numStates, varargin)
            % parseInputsCodegen Parse NV pairs for codegen
            
            coder.internal.prefer_const(varargin); % Required: g1381035
            
            parms = struct( ...
                'CircularVariables', uint32(0), ...
                'StateOrientation',  uint32(0));
            
            popt = struct( ...
                'CaseSensitivity', false, ...
                'StructExpand',    true, ...
                'PartialMatching', false);
            
            optarg           = eml_parse_parameter_inputs(parms, popt, ...
                varargin{:});
            circularVariables = eml_get_parameter_value(optarg.CircularVariables,...
                false(1,numStates), varargin{:});
            stateOrientation = eml_get_parameter_value(optarg.StateOrientation,...
                defaultStateOrientation, varargin{:});
        end        
    end
    
    %% Methods utilized by both command-line and Simulink blocks
    methods(Static, Hidden)
        function stateBounds = validateStateBoundsLimits(stateBounds, isCircVar)
            %validateStateBoundsLimits Validate limits of user-specified state bounds
            %   Ensure that for non-circular state variables, the lower limits
            %   are all less than or equal than the upper limits.
            %   Flip them automatically if the user specified them in the
            %   wrong order.
            
            nonCircularStateBounds = stateBounds(~isCircVar,:);
            
            invalidBounds = nonCircularStateBounds(:,1) > nonCircularStateBounds(:,2);
            
            if ~any(invalidBounds)
                %Return early if all bounds are valid
                return;
            end
            
            % Flip all invalid bounds, so they become valid.
            % This is probably a user error and we can automatically rectify it.
            nonCircularStateBounds(invalidBounds,:) = fliplr(nonCircularStateBounds(invalidBounds,:));
            stateBounds(~isCircVar,:) = nonCircularStateBounds;
        end 
    end
end
