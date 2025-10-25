classdef ModeChangedEventData < event.EventData
    %
    
    % Copyright 2013 The MathWorks, Inc
    
    properties(GetAccess = 'public', SetAccess = 'private')
        Type %Event type, one of {'PreModeChanged', 'PostModeChanged'}
        Data %Event data
    end
    
    methods(Access = public)
        function obj = ModeChangedEventData(varargin)
            %MODEEVENTDATA
            %
            
            %Call superclass constructor
            obj = obj@event.EventData;
            
            if nargin < 1
                type = 'PostModeChanged';
            else
                type = varargin{1};
            end
            if nargin < 2
                data = [];
            else
                data = varargin{2};
            end
            
            %Set data property
            obj.Type = type;
            obj.Data = data;
        end
    end
    
    methods
        function set.Type(this,newValue)
            %Must be one of {'PreModeChanged','PostModeChanged'}
            if ischar(newValue) && any(strcmp(newValue,{'PreModeChanged','PostModeChanged'}))
                this.Type = newValue;
            else
                error(message('Controllib:general:UnexpectedError','Invalid EventData Type'));
            end
        end
    end
end