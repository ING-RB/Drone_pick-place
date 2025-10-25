classdef MixedInGC < handle
    properties(Access = protected)
        %Tool-Component peer
        TCPeer
    end
    
    %% Public Methods 
    methods
        function peer = getPeer(this)
            % Adding this method for back compatibility.
            peer = this.TCPeer;
        end
    end
end