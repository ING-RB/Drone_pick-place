classdef StructData < handle    
    % Class introduced for compatibility with peer model. Event data payload is
    % expected to have methods in peerModel as it is a java object. This
    % class mimics that object.
    
    % Copyright 2019 The MathWorks, Inc.
    
    % TAG: PeerNodeShim
    
    properties
        Data;
    end
    
    methods
        function this = StructData(data)
            this.Data = data;
        end        
        
        function data = get(this, key)
            data = [];
            
            if isfield(this.Data, key)
                data = this.Data.(key);
            end
        end
        
        function exist = containsKey(this, key)
            exist = isfield(this.Data, key);
        end
    end
end

