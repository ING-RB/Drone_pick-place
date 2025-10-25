classdef boustrophedonOptions
%boustrophedonOptions Options for Boustrophedon decomposition algorithm

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    properties
        ReturnConnectivity  (1,1) double {mustBeMember(ReturnConnectivity,[0 1])} = true;
        ReconnectionMethod  (1,1) string {mustBeMember(ReconnectionMethod,{'none','nearest','all'})} = 'nearest';
        ConnectedCostFcn    (1,1) string {boustrophedonOptions.validateCostFcn(ConnectedCostFcn,'ConnectedCostFcn')}    = 'boustrophedonOptions.defaultConnectedCostFcn';
        DisconnectedCostFcn (1,1) string {boustrophedonOptions.validateCostFcn(DisconnectedCostFcn,'DisconnectedCostFcn')} = 'boustrophedonOptions.defaultDisconnectedCostFcn';
        UserData            (1,1) struct = struct;
    end
    methods
        function obj = boustrophedonOptions(nv)
            arguments
                nv.?boustrophedonOptions;
            end
            props = properties('boustrophedonOptions');
            for i = 1:numel(props)
                prop = props{i};
                if isfield(nv,prop)
                    obj.(prop) = nv.(prop);
                end
            end
        end
    end

    methods (Static)
        function cost = defaultDisconnectedCostFcn(polySet,i,J,userData)
            arguments
                polySet {mustBeA(polySet,{'polyshape','nav.decomp.internal.polyshapeMgr'})}
                i (1,1) {mustBeInteger,mustBePositive}
                J (:,1) {mustBeInteger,mustBePositive}
                userData (1,1) struct %#ok<INUSA>
            end
            c1 = [0 0];
            c2 = zeros(numel(J),2);
            [c1(1),c1(2)] = polySet(i).centroid;
            for i = 1:numel(J)
                [c2(i,1),c2(i,2)] = polySet(J(i)).centroid;
            end
            cost = vecnorm(c2-c1,2,2);
        end
        function cost = defaultConnectedCostFcn(polySet,i,J,userData) %#ok<INUSD>
            cost = zeros(numel(J),1);
        end
    end
    methods (Static, Hidden)
        function validateCostFcn(fcnString,costFcnType)
        %validateCostFcn Ensures the function name corresponds to a valid
        %function with correct number of inputs/outputs
            
            f = str2func(fcnString);
            if nargin(f) ~= 4
                eidType = 'BoustrophedonOptions:CostFcn:MustAccept4Inputs'; %#ok<*NASGU>
                msgType = costFcnType + " must accept the following four inputs:(polySet,i,J,userData). See boustrophedonOptions.defaultDisconnectedCostFcn for an example.";
                error(eidType,msgType);
            end
            if nargout(f) < 1
                eidType = 'BoustrophedonOptions:CostFcn:MustReturnAtLeast1Output';
                msgType = costFcnType + " must return at least one output, cost. See boustrophedonOptions.defaultDisconnectedCostFcn for an example.";
                error(eidType,msgType);
            end
        end
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'ReturnConnectivity','ReconnectionMethod','ConnectedCostFcn','DisconnectedCostFcn'};
        end
    end
end
