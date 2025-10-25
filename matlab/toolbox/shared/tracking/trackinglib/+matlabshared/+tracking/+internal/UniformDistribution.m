classdef UniformDistribution < matlabshared.tracking.internal.ProbabilityDistribution
    %UniformDistribution Multivariate uniform distribution
    %
    %   OBJ = matlabshared.tracking.internal.UniformDistribution(NUMVARS) will create a
    %   NUMVARS-variate uniform distribution. You can specify the lower and
    %   upper limits (open interval) for each random variable by modifying
    %   the RandomVariableLimits property of the returned OBJ.
    %
    %   Example:
    %      % Construct bi-variate uniform distribution
    %      u = matlabshared.tracking.internal.UniformDistribution(2);
    %
    %      % Set random variable bounds
    %      u.RandomVariableLimits = [-10 3; -2*pi 2*pi]
    %
    %      % Draw 20 random samples
    %      samples = u.sample(20)

    %   Copyright 2015-2019 The MathWorks, Inc.
    
    %#codegen
    
    properties (Dependent)
        %RandomVariableLimits - Lower and upper limits for each of the random variables
        %    Each row of this NumRandomVariables-by-2 array corresponds
        %    to the lower and upper limits of a single random variable. The
        %    limits define an open interval.
        %    If the underlying distribution is k-variate, the array has k
        %    rows.
        %
        %    Default: [zeros(NumRandomVariables, 1) ones(NumRandomVariables, 1)]
        RandomVariableLimits
    end
    
    properties (Access = private)
        %InternalRandomVariableLimits - Internal storage for random variable limits
        InternalRandomVariableLimits
    end
    
    methods
        function obj = UniformDistribution(numVars)
            %MultivariateUniformDistribution Construct a numVars-variate uniform distribution
            obj@matlabshared.tracking.internal.ProbabilityDistribution(numVars);
            
            obj.reset(numVars);
        end
        
        function samples = sample(obj, numSamples, orientation)
            %SAMPLE Draw random samples from the multivariate uniform distribution
            %   SAMPLES = SAMPLE(OBJ, NUMSAMPLES, ORIENTATION) draws
            %   NUMSAMPLES random samples from the underlying distribution.
            %   NUMSAMPLES has to be a scalar value. ORIENTATION is either
            %   'row' or 'column'. 
            %
            %   If ORIENTATION is 'row', the SAMPLES output has NUMSAMPLES
            %   rows and >= 1 columns. The number of columns is equal to
            %   the number of state variables of the distribution. For
            %   example, for a bivariate probability distribution, SAMPLES
            %   has 2 output columns. 
            %
            %   If ORIENTATION is 'column', the row and column
            %   dimensions of SAMPLES are swapped.
            
            if nargin<3
                orientation = 'row';
            else
                coder.internal.prefer_const(orientation);
                validatestring(orientation,{'row','column'},'sample','orientation');
            end
            
            assert(numSamples >= 1);
            
            % Calculate half limits, mean, and offset
            halfLimits = obj.RandomVariableLimits / 2;
            mu = halfLimits(:,1) + halfLimits(:,2);
            sig = halfLimits(:,2) - halfLimits(:,1);
            
            if strcmp(orientation,'row')
                % Each of the random variables is independently uniform
                % distributed, so I can draw all random samples at once.
                % Calling rand([numSamples, obj.NumRandomVariables]) yields
                % equivalent values to:
                %    for i = 1:obj.NumRandomVariables
                %        s(:,i) = rand([numSamples, 1]);
                %    end
                
                randData = rand([numSamples obj.NumRandomVariables]); % Row
                
                samples = matlabshared.tracking.internal.sampleUniformImpl(randData, mu', sig');
            else
                % Swap the order of the data, then scale to the sample space
                randData = rand([obj.NumRandomVariables numSamples]); % Col
                
                samples = matlabshared.tracking.internal.sampleUniformImpl(randData, mu, sig);
            end
        end
        
        function reset(obj, numVars)
            %reset Reset the distribution with a new number of random variables
            
            % Reset number of random variables. This will also take care of
            % input validation.
            obj.NumRandomVariables = numVars;
            
            % Re-initialize the variable limits
            obj.RandomVariableLimits = [zeros(obj.NumRandomVariables, 1) ...
                ones(obj.NumRandomVariables, 1)];
        end
        
        function cObj = copy(obj)
            %COPY Create a copy of the distribution object
            %   COBJ = COPY(OBJ) creates a deep copy of the
            %   UniformDistribution object OBJ and returns it in COBJ.
            %   OBJ has to be a scalar handle object.
            %
            %   COBJ is an independent handle object that has the same
            %   property values as OBJ.
            
            coder.internal.errorIf(~isscalar(obj), 'shared_tracking:particle:PolicyCopyNotScalar', ...
                'UniformDistribution');
            
            % Call copy in the base class
            cObj = copy@matlabshared.tracking.internal.ProbabilityDistribution(obj);
            
            % Assign data that has not be copied by the base class
            cObj.InternalRandomVariableLimits = obj.InternalRandomVariableLimits;
        end
    end
    
    methods
        function varLimits = get.RandomVariableLimits(obj)
            %get.RandomVariableLimits Getter for RandomVariableLimits property
            
            varLimits = obj.InternalRandomVariableLimits;
        end
        
        function set.RandomVariableLimits(obj, varLimits)
            %set.RandomVariableLimits Setter for RandomVariableLimits property
            
            validateattributes(varLimits, {'numeric'}, {'ncols', 2, 'nrows', obj.NumRandomVariables, ...
                'nonnan', 'finite', 'real'}, 'UniformDistribution', 'RandomVariableLimits');
            
            % Assert that lower limits are all <= to upper limits
            assert(all(varLimits(:,1) <= varLimits(:,2)));
            
            obj.InternalRandomVariableLimits = double(varLimits);
        end
    end
    
end

