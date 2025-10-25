classdef (Abstract) VEAction  < internal.matlab.datatoolsservices.actiondataservice.Action
    % VEAction Abstract class is a subclass of the Action class
    
    % This class gets an instance of the VariableEditor's PeerManager and
    % listens to changes in Selection/Focus etc and calls the
    % UdpateActionState. Subclasses implementing the UpdateActionState
    % will be able to re-evaluate the Action state and update on these events.
    
    % Copyright 2017-2024 The MathWorks, Inc.

    properties (Access = {?internal.matlab.variableeditor.VEAction, ?matlab.unittest.TestCase}, WeakHandle)
        veManager internal.matlab.variableeditor.MLManager;
    end
    
    methods 
        % Adds listeners on the PeerManager and PeerManagerFactory instances.
        function this = VEAction(props, manager)
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);

            this.veManager = manager;
        end
    end

    methods(Access = 'protected')
        function viewModel = getVariableEditorViewModel(this)
            viewModel = [];

            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
                viewModel = focusedDoc.ViewModel;
            end
        end

        function dataModel = getVariableEditorDataModel(this)
            dataModel = [];

            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc)
                dataModel = focusedDoc.DataModel;
            end
        end
    end

    methods(Static, Hidden)
        function ids = getSetDebugMode(mode)
            persistent isDebugSet;

            if nargin > 0
                isDebugSet = mode;
            end

            if isempty(isDebugSet)
                isDebugSet = false;
            end

            ids = isDebugSet;
        end
    end

    methods(Abstract)
        UpdateActionState(this);        
    end    
end

