classdef Container < handle
    % Creates a container that can hold multiple components and their connections.
    %
    % Container Methods:
    %    add                     - adds a component to the container
    %    remove                  - removes a component from the container
    %    removeAll               - removes all components
    %    connect                 - connect two components
    %    disconnect              - disconnect two components
    %    disconnectAll           - disconnects all components
    %    getComponent            - returns a component
    %    getComponents           - returns all components
    %    getConnector            - returns a connector
    %    getConnectors           - returns all connectors
    %    isAncestorOf            - checks if a component is in the container
    %
    %   See also Connector, Port.
    
    % Author(s): Murad Abu-Khalaf , January 3, 2011
    % Revised:
    % Copyright 2009-2011 The MathWorks, Inc.
    
    
    %% ------ PROPERTIES
    properties (Access = protected)
        Components_
        Connectors_
    end
    
    %% ------ MODEL CONSTRUCTION
    methods
        function this = Container(varargin)
            % Constructor requiring the arguments Source, Destination.
            this.Components_ = {};
            this.Connectors_ = {};
        end
        
        %         function delete(this)
        %             disp([class(this) ' is deleting...']);
        %         end
    end
    
    %% ------ SERILIZATION
    methods
        % Never saved or loaded!
        %         function S = saveobj(obj)
        %         end
        %         function obj = reload(obj, S)
        %         end
    end
    
    %% ------ Access methods
    methods (Access = public)
        
        function add(this, comp)
            if isempty(comp.Name)
                ctrlMsgUtils.error('Controllib:databrowser:UnnamedComponent');
            end
            % Add this component provided its handle.
            names  = cellfun(@(c) c.Name, this.Components_,'UniformOutput',false);
            equals = cellfun(@(c) eq(comp,c), this.Components_,'UniformOutput',true);
            
            similarnames = find(strcmp(comp.Name,names),1);
            
            if any(equals) || ~isempty(similarnames)
                ctrlMsgUtils.error('Controllib:databrowser:NoSameComponent');
            else
                comp.setParent(this);
                this.Components_ = [this.Components_; {comp}];
            end
        end
        
        function remove(this,comp)
            % Remove this component provided its handle or name.
            if ischar(comp)
                comp = this.getComponent(comp);
            end
            if ~(isa(comp,'handle') && isAncestorOf(this,comp))
                return;
            end
            idx  = cellfun(@(x) eq(comp,x), this.Components_,'UniformOutput',true);
            this.Components_(idx) = [];
            
            % Remove all connectors related to the removed component
            idx = getConnectorsWithSource(this,comp.Name);
            this.Connectors_(idx) = [];
            idx = getConnectorsWithDestination(this,comp.Name);
            this.Connectors_(idx) = [];
        end
        
        function removeAll(this)
            % Removes all components from this container.
            this.Components_ = {};
            this.Connectors_ = {};
        end
        
        function r = getComponent(this, name)
            % Return a component provided its name. This implementation
            % assumes names are distinct
            r = [];
            names = cellfun(@(c) c.Name, this.Components_,'UniformOutput',false);
            idx = strcmp(name,names);
            if any(idx)
                r = this.Components_{idx};
            end
        end
        
        function r = getComponents(this)
            % Return all components.
            r = this.Components_;
        end
        
        function r = isAncestorOf(this,comp)
            % Checks if the component is contained in this container.
            for i=1:numel(this.Components_)
                % This is robust to overloaded eq. For example,
                % eq([],aHandle) = [];
                r = eq(comp,this.Components_{i});
                if r
                    return;
                end
            end
            r = false;
        end
        
        function connect(this, src, dest)
            % Assumes source and destination have only one port.
            [SrcComponent,SrcPort,DstComponent,DstPort] = toolpack.Container.resolve(src,dest);
            try
                hSrcPort  = this.getComponent(SrcComponent).Outport(SrcPort);
                hDstPort = this.getComponent(DstComponent).Inport(DstPort);
                wire = toolpack.Connector(hSrcPort,hDstPort);
                wire.Name = [src '_' dest];
            catch E
                rethrow(E);
            end
            this.Connectors_ = [this.Connectors_; {wire}];
        end
        
        function disconnect(this, src, dest)
            % Assumes source and destination have only one port.
            wire = getConnector(this, src,dest);
            if isempty(wire)
                return;
            end
            idx  = cellfun(@(x) eq(wire,x), this.Connectors_,'UniformOutput',true);
            if any(idx)
                this.Connectors_(idx) = [];
                delete(wire);
            end
        end
        
        function disconnectAll(this)
            % Disconnect all components. % Assumes source and destination
            % have only one port.
            cellfun(@(x) delete(x), this.Connectors_,'UniformOutput',true);
            this.Connectors_ = {};
        end
        
        function r = getConnector(this, srcname,dstname)
            r = [];
            srcIDX = getConnectorsWithSource(this,srcname);
            dstIDX = getConnectorsWithDestination(this,dstname);
            idx = and(srcIDX,dstIDX);
            if any(idx)
                r = this.Connectors_{idx};
            end
        end
        
        function r = getConnectors(this)
            % Return all components.
            r = this.Connectors_;
        end
        
    end
    
    methods (Access = private)
        function idx = getConnectorsWithSource(this,srcname)
            names  = cellfun(@(c) c.Source.getComponent.Name, this.Connectors_,'UniformOutput',false);
            idx = strcmp(srcname,names);
        end
        
        function idx = getConnectorsWithDestination(this,dstname)
            names  = cellfun(@(c) c.Destination.getComponent.Name, this.Connectors_,'UniformOutput',false);
            idx = strcmp(dstname,names);
        end
    end
    
    methods (Static, Access = private)
        function [SrcComponent,SrcPort,DstComponent,DstPort] = resolve(src,dest)
            % Connect components.
            SrcComponent = src(1:((strfind(src,'/')-1)));
            SrcPort = str2double(src(((strfind(src,'/')+1)):end));
            DstComponent = dest(1:((strfind(dest,'/')-1)));
            DstPort = str2double(dest(((strfind(dest,'/')+1)):end));
        end
    end
    
    methods
        function r = get.Components_(this)
            %idx  = cellfun(@(x) ~isvalid(x), this.Components_,'UniformOutput',true);
            %this.Components_(idx) = [];
            r = this.Components_;
            % Cannot remove invalid Components because they can become so
            % while being deleted and not after completely being deleted.
            % this results in methods like isAncestorOf, getComponent etc..
            % all returning the wrong answer.
        end
        function r = get.Connectors_(this)
            idx  = cellfun(@(x) ~isvalid(x), this.Connectors_,'UniformOutput',true);
            this.Connectors_(idx) = [];
            r = this.Connectors_;
        end
    end
end
