classdef (Hidden) ImageController < ...
        matlab.ui.control.internal.controller.ComponentController


    % ImageController class is the controller class for
    % matlab.ui.control.Image object.

    % Copyright 2018-2021 The MathWorks, Inc.

    methods
        function obj = ImageController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
        end

        function excludedPropertyNames = getExcludedComponentSpecificPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view at Run time

            excludedPropertyNames = {'ImageSource';};
        end
    end

    methods(Access = 'protected')
        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view
            
            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);
            
            % Non-public properties that need to be sent to the view
            propertyNames = [propertyNames; {...
                'IconID';...
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

            % ImageSource Specific
            viewPvPairs = [viewPvPairs, ...
                getImagePropertiesForView(obj, propertyNames);
                ];

        end

        function handlePropertiesChanged(obj, changedPropertiesStruct)
            % Handles ImageSource property changing

            % Handle ImageSource property from peer node
            % handlePropertiesChanged() for this class gets called in two cases:
            % 1. when Image component with ImageSource property gets dragged and
            % dropped off the palette.  In this case, the ImageSource property
            % is not set
            % 2. when an app that contains image component is opened.
            % The ImageSource property may be set.
            if(isfield(changedPropertiesStruct, 'ImageSource'))
                try
                    obj.Model.ImageSource = changedPropertiesStruct.ImageSource;
                catch ex
                    % Turn off callstack for warning: by default the
                    % warning will include the callstack
                    w = warning('off', 'backtrace');

                    % Exception happens for the possible reasons:
                    % 1) Image file not in the MATLAB search path;
                    % 2) Image file is deleted;
                    % 3) Image file is damaged and not a valid image
                    % format.
                    % At such a case, load an app as possible as App Designer
                    % could, and so set ImageSource to PrivateImageSource directly to
                    % avoid value validation, and warn the user
                    obj.Model.PrivateImageSource = changedPropertiesStruct.ImageSource;

                    warning(ex.identifier, ex.message);
                    % Restore warning state
                    warning(w);
                end

                % Give others the chance to handle the remaining properties
                changedPropertiesStruct = rmfield(changedPropertiesStruct, 'ImageSource');
            end

            % Handles properties changed from client
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end

        function handleEvent(obj, src, event)

            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                % Handle changes in the property editor that needs a
                % server side validation

                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;

                if(strcmp(propertyName, 'ImageSource'))

                    % ImageSource should not have any path
                    % messes up packaging, so truncate any path
                    % from the filename.
                    [~, file, ext] = fileparts(propertyValue);
                    imageFileName = [file ext];

                    % Just after stripping the path / directory from the file
                    % Explicitly check, If the file exists on the MATLAB PATH
                    %
                    % AppDesigner accepts the files (icon / image in this case) on
                    % the Matlab path ONLY. The reason for for not
                    % accepting files which are not on the path is problems during packaging the app.
                    %
                    % Therefore, if it does not exists on the MATLAB path ,
                    % send message to the user " Add the file on the path "
                    % g1515118

                    isEmptyFileName = isempty(propertyValue) && isa(propertyValue,'char');

                    if (~isEmptyFileName)
                        if ~exist(imageFileName, 'file')

                            ex = MException(message('MATLAB:ui:components:fileNotFoundOnMatlabPath', 'ImageSource'));

                            propertySetFail(obj, ...
                                propertyName, ...
                                event.Data.CommandId, ...
                                ex);

                        end
                    end

                    setModelProperty(obj, ...
                        propertyName, ...
                        imageFileName, ...
                        event ...
                        );
                end
            elseif(strcmp(event.Data.Name, 'ImageClicked'))
                % Handles when the user clicks and releases

                % Create event data
                eventData = matlab.ui.eventdata.ImageClickedData;

                % Emit 'ImageClicked' which in turn will trigger the user callback
                obj.handleUserInteraction('ImageClicked', event.Data, {'ImageClicked', eventData});
            elseif(strcmp(event.Data.Name, 'HyperlinkClicked'))
                % Handles when the user clicks and releases

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
                
                    warning(['MATLAB:ui:Image:' mnemonicField], messageObj.getString())
                    
                end

            else

                handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
            end
        end

        function viewPvPairs = getImagePropertiesForView(obj, propertyNames)
            % GETPIMAGEROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties related to displaying an image, given the PROPERTYNAMES
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
            import appdesservices.internal.util.ismemberForStringArrays;

            viewPvPairs = {};

            if (ismemberForStringArrays("ImageSource", propertyNames))
                imageData = '';
                if (~isempty(obj.Model.ImageSource))
                    try
                        imageData = matlab.ui.internal.IconUtils.getIconForView(obj.Model.ImageSource, obj.Model.ImageType);
                    catch ex
                        % Create and throw warning
                        messageText = getString(message('MATLAB:ui:components:UnexpectedErrorInImageSourceOrIcon', 'ImageSource'));
                        matlab.ui.control.internal.model.PropertyHandling.displayWarning(obj, 'UnexpectedErrorInImageSourceOrIcon', ...
                            messageText, ':\n%s', ex.getReport());
                    end
                end

                iconPvPairs = {'IconURL', imageData};
                viewPvPairs = [viewPvPairs, ...
                    iconPvPairs, ...
                    ];
            end
        end

        function propertyNames = getAdditonalComponentSpecificPropertyNamesForView(obj)
            % GETADDITIONALCOMPONENTSPECIFICPROPERTYNAMESFORVIEW - Specify
            % per component if there are any non-public properties that
            % should be sent to the view at runtime.
            propertyNames = {'ImageClickedFcn'};
        end
    end
end


