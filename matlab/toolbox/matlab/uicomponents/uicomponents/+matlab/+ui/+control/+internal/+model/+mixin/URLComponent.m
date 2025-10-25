classdef (Hidden) URLComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.
    
    % This is a mixin parent class for all visual components that have a
    % 'URL' property.
    %
    % This class provides all implementation and storage for 'URL'
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(NonCopyable, Dependent, AbortSet)
        %URL - Web page address or file location to open in new browser when hyperlink is clicked
        URL = '';
    end
    properties (Access = 'protected')
        
        PrivateURL = '';
    end            
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.URL(obj, newValue)
            % Error Checking
            messageObj = [];
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateText(newValue);
                 
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTextValue', ...
                    'URL');
            end
            
            % URLS starting with matlab: are not supported with the URL
            % property
            % HyperlinkClickedFcn is the correct place to indicate MATLAB
            % code being executed
            if isempty(messageObj) && ~isempty(newValue)
                % We won't support URLS that execute matlab or javascript
                % code directly.  Erroring will set expecations immediately
                % and be less confusing to app authors.
                if startsWith(newValue, 'matlab:')
                
                    messageObj = message('MATLAB:ui:components:MATLABColon', ...
                        'matlab:', 'URL');  
                    
                elseif startsWith(newValue, 'javascript:')
                
                    messageObj = message('MATLAB:ui:components:NotSupportedInURL', ...
                        'javascript:', 'URL'); 
                else

                    splitURL = split(newValue, '.');
                
                    % If the url starts with file, be more lenient.
                    % The browser will provide the correct error indicator
                    if ~startsWith(newValue, 'file:') &&  ...
                            (numel(splitURL) < 2 || ...
                            numel(splitURL) == 2 && (startsWith(newValue, '.') ||...
                            endsWith(newValue, '.')))

                        messageObj = message('MATLAB:ui:components:MustHaveTopLevelDomain', ...
                        'URL'); 
                    end
                end
            end
            
            if ~isempty(messageObj)
                % MnemonicField is last section of error id
                mnemonicField = 'invalidURL';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throwAsCaller(exceptionObject);
            end
            
            % Property Setting
            obj.PrivateURL = newValue;
            
            % Update View
            markPropertiesDirty(obj, {'URL'});
        end
        
        function value = get.URL(obj)
            value = obj.PrivateURL;
        end
    end
end
