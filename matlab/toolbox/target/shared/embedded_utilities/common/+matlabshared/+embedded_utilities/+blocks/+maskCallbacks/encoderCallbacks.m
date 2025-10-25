function encoderCallbacks(blkH,widget)

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
        fieldName = '';
        fieldSize = '';
        fieldType = '';
        byteOrder = '';
        numRows = tableControl.getNumberOfRows();
        for i=1:numRows
            fieldName = [fieldName,',' tableControl.getValue([i fieldnameIdx])];
            fieldType = [fieldType,',' tableControl.getValue([i fieldTypeIdx])];
            fieldLength = tableControl.getValue([i fieldLengthIdx]);
            validateattributes(str2double(fieldLength), {'numeric'}, ...
                { '>', 0,'<=', intmax('uint16'),'real', 'nonnan','integer','scalar'}, ...
                '', 'field length')
            fieldSize = [fieldSize,',',fieldLength];
            byteOrder = [byteOrder,',',tableControl.getValue([i byteOrderIdx])];
        end
        % Get field name, data type, size and byte order from the the table
        % and set the system object properties
        set_param(blkH,'FixedFieldDataTypes',fieldType,'FixedSizeFieldLength',fieldSize,'FieldNames',fieldName,'IsLittleEndian',byteOrder);
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
    case 'MoveUp'
        rowIndex = tableControl.getSelectedRows();
        numRows = numel(rowIndex);
        for i = 1:numRows
            if rowIndex(i) == 1
                break;
            end
            tableControl.swapRows(rowIndex(i)-1, rowIndex(i));
        end
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
        imageNameEncoder = fullfile(matlabshared.embedded_utilities.internal.getEmbeddedUtilitesRootDir,'+matlabshared','+embedded_utilities','+blocks','+maskCallbacks','checksumTemplate_ProtocolEncoder.fig');
        open(imageNameEncoder);
        set(gcf,'Name','Function template for custom checksum logic in Protocol Encoder block','NumberTitle','off','MenuBar','none','Resize','off');
    case 'TerminatorOption'
        if strcmpi(get_param(blkH,'TerminatorOption'),'Custom terminator')
            maskObj.getParameter('CustomTerminatorVal').Enabled = 'on';
        else
            maskObj.getParameter('CustomTerminatorVal').Enabled = 'off';
        end
    otherwise
end
end