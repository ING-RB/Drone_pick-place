classdef (Abstract) ProbabilityDistribution < handle
    %ProbabilityDistribution Base class defining the interface for probability distributions
    %
    %   OBJ = matlabshared.tracking.internal.ProbabilityDistribution(NUMVARS) will create a
    %   NUMVARS-variate probability distribution.

    %   Copyright 2015-2017 The MathWorks, Inc.
    
    %#codegen      
    
    properties (Dependent, SetAccess = protected)
        %NumRandomVariables - Number of random variables for this distribution
        %   For a univariate distribution, this property will be 1, for a
        %   bivariate 2, and so on.
        NumRandomVariables
    end       
    
    properties (Access = private)
        %InternalNumRandomVariables - Internal storage for number of random variables
        InternalNumRandomVariables
    end
    
    methods (Abstract)
        %SAMPLE Draw random samples from the distribution
        %   SAMPLES = SAMPLE(OBJ, NUMSAMPLES, ORIENTATION) draws NUMSAMPLES
        %   random samples from the underlying distribution. NUMSAMPLES has
        %   to be a scalar value.
        %
        %   If ORIENTATION is 'row', the SAMPLES output has NUMSAMPLES rows
        %   and >= 1 columns. The number of columns is equal to the number
        %   of state variables of the distribution. For example, for a
        %   bivariate probability distribution, SAMPLES has 2 output
        %   columns.
        %
        %   If ORIENTATION is 'column', the row and column
        %   dimensions of SAMPLES are swapped.
        samples = sample(obj, numSamples, orientation)
        
        %RESET Reset the distribution with a new number of random variables
        %   RESET(OBJ, NUMVARS) resets the underlying number of random
        %   variables to the value provided in NUMVARS. NUMVARS needs to be
        %   a scalar and >= 1.
        reset(obj, numVars)            
    end
        
    methods
        function obj = ProbabilityDistribution(numVars)
            %ProbabilityDistribution Construct a numVars-variate probability distribution
            
            obj.NumRandomVariables = numVars;
        end
        
        function numVars = get.NumRandomVariables(obj)
            %get.NumRandomVariables Custom getter for NumRandomVariables property
            
            numVars = obj.InternalNumRandomVariables;
        end
        
        function set.NumRandomVariables(obj, numVars)
            %set.NumRandomVariables Custom setter for NumRandomVariables property
            
            validateattributes(numVars, {'numeric'}, {'scalar', 'integer', '>=', 1}, ...
                'ProbabilityDistribution', 'numVars');
            
            obj.InternalNumRandomVariables = double(numVars);
        end
        
        function cObj = copy(obj)
            %COPY Create a copy of the distribution object
            %   COBJ = COPY(OBJ) creates a deep copy of the
            %   ProbabilityDistribution object OBJ and returns it in COBJ. 
            %   OBJ has to be a scalar handle object.
            %
            %   COBJ is an independent handle object that has the same
            %   property values as OBJ.
            
            coder.internal.errorIf(~isscalar(obj), 'shared_tracking:particle:PolicyCopyNotScalar', ...
                'ProbabilityDistribution');
            
            % Create a new object with the same properties
            % Use the object's runtime class to allow copying of derived
            % classes.
            fcnClassName = str2func(class(obj));
            cObj = fcnClassName(obj.NumRandomVariables);           
        end
    end    
end

