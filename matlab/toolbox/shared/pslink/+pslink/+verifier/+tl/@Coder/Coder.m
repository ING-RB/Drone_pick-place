classdef Coder < pslink.verifier.Coder
%

% Copyright 2011-2024 The MathWorks, Inc.

    
    properties(Constant, GetAccess=public)
        CODER_NAME = 'TargetLink';
        CODER_ID = 'tl';
        CODER_VERIF_NAME = 'TargetLink';
        CODER_IDE_NAME = 'TargetLink';
    end
    
    properties(Hidden=true, SetAccess=protected, GetAccess=public)
        lutInfo
        cgLanguage
    end
    
    methods(Access=public)
        
        %% Public Method: Coder -------------------------------------------
        %  Abstract:
        %    Constructor.
        function self = Coder(slSystemName, isMdlRef)
            if nargin < 2
                isMdlRef = false;
            end
            self = self@pslink.verifier.Coder(slSystemName, isMdlRef);

            self.lutInfo = [];
            self.cgLanguage = 'C';

            self.sysDirInfo = pslink.util.Helper.getConfigDirInfo(self.slSystemName, pslink.verifier.tl.Coder.CODER_ID);
            self.cgName = self.sysDirInfo.SystemCodeGenName;
            self.cgDirStatus = exist(self.sysDirInfo.SystemCodeGenDir, 'dir');
            
            self.mustWriteAllData = false;
            self.inputFullRange = true;
            self.outputFullRange = true;
            self.paramFullRange = true;
        end
        
        %% Public Method: getCheckSum -------------------------------------
        %  Abstract:
        %    Returns the check sum computed at code generation time.      
        function checkSum = getCheckSum(self) %#ok<MANU>
            checkSum = [];
        end        

        %% Public Method: extractLinksData -------------------------------------
        %  Abstract:
        %    Returns the check sum computed at code generation time.   
        function extractLinksData(self, ~)
            % Extract LinksData info for Back to Model
            self.dlinkInfo = pslink.util.LinksData.ExtractLinksData(self.slModelName, false, self.slModelFileName, self.slModelVersion);            
        end

        %% Public Method: extractAllInfo ----------------------------------
        %  Abstract:
        %    Implement all the logic for extracting information specific
        %    to Target-Link
        function extractAllInfo(self, pslinkOptions)        

            if nargin < 2
                pslinkOptions = pslink.Options();
                pslinkOptions = get(pslinkOptions);
                pslinkOptions.AutoStubLUT = false;
                pslinkOptions.InputRangeMode = 'DesignMinMax';
                pslinkOptions.OutputRangeMode = 'None';
                pslinkOptions.ParamRangeMode = 'None';
            end

            self.extractLinksData();

            % Perform function stubbing - lookup tables
            if pslinkOptions.AutoStubLUT
                generateStubs(self, pslinkOptions);
            end

            self.extractDrsInfo(pslinkOptions);

            execMap = extractExecutionInfo(self);
            self.fcnInfo.codeLanguage = 'C';
            if ~isempty(self.codeInfo)
                fillDataRangeInfo(self);
                fillFcnInfo(self, execMap);
                self.fcnInfo.mustWriteAllData = self.mustWriteAllData;
            else
                self.fcnInfo.mustWriteAllData = true;
            end
            
        end
        
        %% Public Method: getFileInfo -------------------------------------
        %  Abstract:
        %    Returns the list of header and source files required for
        %    compiling the generated code.
        function fileInfo = getFileInfo(self, opts)
            % Get and check the options
            if nargin < 2
                opts = struct('includeMdlRefs', false);
            end
            if ~isfield(opts, 'includeMdlRefs')
                opts.inputFullRange = false;
            end
                       
            fillFileInfo(self, opts);
            
            fileInfo = self.fileInfo;
        end
        
        %% Public Method: getBooleanType -------------------------------------
        %  Abstract:
        %    Returns the boolean type replacement for the generated code.
         function booleanTypes = getBooleanType(self)
             self.booleanTypes = {};
             booleanTypes = self.booleanTypes;
         end
        
        %% Public Method: getFcnToStub ----------------------------------
        %  Abstract:
        %    Returns the list of functions to stub.
        function fcnToStub = getFcnToStub(self)
             self.fcnToStub = {};
             fcnToStub = self.fcnToStub; 
        end
         
    end
    
    methods(Static=true)
        [resultDescription, resultDetails, resultType, hasError, resultId] = checkOptions(systemName, opts)
        cgDirInfo = getCodeGenerationDir(systemName)
        
        %% Public Static Method: getCoderName -----------------------------
        %  Abstract:
        %
        function str = getCoderName()
            str = pslink.verifier.tl.Coder.CODER_NAME;
        end
        
        %% Public Static Method: getCoderVersion --------------------------
        %  Abstract:
        %
        function str = getCoderVersion()
            TLdata = ver('tl');
            str = TLdata.Version;
        end
                
    end
    
    methods(Static=true, Access=private)
        %% Private Static Method: getScalingInfo --------------------------
        %  Abstract:
        %    Returns the lsb and offset for a variable
        function [lsb, offset, name] = getScalingInfo(hObj)
            scaling = dsdd('Get', hObj, 'Scaling');
            if ~ischar(scaling)
                lsb     = dsdd('GetLSB',       scaling);
                offset  = dsdd('GetOffset',    scaling);
                name    = dsdd('GetAttribute', scaling, 'name');
                % tmp     = dsdd('GetAll', scaling);
            else
                lsb = dsdd('Get', hObj, 'lsb');
                offset = dsdd('Get', hObj, 'Offset');
            end
            
            if isempty(lsb)
                lsb = 1;
            end
            
            if isempty(offset)
                offset = 0;
            end
        end
        
        %% Private Static Method: isSupportedType -------------------------
        %  Abstract:
        %    
        function isValid = isSupportedType(type)
            % Returns 1 if the type is valid for DRS else 0
            % The valid base types are:
            %    Int8, Uint8, Int16, UInt16, Int32, UInt32, Float32,
            %    Float64, Bool, Int, Uint, Struct
            % Base types considered invalid are:
            %    Void, Pointer, Union, Enum, Bitfield
            
            isValid = false;
            isFloatOrInt = ~isempty(regexpi(type, '\w*int\w*|\w*float\w*', 'start'));
            
            if isFloatOrInt || strcmpi(type, 'bool') || strcmpi(type, 'Struct')
                isValid = true;
            end
        end

        %% Private Static Method: getVariableInfo -------------------------
        %  Abstract:
        % 
        function varInfo = getVariableInfo(hObj)
            % Returns flags indicating the type of variable - global, macro, const,
            % volatile and static and scalar
            
            % Get the class of the variable and the macro flag
            objClass = dsdd('GetClass', hObj);
            if isempty(objClass)
                varInfo.isGlobal   = 0;
                varInfo.isMacro    = 0;
                varInfo.isConst    = 0;
                varInfo.isVolatile = 0;
                varInfo.isStatic   = 0;
                varInfo.isScalar   = 0;
                varInfo.isArray    = 0;
                varInfo.info       = '';
            else
                varInfo.isGlobal = strcmp('global', dsdd('GetScope', objClass));
                varInfo.isMacro  = dsdd('GetMacro', objClass);
                % need a check because some times the previous command return an empty value
                if isempty(varInfo.isMacro)
                    varInfo.isMacro = 0;
                end
                varInfo.info = dsdd('GetInfo', objClass);
                if isempty(varInfo.info)
                    varInfo.info = '';
                end
                varInfo.isConst = dsdd('GetConst', objClass);
                if isempty(varInfo.isConst)
                    varInfo.isConst = 0;
                end
                varInfo.isVolatile = dsdd('GetVolatile', objClass);
                if isempty(varInfo.isVolatile)
                    varInfo.isVolatile = 0;
                end
                varInfo.isStatic = strcmp('static', dsdd('GetStorage', objClass));
                if isempty(varInfo.isStatic)
                    varInfo.isStatic = 0;
                end

                value = dsdd('GetValue', hObj);
                if isempty(value)
                    varInfo.isScalar = 1;
                else
                    %R13 TBD isScalar = isscalar(value);
                    if ndims(value) == 2
                        [dim1,dim2] = size(value);
                        if (dim1 == 1) && (dim2 == 1)
                            varInfo.isScalar = 1;
                        else
                            varInfo.isScalar = 0;
                        end
                    else
                        varInfo.isScalar = 0;
                    end
                end
                varInfo.isArray = ~varInfo.isScalar;
            end
        end
    
        %% Public Static Method: doubleToScaledValue ----------------------
        %  Abstract:
        %    Convert a value to it's integer representation using scaling
        %    factor and offset
        function [scaledValue] = doubleToScaledValue(doubleValue, scaling, offset, type)
            if regexpi(type, '\w*int\w*')
                scaledValue = round((doubleValue-offset)/scaling);
            else
                if strcmpi(type, 'bool')
                    scaledValue = round((doubleValue-offset)/scaling);
                else
                    scaledValue = (doubleValue-offset)/scaling;
                end
            end
        end
        
        %% Public Static Method: getType ----------------------------------
        %  Abstract:
        %    Returns the type information for a variable as a string
        function type = getType(hObj)
            % type will either be the type (as string) or a handle
            type = dsdd('Get', hObj, 'Type');
            if ~ischar(type)
                type = dsdd('Get',type, 'BaseType');
            end
        end
        
    end
    
end

% LocalWords:  tl tmp dsdd
