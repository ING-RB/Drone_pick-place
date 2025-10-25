classdef VEActionDataService < internal.matlab.datatoolsservices.actiondataservice.ActionDataService
    %Variable Editor Action Data Service
    % This class maintains the listeners for all Variable Editor Actions

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Access = {?internal.matlab.variableeditor.VEActionDataService, ?matlab.unittest.TestCase})
        veManager
    end

    properties (Access = {?matlab.unittest.TestCase}, Transient)
        % Listeners for any events on the Variable Editor
        managerFocusGainedListener
        managerFocusLostListener
        veDocumentFocusGainedListener
        veDocumentFocusLostListener
        veDocumentOpenedListener
        veDocumentTypeChangedListener
        veSelectionChangeListener
        dataChangeListener

        listenersEnabled (1,1) logical = false

        CurrentSelection
        CurrentSize
        ActionStateInitialized (1,1) logical = false;
    end

    methods
        function this = VEActionDataService(remoteProvider, veManager)
            this@internal.matlab.datatoolsservices.actiondataservice.ActionDataService(remoteProvider);
            this.veManager = veManager;
            this.setupListeners();
        end

        % Cleanup all listeners on action deletion
        function delete(this)
            this.deleteListener('managerFocusGainedListener');
            this.deleteListener('managerFocusLostListener');
            this.deleteListener('veDocumentFocusGainedListener');
            this.deleteListener('veDocumentFocusLostListener');
            this.deleteListener('veDocumentTypeChangedListener');
            this.deleteListener('veSelectionChangeListener');
            this.deleteListener('veDocumentOpenedListener');
            this.deleteListener('dataChangeListener');
            this.veManager = [];
        end
        
    end

    methods
        function initActionStates(this)
            focusedDoc = this.veManager.FocusedDocument;
            if ~isempty(focusedDoc) && isa(focusedDoc.ViewModel,'internal.matlab.variableeditor.SelectionModel')
                s = focusedDoc.ViewModel.getSelection();
                this.CurrentSelection = s;
                this.CurrentSize = getDataSize(focusedDoc.ViewModel.DataModel.getData);
                % If selection already exists on view, init Action State.
                if ~isempty(s) && ~isempty(s(1))
                    this.enableListenersAndUpdateActionStates();
                end
            end
        end
    end

    methods (Access = {?matlab.unittest.TestCase})
        function setupListeners(this)
             this.veDocumentFocusGainedListener = event.listener(this.veManager, 'DocumentFocusGained',...
                @(es, ed) this.handleVEDocumentFocus(es, ed));           
            this.veDocumentFocusLostListener = event.listener(this.veManager, 'DocumentFocusLost',...
                @(es, ed) this.handleVEDocumentFocus(es, ed));

            % Disable listeners while a document is in an open cycle
            this.veDocumentOpenedListener = event.listener(this.veManager, 'DocumentOpened', ...
                @(es, ed) this.disableListeners());

            % If focusedDocument exists at time of action creation, call
            % handleVEDocumentFocus to attach listeners
            if (~isempty(this.veManager.FocusedDocument))
                this.handleVEDocumentFocus(struct('FocusedDocument', this.veManager.FocusedDocument));
            end
        end

        function disableListeners(this)
            this.listenersEnabled = false;
        end

        function enableListenersAndUpdateActionStates(this)
            this.listenersEnabled = true;
            this.updateActionStates();
        end

        % Adds Listeners on the Variable Editor PeerDocument during
        % Focus/Selection changes.
        function handleVEDocumentFocus(this, es, ~)
            this.CurrentSelection = [];
            this.CurrentSize = [];
            if ~isempty(this.veDocumentTypeChangedListener)
                delete(this.veDocumentTypeChangedListener);
            end
            if ~isempty(es.FocusedDocument)
                this.veDocumentTypeChangedListener = event.listener(es.FocusedDocument, 'DocumentTypeChanged',...
                                @(es, ed) this.handleDocTypeChanged(es, ed));
                if isa(es.FocusedDocument.ViewModel,'internal.matlab.variableeditor.SelectionModel')
                    if ~isempty(this.veSelectionChangeListener)
                         delete(this.veSelectionChangeListener);
                    end
                    this.veSelectionChangeListener = event.listener(es.FocusedDocument.ViewModel, ...
                            'SelectionChanged', @(es, ed) this.enableListenersAndUpdateActionStates());
                    this.CurrentSelection = es.FocusedDocument.ViewModel.getSelection;
                else
                    % For Unsupported Views enable the listeners from the
                    % start
                    this.listenersEnabled = true;
                end
                if ~isempty(this.dataChangeListener)
                     delete(this.dataChangeListener);
                end
                this.dataChangeListener = event.listener(es.FocusedDocument.ViewModel,'DataChange', @(es, ed) this.updateActionStates());
            end
            this.updateActionStates();
        end

        % Adds listeners on the ViewModel of the PeerDocument for Selection changes.
        function handleDocTypeChanged(this, es, ~)
            this.CurrentSelection = [];
            if isa(es.ViewModel,'internal.matlab.variableeditor.SelectionModel')
                if ~isempty(this.veSelectionChangeListener)
                     delete(this.veSelectionChangeListener);
                end
                this.veSelectionChangeListener = event.listener(es.ViewModel,'SelectionChanged', @(es, ed) this.enableListenersAndUpdateActionStates());
                this.CurrentSelection = es.ViewModel.getSelection;
                this.CurrentSize = getDataSize(es.ViewModel.DataModel.getData);
            else
                % For Unsupported Views enable the listeners from the
                % start
                this.listenersEnabled = true;
            end
            this.updateActionStates();
        end

        function updateActionStates(this)
            if this.listenersEnabled
                try
                    if isa(this.veManager.Documents.ViewModel,'internal.matlab.variableeditor.SelectionModel')
                        sel = this.veManager.Documents.ViewModel.getSelection();
                        sz = getDataSize(this.veManager.Documents.ViewModel.DataModel.getData());
                        if this.ActionStateInitialized && isequal(sel, this.CurrentSelection) && isequal(sz, this.CurrentSize)
                            % If selection hasn't changed, just return
                            return;
                        end
                        this.CurrentSelection = sel;
                        this.CurrentSize = sz;
                        this.ActionStateInitialized = true;
                    end
                catch
                    % Ignore errors.  Not all ViewModels have a 'getSelection'
                    % method, but because the large majority of them do, it's
                    % quicker to just call the method and catch the error when
                    % there isn't one.
                end

                try
                internal.matlab.datatoolsservices.logDebug("VEActiondataService::updateActionStates", "updateActionStates for:" + this.veManager.Channel);
                catch
                end
                actions = this.getAllActions();

                if ~isempty(actions)
                    for i=1:length(actions)
                        action = actions(i); % This would be an action wrapper
                        if isa(action, "internal.matlab.variableeditor.VEAction")
                            action.UpdateActionState();
                        end
                    end
                end
            end
        end

        function deleteListener(this, listener)
            if ~isempty(this.(listener)) && isvalid(this.(listener))
                delete(this.(listener));
            end
        end
    end
end

function sz = getDataSize(d)
    if isa(d, "struct")
        sz = length(fieldnames(d));
    else
        sz = size(d);
    end
end

