classdef graphPropertyContainer
    %GRAPHPROPERTYCONTAINER Hold node or edge properties for graph/digraph

    %   Copyright 2021 The MathWorks, Inc.
    %#codegen


    properties(Access = private)
        errTag % 'graph' or 'digraph', for getting the the right error messages
        nodeOrEdge % 'node' for node properties, 'edge' for edge properties
        data % cell array containing property data
        VariableNames % cellstr of variable names used for putting the data in tables
        nrows % number of nodes or edges. The number of rows in each element of data must be nrows
        nproperties % number of properties. length(data) = nproperties
        canHaveProperties % logical - false if nproperties = 0
    end
    methods
        function obj = graphPropertyContainer(in1, in2, dataIn, nrowsIn)
            % Syntax:
            % obj = graphPropertyContainer('node','graph',nodeTable)
            % Create a node property container for a graph, containing the
            % information from nodeTable
            %
            % obj = graphPropertyContainer('edge','digraph',[1 2 3])
            % Create an edge container with one property - 'Weight' - and
            % three rows
            %
            % obj = graphPropertyContainer('edge','digraph',[],3)
            % Create an edge container for a digraph with no properties and
            % three edges
            %
            % obj = graphPropertyContainer(otherContainer,inds)
            % Copy otherContainer, excluding any property rows not in inds
            % E.g., if otherContainer has one propery with values [1 2 3]'
            % and inds = [1 3], obj will have one property with values
            % [1 3]' (by 'property' I mean node or edge property in this
            % context)

            coder.internal.prefer_const(in1, in2);
            narginchk(2,4);
            if nargin == 2
                % Copy graphPropertyObject
                obj = constructorCopyGraphPropertyContainer(obj, in1, in2);
                return
            end

            obj.nodeOrEdge = coder.const(in1);
            % the coder.const here is just to make sure we error if in1 is
            % not const. It needs to be const so that Coder can eliminate
            % any branches that can't be hit because of the value of
            % nodeOrEdge

            obj.errTag = coder.const(in2);
            % just a way to make sure errTag is const

            if nargin == 4 && coder.internal.isConstTrue(isempty(dataIn)) ...
                    && ~coder.internal.isConstTrue(isempty(nrowsIn))
                obj = constructorNoProperties(obj, nrowsIn);
            elseif istable(dataIn)
                obj = constructorTableInput(obj,dataIn);
            elseif obj.isNode % node names
                coder.internal.assert(false, ...
                    'MATLAB:graphfun:codegen:NodeNamesNotSupported');
            else % edge properties
                obj = constructorEdgeWeights(obj,dataIn);
            end
        end

        function obj = constructorCopyGraphPropertyContainer(obj, G, inds)
            obj.VariableNames = G.VariableNames;            
            obj.nproperties = G.nproperties;
            obj.canHaveProperties = G.canHaveProperties;
            obj.errTag = G.errTag;
            obj.nodeOrEdge = G.nodeOrEdge;
            if obj.canHaveProperties
                obj.data = cell(1,obj.nproperties);
                coder.unroll()
                for ii = coder.internal.indexInt(1):obj.nproperties
                    obj.data{ii} = G.data{ii}(inds,:);
                end
            else
                obj.data = {};
            end
            obj.nrows = coder.internal.indexInt(numel(inds));
        end

        function obj = constructorNoProperties(obj, nrowsIn)
            obj.data = {};
            obj.VariableNames = {};
            obj.nrows = coder.internal.indexInt(nrowsIn);
            obj.canHaveProperties = false;
            obj.nproperties = coder.internal.indexInt(0);
        end

        function obj = constructorEdgeWeights(obj, dataIn)
            coder.internal.assert(isfloat(dataIn) && isreal(dataIn) && ~issparse(dataIn), ['MATLAB:graphfun:' obj.errTag ':InvalidWeights']);
            coder.internal.assert(iscolumn(dataIn) || (size(dataIn, 1) == 0 && size(dataIn, 2) == 0),['MATLAB:graphfun:' obj.errTag ':NonColumnWeights']);

            obj.nrows = coder.internal.indexInt(size(dataIn,1));
            obj.VariableNames = {'Weight'};
            obj.data = {makeVarsize(dataIn(:))};
            obj.nproperties = coder.internal.indexInt(1);
            obj.canHaveProperties = true;
        end

        function obj = constructorTableInput(obj, dataIn)
            obj.nrows = coder.internal.indexInt(size(dataIn,1));
            obj.VariableNames = coder.const(dataIn.Properties.VariableNames);
            obj.nproperties = coder.const(coder.internal.indexInt(numel(obj.VariableNames)));
            if obj.nproperties == 0
                obj.data = {};
                obj.canHaveProperties = false;
            else
                obj.data = cell(1,size(dataIn,2));
                obj.canHaveProperties = true;
                coder.unroll()
                for ii = coder.internal.indexInt(1):size(dataIn,2)
                    if strcmp(obj.nodeOrEdge,'node')
                        coder.internal.assert(~strcmp(obj.VariableNames{ii},'Name'), ...
                            'MATLAB:graphfun:codegen:NodeNamesNotSupported');
                    elseif strcmp(obj.VariableNames{ii},'Weight')
                        currentData = dataIn.(ii);
                        coder.internal.assert(isfloat(currentData) && ...
                            isreal(currentData) && ~issparse(currentData), ...
                            ['MATLAB:graphfun:' obj.errTag ':InvalidWeights']);
                    end
                    obj.data{ii} = makeVarsize(dataIn.(ii));
                end
            end
        end


        function tableOut = makeTable(obj,extraData,extraNames)
            if nargin == 1
                if isempty(obj.VariableNames)
                    tableOut = array2table(zeros(obj.nrows,0), ...
                        'VariableNames',{});
                elseif isempty(obj.data)
                    tableOut = cell2table(cell(0, ...
                        obj.nproperties), ...
                        'VariableNames',obj.VariableNames);
                elseif coder.target('MATLAB') && obj.nrows == 1
                    tableOut = array2table(zeros(1,obj.nproperties), ...
                        'VariableNames',obj.VariableNames);
                    % This is a trick to make sure that char arrays are
                    % preserved as char arrays and not cellstrs when
                    % creating one row tables.
                    % Codegen doesn't have this problem because it can
                    % distinguish between const, scalar chars (parameters) and variable
                    % sized chars (data)
                    for ii = 1:obj.nproperties
                        tableOut.(ii) = obj.data{ii};
                    end
                else
                    tableOut = table(obj.data{:},'VariableNames', ...
                        obj.VariableNames);
                end
            else
                newData = {extraData{:},obj.data{:}};
                if iscell(extraNames)
                    newVariableNames = {extraNames{:}, ...
                        obj.VariableNames{:}};
                else
                    newVariableNames = {extraNames, ...
                        obj.VariableNames{:}};
                end
                tableOut = table(newData{:},'VariableNames', ...
                    newVariableNames);
            end
        end

        function tf = checkVariables(obj,newVariableNames)
            if ~obj.canHaveProperties
                tf = isempty(newVariableNames);
                return
            end

            if coder.internal.isConst(newVariableNames)
                ISMEMBEROUT = coder.const(feval('ismember', ...
                    obj.VariableNames,newVariableNames));
                tf = coder.const(feval('any',ISMEMBEROUT));
            else
                numVars = obj.nproperties;
                numNewVars = numel(newVariableNames);
                if numVars ~= numNewVars
                    tf = false;
                    return;
                end
                newVarHasMatch = false(1,numNewVars);
                coder.unroll()
                for ii = 1:numVars
                    for jj = 1:numNewVars
                        if strcmp(obj.VariableNames{ii}, ...
                                newVariableNames{jj})
                            newVarHasMatch(jj) = true;
                        end
                    end
                end
                tf = all(newVarHasMatch);
            end
        end

        function obj = append(obj,in,numToAdd)
            % numToAdd indicates how many rows to add if in is empty.
            % When in isn't empty, numToAdd is ignored.
            if istable(in)
                numToAdd = size(in,1);
            end
            coder.internal.assert(obj.canHaveProperties || isempty(in), ...
                'MATLAB:graphfun:codegen:PropertiesCannotBeAdded');
            if ~coder.internal.isConstTrue(isempty(in))
                % assumes in is a table. Note that this is not checked
                coder.internal.assert(checkVariables(obj, ...
                    in.Properties.VariableNames),'MATLAB:graphfun:codegen:PropertiesCannotBeAdded');
                coder.unroll();
                for ii = 1:obj.nproperties
                    obj.data{ii} = [obj.data{ii};in.(obj.VariableNames{ii})];
                end
            else
                coder.internal.assert(~obj.canHaveProperties || numToAdd == 0, ...
                    'MATLAB:graphfun:codegen:PropertiesCannotBeAdded');
            end
            obj.nrows = obj.nrows + cast(numToAdd,'like',obj.nrows);
        end

        function obj = remove(obj,index_in)
            ONE = coder.internal.indexInt(1);
            coder.varsize('index',[inf,1],[1 0]);
            index = index_in(:);
            ii = coder.internal.indexInt(numel(index));
            while ii > 0
                if index(ii) > obj.nrows || index(ii) <= 0
                    index(ii) = [];
                end
                ii = ii - ONE;
            end
            if ~isempty(obj.data)
                coder.unroll()
                for ii = ONE:numel(obj.data)
                    obj.data{ii}(index,:) = [];
                end
            end
            obj.nrows = obj.nrows - cast(numel(index),'like',obj.nrows);
        end
        
        function [value,tf] = getByName(obj,name)
            coder.internal.prefer_const(name);
            [~,INDEX] = coder.const(@feval,'ismember',name,obj.VariableNames);
            if INDEX == 0
                tf = false;
                value = [];
                return;
            else
                tf = true;
                value = obj.data{INDEX};
            end
        end

        function tf = hasProperties(obj)
            coder.inline('always');
            tf = coder.const(obj.canHaveProperties);
        end

        function obj = insertOneRow(obj,index,value)
            % Insert one new row to NodeProperties or EdgeProperties
            
            ONE = coder.internal.indexInt(1);
            indexInt = coder.internal.indexInt(index);
            coder.internal.assert(obj.nproperties == numel(value), ...
                'MATLAB:graphfun:codegen:PropertiesMissing');

            coder.unroll()
            for ii = ONE:obj.nproperties
                obj.data{ii} = [obj.data{ii}(ONE:indexInt-ONE,:); value{ii}; obj.data{ii}(indexInt:end,:)];
            end
            obj.nrows = obj.nrows+1;
        end

        function obj = setProperties(obj,in)
            coder.internal.assert(size(in,2) == obj.nproperties, ...
                'MATLAB:graphfun:codegen:PropertiesMissing');

            if obj.isNode()
                errIDPart = 'SetNodes';
            else
                errIDPart = 'SetEdges';
            end

            coder.internal.assert(size(in,1) == obj.nrows, ...
                ['MATLAB:graphfun:' obj.errTag ':' errIDPart]);
            
            if ~istable(in)
                % In-memory error for G.Edges = a, where a is not a table
                coder.internal.assert(obj.isNode,'MATLAB:graphfun:graph:SetEdges');
                % G.Nodes = a, where a is not a table, assumes a contains
                % node names
                coder.internal.assert(false,'MATLAB:graphfun:codegen:NodeNamesNotSupported');
            end
            
            coder.unroll()
            for ii = coder.internal.indexInt(1):obj.nproperties
                obj.data{ii} = in.(ii);
            end
        end

        function tf = isempty(obj)
            % Only return true if obj was constructed without properties
            % and has 0 rows
            tf = ~obj.canHaveProperties && obj.nrows == 0;
        end
        
        function tf = isequal(obj1,obj2,varargin)
            if nargin > 2
                tf = isequal(obj1, obj2);
                ii = 1;
                while tf && ii <= nargin-2
                    tf = isequal(obj1, varargin{ii});
                    ii = ii+1;
                end
                return;
            end

            if ~isequal(obj1.nodeOrEdge,obj2.nodeOrEdge)
                tf = false;
                return
            end

            if ~isequal(obj1.canHaveProperties,obj2.canHaveProperties)
                tf = false;
                return
            end

            if ~isequal(obj1.nproperties,obj2.nproperties)
                tf = false;
                return
            end

            if ~isequal(obj1.nrows,obj2.nrows)
                tf = false;
                return
            end

            if ~isequal(obj1.nrows,obj2.nrows)
                tf = false;
                return
            end

            if ~isequal(obj1.VariableNames,obj2.VariableNames)
                tf = false;
                return
            end

            tf = true;
            for ii = 1:obj1.nproperties
                tf = tf && isequal(obj1.data{ii},obj2.data{ii});
            end
            return
        end

        function tf = isequaln(obj1,obj2,varargin)
            if nargin > 2
                tf = isequaln(obj1, obj2);
                ii = 1;
                while tf && ii <= nargin-2
                    tf = isequaln(obj1, varargin{ii});
                    ii = ii+1;
                end
                return;
            end

            if ~isequal(obj1.nodeOrEdge,obj2.nodeOrEdge)
                tf = false;
                return
            end

            if ~isequal(obj1.canHaveProperties,obj2.canHaveProperties)
                tf = false;
                return
            end

            if ~isequal(obj1.nproperties,obj2.nproperties)
                tf = false;
                return
            end

            if ~isequal(obj1.nrows,obj2.nrows)
                tf = false;
                return
            end

            if ~isequal(obj1.nrows,obj2.nrows)
                tf = false;
                return
            end

            if ~isequal(obj1.VariableNames,obj2.VariableNames)
                tf = false;
                return
            end

            tf = true;
            for ii = 1:obj1.nproperties
                tf = tf && isequaln(obj1.data{ii},obj2.data{ii});
            end
            return
        end
    end

    methods (Access = private)
        function tf = isNode(obj)
            % Because obj.nodeOrEdge is const, this will be contant folded
            % out
            coder.internal.prefer_const(obj);
            coder.inline('always');
            % If constant folding somehow fails, lets avoid an extra
            % function call here.
            tf = coder.const(feval('strcmp',obj.nodeOrEdge,'node'));
        end
    end

    methods (Static, Hidden)
        function result = matlabCodegenNontunableProperties(~)
            % These properties are constant after they are assigned in
            % the constructor. They must be given compile-time constant
            % values.
            result = {'nodeOrEdge','errTag','VariableNames','nproperties','canHaveProperties'};
        end
    end
end

function out = makeVarsize(in)
% This helper allows us to force unnamed variables to be varsized
coder.varsize('out')
out = in;
end