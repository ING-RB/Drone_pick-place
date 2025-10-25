classdef SensorWriterPlugin < positioning.internal.PluginWriterBase
%SENSORWRITERPLUGIN Class for writing new sensors for insEKF
%   Writes a templatized version of a positioning.INSSensorModel
%

%   Copyright 2022 The MathWorks, Inc.    

    methods 
        function writeTemplate(writer, name)
            writer.setupWriter(name);
            writer.writeStatesFunction;
            writer.writeMeasurementFunction;
            writer.writeStateTransition;
            writer.writeMeasurementJacobian;
            writer.writeStateTransitionJacobian;
        end
    end
    methods (Access = protected)
        function b = getBaseClass(~)
            b = 'positioning.INSSensorModel';
        end
        function p = getPluginType(~)
            p = 'Sensor';
        end
        function ex = getExample(writer)
            exs = "filt = insEKF(" + writer.ClassWriter.Name + ", insMotionPose);";
            ex = [blanks(4) char(exs)];
        end
        function n = statesOptionalNote(~)
            n = {' ', ...
                '*** THIS METHOD IS OPTIONAL ***'...
                'If you delete this method, also delete stateTransition and', ...
                'stateTransitionJacobian, and any references in the class to', ...
                'State1 or State2.'};
        end
        function n = getStatesFcnName(~)
            n = 'sensorstates';
        end
        function addProps(writer)
            mlenprop = sigutils.internal.emission.PropertyDef('MeasurementLength');
            mlenprop.H1Line = 'Length of the sensor measurement';
            mlenprop.Attributes = 'Constant';
            mlenprop.InitValue = '3';
            writer.ClassWriter.addProperty(mlenprop);
        end
        function c = callStateInfoPreamble(~, filtname)
            c = "stateinfo(" + filtname + ", sensor";
        end
    end
end

