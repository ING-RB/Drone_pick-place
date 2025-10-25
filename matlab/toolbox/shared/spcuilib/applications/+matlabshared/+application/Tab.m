classdef Tab < matlab.ui.internal.toolstrip.Tab
    properties (Hidden, SetAccess = protected)
        Sections = struct;
    end
    
    methods
        function this = Tab(id)
            this@matlab.ui.internal.toolstrip.Tab;
            this.Title = getString(message([getCatalog(this) ':' id 'TabTitle']));
            this.Tag = id;
        end
        
        function add(this, section)
            add@matlab.ui.internal.toolstrip.Tab(this, section);
            section.Tab = this;
            sectionTag = section.Tag;
            % Remove 'Section' as a trailing argument in the tag so its not repeated
            if endsWith(sectionTag, 'Section')
                sectionTag(end-6:end) = [];
            end
            this.Sections.(sectionTag) = section;
        end
        
        function s = getSection(this, tag)
            s = this.Sections.(tag);
        end
        
        function s = getAllSections(this)
            s = struct2cell(this.Sections);
            s = [s{:}];
        end
        
        function l = createSectionListener(this, cb)
            s = getAllSections(this);
            l = [event.listener(s, 'PropertyChanged', cb) event.listener(s, 'ButtonPressed', cb)];
        end
    end
    
    methods (Sealed)
        function out = eq(varargin)
            out = eq@matlab.ui.internal.toolstrip.Tab(varargin{:});
        end
    end
    
    methods (Access = protected)
        
        function catalog = getCatalog(~)
            catalog = 'Spcuilib:application';
        end
    end
end

% [EOF]
