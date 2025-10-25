classdef OutputFormat < handle
    %OutputFormat Define Report Explorer output types
    
    %   Copyright 2020-2024 The MathWorks, Inc.

    methods (Static)
        function format = getFormat(id)
            import rptgen.internal.output.OutputFormat
            registry = OutputFormat.Registry;
            format = registry(char(id));
        end
        
        function formats = listAllFormats()
            import rptgen.internal.output.OutputFormat
            registry = OutputFormat.Registry;
            formats = values(registry);
            sortProp = cellfun(@(format) toString(format),formats);
            [~,idxs] = sort(sortProp);
            formats = formats(idxs);
        end
        
        function descs = listAllDescriptions()
            import rptgen.internal.output.OutputFormat
            formats = OutputFormat.listAllFormats();
            descs = cellfun(@(format) char(getDescription(format)), ...
                formats,'UniformOutput', false);
        end
        
        function ids = listAllIDs()
            import rptgen.internal.output.OutputFormat
            formats = OutputFormat.listAllFormats();
            ids = cellfun(@(format) char(getID(format)),formats, ...
                'UniformOutput', false);
        end
        
    end
    
    properties (Access= protected, Constant)
        PREF_VISIBLE string = "visible"
        PREF_EXTENSION string = "extension";
        PREF_IMAGESL string = "imagesl";
        PREF_IMAGESF string = "imagesf";
        PREF_IMAGEHG string = "imagehg";
        SETTINGS_TYPE_INFO string = "typeinfo";
    end 
    
    properties

        ID {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ID, ...
            'string')} = []
        
        Description {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(Description,'string')} = []
        
        Visible logical = false
        
        VisibleDefault logical = false
        
        ExtensionDefault {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ExtensionDefault,'string')} = []
        
        Extension {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(Extension,'string')} = []

        ImageHG {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageHG,'string')} = []
        
        ImageFormatHG {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageFormatHG, ...
            'rptgen.internal.output.ImageFormat')} = []
        
        ImageHGDefault {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageHGDefault,'string')} = []
        
        ImageSL {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageSL,'string')} = []
        
        ImageFormatSL {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageFormatSL, ...
            'rptgen.internal.output.ImageFormat')} = []
        
        ImageSLDefault {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageSLDefault,'string')} = []
                
        ImageSF {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageSF,'string')} = []
        
        ImageFormatSF {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageFormatSF, ...
            'rptgen.internal.output.ImageFormat')} = []
        
        ImageSFDefault {rptgen.internal.validator. ...
            mustBeObjectOrEmpty(ImageSFDefault,'string')} = []
        
    end
    
    properties (GetAccess=public,SetAccess=private)
        CleanFiles logical = false;
    end
    
    methods (Access=protected)
        
        function obj = OutputFormat(varargin)
            % obj = OutputFormat(newID,defaultVisible,theDescription)
            %
            % obj =OutputFormat(newID,defaultVisible,theDescription
            % defaultExtension,imageHG,imageSL,imageSF)
            
            obj.ID = varargin{1};
            obj.VisibleDefault = varargin{2};
            if obj.isJavaDesktop() && usejava("jvm")
                % JAVA desktop uses JAVA preference panel, that cache data
                % using JAVA preferences
                obj.Visible = javaMethod('getBooleanPref',...
                    'com.mathworks.services.Prefs', ...
                    makePrefsKey(obj,obj.PREF_VISIBLE),obj.VisibleDefault);
            else
                % Use MATLAB settings, if exists                
                s = settings;
                sid = obj.getIdForSettings(lower(obj.ID));
                try
                    obj.Visible = s.rptgen.(obj.SETTINGS_TYPE_INFO).(sid).(obj.PREF_VISIBLE).ActiveValue;
                catch
                    obj.Visible = obj.VisibleDefault;
                end
            end
            obj.Description = varargin{3};
            
            if nargin > 3
                obj.ExtensionDefault = varargin{4};
                obj.ImageHGDefault = varargin{5};
                obj.ImageSLDefault = varargin{6};
                obj.ImageSFDefault = varargin{7};
            end
            
        end
        
        function key =makePrefsKey(obj, propName)
            key = "rptgen.typeinfo." + lower(obj.ID) + "." + propName;
        end
              
    end
    
    methods (Static)
    
        function v = FORMAT_DB, v = "db"; end
        function v = FORMAT_HTML, v = "html"; end
        function v = FORMAT_FOT, v = "fot"; end
        function v = FORMAT_PDF_FOP, v = "pdf-fop"; end
        function v = FORMAT_RTF97, v = "rtf97"; end
        function v = FORMAT_DOC_RTF, v = "doc-rtf"; end
        function v = FORMAT_DOM_DOCX, v = "dom-docx"; end
        function v = FORMAT_DOM_HTMX, v = "dom-htmx"; end
        function v = FORMAT_DOM_HTMX_MULTIPAGE, v = "dom-htmx-multipage"; end
        function v = FORMAT_DOM_HTML_FILE, v  = "dom-html-file"; end
        function v = FORMAT_DOM_PDF, v  = "dom-pdf"; end
        function v = FORMAT_DOM_PDF_DIRECT, v  = "dom-pdf-direct"; end
        function v = FORMAT_DOM_PDFA_DIRECT, v  = "dom-pdfa-direct"; end
        
    end
    
    methods
        
        
        function desc = toString(obj)
            % Returns the unique ID
            desc = obj.Description;
        end
    
        function id = getID(obj)
            % Getter for property ID.
            % @return Value of property ID.
            id = obj.ID;
        end

        function resetToDefaults(obj)
            % Sets the Extension, Visible, ImageSL,ImageSF,ImageHG prefs 
            % to their default values
            setExtension(obj, getExtensionDefault(obj));
            setVisible(obj, getVisibleDefault(obj));
            setImageSL(obj, getImageSLDefault(obj));
            setImageSF(obj, getImageSFDefault(obj));
            setImageHG(obj, getImageHGDefault(obj));
            setViewCommand(obj,"");
        end
        

        function ext = getExtension(obj)
            % Getter for property Extension.
            if isempty(obj.Extension)
                if obj.isJavaDesktop() && usejava("jvm")
                    % JAVA desktop uses JAVA preference panel, that cache data
                    % using JAVA preferences
                    extension = javaMethod('getStringPref',...
                        'com.mathworks.services.Prefs', ...
                        makePrefsKey(obj,obj.PREF_EXTENSION),obj.ExtensionDefault);
                else
                    % Use MATLAB settings
                    stypeInfo = obj.getRptgenTypeInfoSettings();
                    sid = obj.getIdForSettings(lower(obj.ID));
                    extension = stypeInfo.(sid).(obj.PREF_EXTENSION).ActiveValue;
                    if isempty(extension)
                        extension = obj.ExtensionDefault;
                    end
                end
                obj.Extension = string(char(extension));
            end
            ext = obj.Extension;
        end
    
        end
        
        methods (Static)
            
            function ext = getFileExtension(formatID)
                % A convenience method for quickly getting the extension associated with an output format
                import rptgen.internal.output.OutputFormat
                format = OutputFormat.getFormat(formatID);
                ext = getExtension(format);
            end
            
        end
         
        methods (Access=protected)
            function ext = getExtensionDefault(obj)
                ext = obj.ExtensionDefault;
            end
        end
     
     methods 
    
         function setExtension(obj, newExtension)
             % Setter for property Extension.
             % @param newExtension New value of property Extension.
             obj.Extension = newExtension;

             if obj.isJavaDesktop() && usejava("jvm")
                 % JAVA desktop uses JAVA preference panel, that cache data
                 % using JAVA preferences
                 javaMethod('setStringPref',...
                     'com.mathworks.services.Prefs', ...
                     makePrefsKey(obj,obj.PREF_EXTENSION),obj.Extension);
             else
                 % Use MATLAB settings
                 stypeInfo = obj.getRptgenTypeInfoSettings();
                 sid = obj.getIdForSettings(lower(obj.ID));
                 stypeInfo.(sid).(obj.PREF_EXTENSION).PersonalValue = obj.Extension;
             end
         end
    
         function desc = getDescription(obj)
             % Getter for property Description.
             % @return Value of property Description.
             desc = obj.Description;
         end
    
         function formatID = getImageSL(obj)
             % Get the default image format used for SL.
             % Note: gets from the prefs file.
             if isempty(obj.ImageSL)
                 if obj.isJavaDesktop() && usejava("jvm")
                     % JAVA desktop uses JAVA preference panel, that cache
                     % data using JAVA preferences
                     format = javaMethod('getStringPref',...
                         'com.mathworks.services.Prefs', ...
                         makePrefsKey(obj,obj.PREF_IMAGESL),getImageSLDefault(obj));
                 else
                     % Use MATLAB settings
                     stypeInfo = obj.getRptgenTypeInfoSettings();
                     sid = obj.getIdForSettings(lower(obj.ID));
                     format = stypeInfo.(sid).(obj.PREF_IMAGESL).ActiveValue;
                     if isempty(format)
                         format = getImageSLDefault(obj);
                     end
                 end
                  obj.ImageSL = string(char(format));
             end
             formatID = obj.ImageSL;
         end
         
         function setImageSL(obj, newImageSL)
             % Set the default image format used for SF
             %  Note: sets the prefs file
             obj.ImageSL = newImageSL;

             if obj.isJavaDesktop() && usejava("jvm")
                 % JAVA desktop uses JAVA preference panel, that cache data
                 % using JAVA preferences
                 javaMethod('setStringPref',...
                     'com.mathworks.services.Prefs', ...
                     makePrefsKey(obj,obj.PREF_IMAGESL),obj.ImageSL);
             else
                 % Use MATLAB settings
                 stypeInfo = obj.getRptgenTypeInfoSettings();
                 sid = obj.getIdForSettings(lower(obj.ID));
                 stypeInfo.(sid).(obj.PREF_IMAGESL).PersonalValue = obj.ImageSL;
             end
         end
       
         function format = getImageFormatSL(obj)
             import rptgen.internal.output.ImageFormat
             if isempty(obj.ImageFormatSL) || ...
                     getID(obj.ImageFormatSL) ~= getImageSL(obj)
                 obj.ImageFormatSL = ImageFormat.getFormat(getImageSL(obj));
             end
             format = obj.ImageFormatSL;
         end
         
         function setImageFormatSL(obj,newFormat)
             import rptgen.internal.output.ImageFormat
             obj.ImageFormatSL = newFormat;
             if ~isempty(newFormat)
                 setImageSL(obj, getID(newFormat));
             end
         end
         
         function formatID = getImageSF(obj)
             % Get the default image format used for SF.
             % Note: gets from the prefs file.
             if isempty(obj.ImageSF)
                 if obj.isJavaDesktop() && usejava("jvm")
                     % JAVA desktop uses JAVA preference panel, that cache
                     % data using JAVA preferences
                     format = javaMethod('getStringPref',...
                         'com.mathworks.services.Prefs', ...
                         makePrefsKey(obj,obj.PREF_IMAGESF),getImageSFDefault(obj));
                 else
                     % Use MATLAB settings
                     stypeInfo = obj.getRptgenTypeInfoSettings();
                     sid = obj.getIdForSettings(lower(obj.ID));
                     format = stypeInfo.(sid).(obj.PREF_IMAGESF).ActiveValue;
                     if isempty(format)
                         format = getImageSFDefault(obj);
                     end
                 end
                 obj.ImageSF = string(char(format));
             end
             formatID = obj.ImageSF;
         end
    
         function format = getImageFormatSF(obj)
             import rptgen.internal.output.ImageFormat
             if isempty(obj.ImageFormatSF) || getID(obj.ImageFormatSF) ~= getImageSF(obj)
                 obj.ImageFormatSF = ImageFormat.getFormat(getImageSF(obj));
             end
             format = obj.ImageFormatSF;
         end
    
         function setImageFormatSF(obj,newFormat)
             import rptgen.internal.output.ImageFormat
             obj.ImageFormatSF = newFormat;
             if ~isempty(newFormat)
                 setImageSF(obj, getID(newFormat));
             end             
         end
    
         function setImageSF(obj,newImageSF)
             % Set the default image format used for SF
             %  Note: sets the prefs file
             %/
             obj.ImageSF = newImageSF;

             if obj.isJavaDesktop() && usejava("jvm")
                 % JAVA desktop uses JAVA preference panel, that cache data
                 % using JAVA preferences
                 javaMethod('setStringPref',...
                     'com.mathworks.services.Prefs', ...
                     makePrefsKey(obj,obj.PREF_IMAGESF),obj.ImageSF);
             else
                 % Use MATLAB settings
                 stypeInfo = obj.getRptgenTypeInfoSettings();
                 sid = obj.getIdForSettings(lower(obj.ID));
                 stypeInfo.(sid).(obj.PREF_IMAGESF).PersonalValue = obj.ImageSF;
             end
         end
         
         function formatID = getImageHG(obj)
             % Get the default image format used for HG.
             % Note: gets from the prefs file.
             if isempty(obj.ImageHG)
                 if obj.isJavaDesktop() && usejava("jvm")
                     % JAVA desktop uses JAVA preference panel, that cache
                     % data using JAVA preferences
                     format = javaMethod('getStringPref',...
                         'com.mathworks.services.Prefs', ...
                         makePrefsKey(obj,obj.PREF_IMAGEHG),getImageHGDefault(obj));
                 else
                     % Use MATLAB settings
                     stypeInfo = obj.getRptgenTypeInfoSettings();
                     sid = obj.getIdForSettings(lower(obj.ID));
                     format = stypeInfo.(sid).(obj.PREF_IMAGEHG).ActiveValue;
                     if isempty(format)
                         format = getImageHGDefault(obj);
                     end
                 end
                 obj.ImageHG = string(char(format));
             end
             formatID = obj.ImageHG;
         end
         
         function setImageHG(obj,newImageHG)
             % Set the default image format used for HG
             %  Note: sets the prefs file
             obj.ImageHG = newImageHG;

             if obj.isJavaDesktop() && usejava("jvm")
                 % JAVA desktop uses JAVA preference panel, that cache data
                 % using JAVA preferences
                 javaMethod('setStringPref',...
                     'com.mathworks.services.Prefs', ...
                     makePrefsKey(obj,obj.PREF_IMAGEHG),obj.ImageHG);
             else
                 % Use MATLAB settings
                 stypeInfo = obj.getRptgenTypeInfoSettings();
                 sid = obj.getIdForSettings(lower(obj.ID));
                 stypeInfo.(sid).(obj.PREF_IMAGEHG).PersonalValue = obj.ImageHG;
             end
         end
    
         function setImageFormatHG(obj,newFormat)
             obj.ImageFormatHG = newFormat;
             if ~isempty(newFormat)
                 setImageHG(obj, getID(newFormat));
             end
         end

         function format = getImageFormatHG(obj)
             import rptgen.internal.output.ImageFormat
             if isempty(obj.ImageFormatHG) || getID(obj.ImageFormatHG) ~= getImageHG(obj)
                 obj.ImageFormatHG = ImageFormat.getFormat(getImageHG(obj));
             end
             format = obj.ImageFormatHG;
         end
         
         function tf = getVisible(obj)
             %no need to consult prefs.  visible is initialized at startup
             tf = obj.Visible;
         end
         
         function setVisible(obj,newVisible)
             if obj.isJavaDesktop() && usejava("jvm")
                 % JAVA desktop uses JAVA preference panel, that cache data
                 % using JAVA preferences
                 javaMethod('setBooleanPref',...
                     'com.mathworks.services.Prefs', ...
                     makePrefsKey(obj,obj.PREF_VISIBLE),newVisible);
             else
                 % Use MATLAB settings
                 stypeInfo = obj.getRptgenTypeInfoSettings();
                 sid = obj.getIdForSettings(lower(obj.ID));
                 stypeInfo.(sid).(obj.PREF_VISIBLE).PersonalValue = newVisible;
             end

             obj.Visible = newVisible;
         end

         function cmd = getViewCommand(obj)
             % Convenience method.  Note that view command is actually
             % mapped to the extension, not the outputformat
             if obj.isJavaDesktop() && usejava("jvm")
                 % JAVA desktop uses JAVA preference panel
                 cmd = javaMethod('getViewCommand', ...
                     'com.mathworks.toolbox.rptgencore.tools.RptgenPrefsPanel', ...
                     getExtension(obj));
             else
                 % Use JS-based preference panel
                 cmd = matlab.ui.internal.preferences.preferencePanels.RptgenPreferencePanel.getViewCommand(getExtension(obj));
             end
         end
         
         function setViewCommand(obj,newCmd)
             % Convenience method.  Note that view command is actually
             % mapped to the extension, not the outputformat
             if obj.isJavaDesktop() && usejava("jvm")
                 % JAVA desktop uses JAVA preference panel
                 javaMethod('setViewCommand',...
                     'com.mathworks.toolbox.rptgencore.tools.RptgenPrefsPanel', ...
                     getExtension(obj),newCmd);
             else
                 % Use JS-based preference panel
                 matlab.ui.internal.preferences.preferencePanels.RptgenPreferencePanel.setViewCommand(getExtension(obj), newCmd);
             end
         end
 
         function tf = getCleanFiles(obj)
             % Tells the Report Generator whether or not to delete the
             % files in /file_ext_files after generation.
             % This is an inherent property of the format and
             % is not customizable.
             tf = obj.CleanFiles;
         end
    
       end
      
       methods (Access=protected)
           
           function formatID = getImageSLDefault(obj)
               % Return the value to use in case it doesn't exist in the
               % prefs file
               formatID = obj.ImageSLDefault;
           end          
           
           function formatID = getImageSFDefault(obj)
               % Return the value to use in case it doesn't exist in the
               % prefs file
               formatID = obj.ImageSFDefault;           
           end
   
           function formatID = getImageHGDefault(obj)
               % Return the value to use in case it doesn't exist in the prefs file
               %/
               formatID = obj.ImageHGDefault;
           end
           
           function tf = getVisibleDefault(obj)
               %no need to consult prefs.  visible is initialized at startup
               tf = obj.VisibleDefault;
           end
                
       end
    
    
    methods (Static,Access=private)
        
        function registry = Registry()
            import rptgen.internal.output.OutputFormat
            persistent REGISTRY
            if isempty(REGISTRY)
                REGISTRY = containers.Map('KeyType', 'char', ...
                    'ValueType', 'any');
                OutputFormat.buildRegistry(REGISTRY);
            end
            registry = REGISTRY;
        end
        
        function registerFormats(registry,formats)
            nFormats = numel(formats);
            for i=1:nFormats
                format = formats(i);
                registry(char(format.ID)) = format;
            end
        end
        
        function msg = localize(msgID)
            msg = string(message("rptgen:java_rptgencore:"+msgID));
        end
        
        function buildRegistry(registry)
            import rptgen.internal.output.*
            
            of = {};
            of{1} = OutputFormat(OutputFormat.FORMAT_DB,true,OutputFormat.localize("formatDocBook"),"xml","png","png","png");
            
            of{end+1} = OutputFormatXSLT(OutputFormat.FORMAT_HTML,true,OutputFormat.localize("formatHTML"),"html","png","png","png");
            of{end+1} = OutputFormatXSLT(OutputFormat.FORMAT_FOT,false,OutputFormat.localize("formatFO"),"fo","png","svg","svg");
            
            of{end+1} = OutputFormatFOP(OutputFormat.FORMAT_PDF_FOP,true,OutputFormat.localize("formatAcrobat"),"pdf","png","svg","svg", 'application/pdf');
            of{end}.CleanFiles = true;
            
            if ispc
                of{end+1} = OutputFormatDSSSL(OutputFormat.FORMAT_RTF97,true,OutputFormat.localize("formatRTF"),"rtf","wmf","wmf","wmf", "rtf","RTF97");
                of{end+1} = OutputFormatDSSSL(OutputFormat.FORMAT_DOC_RTF,true,OutputFormat.localize("formatDoc"),"doc","wmf","wmf","wmf", "rtf","RTF97");
                of{end}.CleanFiles = true;
            else
                % Simulink and Stateflow no longer support encapsulated PostScript.
                of{end+1} = OutputFormatDSSSL(OutputFormat.FORMAT_RTF97,true,OutputFormat.localize("formatRTF"),"rtf","png","png","png", "rtf","RTF97");
                of{end+1} = OutputFormatDSSSL(OutputFormat.FORMAT_DOC_RTF,true,OutputFormat.localize("formatDoc"),"doc","png","png","png", "rtf","RTF97");
            end
            
            of{end+1} = OutputFormatDB2DOM(OutputFormat.FORMAT_DOM_DOCX, true, OutputFormat.localize("formatDOM_DOCX"), "docx", "png", "png", "png");
            of{end}.CleanFiles = true;
            of{end+1} = OutputFormatDB2DOM(OutputFormat.FORMAT_DOM_HTMX, true, OutputFormat.localize("formatDOM_HTML"), "zip", "png", "png", "png");
            of{end}.CleanFiles = true;
            of{end+1} = OutputFormatDB2DOM(OutputFormat.FORMAT_DOM_HTMX_MULTIPAGE, true, OutputFormat.localize("formatDOM_HTML_MULTIPAGE"), "zip", "png", "png", "png");
            of{end}.CleanFiles = true;
            of{end+1} = OutputFormatDB2DOM(OutputFormat.FORMAT_DOM_HTML_FILE, true, OutputFormat.localize("formatDOM_HTML_File"), "html", "png", "png", "png");
            of{end}.CleanFiles = true;
            of{end+1} = OutputFormatDB2DOM(OutputFormat.FORMAT_DOM_PDF, true, OutputFormat.localize("formatDOM_PDF"), "pdf", "png", "png", "png");
            of{end}.CleanFiles = true;
            of{end+1} = OutputFormatDB2DOM(OutputFormat.FORMAT_DOM_PDF_DIRECT, true, OutputFormat.localize("formatDOM_PDF_Direct"), "pdf", "png", "svg", "svg");
            of{end}.CleanFiles = true;
            of{end+1} = OutputFormatDB2DOM(OutputFormat.FORMAT_DOM_PDFA_DIRECT, true, OutputFormat.localize("formatDOM_PDFA_Direct"), "pdf", "png", "svg", "svg");
            of{end}.CleanFiles = true;
            
            nFormats = numel(of);
            for i=1:nFormats
                format = of{i};
                registry(char(format.ID)) = format;
            end
            
        end

        function stypeInfo = getRptgenTypeInfoSettings()
            % Returns the rptgen typeinfo settings. If it doesn't exist,
            % this method creates one with default values (from registry)
            % and then returns it. The typeinfo settings contains the
            % settings for all the output formats as present in the
            % registry.
            import rptgen.internal.output.OutputFormat

            % Get the MATLAB settings root object
            s = settings;

            % Check for rptgen settings
            if ~s.hasGroup("rptgen")
                s.addGroup("rptgen");
            end

            % Get the rptgen settings
            srptgen = s.rptgen;

            % Get the typeinfo settings
            if ~srptgen.hasGroup(OutputFormat.SETTINGS_TYPE_INFO)
                stypeInfo = srptgen.addGroup(OutputFormat.SETTINGS_TYPE_INFO);
            else
                stypeInfo = srptgen.(OutputFormat.SETTINGS_TYPE_INFO);
            end

            % Create settings for each output format from the registry
            registry = OutputFormat.Registry();
            keys = registry.keys;
            for iKey = 1:registry.Count
                id = keys{iKey};
                value = registry(char(id));

                % Get settings for the current output format
                idForSettings = OutputFormat.getIdForSettings(id);
                if ~stypeInfo.hasGroup(idForSettings)
                    sid = stypeInfo.addGroup(idForSettings);
                else
                    sid = stypeInfo.(idForSettings);
                end

                % Settings for the visbility of the output format
                if ~sid.hasSetting(OutputFormat.PREF_VISIBLE)
                    visibleSetting = sid.addSetting(OutputFormat.PREF_VISIBLE);
                    visibleSetting.PersonalValue = value.VisibleDefault;
                end

                % Settings for the extension of the output format
                if ~sid.hasSetting(OutputFormat.PREF_EXTENSION)
                    extnSetting = sid.addSetting(OutputFormat.PREF_EXTENSION);
                    extnSetting.PersonalValue = value.ExtensionDefault;
                end

                % Settings for the SL image format
                if ~sid.hasSetting(OutputFormat.PREF_IMAGESL)
                    imgSLSetting = sid.addSetting(OutputFormat.PREF_IMAGESL);
                    imgSLSetting.PersonalValue = value.ImageSLDefault;
                end

                % Settings for the SF image format
                if ~sid.hasSetting(OutputFormat.PREF_IMAGESF)
                    imgSFSetting = sid.addSetting(OutputFormat.PREF_IMAGESF);
                    imgSFSetting.PersonalValue = value.ImageSFDefault;
                end

                % Settings for the HG image format
                if ~sid.hasSetting(OutputFormat.PREF_IMAGEHG)
                    imgHGSetting = sid.addSetting(OutputFormat.PREF_IMAGEHG);
                    imgHGSetting.PersonalValue = value.ImageHGDefault;
                end
            end
        end

        function sid = getIdForSettings(id)
            % Update and return the id that can be used as a settings name.
            % Output format ids can not be directly used as settings id
            % because they can contain "-", for e.g., "pdf-fop". So this
            % method replaces "-" with "_" to generate a valid settings id,
            % for e.g., "pdf_fop".
            sid = replace(id, "-", "_");
        end

        function tf = isJavaDesktop()
            % Returns true for JAVA desktop and false for JavaScript
            % desktop and MATLAB Online environments.
            tf = false;

            import matlab.internal.capability.Capability;
            if Capability.isSupported(Capability.LocalClient) && ...
                    ~matlab.internal.feature("webui")
                tf = true;
            end
        end

    end

end
