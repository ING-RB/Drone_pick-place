%   Copyright 2022 The MathWorks, Inc.
classdef driverUtilFiles < matlab.mixin.SetGet
    %This file contains methods for parsing the function definitions from
    %headerfiles and util files needed for driverBlock
    properties
        %Name Name of the block object
        Name = '';
        %BlockType Type of system object : sink or source
        BlockType = '';
        %Peripheral of system object : I2C,SPI or CAN etc
        Peripheral = '';
        %MaskDescription Block Mask description of system block
        MaskDescription = 'System object mask';
        %HeaderFile Cell array containing main files to be parsed
        HeaderFile = {};
        SourceFile = {};
        HeaderPath = {};
        SourcePath = {};
        FunctionBlock = {};
        EnumBlock = {};
        StrucBlock = {};
        Inputs = {};
        Outputs = {};
        Masks = {};
        Internals = {};
        Constants = {};
        SetupFunction = {};
        StepFunction = {};
        SetupHeaderFile = {};
        ReleaseFunction = {};
    end
    properties (Hidden)
        %below is the map of data types
        dataTypeMap =  dictionary({'uint8','int8','uint16','int16','uint32','int32', ...
            'uint64','int64','single','double','void*','uint8_T','int8_T','uint16_T','int16_T','uint32_T','int32_T', ...
            'uint64_T','int64_T','real32_T','real64_T','void*','boolean_T','pointer_T','void'}, ...
            {'uint8','int8','uint16','int16','uint32','int32', ...
            'uint64','int64','single','double','void*','uint8','int8','uint16','int16','uint32','int32', ...
            'uint64','int64','single','double','void*','uint8','void*','void'}) %#ok<*MCHDP>
        fnMap =  dictionary;
        enMap =  dictionary;
        strucMap =  dictionary;
        IncludeFiles = {};
        stepFnMap;
        stepInArg;
        setupFnMap;
        setupInArg;
    end
    methods(Access = 'public')
        function obj = driverUtilFiles(varargin)
        end
    end

    methods(Access = 'protected')
        function getIncludeFiles(obj,file)
            % collects extra header files from main test header file
            data = fileread(file);
            incPattern = '^(#include)\s*\"[\w|.]*?\"';
            [~,~,~,s,~,~] = regexp(data,incPattern,'lineanchors');
            for i=1:numel(s)
                s{i} = s{i}(1:end-1);
                s{i} = strtrim(strsplit(s{i},'"'));
                if(~any(ismember(obj.IncludeFiles,s{i}{2})))
                    obj.IncludeFiles{end+1} = s{i}{2};
                end
            end
        end
        function parseInclude(obj,fileName)
            % parses the dependent header files for defines and enums
            data = fileread(fileName);
            data = strrep(data,' *','*');
            %parse defines
            defPattern = '^(typedef)[\w|*|\s]*?\;';
            [~,~,~,s,~,~] = regexp(data,defPattern,'lineanchors');
            for i=1:numel(s)
                s{i} = s{i}(8:end-1);
                s{i} = strtrim(s{i});
                s{i} = strrep(s{i}, ' *', '*');
                temp = strtrim(split(s{i},' '));
                if(~isKey(obj.dataTypeMap,temp{2}))
                    if isKey(obj.dataTypeMap,temp{1})
                        obj.dataTypeMap(temp{2}) = obj.dataTypeMap(temp{1});
                    else
                        obj.dataTypeMap(temp{2}) = temp{1};
                    end
                end
            end
            %parse enums
            enumPattern = '(enum)[^\;]*?\;';
            [~,~,~,s,~,~] = regexp(data,enumPattern,'lineanchors');
            for i=1:numel(s)
                s{i} = s{i}(5:end-1);
                s{i} = strtrim(s{i});
                x = strsplit(s{i},'{');
                m = strsplit(s{i},'}');
                if(~isempty(strtrim(x{1})))
                    eName = strtrim(x{1});
                else
                    eName = strtrim(m{2});
                end
                if(~any(ismember(obj.EnumBlock,eName)))

                    a = s{i};
                    eVals = extractBetween(a,'{','}');
                    prev = 0;
                    str = '';
                    for k=1:numel(eVals)

                        if contains(eVals{k},'=')
                            eVals{k} = strrep(eVals{k},'=','(');
                            eVals{k} = [eVals{k} ')'];
                            val = extractBetween(eVals{k},'(',')');
                            val = strtrim(val{1});
                            prev = str2num(val) + 1; %#ok<*ST2NM>
                        else
                            val = sprintf('(%d)',prev);
                            eVals{k} = [eVals{k} val];
                            prev = prev + 1 ;
                        end
                        str = sprintf([str '%s\n'],eVals{k});
                    end
                    j = EnumStruct(eName,str);
                    obj.enMap(eName) = j;
                    obj.EnumBlock{end+1} = eName;
                end
            end
        end
        function parse(obj,fileName)
            %parses the main header file
            data = fileread(fileName);
            data = strrep(data,' *','*');
            %parse defines
            defPattern = '^(typedef)[\w|*|\s]*?\;';
            [~,~,~,s,~,~] = regexp(data,defPattern,'lineanchors');
            for i=1:numel(s)
                s{i} = s{i}(8:end-1);
                s{i} = strtrim(s{i});
                s{i} = strrep(s{i}, ' *', '*');
                temp = strtrim(split(s{i},' '));
                if(~isKey(obj.dataTypeMap,temp{2}))
                    if isKey(obj.dataTypeMap,temp{1})
                        obj.dataTypeMap(temp{2}) = obj.dataTypeMap(temp{1});
                    else
                        obj.dataTypeMap(temp{2}) = temp{1};
                    end
                end
            end
            % parse functions
            functionPattern = '^[\w|*|\s]*\w*?\([\w|\s|\,\*]*?\)\;';
            [~,~,~,s,~,~] = regexp(data,functionPattern,'lineanchors');
            for i=1:numel(s)
                s{i} = s{i}(1:end-1);
                s{i} = strtrim(s{i});
                s{i} = strrep(s{i},' *','*');
                if(~any(ismember(obj.FunctionBlock,s{i})))
                    obj.FunctionBlock{end+1} = s{i};
                    [a,b,c] = parseFunction(obj,s{i});
                    j = matlabshared.sensors.utils.FunctionStruct(b,a,c);
                    obj.fnMap(s{i}) = j;
                end
            end
        end

        function [output,functionName,argumentType] = parseFunction(~,functionString)
            %parses individual elements from a function string
            if ~isempty(functionString)
                [~,~,~,d,~,~] = regexp(functionString,'^[\w|\s|*]*?\(','lineanchors');
                x = strsplit(d{1}(1:end-1),' ');
                output = x{1};
                if(length(x)>1)
                    functionName = x{2};
                else
                    functionName = x{1};
                end
                x = strsplit(functionString((length(d{1})+1):end-1),',');

                argumentType = {};
                for i=1:length(x)
                    x{i} = strtrim(x{i});
                    temp = strsplit(x{i},' ');
                    if numel(temp)>0 && ~isempty(temp{end})
                        argumentType{end+1} = temp{1}; %#ok<*AGROW>
                    end
                end
            else
                output = '';
                functionName = '';
                argumentType = {''};
            end
        end

        function processTemplateFile(~,inputFile,outputFile,args)
            % read whole file data into an array
            if nargin > 0
                inputFile = convertStringsToChars(inputFile);
            end
            if nargin > 1
                outputFile = convertStringsToChars(outputFile);
            end
            validateattributes(args,{'cell'},{'nonempty'},'processTemplateFile','args');
            fid = fopen(inputFile,'r');
            txt = fread(fid,'*char')';
            fclose(fid);
            % Replace the Search string with Replace String
            for i = 1:2:numel(args)
                txt = strrep(txt,args{i},args{i+1});
            end
            % Write it back into the file
            fid  = fopen(outputFile,'w');
            fwrite(fid,txt,'char');
            fclose(fid);
        end


        function generateEnumFiles(obj)
            %generates enum class files for parsed enums
            for i=1:numel(obj.EnumBlock)
                outputFile = [obj.EnumBlock{i} '.m'];
                enumInit = '';
                info = obj.enMap(obj.EnumBlock{i});
                enumInit = sprintf('classdef %s < Simulink.IntEnumType\nenumeration\n%send\nend\n\n',info.Name,info.Values{1});
                fid  = fopen(outputFile,'w');
                fwrite(fid,enumInit,'char');
                fclose(fid);
                h = matlab.desktop.editor.openDocument(fullfile(pwd,outputFile));
                h.smartIndentContents;
                h.save;
                h.close;
            end
        end
        function results = getFunctionCall(obj,fun)
            %returns proper string for functions to include in system
            %object file
            info = obj.fnMap(fun);
            ret = info.retType;
            returnString = '';
            if ~isempty(info.retArg)
                if ~isequal(ret,'void')
                    value = info.retArg{1};
                    if ~isa(value,'Output')
                        returnString = sprintf('obj.%s = ',value.Name);
                    else
                        returnString = sprintf('%s = ',value.Name);
                    end
                end
            end
            arg = info.inpArgs;
            argString = '';
            for i=1:numel(arg)
                value = arg{i};
                if isa(value,'matlabshared.sensors.utils.Output')
                    sz = char(extractAfter(extractBetween(value.Size,'[',']'),','));
                    if str2num(sz)>1
                        argString = sprintf([argString ',coder.ref(%s),%s'],value.Name,sz);
                    else
                        argString = sprintf([argString ',coder.ref(%s)'],value.Name);
                    end
                elseif ~isa(value,'Input')
                    argString = sprintf([argString ', obj.%s'],value.Name);
                else
                    argString = sprintf([argString ', %s'],value.Name);
                end
            end
            results = sprintf('%scoder.ceval(''%s''%s);',returnString,info.Name,argString);
        end
    end
end
