classdef MsgServiceContextMenuProvider < internal.matlab.datatoolsservices.contextmenuservice.ContextMenuProvider
    %MESSAGESERVICECONTEXTMENUPROVIDER This is the communicator that sends
    % contextMenuXML options across to the client upon a request. 
    
    %TODO: In case client is started standalone without server, queue
    %getContextMenuXML requests from client.
    
    % Copyright 2019-2024 The MathWorks, Inc.
    
    properties                
        msgServiceChannel = '/datatools/ContextMenuService';
        menuServiceSubscriptionHandle;
    end
    
    methods
        % xmlFile to be parsed for context menu options
        % config contains startup options
        function this = MsgServiceContextMenuProvider(xmlFile, config)
            if (nargin < 2)
                config = struct;
            end
            this@internal.matlab.datatoolsservices.contextmenuservice.ContextMenuProvider(xmlFile, config);
            this.addSubscription(config);
        end
        
        % Add msg service subscription on a channel specified by config.
        % Else, a listener will be added on a default channel
        function addSubscription(this, config)
            if isempty(this.menuServiceSubscriptionHandle)
                if isfield(config, 'channel') && ~isempty(config.channel)
                    this.msgServiceChannel = config.channel;
                end
                this.menuServiceSubscriptionHandle = message.subscribe(this.msgServiceChannel, @(msg)this.handleMessageReceived(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            end            
        end
        
        % Removes subscription already added
        function removeSubscription(this)
            message.unsubscribe(this.menuServiceSubscriptionHandle);
            this.menuServiceSubscriptionHandle = [];
        end
        
        % gets contextMenuXML that was created and sends this across to the
        % cient. NOTE: this is a struct and does not have to be
        % JSONencoded.
        function menuXML = getContextMenuXML(this)
            menuXML = this.getContextMenuXML@internal.matlab.datatoolsservices.contextmenuservice.ContextMenuProvider();          
            this.sendMessage(menuXML);
        end
        
        % publishes message on our channel. 
        function sendMessage(this, xmlMessage)            
            if ~isempty(xmlMessage)               
                message.publish(this.msgServiceChannel, xmlMessage);
            end
        end       
        
        % handles any requests received from the client and sends
        % contextMenuXML across if request is of this type.
        function handleMessageReceived(this, msg)
            if ~isempty(msg) && isfield(msg, 'requestType') && strcmp(msg.requestType, 'contextMenuXML')
                this.getContextMenuXML();
            end            
        end
        
        % Cleanup on delete
        function delete(this)
            this.removeSubscription();
        end
    end   
    
end

