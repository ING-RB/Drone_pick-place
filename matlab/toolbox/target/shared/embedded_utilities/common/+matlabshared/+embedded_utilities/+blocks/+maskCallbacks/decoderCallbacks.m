function decoderCallbacks(blkH,widget)

maskObj = Simulink.Mask.get(blkH);
tableControl = maskObj.getDialogControl('FieldTable');
fieldnameIdx = 1;
fieldLengthIdx = 2;
fieldTypeIdx = 3;
byteOrderIdx = 4;

% Return if simulation is paused or running or during external mode.
if strcmpi(get_param(bdroot, 'SimulationStatus'), 'paused') || ...
        strcmpi(get_param(bdroot, 'SimulationStatus'), 'running') ||...
        strcmpi(get_param(bdroot,"ExtModeConnected"),'on')
    return;
end

switch widget
    case 'init'
        % Function updates the field table as per the parameter specified
        syncTable(blkH);
        fieldName = '';
        fieldSize = '';
        fieldType = '';
        byteOrder = '';
        numRows = tableControl.getNumberOfRows();
        if strcmpi(get_param(blkH,'IsParseCSV'),'off')
            for i=1:numRows
                fieldName = [fieldName,',' tableControl.getValue([i fieldnameIdx])];
                % For variable size packet, the last coloumn value of feild
                % type, feild size and byte order is insignificant.
                if ~(strcmpi(get_param(blkH,'IsVariableSizeLastField'),'on') && i == numRows)
                    fieldType = [fieldType,',' tableControl.getValue([i fieldTypeIdx])];
                    fieldLength = tableControl.getValue([i fieldLengthIdx]);
                    validateattributes(str2double(fieldLength), {'numeric'}, ...
                        { '>', 0,'<=', intmax('uint16'),'real', 'nonnan','integer','scalar'}, ...
                        '', 'field length')
                    fieldSize = [fieldSize,',',fieldLength];
                    byteOrder = [byteOrder,',',tableControl.getValue([i byteOrderIdx])];
                end
            end
            % Get field name, data type, size and byte order from the the table
            % and set the system object properties
            set_param(blkH,'FixedFieldDataTypes', fieldType,'FixedSizeFieldLength',fieldSize,'FieldNames',fieldName,'IsLittleEndian',byteOrder);
        else
            for i=1:numRows
                fieldName = [fieldName,',' tableControl.getValue([i fieldnameIdx])];
                fieldLength = tableControl.getValue([i fieldLengthIdx]);
                validateattributes(str2double(fieldLength), {'numeric'}, ...
                    { '>', 0,'<=', intmax('uint16'), 'real', 'nonnan','integer','scalar'}, ...
                    '', 'Field length')
                fieldSize = [fieldSize,',', fieldLength];
            end
            % Get field name and size from the the table
            % and set the system object properties
            set_param(blkH,'CSVFieldLengthInBytes',fieldSize,'FieldNames',fieldName);
        end
        if strcmpi(get_param(blkH,'IsChecksumRequired'),'on') && strcmpi(get_param(blkH,'ChecksumAlgorithm'),'Custom algorithm')
            % Remove .m from the function name
            filename = get_param(blkH,'ChecksumFilepath');
            [~,functionName,ext] = fileparts(filename);
            if ~strcmpi(ext, '.m')
                error(message('embedded_utilities:general:invalidChecksumLogicExtension'));
            elseif ~exist(functionName,'file')
                error(message('embedded_utilities:general:checksumLogicNotFound'));
            else
                set_param(blkH,'CustomCSLogicFcnName',functionName);
            end
        end
    case 'IsParseCSV'
        if strcmpi(get_param(blkH,'IsParseCSV'),'on')
            set_param(blkH,'IsVariableSizeLastField','off');
            maskObj.getParameter('IsVariableSizeLastField').Enabled = 'off';
            maskObj.getParameter('MaxVariableSizeFieldLength').Enabled = 'off';
        else
            maskObj.getParameter('IsVariableSizeLastField').Enabled = 'on';
            maskObj.getParameter('MaxVariableSizeFieldLength').Enabled = 'off';
            if strcmpi(get_param(blkH,'IsVariableSizeLastField'),'on')
                maskObj.getParameter('MaxVariableSizeFieldLength').Enabled = 'on';
            else
                maskObj.getParameter('MaxVariableSizeFieldLength').Enabled = 'off';
            end
        end
        syncTable(blkH);
    case 'Add'
        numRows = tableControl.getNumberOfRows();
        rowIndex = numRows+1;
        rowName = sprintf('Field%d', rowIndex);
        fieldName = cell(1,numRows);
        for i=1:numRows
           fieldName{i} = tableControl.getValue([i fieldnameIdx]);
        end
        while(~isempty(find(contains(fieldName, rowName), 1))) % loop until a unique value
          rowIndex = rowIndex + 1;
          rowName =  sprintf('Field%d', rowIndex);
       end
        tableControl.addRow(rowName,'1','uint8','Little endian');
        syncTable(blkH);
    case 'Delete'
        totalNumRows = tableControl.getNumberOfRows();
        rowIndex = tableControl.getSelectedRows();
        numRows = numel(rowIndex);
        if totalNumRows  == 1
            error(message('embedded_utilities:general:noPacketFields'));
        end
        for i = 1:numRows
            tableControl.removeRow(rowIndex(i));
        end
        syncTable(blkH);
    case 'MoveUp'
        rowIndex = tableControl.getSelectedRows();
        numRows = numel(rowIndex);
        for i = 1:numRows
            if rowIndex(i) == 1
                break;
            end
            tableControl.swapRows(rowIndex(i)-1, rowIndex(i));
        end
        syncTable(blkH);
    case 'MoveDown'
        rowIndex = tableControl.getSelectedRows();
        numRows = numel(rowIndex);
        rowIndex = sort(rowIndex,'descend');

        for i = 1:numRows
            if rowIndex(i) == tableControl.getNumberOfRows()
                break;
            end
            tableControl.swapRows(rowIndex(i)+1, rowIndex(i));
        end
        syncTable(blkH);
    case 'IsVariableSizeLastField'
        if strcmpi(get_param(blkH,'IsVariableSizeLastField'),'on')
            maskObj.getParameter('MaxVariableSizeFieldLength').Enabled = 'on';
        else
            maskObj.getParameter('MaxVariableSizeFieldLength').Enabled = 'off';
        end
        syncTable(blkH);
    case 'Checksum'
        browseHandle = getDialogControl(maskObj,'Browse');
        linkHandle = getDialogControl(maskObj,'CSLink');
        if strcmpi(get_param(blkH,'IsChecksumRequired'),'on')
            maskObj.getParameter('ChecksumAlgorithm').Enabled = 'on';
            if strcmpi(get_param(blkH,'ChecksumAlgorithm'),'Custom algorithm')
                maskObj.getParameter('ChecksumSize').Enabled = 'on';
                maskObj.getParameter('ChecksumFilepath').Enabled = 'on';
                browseHandle.Enabled = 'on';
                linkHandle.Enabled = 'on';
                browseHandle.Visible = 'on';
                linkHandle.Visible = 'on';
            else
                maskObj.getParameter('ChecksumSize').Enabled = 'off';
                maskObj.getParameter('ChecksumFilepath').Enabled = 'off';
                browseHandle.Enabled = 'off';
                linkHandle.Enabled = 'off';
            end
        else
            maskObj.getParameter('ChecksumAlgorithm').Enabled = 'off';
            maskObj.getParameter('ChecksumSize').Enabled = 'off';
            maskObj.getParameter('ChecksumFilepath').Enabled = 'off';
            browseHandle.Enabled = 'off';
            linkHandle.Enabled = 'off';
        end
    case 'Browse'
        [fileName,filePath] = uigetfile('*.m','Pick a file');
        if ~isequal(filePath,0)
            set_param(blkH,'ChecksumFilepath',fullfile(filePath,fileName));
        end
     case 'CSLink'
        imageNameDecoder = fullfile(matlabshared.embedded_utilities.internal.getEmbeddedUtilitesRootDir,'+matlabshared','+embedded_utilities','+blocks','+maskCallbacks','checksumTemplate_ProtocolDecoder.fig');
        open(imageNameDecoder);
        set(gcf,'Name','Function template for custom checksum logic in Protocol Decoder block','NumberTitle','off','MenuBar','none','Resize','off');
    case 'TerminatorOption'
        if strcmpi(get_param(blkH,'TerminatorOption'),'Custom terminator')
            maskObj.getParameter('CustomTerminatorVal').Enabled = 'on';
        else
            maskObj.getParameter('CustomTerminatorVal').Enabled = 'off';
        end
        syncTable(blkH);
    otherwise
