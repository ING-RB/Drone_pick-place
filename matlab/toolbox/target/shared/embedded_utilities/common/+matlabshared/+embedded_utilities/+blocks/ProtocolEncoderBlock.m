classdef ProtocolEncoderBlock < matlabshared.embedded_utilities.internal.ProtocolEncoderBase
    % Block class for encoder
    
    %Copyright 2021 The MathWorks, Inc.
    
    %#codegen
    properties(Nontunable)
        FixedFieldDataTypes = '';
        FixedSizeFieldLength = ''
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
    end
    
    methods(Access = protected)
        % Block mask display
        function packet = getOutputNamesImpl(~)
            packet = 'packet';
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            inport_label = [];
            num = numel(obj.FieldNames);
            if num > 0
                for i = 1:num
                    inport_label = [inport_label 'port_label(''input'',' num2str(i) ',''' obj.FieldNames{i} ''');' ]; %#ok<AGROW>
                end
            else
                inport_label = 'port_label(''input'', 1, ''data'');';
            end
            
            outport_label = 'port_label(''output'', 1, ''packet'');';
            maskDisplayCmds = [ ...
                ['color(''white'');',newline],...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');'],   ...
                ['color(''black'');',newline], ...
                ['text(52,12,' [''' ' 'Protocol Encoder' ''',''horizontalAlignment'',''center'');' newline]]   ...
                [inport_label,newline]...
                outport_label
                ];
        end
    end
    
    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'Protocol Encoder','ShowSourceLink',false);
        end
        
        function groups = getPropertyGroupsImpl
            header = matlab.system.display.internal.Property('Header', 'Description', 'Header');
            logo = matlab.system.display.internal.Property('Logo', 'Description', '','IsHidden',false);
            fieldNames = matlab.system.display.internal.Property('FieldNames', 'Description', '','IsHidden',true);
            fixedFieldDataTypes = matlab.system.display.internal.Property('FixedFieldDataTypes', 'Description', '','IsHidden',true);
            fixedSizeFieldLength = matlab.system.display.internal.Property('FixedSizeFieldLength', 'Description', '','IsHidden',true);
            isLittleEndian = matlab.system.display.internal.Property('IsLittleEndian', 'Description', '','IsHidden',true);
            terminatorOption = matlab.system.display.internal.Property('TerminatorOption', 'Description', 'Terminator');
            customTerminatorVal = matlab.system.display.internal.Property('CustomTerminatorVal', 'Description', '');
            isChecksumRequired = matlab.system.display.internal.Property('IsChecksumRequired', 'Description', '');
            checksumAlgorithm  = matlab.system.display.internal.Property('ChecksumAlgorithm', 'Description', '');
            checksumSize = matlab.system.display.internal.Property('ChecksumSize', 'Description', '');
            checksumFilePath  = matlab.system.display.internal.Property('ChecksumFilepath', 'Description', '');
            checksumFunctionName  = matlab.system.display.internal.Property('CustomCSLogicFcnName', 'Description', '','IsHidden',true);

            
            encoderProperties = matlab.system.display.Section('PropertyList', {logo,header,fieldNames,fixedFieldDataTypes,fixedSizeFieldLength,isLittleEndian,...
                terminatorOption,customTerminatorVal,...
                isChecksumRequired,checksumAlgorithm,checksumSize,checksumFilePath,checksumFunctionName});
            
            MainGroup = matlab.system.display.SectionGroup('Title','Main','Sections',encoderProperties);
            
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
