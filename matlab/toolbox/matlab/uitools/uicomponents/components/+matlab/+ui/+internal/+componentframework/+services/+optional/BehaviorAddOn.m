% WEBCONTROLLER Web-based controller base class. 
classdef (Abstract) BehaviorAddOn <  handle

%   Copyright 2016-2017 The MathWorks, Inc.

    methods ( Access=protected )

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      defineViewProperties                     
         %
         %  Description: Within the context of MVC ( Model-View-Controller )   
         %               software paradigm, this is the method the "Controller"
         %               layer uses to define which properties will be consumed by
         %               the web-based user interface.
         %  Inputs:      None 
         %  Outputs:     None 
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function defineViewProperties( ~, ~ )
             % The constructor of this class calls this method on the derived
             % class. This function needs to exist for correct binding.
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      defineRenamedProperties                     
         %
         %  Description: Within the context of MVC ( Model-View-Controller )   
         %               software paradigm, this is the method the "Controller"
         %               layer uses to rename properties, which has been defined
         %               by the "Model" layer.
         %  Inputs:      None 
         %  Outputs:     None 
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function defineRenamedProperties( ~, ~ )
            % The constructor of this class calls this method on the derived
            % class. This function needs to exist for correct binding.
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      definePropertyDependencies                     
         %  Description: Within the context of MVC ( Model-View-Controller )   
         %               software paradigm, this is the method the "Controller"
         %               layer uses to establish property dependencies between 
         %               a property (or set of properties) defined by the "Model"
         %               layer and dependent "View" layer property.
         %  Inputs:      None 
         %  Outputs:     None 
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function definePropertyDependencies( ~, ~ )
            % The constructor of this class calls this method on the derived
            % class. This function needs to exist for correct binding.
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      defineRequireUpdateProperties
         %  Description: Within the context of MVC ( Model-View-Controller )
         %               software paradigm, this is the method the "Controller"
         %               layer uses to establish property which needs updates
         %               before updating them to view.
         %  Inputs:      None
         %  Outputs:     None
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

         function defineRequireUpdateProperties( ~, ~ )
            % The constructor of this class calls this method on the derived
            % class. This function needs to exist for correct binding.
         end
    end
    
    methods
        
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:  Constructor
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function this = BehaviorAddOn( propManagementService )
           if ~isempty( propManagementService )
             % Hookup the additional behavior to the Property Management Service (PMS)
             this.defineViewProperties( propManagementService );
             this.defineRenamedProperties( propManagementService );
             this.definePropertyDependencies( propManagementService );
             this.defineRequireUpdateProperties( propManagementService );
           end
         end
    end
end    
