classdef MetadataModel < handle & appdesigner.internal.model.AbstractAppDesignerModel
    %METADATAMODEL A model for the metadata of App Designer apps.
    %Validates and ensures consistency of the various public and private
    %metadata fields.
    %
    % Generally, sets of the wrong datatype or value are ignored.  This
    % class does not error as 1) public metadata is optional to the file
    % and 2) private metadata sets should be fully processed to ensure
    % consistency.  Errors are thrown when private metadata is set to
    % invalid values or datatypes.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    properties
        % Public metadata
        Name = ''
        Author = ''
        Version = '1.0'
        Summary = ''
        Description = ''
        
        % Internal metadata - loading related
        MATLABRelease = appdesigner.internal.serialization.util.ReleaseUtil.getCurrentRelease()
        MinimumSupportedMATLABRelease = 'R2018a'
        MLAPPVersion = appdesigner.internal.serialization.app.AppVersion.MLAPPVersionTwo
        AppType = appdesigner.internal.serialization.app.AppTypes.StandardApp
        % RequiredProducts is a cellstr
        RequiredProducts = {}
        % UserComponents is a cellstr
        UserComponents = {}
        ImageRelativePaths = {}
        
        % Internal metadata - dictates source of the screenshot
        ScreenshotMode = 'auto'
    end
    
    properties (Dependent)
        % Internal metadata - Other
        % Uuid is used to uniquely identify the app for DDUX.
        Uuid
    end
    
    properties (Access = private)
        % Storage for the Uuid dependent property
        PrivateUuid = '';
    end
    
    methods
        function obj = MetadataModel(appModel, proxyView)
            if (nargin > 0)
                appModel.MetadataModel = obj;
                obj.createController(proxyView);
            end
        end
        
        function controller = createController(obj,  proxyView)
            % Creates the controller for this Model.  this method is the
            % concrete implementation of the abstract method from
            % appdesigner.internal.model.AbstractAppDesignerModel
            
            controller = appdesigner.internal.controller.MetadataController(obj, proxyView);
            controller.populateView(proxyView);
        end        

        function setDataOnSerializer(obj, serializer)
            serializer.Metadata = obj;
        end
    end
    
    % Setters & getters
    methods (Access = private)
        function val = convertToCellStr(obj, val)
            val = convertStringsToChars(val);
            
            if ~(iscellstr(val) || isempty(val))
                % Valid values are cellstrs.  The view sends [] for an
                % empty value, which is technically a double.  That value
                % is still acceptable, but it must be converted.
                propName = inputname(1);
                error('appdesigner:metadata:InvalidValue', 'Invalid %s', propName);
            end
            
            if ~iscell(val) && isempty(val)
                val = {};
            end
        end
    end
    methods
        function set.MATLABRelease(obj, val)
            import appdesigner.internal.serialization.util.ReleaseUtil;
            val = convertStringsToChars(val);
            if ~ischar(val) || ~ReleaseUtil.isValidReleaseString(val)
                error('appdesigner:metadata:InvalidValue', 'Invalid MATLABRelease.');
            end
            
            obj.MATLABRelease = val;
        end
        
        function set.MinimumSupportedMATLABRelease(obj, val)
            import appdesigner.internal.serialization.util.ReleaseUtil;
            val = convertStringsToChars(val);
            if ~ischar(val) || ~ReleaseUtil.isValidReleaseString(val)
                error('appdesigner:metadata:InvalidValue', 'Invalid MinimumSupportedMATLABRelease.');
            end

            obj.MinimumSupportedMATLABRelease = val;
        end
        
        function set.AppType(obj, val)
            import appdesigner.internal.serialization.app.AppTypes;
            
            % Valid values are 'Standard', 'Responsive'.  Use the AppTypes
            % enum as an additional safeguard.
            val = convertStringsToChars(val);
            
            if ~ischar(val)
                error('appdesigner:metadata:InvalidValue', 'Invalid AppType.');
            end
            
            switch val
                case {AppTypes.StandardApp, AppTypes.ResponsiveApp, AppTypes.UserComponentApp}
                    obj.AppType = val;
                otherwise
                    error('appdesigner:metadata:InvalidValue', 'Invalid AppType.');
            end
        end
        
        function set.MLAPPVersion(obj, val)
            % Valid values are '1' and '2'
            import appdesigner.internal.serialization.app.AppVersion;
            val = convertStringsToChars(val);
            
            if ~ischar(val)
                error('appdesigner:metadata:InvalidValue', 'Invalid MLAPPVersion.');
            end
            
            switch val
                case {AppVersion.MLAPPVersionOne, AppVersion.MLAPPVersionTwo}
                    obj.MLAPPVersion = val;
                case ''
                    obj.MLAPPVersion = ''; % plain-text will not write an MLAPP version
                otherwise
                    error('appdesigner:metadata:InvalidValue', 'Invalid MLAPPVersion.');
            end
        end
        
        function set.ScreenshotMode(obj, val)
            % Valid values are auto/manual/none
            val = convertStringsToChars(val);
            
            if ~ischar(val)
                error('appdesigner:metadata:InvalidValue', 'Invalid ScreenshotMode.');
            end
            
            switch val
                case {'auto', 'manual', 'none'}
                    obj.ScreenshotMode = val;
                otherwise
                    error('appdesigner:metadata:InvalidValue', 'Invalid ScreenshotMode.');
            end
        end
        
        function set.RequiredProducts(obj, val)
            obj.RequiredProducts = convertToCellStr(obj, val);
        end

        function set.ImageRelativePaths(obj, val)
            obj.ImageRelativePaths = convertToCellStr(obj, val);
        end
        
        function set.UserComponents(obj, val)
            obj.UserComponents = convertToCellStr(obj, val);
        end
        
        function set.Uuid(obj, val)
            % Only allow setting the Uuid if it is already empty.
            if isempty(obj.PrivateUuid) && ischar(val) || strcmp(val, obj.PrivateUuid)
                obj.PrivateUuid = val;
            else
                error('appdesigner:metadata:InvalidValue', 'Invalid Uuid.');
            end
        end
        
        function val = get.Uuid(obj)
            % Uuid is a new field introduced into Metadata in 18b for
            % instrumenting DDUX into App Designer. Uuid is used as an app
            % indentifier for tracking app's lifecycle, and linking app to
            % the DDUX logged data, for an instance, loading and saving
            % performance.
            %
            % Uuid is not a user-visible property, and is auto-generated
            % during serialization .mlapp file.
            %
            % From architecture perspective, this method is a single entry
            % point to create Uuid for an app.
            
            % There are two scenarios: Uuid exists or not.
            % 1) Uuid does not exist
            %     - app created before this change
            %     - a new app
            %     - GUIDE app converter creates .mlapp file directly with
            %     MLAPPSerializer API
            %   Make sure 'Uuid' to be generated for all the cases
            % 2) Uuid exists
            %     - an app created in 18b with this change
            %   'Uuid' won't change after generation for an app.
            if isempty(obj.PrivateUuid)
                % Convert to char here as the API returns a string, and our
                % serialization infrastructure is not set up to deal with
                % strings yet.
                obj.PrivateUuid = char(matlab.lang.internal.uuid());
            end
            
            val = obj.PrivateUuid;
        end
        
        function set.Name(obj, val)
            val = convertStringsToChars(val);
            if ischar(val)
                obj.Name = val;
            else
                error('appdesigner:metadata:InvalidValue', 'Invalid Name.');
            end
        end
        
        function set.Author(obj, val)
            val = convertStringsToChars(val);
            if ischar(val)
                obj.Author = val;
            else
                error('appdesigner:metadata:InvalidValue', 'Invalid Author.');
            end
        end
        
        function set.Version(obj, val)
            val = convertStringsToChars(val);
            if ischar(val)
                obj.Version = val;
            else
                error('appdesigner:metadata:InvalidValue', 'Invalid Version.');
            end
        end
        
        function set.Summary(obj, val)
            val = convertStringsToChars(val);
            if ischar(val)
                obj.Summary = val;
            else
                error('appdesigner:metadata:InvalidValue', 'Invalid Summary.');
            end
        end
        
        function set.Description(obj, val)
            val = convertStringsToChars(val);
            if ischar(val)
                obj.Description = val;
            else
                error('appdesigner:metadata:InvalidValue', 'Invalid Description.');
            end
        end
    end
end
