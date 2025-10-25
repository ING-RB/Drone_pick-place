classdef (Abstract) Constants < handle
    % Constants: This calss holds all the string constants used in the
    % MetadataApp code
    
    % Copyright 2020-2023 The MathWorks, Inc.
    properties(Constant)
        UpdateModelEvent = 'UpdateModelEvent'
        CleanUpAppEvent = 'CleanUpAppEvent'
        RegistrationErrorEvent = 'RegistrationErrorEvent'
        RegistrationSuccessEvent = 'RegistrationSuccessEvent'
        
        Register = 'Register'
        Update = 'Update'
        Deregister = 'Deregister'
        
        PackagePrefix = '+'
        PackageSeperator = '.'

        ClassFolderPrefix = '@'
        
        ComponentName = 'componentName'
        Components = 'Components'
        Status = 'status'
        ClassName = 'className'
        
        MetadataDir = 'resources'
        MetadataFile = 'appDesigner.json'
        
        UserComponentSuperclass = 'matlab.ui.componentcontainer.ComponentContainer'
        ImageFormatRegex = '(?<=\/)\w*(?=;)'
        TempDir = 'UserComponentsMetadata'
        
        Registered = 'Registered'
        NotRegistered = 'Not Registered'
        MissingFile = 'Missing File'
        
        MyComponents = string(message('MATLAB:appdesigner:usercomponentmetadata:MyComponents'))
        Left = 'Left'
        
        PNGImageFormat = 'png'
        DefaultVersion = '1.0'
        EmailRegex = '.+@[a-zA-Z0-9-.]{1,64}\.[a-zA-Z]{2,64}$'
        VersionRegex = '^\d+\.\d+$'
        
        Ok = string(message('MATLAB:appdesigner:usercomponentmetadata:OkLabel'))
        Cancel = string(message('MATLAB:appdesigner:usercomponentmetadata:CancelLabel'))
        AddPath = string(message('MATLAB:appdesigner:usercomponentmetadata:AddPathLabel'))
        
        UserComponentPackagePath = {'toolbox', 'matlab', 'appdesigner', 'appdesigner', '+appdesigner', '+internal', '+usercomponent', '+metadata'}
        SchemaFileName = 'appDesignerSchema.json'
        
        MessageCatalogPrefix = 'MATLAB:appdesigner:usercomponentmetadata:'
        MaxFilePathLength = 76;
        
        DefaultComponentIcon = 'default_component_icon.png'
        HelpIcon = 'help.svg'
        FolderIcon = 'folder_24.png'
        
        MATLABRelease = 'MATLABRelease'
        Schema = 'schema'
        
        Pixels = 'pixels'
        
        ComponentLibIconSize = [24 24]
    end
    
end