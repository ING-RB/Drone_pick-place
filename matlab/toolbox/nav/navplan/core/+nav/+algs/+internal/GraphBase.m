classdef (Abstract) GraphBase < nav.algs.internal.InternalAccess
%GraphBase Create graph object specific for search-based planners
%based on planning environment
%
% GraphBase is an interface for all the search-based planner-specific graph
% data structures. GraphBase defines the planning environment in which the
% search will be performed, for example robot arm, an omnidirectional robot
% or a car-like robot etc.
%
% If you are creating your own graph object, you should derive from this
% class. The States property represents the nodes while the Links property
% represents the edges. Using this object allows you to find successors to
% queried state, calculate LinkWeight(cost of traversing the link) and
% index the states.
%
% GRAPHOBJ = nav.algs.internal.GraphBase(STATETABLE, LINKTABLE) creates a graph
% base object with the specified states STATETABLE and the links connecting
% the states LINKTABLE. The STATETABLE input sets the value of the States
% property while the LinkTable input sets the value of the Links property.
%
% This constructor can only be called from a derived class.
%
% GraphBase properties:
%   States          - State table of graph nodes
%   Links           - Link table of graph edges
%   LinkWeightFcn   - Link weight function
%
% GraphBase methods:
%   successors      - Find successor links for graph state index
%   state2index     - Find index for queried state vector
%   index2state     - Find state vector for queried index
%   copy            - Create deep copy of graph base object
%
% See also navGraph, plannerAStar

% Copyright 2022-2024 The MathWorks, Inc.
%#codegen

    properties
        States
        Links
        LinkWeightFcn = @nav.algs.distanceEuclidean;
    end

    properties(Access=private)
        % Flag to allow direct editing of graph internally during
        % construction or calls to addstate/addlink/rmstate/rmlink
        EditGraph
    end

    methods

        function obj = GraphBase(StateTable, LinkTable)
        %GraphBase Constructor for GraphBase object

            obj.States = StateTable;
            obj.Links = LinkTable;
        end

        % Setters and Getters for properties

        function set.States(obj,stateData)
        %set.States Validates and set States table

        % Validate the input for setting the States property
            obj.validateStates(stateData)

            % Validation for updating the values in the State table through
            % table indexing
            flag = obj.updateStatesValidation(stateData);

            % Set States property
            obj.States = stateData;

            % Post-processing after updating Links table
            obj.postGraphUpdate(flag);   
        end

        function set.Links(obj,linkData)
        %set.Links Validates and set Links table.

        % Validate the input for setting the Links property
            obj.validateLinks(linkData);

            % Validation for updating the values in the Links table through
            % table indexing
            flag = obj.updateLinksValidation(linkData);

            % Set Links property
            obj.Links = linkData;

            % Post-processing after updating Links table
            obj.postGraphUpdate(flag);            
        end

        function set.LinkWeightFcn(obj,fcnHandle)
        %set.LinkWeightFcn Validate and set function handle for link weight.
            obj.validateLinkWeightFcn(fcnHandle);
            obj.LinkWeightFcn = fcnHandle;
        end
    end

    methods (Abstract)

        [successorIDs,cost] = successors(obj,id);

        id = state2index(obj,state);

        state = index2state(obj, id);

        copyObj = copy(obj);
    end

    methods (Access = protected)
        function validateLinkWeightFcn(~,fcnHandle)
        % Validates function handle
            validateattributes(fcnHandle,'function_handle',{'nonempty','scalar'},...
                               'GraphBase','LinkWeightFcn')
        end

        function allowEditGraph(obj)
        %allowEditGraph Allow editing the graph
            obj.EditGraph = true;
        end

        function resetEditGraph(obj)
        %resetEditGraph Reset editing the graph
            obj.EditGraph = false;
        end
    end

    methods (Static, Access = protected)

        function validateStates(stateData)
        %Validates the State table
            validateattributes(stateData,'table',{'2d'},'GraphBase','States')
            % Check if the table contains StateVector column
            if isempty(stateData.Properties.VariableNames) || ...
                    ~strcmp('StateVector',stateData.Properties.VariableNames{1})
                coder.internal.error('nav:navalgs:graphbase:InvalidStateTable');
            end
            validateattributes(stateData.StateVector,'double',{'2d'},'GraphBase','StateVector')
        end

        function validateLinks(linkData)
        %Validates the Link table
            validateattributes(linkData,'table',{'2d'},'GraphBase','Links')
            % Check if the table contains EndStates column
            if isempty(linkData.Properties.VariableNames) ||...
                    ~strcmp('EndStates',linkData.Properties.VariableNames{1})
                coder.internal.error('nav:navalgs:graphbase:InvalidLinkTable');
            end
            validateattributes(linkData.EndStates,{'double','cell','string'},{'2d'},...
                               'GraphBase','EndStates')
        end
    end

    methods(Access=protected)

        function updateFlag = updateStatesValidation(obj, stateData)
        %updateStatesValidation Validation checks for updating the States
        %table data

            updateFlag = false;
            if ~coder.internal.is_defined(obj.States) || obj.EditGraph
                return
            end

            % Check if columns are matching
            if ~isequal(obj.States.Properties.VariableNames, stateData.Properties.VariableNames)
                coder.internal.error('nav:navalgs:navGraph:MismatchedColumns', 'States')
            end

            % Validate update operations
            if size(stateData, 1) ~= height(obj.States)
                coder.internal.error('nav:navalgs:navGraph:SetStates') %Set States not allowed
            end
            if coder.target('MATLAB') &&... % Name column is specified for MATLAB target
                    ismember('Name', obj.States.Properties.VariableNames) &&...
                    numel(unique(stateData.Name))~= height(obj.States.Name)
                coder.internal.error('nav:navalgs:navGraph:NameColumnDuplicates') %Duplicate state names are not allowed
            end

            updateFlag = true;
        end

        function updateFlag = updateLinksValidation(obj, linksData)
        %updateLinksValidation Validation checks for updating the Links
        %table data


            updateFlag = false;
            if ~coder.internal.is_defined(obj.Links) || obj.EditGraph
                return
            end

            % Check if columns are matching
            if ~isequal(obj.Links.Properties.VariableNames, linksData.Properties.VariableNames)
                coder.internal.error('nav:navalgs:navGraph:MismatchedColumns', 'Links')
            end

            % Check for direct edits to Links
            coder.internal.errorIf(size(linksData,1) ~= size(obj.Links,1), 'nav:navalgs:navGraph:SetLinks');

            % Check for edits to EndStates
            tf = any(obj.Links.EndStates ~= linksData.EndStates, 'all');
            coder.internal.errorIf(tf, 'nav:navalgs:navGraph:EditEndStates');

            updateFlag = true;

        end

        function postGraphUpdate(~,~)
        %postGraphUpdate Post processing steps after updating the
        %States or Links implemented by the inheriting classes
        end
    end
end
