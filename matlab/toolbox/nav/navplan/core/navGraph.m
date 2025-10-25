classdef navGraph < nav.algs.internal.GraphBase
%

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen


    properties (Access = protected)
        Graph
    end

    properties (Access = {?nav.algs.internal.InternalAccess})
        %Internal copies of data for performance

        % For look-up mode
        %SuccessorLookup Contains starting location and end location for
        % the sorted endstates of Links table for the given node.
        SuccessorLookup

        %LinkWeightLookup Stores endstates IDs and weight as matrix
        LinkWeightLookup

        % Flag for first run, useful for error out while 'SET' during
        % codegen
        isFirstRun=1;
    end

    methods

        function obj = navGraph(varargin)
        %

        % Validate number of arguments:
        % Maximum number of arguments includes states, links
        % and name-value pairs for weight, name, link cost function
            narginchk(0, 8);

            % Validator required constructor inputs
            [inputType, numMinInputs] = navGraph.validateConstructorInputs(...
                varargin{:});

            % Parse the name-value pair inputs to constructor
            [propsStruct, props] = navGraph.validateConstructorNVPairInputs(inputType,...
                                                                            varargin{numMinInputs+1:end});

            % Create the navGraph based on the user input
            [StatesTable, LinksTable] = navGraph.createNavGraph(inputType, ...
                                                                propsStruct, props, varargin{:});

            % Pre-validation
            navGraph.validateStates(StatesTable);
            navGraph.validateLinks(LinksTable);

            %Validating that links must not contain incorrect state i.e.
            %non-existent states
            if(isnumeric(LinksTable.EndStates))
                if(any(LinksTable.EndStates>height(StatesTable),'all'))
                    coder.internal.error('nav:navalgs:navGraph:StatesInLinkNotFound',height(StatesTable))
                end
            end

            % Make sure all elements in the cell array are string scalars or character arrays
            if iscell(LinksTable.EndStates)
                LinksTable.EndStates = cellstr(LinksTable.EndStates);
            end

            % Removing duplicates from states and links
            [StatesTable,LinksTable] = navGraph.removeDuplicates(StatesTable,LinksTable);

            % Setting base object
            obj@nav.algs.internal.GraphBase(StatesTable, LinksTable);

            % Allow graph editing
            obj.allowEditGraph();

            % Sort links according to state IDs or names
            obj.sortLinks();

            % Create digraph object which is used for various operations
            % like finding a state, or link etc.
            obj.Graph = navGraph.createDigraph(obj.States, obj.Links);

            % Set public properties with default or user-specified values
            obj.LinkWeightFcn = propsStruct.LinkWeightFcn;

            obj.isFirstRun =0;
            obj.resetEditGraph();
        end

        function [sucIDs,costs] = successors(obj,currID)

            validateattributes(currID,{'numeric','string',...
                                       'char'},{'nonempty'},'navGraph',...
                               'successors')

            % Converting name input to numeric.
            if isnumeric(currID)
                currIndex = currID;
                validateattributes(currIndex,{'numeric'},{'scalar',...
                                                          'finite','positive','integer','<=',...
                                                          height(obj.States.StateVector)},'navGraph',...
                                   'successor index')
            elseif ischar(currID) || isstring(currID)
                if(isstring(currID))
                    validateattributes(currID,{'string'},{'scalar'},...
                                       'navGraph','successors');
                end
                currIndex = obj.findstate(currID);
            else
                validateattributes(currID,{'cellstr'},{'scalar','nonempty'},...
                                   'navGraph', 'successors')
            end

            % Finds the successors
            if(currIndex~=0)
                sucIDs = successors(obj.Graph,currIndex);
            else
                sucIDs = [];
            end
            costs = [];

            % Computing Cost
            if(~isempty(sucIDs))
                costs =obj.getLinkCost(currIndex,sucIDs);
            end
        end

        function ID = findstate(obj,stateData)

            validateattributes(stateData,{'numeric','string','char',...
                                          'cell','table'},{'nonempty'},'navGraph',...
                               'findstate');

            ID = [];
            if isnumeric(stateData)
                % For state as state vector with same number of columns as
                % navGraph's state vector.
                validateattributes(stateData,{'numeric'},{'finite',...
                                                          'ncols',width(obj.States.StateVector)},...
                                   'navGraph','findstate state')
                ID = zeros(height(stateData),1);
                for i = 1:height(stateData)
                    % Finding the closest nodes based on Euclidean distance.
                    [idx,minDist] = closestStateID(obj,stateData(i,:));
                    % If both states coincides, we will return that id, else 0.
                    if(minDist<=eps)
                        ID(i) = idx;
                    end
                end

            elseif ischar(stateData)|| isstring(stateData)
                % Finding states given as names.
                if isstring(stateData)
                    if(stateData=="")
                        coder.internal.error('nav:navalgs:navGraph:InvalidFindStateInput')
                    end
                end
                nameData = cellstr(stateData);
                idx = findnode(obj.Graph, nameData);
                ID = [ID idx];
            elseif iscellstr(stateData)
                idx = findnode(obj.Graph,stateData);
                ID = [ID idx];
            elseif istable(stateData)
                % Finding states, when state are given as table rows.
                navGraph.validateStates(stateData);
                validateattributes(stateData.StateVector,{'numeric'},...
                                   {'finite','ncols',size(obj.States.StateVector,2)},...
                                   'navGraph','stateData')
                ID = findStateFromTable(obj,stateData);
            else
                coder.internal.error('nav:navalgs:navGraph:InvalidFindStateInput');
            end
        end

        function [id, status] = addstate(obj,varargin)

            numColStates = size(obj.States.Properties.VariableNames,2)+1;

            % Verifying if proper number of columns are input.
            if(nargin~=numColStates)
                coder.internal.error('nav:navalgs:navGraph:IncorrectNumOfInputColumn',...
                                     'States', 'state', width(obj.States.Properties.VariableNames));
            end

            % Verifying that all columns are of same type of already added
            % States
            numInRows = height(varargin{1});
            nameCol = find(strcmp('Name', obj.States.Properties.VariableNames));
            for i =1:numColStates-1

                if ~isempty(nameCol) && i==nameCol
                    classVar = {'cell', 'string'};
                else
                    classVar = {class(obj.States{:,i})};
                end

                numCol = width(obj.States{:,i});
                validateattributes(varargin{i},classVar,...
                                   {'nonempty','nrows',numInRows,'ncols',numCol},...
                                   'navGraph',obj.States.Properties.VariableNames{i});

                if ~isempty(nameCol) && i==nameCol && iscell(varargin{i})
                    varargin{i} = cellstr(varargin{i}); % Make sure all elements in the cell array are string scalars or character arrays
                end
            end

            stateData = table(varargin{:},'VariableNames',obj.States.Properties.VariableNames);
            validateattributes(stateData.StateVector,{'numeric'},...
                               {'nonempty','finite'},'navGraph','addstate');

            % Remove duplicate state vectors from input stateData
            [~, occurIdx] = navGraph.getUniqueStateIDs(stateData.StateVector);
            stateData = stateData(occurIdx,:);
            
            % Status information for each state (1:added, 0:not added)
            if nargout > 1
                status = true(numInRows, 1);
                status(setdiff(1:numInRows,occurIdx)) = false;
            end

            if ~isempty(stateData) && ~isempty(obj.States)
                % Remove duplicate states that exist in current navGraph
                % object

                % Find states corresponding to unique StateVector values
                stateFound = obj.findstate(stateData.StateVector) == 0;
                stateData = stateData(stateFound,:);
                
                if nargout>1
                    % Updates status: stateFound=1 => status=1, stateFound=0 => status=0
                    status(status) = stateFound;
                end

                if ~isempty(stateData) && any(strcmp(obj.States.Properties.VariableNames,'Name'))
                    % Keep states corresponding to unique state Name values
                    stateFound = obj.findstate(stateData.Name) == 0;
                    stateData = stateData(stateFound, :);

                    if nargout>1
                        % Updates status: stateFound=1 => status=1, stateFound=0 => status=0
                        status(status) = stateFound;
                    end
                end
            end

            prevNumStates=height(obj.States);

            % Updating internal graph.
            obj.Graph = obj.Graph.addnode(stateData);

            if(coder.target('MATLAB'))
                if(any(strcmp(obj.States.Properties.VariableNames,'Name')))
                    isstr = isstring(obj.States.Name);
                else
                    isstr = false;
                end
            end

            obj.allowEditGraph();
            obj.States = obj.Graph.Nodes;
            obj.resetEditGraph();
            if(coder.target('MATLAB'))
                if(isstr)
                    obj.States.Name = string(obj.States.Name);
                end
            end
            id = (prevNumStates+1:height(obj.States.StateVector))';
        end

        function rmstate(obj,state)

            if (isnumeric(state))
                validateattributes(state, {'numeric'},{'column','nonempty','positive','finite','integer'},'navGraph','rmstate');
            else
                validateattributes(state, {'cell','char','string'},{'nonempty'},'navGraph','state');
                state = cellstr(state);
                validateattributes(state, {'cell'},{'column'},'navGraph','state');
            end
            if(iscellstr(state)||ischar(state)||isstring(state)||iscell(state))
                nodeID = obj.findstate(state);
            else
                nodeID = state;
                nodeID = nodeID(nodeID<=height(obj.States.StateVector));
            end
            nodeID = nodeID(nodeID~=0);
            obj.Graph = rmnode(obj.Graph,nodeID);

            if(coder.target('MATLAB'))
                if(any(strcmp(obj.States.Properties.VariableNames,'Name')))
                    isstr = isstring(obj.States.Name);
                else
                    isstr = false;
                end
            end

            obj.allowEditGraph();
            obj.States = obj.Graph.Nodes;
            if(coder.target('MATLAB'))
                if(isstr)
                    obj.States.Name = string(obj.States.Name);
                end
            end
            obj.resetEditGraph();

            linkT = navGraph.updateLinkTableColumn(obj.Graph.Edges,'EndStates');
            % Renaming edges to indices
            if(isnumeric(obj.Links.EndStates) && ~isnumeric(linkT.EndStates))
                linkT.EndStates = navGraph.edgeNamesToIndices(...
                    obj.States.Name, obj.Graph.Edges.EndNodes);
            end
            % Convert to string array if source data is a string array
            % (note that digraph stores the names as cellstr)
            if isstring(obj.Links.EndStates)
                linkT.EndStates = string(linkT.EndStates);
            end
            obj.allowEditGraph()
            obj.Links = linkT;
            obj.resetEditGraph();
        end

        function ID = findlink(obj,statePair)

            validateattributes(statePair,{'numeric','cell','string','char'},...
                               {'ncols',2},'navGraph','findlink');
            if ischar(statePair) ||isstring(statePair)
                state1ID = obj.findstate(statePair(:,1));
                state2ID = obj.findstate(statePair(:,2));
            elseif iscellstr(statePair)
                stateTo = statePair(:,1);
                stateFro = statePair(:,2);
                state1ID = obj.findstate(stateTo);
                state2ID = obj.findstate(stateFro);
            else
                validateattributes(statePair,{'numeric'},{'finite',...
                                                          'nonempty','integer'},'navGraph','findlink')
                state1ID = statePair(:,1);
                state2ID = statePair(:,2);
            end
            ID = findedge(obj.Graph,state1ID,state2ID);
        end

        function [id, status] = addlink(obj,varargin)

            numColLinks = size(obj.Links.Properties.VariableNames,2)+1;

            % Verifying if proper number of columns are input.
            if(nargin~=numColLinks)
                coder.internal.error('nav:navalgs:navGraph:IncorrectNumOfInputColumn',...
                                     'Links', 'link', width(obj.Links.Properties.VariableNames));
            end

            % Verifying if states are present in navGraph
            if(isempty(obj.States))
                coder.internal.error('nav:navalgs:navGraph:StatesNotPresent');
            end

            % Verifying that all columns are of same type of already added
            % States
            numInRows = height(varargin{1});

            % Validate remaining columns
            for i =1:numColLinks-1
                if i==1 %First column is EndStates and can be
                    classVar = {'numeric', 'string', 'cell'};
                else
                    classVar = {class(obj.Links{:,i})};
                end
                validateattributes(varargin{i},classVar,...
                                   {'nonempty','nrows',numInRows},...
                                   'navGraph',obj.Links.Properties.VariableNames{i});
                if i==1 && iscell(varargin{i}) % EndStates column is a cell array
                    varargin{i} = cellstr(varargin{i}); % Make sure all elements in the cell array are string scalars or character arrays
                end
            end

            % Create link data table to added to navGraph
            linkData = table(varargin{:},'VariableNames',obj.Links.Properties.VariableNames);

            % Validate links in more detail (like number of columns)
            obj.validateLinks(linkData);

            % Update EndStates format of input links if they are different
            % from original format defined during navGraph construction
            if isnumeric(obj.Links.EndStates) && ~isnumeric(linkData.EndStates)
                linkData.EndStates = obj.edgeNamesToIndices(obj.States.Name, linkData.EndStates);
            elseif ~isnumeric(obj.Links.EndStates) && isnumeric(linkData.EndStates)
                names = obj.States.Name';
                linkData.EndStates = names(linkData.EndStates);
            end
            if iscellstr(obj.Links.EndStates) && isstring(linkData.EndStates)
                linkData.EndStates = cellstr(linkData.EndStates);
            elseif isstring(obj.Links.EndStates) && iscellstr(linkData.EndStates)
                linkData.EndStates = string(linkData.EndStates);
            end

            % Fetching state names.
            stateNames = "";
            if(iscellstr(linkData.EndStates)||isstring(linkData.EndStates))
                stateNames = obj.States.Name;
            end

            % Remove duplicates and self loop links
            [linkData, occurIdx] = navGraph.omitSelfLoopAndDuplicateLinks(...
                    linkData, stateNames);

            % Status information for each link (1:added, 0:not added)
            if nargout>1
                status = true(numInRows,1);
                status(setdiff(1:numInRows, occurIdx)) = false;
            end            

            if ~isempty(linkData) && ~isempty(obj.Links)
                % Remove duplicate link that exist in current navGraph
                % object                
                linkFound = obj.findlink(linkData.EndStates)==0;
                linkData = linkData(linkFound, :);                
                if nargout>1
                    % Updates status: linkFound=1 => status=1, linkFound=0 => status=0
                    status(status) = linkFound;
                end
            end

            % Adding the links            
            if(~isempty(linkData))
                prevNumLinks=height(obj.Links);
                links = [obj.Links; linkData];
                id = (prevNumLinks+1:height(links.EndStates))';
            else
                links = obj.Links;
                id = zeros(0,1);
            end
            obj.allowEditGraph()
            obj.Links = links;
            sortedIndex = obj.sortLinks();
            obj.resetEditGraph()

            % Updated output id based on sorted indices
            id = find(ismember(sortedIndex, id));

            % Updating internal graph.
            obj.Graph = navGraph.createDigraph(obj.States, obj.Links);
        end

        function rmlink(obj,link)

            validateattributes(link, {'numeric','cell','char','string'},{'nonempty'},'navGraph','rmlink');
            if(iscellstr(link)||ischar(link)||isstring(link)||size(link,2)==2)
                if(isnumeric(link))
                    %When Link IDs are given
                    validateattributes(link, {'numeric'},{'positive','finite'},'navGraph','rmlink');
                    numStates = height(obj.States);
                    link = link(all(link<=numStates,2),:);
                end
                if(~isempty(link))
                    linkID = obj.findlink(link);
                else
                    linkID = [];
                end
            else
                %When state pairs are given.
                validateattributes(link, {'numeric'},{'positive','finite'},'navGraph','rmlink');
                numLinks = height(obj.Links);
                linkID = link(link<=numLinks);
            end
            linkID = linkID(linkID~=0);

            % Removing links from graph.
            obj.Graph = rmedge(obj.Graph,linkID);

            linkT = navGraph.updateLinkTableColumn(obj.Graph.Edges,'EndStates');
            % Renaming edges to indices
            if(isnumeric(obj.Links.EndStates) && ~isnumeric(linkT.EndStates))
                linkT.EndStates = navGraph.edgeNamesToIndices(...
                    obj.States.Name, obj.Graph.Edges.EndNodes);
            end
            % Convert to string array if source data is a string array as
            % digraph stores this to cell array
            if isstring(obj.Links.EndStates)
                linkT.EndStates = string(linkT.EndStates);
            end
            obj.allowEditGraph();
            obj.Links = linkT;
            obj.resetEditGraph();
        end

        function statevector = index2state(obj,stateID)
            validateattributes(stateID,{'numeric'},{'nonempty',...
                                                    'finite','integer','positive'},'navGraph','state2index');
            stateID = stateID(stateID<=height(obj.States.StateVector));
            statevector = obj.States.StateVector(stateID,:);
        end

        function stateID = state2index(obj,state)
            validateattributes(state,{'numeric'},{'nonempty',...
                                                  'finite','ncols',size(obj.States.StateVector,2)},...
                               'navGraph','state2index');
            stateID = obj.findstate(state);
        end

        function grPlot = show(obj, varargin)
        %

        % If called in code generation, throw incompatibility error
            coder.internal.errorIf(~coder.target('MATLAB'),...
                                   'nav:navalgs:prm:GraphicsSupportCodegen', 'show')
            narginchk(1,3);
            if(nargin==1)
                ax = gca;
            else
                % Get default properties
                propsDefault = struct('Parent',gca);

                % Parse name-value pair inputs and return struct containing
                % properties
                props = coder.internal.parseParameterInputs(propsDefault, struct(), varargin{:});
                propsStruct = coder.internal.vararginToStruct(props, propsDefault, varargin{:});
                ax = propsStruct.Parent;
            end
            graphPlotObj = plot(ax,obj.Graph);

            % Returning graphplot handle
            if nargout > 0
                grPlot = graphPlotObj;
            end
        end

        function newObj = copy(obj)
            newObj = navGraph(obj.States,obj.Links,'LinkWeightFcn',obj.LinkWeightFcn);
        end
    end

    methods(Hidden)

        function [IDs, minDist] = closestStateID(obj,state,varargin)
        %closestStateID Returns the closest state ID in States using
        % Euclidean distance, If parameter 'all' is present then all
        % equidistant states will be return, otherwise only the first one
        % will be returned. minDist is the minimum distance of the closest
        % states.
        %
        %   Example:
        %       % Load example navGraph object.
        %       load navGraphData.mat;
        %
        %       % Finding the ID of closest state to given state
        %       [IDs, minDist] = closestStateID(navGraphObj,[8 7 0]);
        %
        %   See also navGraph

            narginchk(0,3);
            validateattributes(state,{'numeric'},{'nonempty',...
                                                  'finite','nrows',1,'ncols',size(obj.States.StateVector,2)},...
                               'navGraph','closestStateID');
            % Finding distance from all states based on Euclidean distance.
            dist = obj.distanceFromAllStates(state);
            % Finds the closest state index.
            [minDist,IDs] = min(dist);
            if(nargin==3)
                validatestring(varargin{1},{'all'}, 'navGraph');
                IDs = find(dist == min(dist))';
            end
        end

        function dist = distanceFromAllStates(obj,state)
        %distanceFromAllStates Finds the distance of given state, from all
        %the states present in navGraph.
        %
        %   Example:
        %       % Load example navGraph object.
        %       load navGraphData.mat;
        %
        %       % Finding the distance of all states from given state
        %       [dist] = distanceFromAllStates(navGraphObj,[8 7 0]);
        %
        %   See also navGraph
            dist = [];
            validateattributes(state,{'numeric'},{'nonempty',...
                                                  'finite','nrows',1,'ncols',size(obj.States.StateVector,2)},...
                               'navGraph','distanceFromAllNodes');
            if(~isempty(obj.States.StateVector))
                % Euclidean distance
                dist = nav.algs.distanceEuclidean(obj.States.StateVector,state);
            end
        end
    end

    methods (Access = {?nav.algs.internal.InternalAccess})
        function generateLookup(obj)
        %generateLookup Specialized function for navGraph to pre-compute
        %link weights, considering the Cost function to be vectorized
        %and edges to be sorted.

        % Fetching links in numeric way
            edges = obj.Links.EndStates;

            if iscell(edges) || isstring(edges)
                %To find and hence convert string array to integers for
                %edges
                %edges = [obj.findstate(edges(:,1)), obj.findstate(edges(:,2))];
                % Remove the following lines after findstate in above line
                % is implemented
                edges = navGraph.edgeNamesToIndices(obj.States.Name, obj.Links.EndStates);
            end

            % Creates Successor Lookup for start and end indices for each
            % link.
            [counts, values] = groupcounts(edges(:,1));
            ind = [1; 1+cumsum(counts)];
            numNodes = height(obj.States.StateVector);
            obj.SuccessorLookup = zeros(numNodes, 2);
            obj.SuccessorLookup(values,:) = [ind(1:end-1), ind(2:end)-1];

            % Populate link data with link in integer and link weight.
            if any(strcmp(obj.Links.Properties.VariableNames, 'Weight'))
                Weight = obj.Links.Weight;
            else
                if nargin(obj.LinkWeightFcn)==2 ||...
                        any(strcmp(func2str(obj.LinkWeightFcn), navGraph.getStandardCostFcns()))
                    % @(state1, state2) costFunction(state1, state2,..)
                    states1 = obj.index2state(edges(:,1));
                    states2 = obj.index2state(edges(:,2));
                    Weight = obj.LinkWeightFcn(states1,states2);
                elseif nargin(obj.LinkWeightFcn)==3
                    % @(index1, index2, navGraphObj) costFunction(index1, index2, navGraphObj,..)
                    Weight = obj.LinkWeightFcn(edges(:,1), edges(:,2), obj);
                end
            end
            obj.LinkWeightLookup = [edges,Weight];
        end

        function resetLookup(obj)
        %resetLookup The lookup data needs to be recomputed
            obj.SuccessorLookup = zeros(0, 2);
            obj.LinkWeightLookup = zeros(0, 3);
        end

        function ind = sortLinks(obj)
        % Sort links according to state IDs
            if isnumeric(obj.Links.EndStates)
                [obj.Links, ind] = sortrows(obj.Links, 'EndStates');
            elseif iscellstr(obj.Links.EndStates) || isstring(obj.Links.EndStates)
                edgeIndices = navGraph.edgeNamesToIndices(obj.States.Name, ...
                                                          obj.Links.EndStates);
                [~, ind] = sortrows(edgeIndices,[1,2]);
                obj.Links = obj.Links(ind,:);
            end
        end

        function cost = getLinkCost(obj,currIndex,targetIDs)
        %getLinkCost Get the link cost from the cost function or the
        %link table

            if(height(currIndex)==1)
                currIDs = repmat(currIndex,size(targetIDs));
            elseif (height(currIndex)==height(targetIDs))
                currIDs = currIndex;
            end

            if(~strcmp(obj.Links.Properties.VariableNames,'Weight'))
                cost = obj.getLinkFcn(currIDs,targetIDs);
            else
                cost = obj.getLinkWeightFromTable(currIDs,targetIDs);
            end
        end

        function cost = getLinkWeightFromTable(obj,id1,id2)
        %getLinkWeightFromTable Fetches link weight using the weight column
        %present in Links Table.

            lID = obj.findlink([id1,id2]);
            cost = obj.Links.Weight(lID);
        end

        function cost = getLinkFcn(obj,id1,id2)
        %getLinkFcn Computes cost using the given LinkWeightFcn.
            if(nargin(obj.LinkWeightFcn)==2 ||...
               any(strcmp(func2str(obj.LinkWeightFcn), navGraph.getStandardCostFcns())))
                % If LinkWeight function takes input of states.
                states1 = obj.index2state(id1);
                states2 = obj.index2state(id2);
                cost = obj.LinkWeightFcn(states1,states2);
            else
                % If LinkWeight function takes input of states indices.
                if coder.target('MATLAB')
                    cost = obj.LinkWeightFcn(id1,id2,obj);
                else
                    coder.internal.error('nav:navalgs:navGraph:CodegenNotSupported');
                end
            end
        end

        function ID = findStateFromTable(obj,stateData)
        %findStateFromTable Finds if the given stateData table rows are
        %present in navGraph.

            ID = zeros(height(stateData),1);
            for i = 1:height(stateData)
                % Finding the state based on distance using state vector.
                [idx,minDist] = closestStateID(obj,stateData.StateVector(i,:),'all');
                if(max(minDist)<=eps)
                    % Validate if state is already present by comparing
                    % rest of the data in table
                    [stateFound,idFound] = intersect(obj.States(idx,2:end),stateData(i,2:end));
                    if(~isempty(stateFound))
                        % If i'th row stateData is present, return its ID.
                        ID(i) = idx(idFound(1));
                    end
                end
            end
        end
    end

    methods (Hidden, Access = protected)
        function validateLinkWeightFcn(obj,linkWeightFcn)
        %validateLinkWeightFcn For adding additional verification if required
        %while assigning LinkWeightFcn as per navGraph requirement.
            verifyCodegenCompatibility(obj,'linkWeightFcn');
            validateLinkWeightFcn@nav.algs.internal.GraphBase(obj,linkWeightFcn);

            % Validate number of input and output arguments
            nargIn = nargin(linkWeightFcn);
            nargOut = nargout(linkWeightFcn);
            % abs takes care of negative nargin when the function has
            % varargin or varargout
            coder.internal.errorIf((nargIn>=0 && nargIn<2) || ...  % without varargin
                                   (nargIn<0 && nargIn>-3 ) ... % with varargin
                                   , 'nav:navalgs:navGraph:InvalidLinkWeightFcn')
            coder.internal.errorIf(abs(nargOut)<1, 'nav:navalgs:navGraph:InvalidLinkWeightFcn')

            %Reset look-up mode properties
            obj.SuccessorLookup = zeros(0, 2);
            obj.LinkWeightLookup = zeros(0,width(obj.Links.EndStates)+1);
        end
        function verifyCodegenCompatibility(obj,arg)
        % If called in code generation, throw incompatibility error
            coder.internal.errorIf(~coder.target('MATLAB')&&obj.isFirstRun==0,'nav:navalgs:plannerastargrid:PropertySetInCodeGeneration', arg)
        end

        function postGraphUpdate(obj, flag)
        %postGraphUpdate Post processing steps after updating the
        %States or Links

        % Call the superclass's method
            postGraphUpdate@nav.algs.internal.GraphBase(obj, flag)

            % Regenerate digraph object if existing States or Links are updated through
            % assignment operations. E.g., navGraphObj.Links.Weight(10) = 100;
            if flag
                obj.Graph = navGraph.createDigraph(obj.States, obj.Links);
            end

            % Reset lookup data
            obj.resetLookup();
        end
    end

    methods(Hidden, Static, Access = protected)

        function [inputType, numMinInputs] = validateConstructorInputs(varargin)
        % validateConstructorInputs Validate the constructor inputs
        % depending upon the input type. For example, if the first input
        % is a state table, then there must be minimum two inputs, with
        % the second input being the link table

        % Validate first input type if specified
            if nargin >= 1
                validateattributes(varargin{1}, {'numeric', 'table', 'digraph'}, ...
                                   {}, 'navGraph', 'first input')
            end

            if nargin == 0
                % Constructor signature:  navGraph()
                numMinInputs = 0;
                inputType = 'none';
            elseif isa(varargin{1}, 'numeric')
                % Constructor signature: navGraph(states, links, Name=Value)
                inputType = 'numeric';
                numMinInputs = 2;
                narginchk(numMinInputs, inf)
                validateattributes(varargin{1}, {'numeric'}, {'finite'},...
                                   'navGraph', 'first input')
                if isnumeric(varargin{2})
                    validateattributes(varargin{2}, {'numeric'}, {'finite'},...
                                       'navGraph', 'second input')
                else
                    validateattributes(varargin{2}, {'cell','string'}, {},...
                                       'navGraph', 'second input')
                end

            elseif isa(varargin{1}, 'table')
                % Constructor signature: navGraph(StateTable, LinkTable, Name=Value)
                inputType = 'table';
                numMinInputs = 2;
                narginchk(numMinInputs, inf)
                validateattributes(varargin{2}, {'table'}, {},...
                                   'navGraph', 'second input')
            elseif isa(varargin{1}, 'digraph')
                % Constructor signature: navGraph(digraphObj, Name=Value)
                inputType = 'digraph';
                numMinInputs = 1;
                narginchk(numMinInputs, inf)
            end
        end

        function validateStates(stateData)
        %validateStates For adding additional verification if required
        %while assigning States Table as per navGraph requirement.

            validateStates@nav.algs.internal.GraphBase(stateData);
            validateattributes(stateData.StateVector, {'numeric'}, ...
                               {'finite'}, 'navGraph', 'States')
            coder.internal.errorIf(width(stateData.StateVector)<2, 'nav:navalgs:navGraph:InvalidStateInput');
        end

        function validateLinks(linkData)
        %validateLinks For adding additional verification if required
        %while assigning Links Table as per navGraph requirement.

            validateLinks@nav.algs.internal.GraphBase(linkData);
            validateattributes(linkData.EndStates,{'numeric','cell','char',...
                                                   'string'},{'ncols',2}, 'navGraph','Links')
            if(isnumeric(linkData.EndStates))
                validateattributes(linkData.EndStates,{'numeric'},{'finite',...
                                                                   'integer'},'navGraph','Links')

            end
        end

        function [propsStruct, props] = validateConstructorNVPairInputs(inputType, varargin)
        % validateConstructorNVPairInputs Validate name-value pair inputs
        % to the constructor

        % Get default properties
            propsDefault = navGraph.propertyDefaults;

            % Parse name-value pair inputs and return struct containing
            % properties
            props = coder.internal.parseParameterInputs(propsDefault, struct(), varargin{:});
            propsStruct = coder.internal.vararginToStruct(props, propsDefault, varargin{:});

            % If the first input type is table or digraph, then it is not
            % allowed to specify Name, Weight name-value pairs
            if strcmp(inputType, 'table') || strcmp(inputType, 'digraph')
                coder.internal.errorIf(~isempty(propsStruct.Name),...
                                       'nav:navalgs:navGraph:InvalidNameValuePairs', ...
                                       inputType)
                coder.internal.errorIf(~isempty(propsStruct.Weight),...
                                       'nav:navalgs:navGraph:InvalidNameValuePairs',...
                                       inputType)
            end
        end

        function defaults = propertyDefaults()
        % propertyDefaults Define the default values for the
        % public properties
            defaults = struct(...
                'LinkWeightFcn', @nav.algs.distanceEuclidean, ...
                'Weight', [],...
                'Name', {''});
        end

        function [stateTable,linkTable] = createNavGraph(inputType, propsStruct, props, varargin)
        %createNavGraph Convert constructor inputs into graph

        %Props stores whether property is default (~=0) or non-default (~=0)
            nameColumnDisabled = props.Name==0;
            weightColumnDisabled = props.Weight==0;

            switch inputType

              case 'none'
                % Create empty state and link when there are no inputs
                coder.varsize('statesEmpty', [Inf, 3]);
                coder.varsize('linksEmpty', [Inf, 2]);
                statesEmpty = zeros(0, 3);
                linksEmpty = zeros(0, 2);
                stateTable = table(statesEmpty, VariableNames={'StateVector'});
                linkTable = table(linksEmpty, VariableNames={'EndStates'});

              case 'numeric'
                % Create state and link tables from matrix inputs
                states = varargin{1};
                links = varargin{2};

                if nameColumnDisabled && (iscellstr(links) || isstring(links)) && width(links)==2
                    coder.internal.error('nav:navalgs:navGraph:MissingNameColumn')
                end

                % Create State table
                if nameColumnDisabled
                    stateTable = table(states, VariableNames={'StateVector'});
                else
                    validateattributes(propsStruct.Name, {'cell', 'string'},...
                                       {'ncols',1}, 'navGraph', 'Name')
                    name = convertStringsToChars(propsStruct.Name);
                    coder.internal.errorIf(height(states) ~= length(name), ...
                                           'nav:navalgs:navGraph:InvalidNameInput')
                    for ind=1:length(name)

                        validateattributes(name{ind}, {'char'}, {'nonempty'},...
                                           'navGraph', 'Name', ind)
                    end
                    stateTable = table(states, propsStruct.Name,...
                                       VariableNames={'StateVector', 'Name'});
                end

                % Create Link table
                if weightColumnDisabled
                    linkTable = table(links, VariableNames={'EndStates'});
                else
                    validateattributes(propsStruct.Weight, {'numeric'},...
                                       {'ncols', 1, 'finite', 'real'},...
                                       'navGraph', 'Weight')
                    coder.internal.errorIf(height(links) ~= length(propsStruct.Weight), ...
                                           'nav:navalgs:navGraph:InvalidWeightInput')
                    linkTable = table(links, propsStruct.Weight, ...
                                      VariableNames={'EndStates', 'Weight'});
                end

              case 'table'
                % Create state and link tables from table inputs
                stateTable = varargin{1};
                linkTable = varargin{2};

              case 'digraph'
                % Create state and link tables from digraph input
                stateTable = varargin{1}.Nodes;
                linkTable = varargin{1}.Edges;
                linkTable = navGraph.updateLinkTableColumn(linkTable, 'EndStates');
            end
        end

        function Graph = createDigraph(statesTable, linksTable)
        % createDigraph Create digraph object from StatesTable and
        % LinksTable. The digraph object is used for various operations
        % like finding a state, or link etc.

        % Update EndStates column name to EndNodes
            linksTable = navGraph.updateLinkTableColumn(linksTable, 'EndNodes');
            % Create a digraph object
            Graph = digraph(linksTable, statesTable);
        end

        function linksTable = updateLinkTableColumn(linksTable, newName)
        % updateLinkTableColumn Update the name of the first column in
        % the link table from EndStates to EndNodes or vice-versa

        % For codegen purposes we cannot directly update the table
        % properties, so we need to make a deep copy
            columnNames = {newName, linksTable.Properties.VariableNames{2:end}};
            columnData = cell(1, length(columnNames));
            for i = 1:length(columnNames)
                columnData{i} = table2array(linksTable(:,i));
            end
            linksTable = table(columnData{:}, VariableNames=columnNames);
        end

        function egdeIndices = edgeNamesToIndices(name, endStates)
        % edgeNamesToIds Convert edges containing names to numeric
        % indices
            egdeIndices = zeros(size(endStates));
            for i=1:2
                egdeIndices(:,i) = cellfun(@(x) find(strcmp(name, x)),...
                                           endStates(:,i));
            end
        end

        function [StatesTable,LinksTable] = removeDuplicates(StatesTable,LinksTable)
        %removeDuplicates Removes duplicate elements from table

        % Fetching state names.
            stateNames = "";
            if(iscellstr(LinksTable.EndStates)||isstring(LinksTable.EndStates))
                stateNames = StatesTable.Name;
            end

            % Remove duplicate state vectors
            [StatesTable, LinksTable] = navGraph.omitDuplicateStates(StatesTable, LinksTable, stateNames);

            % Removing duplicates and self loop links
            LinksTable = navGraph.omitSelfLoopAndDuplicateLinks(...
                LinksTable,stateNames);

            %Validating links for incorrect state.
            if(isnumeric(LinksTable.EndStates))
                if(any(LinksTable.EndStates>height(StatesTable),'all'))
                    coder.internal.error('nav:navalgs:navGraph:StatesInLinkNotFound',height(StatesTable))
                end
            end
        end

        function [StatesTable, LinksTable] = omitDuplicateStates(StatesTable, LinksTable, stateNames)
        %omitDuplicateStates Removes all the duplicate states from
        %the state table, keeping only first occurrence. Removes the
        %links corresponding to the duplicate states and renumbers the
        %ids if link ids are provided.

        % Get end states IDs of links
            if (stateNames=="")
                linksEndStates = LinksTable.EndStates;
            else
                linksEndStates = navGraph.edgeNamesToIndices(StatesTable.Name,LinksTable.EndStates);
            end

            % Get state ids for unique state vector and the locations of their occurrences
            [stateIDs, occurIdx] = navGraph.getUniqueStateIDs(StatesTable.StateVector);

            % Remove duplicate states
            StatesTable = StatesTable(occurIdx,:);

            % Update EndStates of links with updated state ids after
            % removing duplicate states
            links = stateIDs(linksEndStates);
            if (stateNames=="")
                LinksTable.EndStates = links;
            else
                namesUpdated = stateNames(occurIdx);
                if iscellstr(LinksTable.EndStates)
                    namesUpdated = cellstr(namesUpdated);
                else
                    namesUpdated = string(namesUpdated);
                end
                LinksTable.EndStates = namesUpdated(links);
            end
        end

        function [linkT, occurIdx] = omitSelfLoopAndDuplicateLinks(LinkTable,stateNames)
        %omitSelfLoopAndDuplicateLinks Removes all the duplicate links from
        %the link table, keeping only first occurrence after sorting. Also
        %removes the self loops if exists from the link table.

        %Converting edges into numeric form, so as to bring uniformity
        %in sorting between integers or strings
            if(stateNames~="")
                %Converting edge names to edge indices
                link = navGraph.edgeNamesToIndices(stateNames,LinkTable.EndStates);
            else
                link = LinkTable.EndStates;
            end

            % Finding non-duplicate rows.
            [~, occurIdx] = unique(link,'rows','stable');
            link = link(occurIdx,:);

            %Finding rows without self loops
            occurIdx = occurIdx(link(:,1)~=link(:,2));
            
            % Final links table after removing self loops and duplicates
            linkT = LinkTable(occurIdx,:);
        end

        function navCostFcns = getStandardCostFcns()
        % getStandardCostFcns Get standard cost functions shipping with
        % Navigation toolbox
            navCostFcns = {'nav.algs.distanceEuclidean',...
                           'nav.algs.distanceManhattan',...
                           'nav.algs.distanceEuclideanSquared'};
        end

        function [stateIDs, occurIdx] = getUniqueStateIDs(states)
        %getUniqueStateIDs Get unique states ids with in a specified
        %tolerance
        %Inputs:
        %   STATES : [N,2] matrix
        %Outputs:
        %   STATEIDS : Indices of unique element vector mapped to original
        %              input STATES vector
        %   OCCURIDX : Indices of first occurrences of unique elements in STATES
        %
        % Example:
        %    states = [1,2; 1,2; 1,2; 2,5; 3,4; 3,4; 5,7; 7,8; 7,8];
        %    getUniqueStateIDs outputs
        %       stateIDs = [1,1,1,2,3,3,4,5,5]
        %       occurIdx = [1,4,5,7,8];

            eps1 = eps(class(states)); % Compute epsilon based on class ('double' or 'single')
            states = floor(states/eps1)*eps1;
            [~, occurIdx, stateIDs] = unique(states,"rows", "stable");
            stateIDs = stateIDs'; %Needs to be a row vector while
                                  %dealing with Links table that has single
                                  %row
        end
    end
end
