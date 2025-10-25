classdef(Hidden) FactorGaussianNoiseModel
%This class is for internal use only. It may be removed in the future.

%FACTORGAUSSIANNOISEMODEL Represent a general factor whose measurement noise
%   follows Gaussian distribution.

%   Copyright 2021-2024 The MathWorks, Inc.

%#codegen

    properties (SetAccess=protected)
        %NodeID Node ID number in factor graph
        %
        %   Must be specified at construction
        NodeID
    end

    properties (Dependent)
        %Measurement Measurement values for the factor
        Measurement
        
        %Information The information matrix associated with the measurement
        Information
    end

    properties (Access=protected)
        NumNodes

        MeasurementSize

        InformationSize

        DefaultMeasurement

        DefaultInformation
    end

    properties (Access=protected)
        MeasurementInternal

        InformationInternal
    end

    methods (Access=protected, Abstract)
        nodeTypeImpl(obj, id)
    end

    methods
        function obj = FactorGaussianNoiseModel(ids, numNodes, defaultMeasurement, defaultInformation, varargin )
            %FACTORGAUSSIANNOISEMODEL Constructor
            
            nav.algs.internal.validation.validateNodeID_FactorConstruction(ids, numNodes, class(obj), 'ids');
            numFactors = size(ids, 1);
            obj.MeasurementInternal = repmat(defaultMeasurement, numFactors, 1);
            obj.InformationInternal = defaultInformation;
            obj.MeasurementSize = size(obj.MeasurementInternal);
            obj.InformationSize = size(obj.InformationInternal);
            obj.NodeID = double(ids);
            obj = matlabshared.fusionutils.internal.setProperties( ...
                obj, nargin-4, varargin{:});
            
        end

        function obj = set.Measurement(obj, measurement)
            %set.Measurement Setter for Measurement property
            obj = obj.setMeasurement(measurement);
        end

        function obj = set.Information(obj, info)
            %set.Information Setter for Information property
            if(numel(size(info))==3)
                % Augment defaultInformation if info is a 3D array
                obj.InformationSize = [obj.InformationSize, size(obj.NodeID,1)];
            end
            obj.validateInformation(info);
            obj.InformationInternal = info;
        end

        function measurement = get.Measurement(obj)
            %get.Measurement Getter for Measurement property
            measurement = obj.MeasurementInternal;
        end

        function info = get.Information(obj)
            %set.Information Setter for Information property
            info = obj.InformationInternal;
        end

        function type = nodeType(obj, id)
            %nodeType Retrieve the node type for a specified node ID.
            %
            %   TYPE = NODETYPE(F,ID) returns the node type, TYPE, for the
            %   node with the number ID.

            narginchk(2,2);
            nav.algs.internal.validation.validateNodeID_FactorQuery(id, obj.NodeID, class(obj), 'id');
            type = obj.nodeTypeImpl(id);
        end
    end

    methods (Access=private)
        function validateMeasurement(obj, measurement)
            %validateMeasurement
            validateattributes(measurement, 'numeric', ...
                {'size', obj.MeasurementSize, 'real', 'finite', 'nonsparse'}, class(obj), 'measurement');
        end

        function validateInformation(obj, info)
            %validateInformation
            validateattributes(info, 'numeric', ...
                {'size', obj.InformationSize, 'real', 'finite', 'nonsparse'}, class(obj), 'information');
        end
    end

    methods (Access=protected)
        function obj = setMeasurement(obj, measurement)
            obj.validateMeasurement(measurement);
            obj.MeasurementInternal = double(measurement(:,1:size(obj.MeasurementInternal,2)));
        end
    end
end

