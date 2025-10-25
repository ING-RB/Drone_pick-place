function InitWritePointCloud(block)
%This function is for internal use only. It may be removed in the future.

%%InitWritePointCloud - initialization function for the Write Point Cloud block

%   Copyright 2021-2022 The MathWorks, Inc.

    msk = Simulink.Mask.get(block);
    msk.SelfModifiable = 'on';
    params = msk.Parameters;

    ports = {'/RGB' '/Alpha' '/Intensity'};
    enabled = [];

    portDisplay = "port_label('input', 1, 'XYZ'); port_label('output', 1, 'Msg');";

    resetPorts = false;
    InportPort = 2;

    for iParam = 1:length(params)
        switch params(iParam).Name
            case 'Encoding'
              set(params(iParam), 'TypeOptions', {'none', 'rgb', 'rgba'});
              SelectedEncoding = params(iParam).Value;

            case 'FieldNamesStruct'
                % Create the expression for the field names struct
                fields = "'x', 'single', 'y', 'single', 'z', 'single'";
                if HasRGBValue
                    if HasAlphaValue
                        fields = fields + ", 'rgba', 'uint32'";
                    else
                        fields = fields + ", 'rgb', 'uint32'";
                    end
                end
                if HasIntensityValue
                    fields = fields + ", 'intensity', 'single'";
                end

                fields = "struct(" + fields + ")";
                set(params(iParam), 'Value', fields)

            case 'HasRGB'
                % Determine if we have RGB values
                HasRGBValue = any(strcmp(SelectedEncoding, {'rgb', 'rgba'}) );
                params(iParam).Value = string(HasRGBValue);
                if HasRGBValue
                    if ~contains(msk.Display, 'RGB')
                        resetPorts = true;
                    end
                    % Change the ground block to an input block
                    % replace_block([block '/RGB'], 'Ground', 'Inport', 'noprompt')
                    portDisplay = portDisplay +  ...
                        convertCharsToStrings([' port_label(''input'',' num2str(InportPort) ',''RGB'');']);
                    
                    enabled = [enabled true];

                    InportPort = InportPort + 1;
                else
                    if contains(msk.Display, 'RGB')
                        resetPorts = true;
                    end

                    enabled = [enabled false];

                    % No rgb values, turning off the block
                    % replace_block([block '/RGB'], 'Inport', 'Ground', 'noprompt');
                end

            case 'HasAlpha'
                % Determine if we have Alpha values
                HasAlphaValue = strcmp(SelectedEncoding, 'rgba');
                params(iParam).Value = string(HasAlphaValue);
                if HasAlphaValue
                    if ~contains(msk.Display, 'Alpha')
                        resetPorts = true;
                    end

                    portDisplay = portDisplay +  ...
                        convertCharsToStrings([' port_label(''input'',' num2str(InportPort) ',''Alpha'');']);

                    enabled = [enabled true];
                   
                    InportPort = InportPort + 1;
                else
                    if contains(msk.Display, 'Alpha')
                        resetPorts = true;
                    end
                    
                    enabled = [enabled false];
                end

            case 'HasIntensityCheck'
                % Set the HasIntensity parameter using a checkbox
                HasIntensityValue = strcmp(params(iParam).Value, 'on');

            case 'HasIntensity'
                params(iParam).Value = string(HasIntensityValue);
                
                if HasIntensityValue
                    if ~contains(msk.Display, 'Intensity')
                        resetPorts = true;
                    end

                    portDisplay = portDisplay + ...
                        convertCharsToStrings([' port_label(''input'', ' num2str(InportPort) ', ''Intensity'');']);

                    enabled = [enabled true];

                    InportPort = InportPort + 1;
                else
                    if contains(msk.Display, 'Intensity')
                        resetPorts = true;
                    end

                    enabled = [enabled false];
                end
                
        end
    end

    % If there is a change, we need to reset the ports by setting them to
    % ground
    if resetPorts
        for iPort = 1:length(ports)
            replace_block([block ports{iPort}], 'Inport', 'Ground', 'noprompt')
        end
    end

    % Then turn the grounds into ports
    enabled = logical(enabled);
    if any(enabled)
        enabledPorts = ports(enabled);
        for iPort = 1:length(enabledPorts)
            replace_block([block enabledPorts{iPort}], 'Ground', 'Inport', 'noprompt');
        end
    end

    msk.Display = portDisplay;
end
