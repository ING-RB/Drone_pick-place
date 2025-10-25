classdef SerialportHardwareInfo < handle
    %SERIALPORTHARDWAREINFO contains the instrhwinfo('serialport') result.
    % E.g.
    %     data = internal.SerialportHardwareInfo.GetHardwareInfo()
    %     ans =
    %
    %     HardwareInfo with properties:
    %
    %         AllSerialPorts: ["COM1"    "COM3"    "COM11"]
    %         AvailableSerialPorts: ["COM3"    "COM11"]
    %         ObjectConstructorName: [3×1 string]
    
    %   Copyright 2019 The MathWorks, Inc
    methods (Hidden, Static)
        function out = GetHardwareInfo()
            % GETHARDWAREINFO returns the isntrhwinfo('serialport') result.
            
            out.AllSerialPorts = serialportlist("all")';
            out.AvailableSerialPorts = serialportlist("available")';
            
            objConstructorNames = "";
            for i = 1 : length(out.AllSerialPorts)
                objConstructorNames(i) = "serialport(""" + out.AllSerialPorts(i) + ...
                    """, 38400);"; %#ok<*AGROW>
            end
            out.ObjectConstructorName = objConstructorNames';
        end
    end
end