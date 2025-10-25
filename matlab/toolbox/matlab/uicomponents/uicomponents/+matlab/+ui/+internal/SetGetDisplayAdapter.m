classdef (Hidden) SetGetDisplayAdapter
    
    methods (Static, Hidden)
        function getForDisplay(varname, varargin)
            % GETFORSTYLEDISPLAY - Utility in the spirit of getForDisplay
            % which exists for handle graphics objects.  This utility does
            % not assume the object itself has a 'get' method, but allows
            % value classes to implement their own 'linkDisplay' which will
            % show all properties in a similiar way as get would.
            
            %Copyright  2019 The MathWorks, Inc.
            if nargin == 1
                s = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureMissingVariable',varname));
                disp(s)
            else
                obj = varargin{1};
                classname = varargin{2};
                if ~isa(obj,classname)
                    dots = strfind(classname,'.');
                    if ~isempty(dots)
                        classname = classname(dots(end)+1:end);
                    end
                    s = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureClassMismatch',varname, classname));
                    disp(s)
                else
                    try
                        linkDisplay(obj)
                    catch ME %#ok<NASGU>
                        s = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureUnknown',varname));
                        disp(s)
                    end
                end
            end
        end
    end
    
    methods (Static, Hidden)        
       
        function footer = getFooter(obj, names, variableName)
            % GETFOOTER - Specify text to appear below the property groups
            % in the object display
            footer = '';
            if  isscalar(obj)
                if nargin < 2
                    names = obj.getPropertyGroupNames();
                end
                
                if  ~(isempty(names) || ...
                        ... Don't show footer if all properties are already shown
                        numel(names) == numel(properties(obj))) 
                    FOOTER_INDENT_SPACES = "  ";
                    
                    useHotlinks = feature( 'hotlinks' ) && ~isdeployed();
                    if ~useHotlinks || isempty(variableName)
                        
                        footer =  matlab.ui.control.internal.model.PropertyHandling.createMessageWithDocLink('', 'MATLAB:graphicsDisplayText:FooterTextNoArrayName', 'properties');
                        
                    else
                        
                        className = class(obj);
                        
                        linkToShowAllPropertiesIfVariableExists = ...
                            "<a href=""matlab:if exist('"...
                            + variableName...
                            + "', 'var'), matlab.ui.internal.SetGetDisplayAdapter.getForDisplay('"...
                            + variableName...
                            + "', "...
                            + variableName...
                            + ", '"...
                            + className...
                            +"'), else, matlab.ui.internal.SetGetDisplayAdapter.getForDisplay('"...
                            + variableName...
                            +"'), end"">"...
                            + getString(message('MATLAB:graphicsDisplayText:AllPropertiesText'))...
                            +"</a>";
                        
                        % 'Show ' link text
                        footer = getString(message('MATLAB:graphicsDisplayText:FooterTextWithArrayName', linkToShowAllPropertiesIfVariableExists));
                    end
                    
                    footer = sprintf( '%s%s\n', FOOTER_INDENT_SPACES, footer );
                end
            end
        end
    end
end