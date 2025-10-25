classdef Manager < handle 
    % An abstract class defining the methods for a Variable Manager
    % 

    % Copyright 2013-2024 The MathWorks, Inc.

    % Events
    events
       DocumentOpened;  % Sent when a document is opened
       DocumentClosed;  % Sent when a document is closed
       DocumentFocusGained; % Sent when a document gains focus
       DocumentFocusLost; % Sent when a document loses focus
    end
    
    % Property Definitions:

    % Documents_I
    properties (SetObservable=true, SetAccess='protected', GetAccess='protected', Dependent=false, Hidden=true)
        % Documents_I Property
        Documents_I;
    end %properties
    methods
        function storedValue = get.Documents_I(this)
            storedValue = this.Documents_I;
        end
        
        function set.Documents_I(this, newValue)
            reallyDoCopy = ~isequal(this.Documents_I, newValue);
            if reallyDoCopy
                this.Documents_I = newValue;
            end
        end
    end
    
    % Documents
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=true, Hidden=false)
        % Documents Property
        Documents;
    end %properties
    methods
        function storedValue = get.Documents(this)
            storedValue = this.Documents_I;
        end
        
        function set.Documents(this, newValue)
            this.Documents_I = newValue;
        end
    end
    
    % FocusedDocument
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Hidden=false)
        % FocusedDocument Property
        FocusedDocument;
    end %properties
    methods
        function storedValue = get.FocusedDocument(this)
            storedValue = this.FocusedDocument;
        end
        
        function set.FocusedDocument(this, newValue)
            % Short circuit if old value is same as new value
            % isFocused checks if the manager currently has focus.
            % TODO: Clean the focus workflow and remove the public method
            docIsFocused = this.isFocused();
            docsAreEqual = internal.matlab.variableeditor.areVariablesEqual(this.FocusedDocument, newValue);
            newValueNotaDocument = (~isempty(newValue) && ~isa(newValue, 'internal.matlab.variableeditor.Document'));
            managerDoesNotContainNewDocument = (~isempty(newValue) && ~this.containsDocument(newValue));
            if docIsFocused && docsAreEqual || newValueNotaDocument|| managerDoesNotContainNewDocument
                return;
            end
            
            % newValue can be focusedDocument already. Do not shortcircuit
            % on DocumentFocusLost, we need it to lose focus and then
            % gain focus so the mf0 property can be updated.
            if ~isempty(this.FocusedDocument) && isvalid(this.FocusedDocument)
                % Fire event when document focus is lost
                eventdata = internal.matlab.variableeditor.DocumentChangeEventData;
                eventdata.Document = this.FocusedDocument;
                this.notify('DocumentFocusLost',eventdata);
            end
            
            this.FocusedDocument = newValue;
            
            if ~isempty(newValue)
                % Fire event when document focus is gained
                eventdata = internal.matlab.variableeditor.DocumentChangeEventData;
                eventdata.Document = newValue;
                this.notify('DocumentFocusGained',eventdata);
            end
        end
    end
    
    methods(Access='public')
        % Checks to see if the manager contains the specified document
        function hasDoc = containsDocument(this, doc)
            hasDoc = false;
            for i=1:length(this.Documents)
                if internal.matlab.variableeditor.areVariablesEqual(doc, this.Documents(i))
                    hasDoc = true;
                    return;
                end
            end
        end
        
        % Temporary method to check if manager is currently focused. Method
        % here defaults to true. Subclasses will override it.
        function focused = isFocused(this)
            focused = true;
        end
    end
    
    % Public Abstract Methods
    methods(Access='public',Abstract=true)
        % openvar
        varargout = openvar(this,varargin);

        % closevar
        varargout = closevar(this,varargin);
        
        % getVariableAdapter
        veVar = getVariableAdapter(this, name, workspace, varClass, varSize, data);
    end
end
