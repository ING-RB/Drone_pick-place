classdef Preferences < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (Abstract, Constant)
        Instance;
    end
    
    methods (Access = protected)
        function this = Preferences()
            
            % Get the saved preferences
            resetToCache(this);
        end
        
        function str = convertToStructure(this)
            props = getPreferenceProperties(this);
            cls   = meta.class.fromName(class(this));
            str   = struct;
            
            % Loop over each property, and check if its changed 
            for indx = 1:numel(props)
                p = cls.PropertyList.findobj('Name', props{indx});
                value = this.(props{indx});
                if ~isequal(value, p.DefaultValue)
                    str.(props{indx}) = value;
                end
            end
        end
    end
    
    methods
        function saveToCache(this)
            s = convertToStructure(this);
            app = getPreferenceTag(this);
            if isempty(s)
                rmpref(app, 'Preferences');
            else
                setpref(app, 'Preferences', s);
            end
        end
        
        function resetToCache(this)
            % Reset all preferences to those saved in the cache
            % If a property is not in the cache it will be reset to the
            % default value.
            props = getPreferenceProperties(this);
            indx  = 1;
            cache = getpref(getPreferenceTag(this), 'Preferences', []);
            
            % Loop over each property and set to the cache value if its in
            % the cache, if not in the cache, move to the next property.
            while indx <= numel(props)
                if isfield(cache, props{indx})
                    this.(props{indx}) = cache.(props{indx});
                    props(indx) = [];
                else
                    indx = indx + 1;
                end
            end
            
            % If any props were not in the cache, set it to its default
            % instead.
            if ~isempty(props)
                resetToDefaults(this, props{:});
            end
        end
        
        function resetToDefaults(this, varargin)
            if nargin > 1
                props = varargin;
            else
                props = getPreferenceProperties(this);
            end
            cls = meta.class.fromName(class(this));
            
            % Loop over each property, and check if its changed 
            for indx = 1:numel(props)
                p = cls.PropertyList.findobj('Name', props{indx});
                this.(props{indx}) = p.DefaultValue;
            end
        end
    end
    
    methods (Abstract, Access = protected)
        name  = getPreferenceTag(this)
        props = getPreferenceProperties(this)
    end    
end

% [EOF]
