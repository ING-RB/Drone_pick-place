classdef ProtocolDecoderBlock < matlabshared.embedded_utilities.internal.ProtocolDecoderBase
    % Block class for deocder
    
    %Copyright 2021 The MathWorks, Inc.
    
    %#codegen
    properties(Nontunable)
        FixedFieldDataTypes = '';
        FixedSizeFieldLength = ''
        CSVFieldLengthInBytes = ''
        FieldNames = '';
        ChecksumFilepath = '';
        IsLittleEndian = '';
        Logo = '';
    end
   
    methods
        function set.FieldNames(obj,value)
            coder.extrinsic('strsplit');
            if ~isempty(value) && ischar(value)
                obj.FieldNames = strsplit(value(2:end),',');
            else
                obj.FieldNames = value;
            end
        end
        
        function set.FixedFieldDataTypes(obj,value)
            coder.extrinsic('strsplit');
            if ~isempty(value) && ischar(value)
                obj.FixedFieldDataTypes = strsplit(value(2:end),',');
            else
                obj.FixedFieldDataTypes = value;
            end
        end
        
        function set.FixedSizeFieldLength(obj,value)
            coder.extrinsic('str2num');
            if ~isempty(value) && ischar(value)
                obj.FixedSizeFieldLength = uint16(str2num(value));
            else
                obj.FixedSizeFieldLength = value;
            end
        end
        
        function set.IsLittleEndian(obj,value)
            coder.extrinsic('strsplit');
            if ~isempty(value) && ischar(value)
                value = strsplit(value(2:end),',');
                obj.IsLittleEndian = contains(value,'Little endian');
            else
                obj.IsLittleEndian = value;
            end
           end
                
          function set.CSVFieldLengthInBytes(obj,value)
            coder.extrinsic('str2num');
            if ~isempty(value) && ischar(value)
                obj.CSVFieldLengthInBytes = uint16(str2num(value));
            else
                obj.CSVFieldLengthInBytes = value;
            end
        end
    end
    
    methods(Access = protected)
        % Block mask display
        function varargout = getOutputNamesImpl(obj)
            if ~isempty(obj.FieldNames)
               for i=1:numel(obj.FieldNames)
                  varargout{i} = obj.FieldNames{i};
                end
            else 
                i = 0;
            end
            if obj.IsParseCSV
                i = i+1;
                varargout{i} = 'Variable field lengths';
            elseif obj.IsVariableSizeLastField
                i = i+1;
                varargout{i} = 'Variable field length';
            end
            if obj.IsChecksumRequired
                i = i+1;
                varargout{i} = 'IsValid';
            end
            i = i+1;
            varargout{i} = 'IsNew';
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' ]; %#ok<AGROW>
                end
            end
            inport_label = 'port_label(''input'', 1, ''Data'');';
            if obj.IsInputLengthAvailable
                inport_label = [inport_label,'port_label(''input'', 2, ''Length'');'; ];
            end
            maskDisplayCmds = [ ...
                ['color(''white'');',newline],...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...                                   % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');'],   ...
                ['color(''black'');',newline], ...
                ['text(52,12,' [''' ' 'Protocol Decoder' ''',''horizontalAlignment'',''center'');' newline]]   ...
                [inport_label,newline]...
                outport_label
                ];
        end
    end
    
    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'Protocol Decoder','ShowSourceLink',false);
        end
        
        function groups = getPropertyGroupsImpl
            logo = matlab.system.display.internal.Property('Logo', 'Description', '','IsHidden',false);
            header = matlab.system.display.internal.Property('Header', 'Description', 'Header');
            fieldNames = matlab.system.display.internal.Property('FieldNames', 'Description', '','IsHidden',true);
            fixedFieldDataTypes = matlab.system.display.internal.Property('FixedFieldDataTypes', 'Description', '','IsHidden',true);
            fixedSizeFieldLength = matlab.system.display.internal.Property('FixedSizeFieldLength', 'Description', '','IsHidden',true);
            isLittleEndian = matlab.system.display.internal.Property('IsLittleEndian', 'Description', '','IsHidden',true);
            terminatorOption = matlab.system.display.internal.Property('TerminatorOption', 'Description', 'Terminator');
            customTerminatorVal = matlab.system.display.internal.Property('CustomTerminatorVal', 'Description', '');
            isVariableSizeLastField = matlab.system.display.internal.Property('IsVariableSizeLastField', 'Description', '');
            maxVariableSizeFieldLength = matlab.system.display.internal.Property('MaxVariableSizeFieldLength', 'Description', '');
            isChecksumRequired = matlab.system.display.internal.Property('IsChecksumRequired', 'Description', '');
            checksumAlgorithm  = matlab.system.display.internal.Property('ChecksumAlgorithm', 'Description', '');
            checksumSize = matlab.system.display.internal.Property('ChecksumSize', 'Description', '');
            checksumFilePath  = matlab.system.display.internal.Property('ChecksumFilepath', 'Description', '');
            checksumFunctionName  = matlab.system.display.internal.Property('CustomCSLogicFcnName', 'Description', '','IsHidden',true);

            isParseCSV = matlab.system.display.internal.Property('IsParseCSV', 'Description', '');
            csvFieldLengthInBytes = matlab.system.display.internal.Property('CSVFieldLengthInBytes', 'Description', '','IsHidden',true);
            isInpuLengthAvailable = matlab.system.display.internal.Property('IsInputLengthAvailable', 'Description', '');
            
            decodeProperties = matlab.system.display.Section('PropertyList', {logo,header,fieldNames,fixedFieldDataTypes,fixedSizeFieldLength,isLittleEndian,...
                terminatorOption,customTerminatorVal,isVariableSizeLastField,maxVariableSizeFieldLength...
                isChecksumRequired,checksumAlgorithm,checksumSize,checksumFilePath,checksumFunctionName...
                isParseCSV,csvFieldLengthInBytes,isInpuLengthAvailable});
            
            MainGroup = matlab.system.display.SectionGroup('Title','Main','Sections',decodeProperties);
            
            groups= MainGroup;
        end
        
        function flag = showSimulateUsingImpl
            flag = false;
        end
        
        function simMode = getSimulateUsingImpl
            simMode = "Interpreted execution";
        end
    end
end
