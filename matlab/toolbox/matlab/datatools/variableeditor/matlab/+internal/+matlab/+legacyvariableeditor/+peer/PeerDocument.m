classdef PeerDocument < internal.matlab.legacyvariableeditor.MLDocument & internal.matlab.legacyvariableeditor.peer.PeerVariableNode
    %PEERDOCUMENT PeerModel Variable Document

    % Copyright 2013-2016 The MathWorks, Inc.

    % Property Definitions:
    
    properties (Constant)
        % PeerNodeType
        PeerNodeType = '_VariableEditorDocument_';
    end
    
    properties (Dependent = true)
        DocID;
    end
    
    methods
        % Constructor
        function this = PeerDocument(root, manager, variable, userContext, docID)
            vardata = (variable.getDataModel.getData);                      
            this = this@internal.matlab.legacyvariableeditor.MLDocument(manager, variable, userContext);
            
            [secondaryType, secondaryStatus] = ...
                internal.matlab.datatoolsservices.FormatDataUtils.getVariableSecondaryInfo(vardata);

            this = this@internal.matlab.legacyvariableeditor.peer.PeerVariableNode(root,...
                internal.matlab.legacyvariableeditor.peer.PeerDocument.PeerNodeType,...
                'name',variable.getDataModel.Name,...
                'type',internal.matlab.legacyvariableeditor.peer.PeerDocument.resolveTypeWithDataModel(vardata, variable),...
                'size', variable.ViewModel.getDisplaySize(),...
                'secondaryType', secondaryType, ...
                'secondaryStatus', secondaryStatus, ...
                'workspace', manager.getWorkspaceKey(variable.getDataModel.Workspace),...
                'docID', docID,...
                'userContext', userContext);
            this.DataModel = variable.getDataModel();
            this.ViewModel = variable.getViewModel(this);            
        end

        function data = variableChanged(this, varargin)            
            % varargin{1} : changed data for the variable
            % varargin{2} : size of the variable, has to be formatted to
            % display in MOL(n-D types are to be displayed appropriately.
            % varargin{3} : type of variable, has to be formatted to
            % consider complex/sparse and other types.
            % Use cloneData to get currentType, this ensures we get the
            % right datatype for views like timetable. (g1999619)
            currentType = class(this.DataModel.getCloneData);
            if nargin < 4
                newType = '';
            else
                newType = varargin{3};
            end
            data = this.variableChanged@internal.matlab.legacyvariableeditor.MLDocument(varargin{:});
           
            newSize = '0';
            newClass = '';
            tallVar = isa(varargin{1}, 'tall');
            
            if tallVar || numel(varargin{2})>1
                import internal.matlab.datatoolsservices.FormatDataUtils;
                newSize = internal.matlab.datatoolsservices.FormatDataUtils.formatSize(varargin{1});
                newClass = internal.matlab.legacyvariableeditor.peer.PeerUtils.formatClass(varargin{1});
            end            
            this.setProperty('name', this.DataModel.Name);
            this.setProperty('size', newSize);
            this.setProperty('type', newClass);
            
            [secondaryType, secondaryStatus] = ...
                internal.matlab.datatoolsservices.FormatDataUtils.getVariableSecondaryInfo(varargin{1});
            if ~isempty(secondaryType)
                this.setProperty('secondaryType', secondaryType);
            end
            
            if ~isempty(secondaryStatus)
                this.setProperty('secondaryStatus', secondaryStatus);
            end
        end
        
        function handlePropertySet(this, es, ed)
        end
        
        function handlePropertyDeleted(this, es, ed)
        end
        
        function handlePeerEvents(this, es, ed)
        end
        
        function storedValue = get.DocID(this)
            storedValue = this.PeerNode.getProperties.docID;
        end
    end
    
    methods(Static = true)
        function vartype = resolveTypeWithDataModel(vardata, variable)
            % Resolve cases where the variable data may be recognized as a different
            % type.  For example, empty char being recognized as double.  In cases like
            % this, use the DataModel type.
            vartype = internal.matlab.legacyvariableeditor.peer.PeerUtils.formatClass(vardata);
            if (strcmp(variable.getDataModel.Type, 'Char') && isempty(vardata))
                vartype = 'char';
            elseif (strcmp(variable.getDataModel.Type, 'TimeTable'))
                vartype = 'timetable';
            end
        end
    end
    
end

