classdef ScriptFileValidator
    %This class is undocumented and may change in a future release.
    
    %  Copyright 2016-2020 The MathWorks, Inc.
    properties(Constant, Access=private)
        CreateScriptFileValidationFcnInputParser = createParserForCreateScriptFileValidationFcn();
        ValidateScriptFileInputParser = createParserForValidateScriptFileInput();
    end
    
    methods(Static)
        function fcn = createScriptFileValidationFcn(fileName, varargin)
            import matlab.unittest.internal.ScriptFileValidator;
            import matlab.unittest.internal.getParentNameFromFilename;
            import matlab.unittest.internal.ContentWrapper;
            
            scriptName = getParentNameFromFilename(fileName);
            args = {scriptName};
            
            parser = ScriptFileValidator.CreateScriptFileValidationFcnInputParser;
            parser.parse(varargin{:});
            input = parser.Results;
            
            if input.WithExtension
                args = [args, {'Extension', getExtension(fileName)}];
            end
            
            if input.WithCode
                %Code is wrapped with a ContentWrapper to save storage if
                %the function handle is distributed to multiple locations.
                args = [args, {'Code', ContentWrapper(getCode(fileName))}];
            end
            
            if input.WithLastModifiedMetaData
                args = [args, {'LastModifiedMetaData', getLastModifiedMetaData(fileName)}];
            end
            fcn = @() matlab.unittest.internal.ScriptFileValidator.validateScriptFile(args{:});
        end
        
        function validateScriptFile(scriptName,varargin)
            % validateScriptFile - Validate script file based on given properties
            %
            % Calls to this function are stored as function handles inside
            % of ScriptTestCaseProvider as of R2016b. Therefore, altering this
            % function may affect R2016b (or later) saved test suites.
            import matlab.unittest.internal.ScriptFileValidator;
            
            fileName = matlab.unittest.internal.whichFile(scriptName);
            if isempty(fileName)
                error(message('MATLAB:unittest:TestSuite:ScriptFileNotFound', scriptName));
            end
            
            parser = ScriptFileValidator.ValidateScriptFileInputParser;
            parser.parse(varargin{:});
            input = parser.Results;
            
            if wasProvided(parser,'Extension') && ~strcmpi(getExtension(fileName),input.Extension)
                error(message('MATLAB:unittest:TestSuite:ScriptFileExtensionChanged', ...
                    scriptName, input.Extension, getExtension(fileName)));
            end
            
            if wasProvided(parser,'Code') && ~strcmp(getCode(fileName),input.Code.Content)
                throwContentChangedError(scriptName);
            end
            
            if wasProvided(parser,'LastModifiedMetaData') && ...
                    ~isequal(getLastModifiedMetaData(fileName),input.LastModifiedMetaData)
                throwContentChangedError(scriptName);
            end
        end
    end
end

function throwContentChangedError(scriptName)
error(message('MATLAB:unittest:TestSuite:ScriptContentChanged', scriptName));
end

function parser = createParserForCreateScriptFileValidationFcn()
parser = inputParser();
parser.addParameter('WithExtension',false);
parser.addParameter('WithCode',false);
parser.addParameter('WithLastModifiedMetaData',false);
end

function parser = createParserForValidateScriptFileInput()
parser = inputParser();
parser.addParameter('Extension',[]);
parser.addParameter('Code',[]);
parser.addParameter('LastModifiedMetaData',false);
end

function ext = getExtension(fileName)
[~,~,ext] = fileparts(fileName);
end

function code = getCode(fileName)
code = matlab.internal.getCode(fileName);
end

function lastModified = getLastModifiedMetaData(fileName)
fileModel = matlab.internal.livecode.FileModel.fromFile(fileName);
lastModified = fileModel.LastModified;
end

function bool = wasProvided(parser, parameterName)
bool = ~ismember(parameterName,parser.UsingDefaults);
end