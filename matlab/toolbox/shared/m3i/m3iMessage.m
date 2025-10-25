function m3iMessage(ErrorWarningInfo, varargin)
% Usage: m3iError(source, messageId, extra arguments)
%        e.g: m3iError('Clipboard', 'M3I_Clipboard_Paste_Failure', 'TypeA', 'TypeB')
% Usage: m3iError(messageId, extra arguments)
%        e.g: m3iError('M3I_Clipboard_Paste_Failure', 'TypeA', 'TypeB') 

%   Copyright 2010 The MathWorks, Inc.



    source = '';
    messageId = '';
    messageStr = '';
    
    sourceOrId = varargin{1};
    args = {};
    if isa(source, 'M3I.ClassObject') || isa(source, 'M3I.ImmutableClassObject')
		try
			source = source.uri;
		catch ex
			%object does not allow accessing uri property
        end
        messageId = varargin{2};
        messageStr = getMessageStringFromId(sourceOrId);
        if numel(varargin)>2
            args = varargin(3:end);
        end
    else
        try
            messageStr = getMessageStringFromId(sourceOrId);
            source = '';
            messageId = sourceOrId;
            if numel(varargin)>1
                args = varargin(2:end);
            end
        catch ex
            if length(varargin) > 1
                source = sourceOrId;
                messageId = varargin{2};
                try 
                    messageStr = getMessageStringFromId(messageId);
                    if numel(varargin)>2
                        args = varargin(3:end);
                    end
                catch ex
                    % bail out
                    messageId = source;
                    messageStr = M3I.privateGetMessageStringFromId(messageId);
                end
            else
                % bail out
                messageStr = getMessageStringFromId(sourceOrId);
            end
        end
    end
        
	if ~isa(source, 'char')
		%wrong type passed in
		%todo: raise error
		return;
	end
	message = sprintf(messageStr, args{:});
    
    switch ErrorWarningInfo
        case 1, M3I.privatePushError(source, messageId, message);
        case 2, M3I.privatePushWarning(source, messageId, message);
        case 3, M3I.privatePushInfo(source, messageId, message);
    end
end

function messageStr = getMessageStringFromId(messageId)
    % Messages that are temporarily define for MATLAB use only.
    persistent temporaryMATLABOnlyMessages;
    if isempty(temporaryMATLABOnlyMessages)
        temporaryMATLABOnlyMessages = {
            { 'Example_Error', 'This is an example error $select{%s}{%s}'},
            {'IRV_Access_Error', ['The Inter Rate Variable $select{$s}{%s}'...
                                  ' is read and written by runnable $select{$s}{%s}']},
            {'Validator_Succeeded', 'The validation was successful.'},
            {'SCP_Internal', '%s'},
            {'Invalid_Connector', ['The connector $select{%s}{%s} is invalid.' char(10) ...
                                   '$script{Remove it.}{SCPDiagViewer.remove(''%s'')}']},
            {'Periodic_Runnable', 'No periodic runnable exists in the model.'},
            {'Illegal_Mapping', ['The $select{mapping}{%s} between AUTOSAR port' ...
                                 '$select{%s}{%s} and Simulink port $select{%s}{%s} is illegal.' char(10)...
                                 '$script{Remove it.}{SCPDiagViewer.remove(''%s'');}']},
            {'Incompatible_Types', ['The $select{mapping}{%s} connects incompatible types. ' char(10) ...
                                   'Fix it by pushing: ' char(10) ...
                                   '$script{Software type %s -> Simulink}{SCPDiagViewer.setType(''%s'', ''%s'')}' char(10) ...
                                   '$script{Simulink type %s -> Software}{SCPDiagViewer.setType(''%s'', ''%s'')}'] },                                 
            {'Port_Type', ['Type mismatch in mapping %s' char(10) ...
                              'Fix options:' char(10)...                              
                               '1)    Change AUTOSAR  $script{%s:%s --> %s:%s}{SCPDiagViewer.setType(''%s'', ''%s''); SCPDiagViewer.runValidator();}' char(10) ...
                               '2)    Change Simulink $script{%s:%s --> %s:%s}{Sam2SL.changeType(''%s'', ''%s''); SCPDiagViewer.runValidator();}' char(10) ...
                               ]},
            {'Mapping_Type', ['Type mismatch in mapping %s' char(10) ...
                              'Fix options:' char(10)...                              
                               '1)    Change AUTOSAR  $script{%s:%s --> %s:%s}{SCPDiagViewer.setType(''%s'', ''%s''); SCPDiagViewer.runValidator();}' char(10) ...
                               ]},
            {'Multiple_Mappings', ['Multiple mappings exist for the same Simulink port.' char(10) '%s']},
            {'Untyped_Parameter', 'Parameter $select{%s}{%s} is untyped.'},
            {'Untyped_Calibration', 'Calibration Port $select{%s}{%s} is untyped.'},
            {'Calibration_Type', 'Calibration Port $select{%s}{%s} does not have a valid type.'}
            {'Untyped_DataElement', 'Data Element $select{%s}{%s} is not typed.'},
            {'Unused_DataElement', 'Data Element $select{%s}{%s} is not used.'},
            {'CalibrationInterface_Element', 'Calibration interface element $select{%s}{%s} must be a Calibration Parameter.'}
            {'Untyped_CalibrationParameter', 'Calibration Parameter $select{%s}{%s} is not typed.'},
            {'Unused_CalibrationParameter', 'Calibration Parameter $select{%s}{%s} is not used.'},
            {'ClientServerInterface_Attribute', 'Client Server Interface $select{%s}{%s} cannot have attributes.' },
            {'Return_Parameter', 'Return parameter $select{%s}{%s} is not supported by AUTOSAR.' },
            {'Multiple_Datatype_Packages', 'Multiple datatype packages defined. $select{%s}{%s} and $select{%s}{%s}.'}
            };
    end
    
    % try to find a temporary message
    if ischar(messageId)
        for i=1:length(temporaryMATLABOnlyMessages)
            msg = temporaryMATLABOnlyMessages{i};
            if strcmp(msg{1}, messageId)
                messageStr = msg{2};
                return;
            end
        end        
    end
    messageStr = M3I.privateGetMessageStringFromId(messageId);
end

% LocalWords:  uri Validator AUTOSAR
