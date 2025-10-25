classdef (Hidden) HyperlinkController < ...
		matlab.ui.control.internal.controller.ComponentController
	% HyperlinkController is the controller for Hyperlink
	
	% Copyright 2011-2021 The MathWorks, Inc.
	
	methods
        function obj = HyperlinkController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
        end
	end
	
	methods(Access = 'protected')
		
         function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view
            
            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);
            
            % Non - public properties that need to be sent to the view
            propertyNames = [propertyNames; {...
                'TooltipMode';...
                }];
         end
        
        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.

            viewPvPairs = {};
            
            % Properties from Super
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames), ...
                ];
            
        end
		function handleEvent(obj, src, event)
			% Allow super classes to handle their events
			handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
			
            
            %% Event handling goes here
			if(strcmp(event.Data.Name, 'HyperlinkClicked'))

                try
                    % Execute URL
                    if ~isempty(obj.Model.URL) && event.Data.TreatAsMATLABLink
                        web(obj.Model.URL, '-browser')
                    end
                catch me
                    
                    % MnemonicField is last section of error id
                    mnemonicField = 'failureToLaunchURL';
                    
                    messageObj = message('MATLAB:ui:components:errorInWeb', ...
                    obj.Model.URL, me.message);  
                
                    warning(['MATLAB:ui:Hyperlink:' mnemonicField], messageObj.getString())
                    
                end
				
				% Create event data
                eventData = matlab.ui.eventdata.HyperlinkClickedData;

                % Emit 'ButtonPushed' which in turn will trigger the user callback
                obj.handleUserInteraction('HyperlinkClicked', event.Data, {'HyperlinkClicked', eventData}); 
			end
		end
		
	end
end

