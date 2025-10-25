classdef InterfaceManagerHelper < handle
    properties
        studio;
        im;
    end
    
    methods
        function self = InterfaceManagerHelper( studio, appname )
            self.studio = studio;
            self.im = DAS.InterfaceManager.getApplicationIM( appname );
        end
        
        function element = getAction( self, tag )
            element = self.im.getAction( self.studio, tag );
            if isempty( element )
                element = DAStudio.makeCallback( tag, @HiddenActionSchema );
            end
        end
        
        function element = getSubmenu( self, tag )
            element = self.im.getSubmenu( self.studio, tag );
            if isempty( element )
                element = DAStudio.makeCallback( tag, @HiddenContainerSchema );
            end
        end
        
        function result = isActionInstalled( self, tag )
            element = self.im.getAction( self.studio, tag );
            result = ~isempty( element );
        end
        
        function result = isSubmenuInstalled( self, tag )
            element = self.im.getSubmenu( self.studio, tag );
            result = ~isempty( element );
        end
    end
end

function schema = HiddenActionSchema( tag, ~ )
    schema = sl_action_schema;
    schema.tag = tag;
    schema.state = 'Hidden';
end 

function schema = HiddenContainerSchema( tag, ~ )
    schema = sl_container_schema;
    schema.tag = tag;
    schema.state = 'Hidden';
    schema.childrenFcns = { DAStudio.Actions( 'HiddenSchema' ) };
end 