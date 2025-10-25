classdef GenericEventData < event.EventData
    % Class introduced for compatibility with peer model. Event data is
    % expected to have methods in peerModel as it is a java object. This
    % class mimics that object.
    
    % Copyright 2019 The MathWorks, Inc.
    
    % TAG: PeerNodeShim
    
    properties(SetAccess='private', GetAccess='public')
        Type;
        Target;
        Originator;
        Data;
        SrcLang;
    end
    
    methods
        function this = GenericEventData(type, varargin)
            narginchk(2, 5);
            this.Type = type;
            
            this.SrcLang = [];
            if nargin >= 4
                this.Originator = varargin{1};
                this.Target = varargin{2};
                this.Data = varargin{3};
                if nargin == 5
                    this.SrcLang = varargin{4};
                end
            else
                this.Target = varargin{1};
                if nargin == 3
                    this.Data = varargin{2};
                end
            end
            
            if iscell(this.Data)
                this.Data = appdesservices.internal.peermodel.convertPvPairsToStruct(this.Data);
            elseif isa(this.Data, 'java.util.HashMap')
                this.Data = appdesservices.internal.peermodel.convertJavaMapToStruct(this.Data);
            end
            this.Data = viewmodel.internal.convertJSONCompatibleToMatlab(this.Data);
        end        
        
        % ====================================================
        % The following method is to be compatible with PeerModel API
        function data = getData(this)
            if isstruct(this.Data)
                data = viewmodel.internal.interface.eventdata.StructData(this.Data);
            else
                data = this.Data;
            end
        end
        
        function type = getType(this)
            type = this.Type;
        end
        
        function target = getTarget(this)
            target = this.Target;
        end
        
        function originator = getOriginator(this)            
            originator = this.Originator;
        end
        
        function isFromClient = isFromClient(this)        
            if ~isempty(this.SrcLang)
                isFromClient = strcmp(this.SrcLang, 'JS') || ...
                    (~isempty(this.Originator) && strcmp(this.Originator, this.AD_TEST_SimulatedClientOriginatedEvent)); % for TEST ONLY: need a better way to simulate client event
                    
            else
                % MATLAB implemented MF0ViewModel
                isFromClient = ~isempty(this.Originator);
            end
            
        end
    end

    properties (Constant)
        % For test only
        AD_TEST_SimulatedClientOriginatedEvent = 'AD_TEST_SimulatedClientOriginatedEvent';
    end
end

