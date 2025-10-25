classdef RemoteUnsupportedViewModel < internal.matlab.variableeditor.MLUnsupportedViewModel
    %RemoteUnsupportedViewModel Remote Model Unsupported View Model
    
    % Copyright 2013-2022 The MathWorks, Inc.
    
    properties (Constant)
        TextLengthLimit = 8000;
    end
    
    properties (Transient)
        Provider;
    end

    properties
        parentID;
    end
    
    methods
        function this = RemoteUnsupportedViewModel(parentDocument, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.MLUnsupportedViewModel(variable.DataModel, viewID, userContext);
            this.Provider = parentDocument.Provider;
            this.viewID = viewID;
            this.parentID = parentDocument.DocID;
            
            viewInfo = struct('name', variable.Name, 'viewID', viewID);
            this.Provider.addView(parentDocument.DocID, this.viewID, viewInfo);
            this.Provider.setUpProviderListeners(this, this.viewID);            
        end
        
        function handlePropertySet(~,~,~)
        end
        
        function handlePropertyDeleted(~,~,~)
        end
        
        function handleEventFromClient(this, ~, ed)
            if isfield(ed.data,'source') && strcmp('server',ed.data.source)
                return;
            end
            if isfield(ed.data,'type')
                switch ed.data.type
                    case 'getData'
                        this.cachedData(ed.data);
                    otherwise
                        this.sendErrorMessage(getString(message(...
                            'MATLAB:codetools:variableeditor:UnsupportedRequest', ... 
                            ed.data.type)));
                end
            end
        end
        
        function data=cachedData(this, varargin)
            data = this.getRenderedData();
            this.dispatchEventToClient(struct('type', 'setData', 'source', 'server',...
                                        'data',data));
        end
        
        function renderedData = getRenderedData(this,varargin)
            renderedData = getRenderedData@internal.matlab.variableeditor.MLUnsupportedViewModel(this);
                        
            % Truncate the length of the text to avoid excessive bandwidth
            % consumption.
            if length(renderedData)>internal.matlab.variableeditor.peer.RemoteUnsupportedViewModel.TextLengthLimit
                 renderedData = sprintf('%s\n...',renderedData(1:internal.matlab.variableeditor.peer.RemoteUnsupportedViewModel.TextLengthLimit));
            end
                 
        end 
        
        % Calls into the provider to send an event to the client
        function dispatchEventToClient(this, eventObj)
            this.Provider.dispatchEventToClient(this, eventObj, this.viewID);
        end
        
         function sendErrorMessage(this, message)
            eventObj = struct('type','error','message',message,'source','server');
            this.dispatchEventToClient(eventObj);
         end

         function delete(this)
            if ~isempty(this.Provider) && isvalid(this.Provider)
                this.Provider.deleteView(this.parentID +  "_" + this.viewID);
            end
        end
    end
    
    methods(Access=protected)
        function handleDataChangedOnDataModel(this, es ,ed)
            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.MLUnsupportedViewModel(es, ed);
            this.cachedData({});
        end
        
        function refresh(this, varargin)
            cachedData(this, varargin{:});
        end
    end
end
