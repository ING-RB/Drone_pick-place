classdef MotionWriterPlugin < positioning.internal.PluginWriterBase
%MOTIONWRITERPLUGIN Class for writing new motion models for insEKF
%   Writes a templatized version of a positioning.INSMotionModel
%

%   Copyright 2022 The MathWorks, Inc.    

    methods 
        function writeTemplate(writer, name)
            writer.setupWriter(name);
            writer.writeStatesFunction;
            writer.writeStateTransition;
            writer.writeStateTransitionJacobian;
        end
    end

    methods (Access = protected)
        function b = getBaseClass(~)
            b = 'positioning.INSMotionModel';
        end
        function p = getPluginType(~)
            p = 'Motion';
        end
        function ex = getExample(writer)
            exs = "filt = insEKF(" + writer.ClassWriter.Name + ");";
            ex = [blanks(4) char(exs)];
        end
        function n = statesOptionalNote(~)
            n = {};
        end
        function n = getStatesFcnName(~)
            n = 'modelstates';
        end
        function c = callStateInfoPreamble(~, filtname)
            c = "stateinfo(" + filtname;
        end
    end
end

