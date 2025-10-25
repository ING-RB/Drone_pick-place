classdef factorIMUBiasPrior  < nav.algs.internal.UnaryFactor
%FACTORIMUBIASPRIOR Prior factor for IMU bias
%   F = FACTORIMUBIASPRIOR(ID) returns a factorIMUBiasPrior object, F, with
%   the node identification number set to ID. ID is an N-by-1 array where
%   each row is one IMUBias node ID. N is the number of factors. The
%   measurement represents a a prior on IMU bias (in the format of
%   [bias_gyro, bias_accel]). By default, the prior value is set to
%   [0,0,0,0,0,0] and the corresponding information matrix is set to
%   eye(6).
%   
%   F = FACTORIMUBIASPRIOR(...,Name=Value) specifies properties using one
%   or more name-value arguments.
%
%   FACTORIMUBIASPRIOR properties:
%       NodeID            - ID of node to connect to in factor graph
%       Measurement       - Measured IMU biases in [bias_gyro,bias_accel]
%       Information       - Uncertainty of measurement
%
%   Example:
%       % Create an IMU bias prior factor connected to node 1 and add it 
%       % to a factor graph.
%       f = factorIMUBiasPrior(1);
%       g = factorGraph;
%       addFactor(g,f);
%       % Check the node type. The node that the IMU bias prior factor 
%       % connects to is type "IMU_BIAS".
%       nodeType(g,1);
%
%   See also factorGraph.

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen

    properties (Hidden, Constant)
        FactorType = "IMU_Bias_Prior_F";
    end
    
    methods
        function obj = factorIMUBiasPrior(id, varargin)
            %FACTORIMUBIASPRIOR Constructor;
            narginchk(1, Inf);
            obj@nav.algs.internal.UnaryFactor(id, 1, [0,0,0, 0,0,0], eye(6), varargin{:});
        end
    end

    methods (Access=protected)
        function type = nodeTypeImpl(~, ~)
            type = nav.internal.factorgraph.NodeTypes.IMUBias;
        end
    end
end

