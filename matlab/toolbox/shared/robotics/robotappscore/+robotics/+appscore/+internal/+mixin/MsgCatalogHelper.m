classdef MsgCatalogHelper < handle
    %This class is for internal use only. It may be removed in the future.
    
    %MsgCatalogHelper Mixin class that provides convenienet utility to
    %   access the message catalog

    % Copyright 2018 The MathWorks, Inc.
    
    properties 
        MsgIDPrefix
    end
    
    methods
        function [msg, msgObj] = retrieveMsg(obj, leanMsgID, varargin)
            %retrieveMsg Retrieve message catalog from lean message ID
            msgID = [obj.MsgIDPrefix ':' leanMsgID];
            [msg, msgObj] = obj.getMsg(msgID, varargin{:});
            
        end
        
        function [msg, msgObj] = getMsg(~, msgID, varargin)
            %getMsg Retrieve message catalog from full message ID
            msgObj = message(msgID, varargin{:});
            msg = getString(msgObj);

        end
        
    end
end

