classdef FunctionHelpContainer < matlab.lang.internal.introspective.containers.abstractHelpContainer
    % FUNCTIONHELPCONTAINER - stores help information for an M-function.
    % FUNCTIONHELPCONTAINER stores help information for an M-function that
    % is not a MATLAB Class Object System class definition.
    %
    % Remark:
    % Creation of this object should be made by the static 'create' method
    % of matlab.lang.internal.introspective.containers.HelpContainerFactory class.
    %
    % Example:
    %    filePath = which('addpath');
    %    helpObj = matlab.lang.internal.introspective.containers.HelpContainerFactory.create(filePath);
    %
    % The code above constructs a FUNCTIONHELPCONTAINER object.
    
    % Copyright 2009-2024 The MathWorks, Inc.
    
    methods
        function this = FunctionHelpContainer(filePath)
            % constructor takes in 'filePath' and initializes the properties
            % inherited from the superclass.

            helpFunction = matlab.lang.internal.introspective.getHelpFunction(filePath);
            if helpFunction == ""
                helpStr = help(filePath, '-noDefault');
            else
                helpStr = matlab.lang.internal.introspective.callHelpFunction(helpFunction, filePath, false);        
            end
            
            mainHelpContainer = matlab.lang.internal.introspective.containers.atomicHelpContainer(helpStr);

            pkgClassNames = matlab.lang.internal.introspective.containers.getQualifiedFileName(filePath);

            [folderPath, name] = fileparts(filePath);
            
            if matlab.lang.internal.introspective.containers.isClassDirectory(folderPath)
                % True for non-local methods defined in @class folder
                mFileName = append(pkgClassNames, '.', name);
            else
                % This ensures that packaged MATLAB files are treated correctly.
                mFileName = pkgClassNames;
            end
        
            this = this@matlab.lang.internal.introspective.containers.abstractHelpContainer(mFileName, filePath, mainHelpContainer);
        end
        
        function result = isClassHelpContainer(this) %#ok<MANU>
            % ISCLASSHELPCONTAINER - returns false because object is of
            % instance FunctionHelpContainer, not ClassHelpContainer
            result = false;
        end
    end
    
end