end
end

function syncTable(blkH)
% For Size based parsing if last field is variable, ensure that the field
% length option in the last row is greyed out and set to -1. Also disable
% Feild data type and byte order option
% For CSV based parsing, grey out Field datatype and byte order option.
maskObj = Simulink.Mask.get(blkH);
tableControl = maskObj.getDialogControl('FieldTable');
fieldLengthIdx = 2;
fieldTypeIdx = 3;
ByteOrderIdx = 4;
numRows = tableControl.getNumberOfRows();
if strcmpi(get_param(blkH,'IsParseCSV'),'off')
    for i = 1:numRows - 1
        tableControl.setTableCell( [i  fieldTypeIdx],'Enabled', 'on');
        if strcmpi(tableControl.getValue( [i fieldLengthIdx]),'-1')
            tableControl.setTableCell( [i  fieldLengthIdx],'Value', '1','Enabled', 'on');
        else
            tableControl.setTableCell( [i  fieldTypeIdx],'Enabled', 'on');
        end
        tableControl.setTableCell( [i  ByteOrderIdx],'Enabled', 'on');
    end
    if strcmpi(get_param(blkH,'IsVariableSizeLastField'),'on')
        tableControl.setTableCell( [numRows  fieldTypeIdx],'Value', 'uint8','Enabled', 'off');
        tableControl.setTableCell( [numRows  fieldLengthIdx],'Value', '-1','Enabled', 'off');
        tableControl.setTableCell( [numRows  ByteOrderIdx],'Value', 'Little endian','Enabled', 'off');
    else
        tableControl.setTableCell( [numRows  fieldTypeIdx],'Enabled', 'on');
        % If the last field length was -1, make this 1 or else preserved
        % the value
        if strcmpi(tableControl.getValue([numRows  fieldLengthIdx]),'-1')
            tableControl.setTableCell( [numRows  fieldLengthIdx],'Value', '1','Enabled', 'on');
        else
            tableControl.setTableCell( [numRows  fieldLengthIdx],'Enabled', 'on');
        end
        tableControl.setTableCell( [numRows  ByteOrderIdx],'Enabled', 'on');
    end
else
    numRows = tableControl.getNumberOfRows();
    for i = 1:numRows
        tableControl.setTableCell( [i  fieldTypeIdx],'Value','uint8','Enabled', 'off');
        tableControl.setTableCell( [i  ByteOrderIdx],'Value','Little endian','Enabled', 'off');
        % If the last field length was -1, make this 1 or else preserve
        % the value
        if i == numRows && strcmpi(tableControl.getValue([numRows  fieldLengthIdx]),'-1')
            tableControl.setTableCell( [numRows  fieldLengthIdx],'Value', '1','Enabled', 'on');
        else
            tableControl.setTableCell( [numRows  fieldLengthIdx],'Enabled', 'on');
        end
    end
end
end