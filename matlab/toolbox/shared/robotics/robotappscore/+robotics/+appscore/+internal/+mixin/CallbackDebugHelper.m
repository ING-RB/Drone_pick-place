
classdef CallbackDebugHelper < handle
    %This class is for internal use only. It may be removed in the future.
        
    %CALLBACKDEBUGHELPER Mixin class to provide debug print-out for callback data
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties
        CallbackDebug = true
    end

    methods

        function echo(obj, source, event)
            %echo
            if obj.CallbackDebug
                if isprop(source, 'Tag') && ~isempty(source.Tag)
                    src = source.Tag;
                elseif isprop(source, 'Name') && ~isempty(source.Name)
                    src = source.Name;
                else
                    src = source.Type;
                end
                fprintf('%s --- %s\n', src, event.EventName);
                
            end
        end

    end

end