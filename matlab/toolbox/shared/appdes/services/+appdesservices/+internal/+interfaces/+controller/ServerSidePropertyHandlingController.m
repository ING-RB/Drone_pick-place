classdef ServerSidePropertyHandlingController < handle
    % Controller mixin class that provides methods to set properties on the
    % server
    %
    % Controllers should mix this class in 
    
    methods
        function setServerSideProperty(obj, model, propertyName, propertyValue, commandId)
            % Sets a model property, assuming that the model property
            % needed to be set on the server.
            %
            % This provides a return message to the client if the set
            % fails.
            %
            % This method should be used whenever setting a model property
            % that could potentially error out.
            
            try
                model.(propertyName) = propertyValue;
                
                % Property setting success
                propertySetSuccess(obj, propertyName, commandId)                
            catch ex
				% setting the property failed
                propertySetFail(obj, propertyName, commandId, ex);
            end
        end
        
        function propertySetSuccess(obj, propertyName, commandId)
            % Emits and event back to the client telling it success
            %
            % This can be used as a standalone function when a model is
            % updated successfully, but setServerSideProperty was not used.
            obj.ClientEventSender.sendEventToClient('propertyEditResult',...
                { ...
                'CommandId', commandId, ...
                'Property', propertyName, ...
                'ErrorMessage', '', ...
                'Success', true
                });
        end
        
        function propertySetFail(obj, propertyName, commandId, ex)
            % setting the property failed
            message = ex.message;
            
            % g1319014, trim out any hyperlinks from the message
            %
            % When g1320050 is fixed, use getReport()
            %
            % Util now, need to manually strip out
            message = regexprep(message, '<a.*?>', '');
            message = regexprep(message, '</a>', '');
            
            % fire the event on the peer node
            obj.ClientEventSender.sendEventToClient('propertyEditResult',...
                { ...
                'CommandId',  commandId, ...
                'Property', propertyName, ...
                'ErrorMessage', message, ...
                'Success', false
                });
        end
        
        function convertedValue = convertClientNumbertoServerNumber(~, value)
         convertedValue = appdesservices.internal.util.convertClientNumberToServerNumber(value);
        end
    end
    
end