function dduxUpdateBlock(varargin)

    try 
        
        % Identifies DDUX data
        Product = "ML";
        AppComponent = "ML_HWC";
        EventKey = "ML_HWC_SENSOR_INFO";
        
        % coder.internal.errorIf(true, 'matlab_sensors:general:propertyValueFixedCodegen','Dummy', '3');
        
        dataid = matlab.ddux.internal.DataIdentification(Product,AppComponent,EventKey);
        data = struct();
        data.sensor_product = "Simulink"; %Collect the sensor product
        data.sensor_name = varargin{2};    % Collect name of the sensor   
        data.board_name = varargin{3};
        data.sensor_hsp=regexprep(data.board_name, '\ .*', '');  % Collect HSP name of the target

        if varargin{1}
            data.sensor_interface=varargin{4};     % Collect the interface info between board and sensor
            if varargin{5}
                data.sensor_mode = matlabshared.sensors.internal.Mode.Streaming;
            else
                data.sensor_mode = matlabshared.sensors.internal.Mode.OnDemand;
            end
            data.sensor_mode = char(data.sensor_mode);
            data.sensor_api = varargin{6};
        else    
            % coder.internal.errorIf(true, 'matlab_sensors:general:propertyValueFixedCodegen','Dummy', '2');
            if strcmpi(get_param(bdroot,"ExtMode"),'on')
                data.sensor_mode="Monitor and tune";
            else
                data.sensor_mode = "Build";
            end
            
        end 
        matlab.ddux.internal.logData(dataid,data);
    catch
    
    end

end