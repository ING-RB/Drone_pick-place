classdef PluginWriterBase < handle
%PLUGINWRITERBASE Base class for sensor and motion model writer

%   Copyright 2022 The MathWorks, Inc.    
   
    properties
        ClassWriter  % handle to class writer
        FcnWriter   % handle to current method generator
    end
    properties (Constant)
        StateNames = {'State1Length', 'State2Length'};
        CommentWrap = 59;
    end

    methods
        function setupWriter(writer, className)
            %SETUPWRITER Setup the internal file writer
            %   className - name of the class
            plugintype = lower(getPluginType(writer));

            clswrtr = sigutils.internal.emission.MatlabClassGenerator;
            writer.ClassWriter = clswrtr;
            clswrtr.Name = char(className);
            clswrtr.RCSRevisionAndDate = false;
            clswrtr.TimeStampInHeader = true;
            clswrtr.H1Line = ['Template for ' plugintype ' model using insEKF'];
            clswrtr.Help = {...
                ['Customize this ' plugintype ' model and use it with the insEKF to fuse'], ...
                'data.', ...
                '', ...
                'Example:', ...
                getExample(writer)}; 
            clswrtr.SeeAlso = {'insEKF', getBaseClass(writer)};
            clswrtr.SuperClasses = getBaseClass(writer); 


            % Create properties
            prop = sigutils.internal.emission.PropertyDef('State1Length');
            prop.H1Line = ['Length of ' plugintype ' model state State1'];
            prop.Attributes = 'Constant';
            prop.InitValue = '1';
            writer.ClassWriter.addProperty(prop);

            prop = sigutils.internal.emission.PropertyDef('State2Length');
            prop.H1Line = ['Length of ' plugintype ' model state State2'];
            prop.Attributes = 'Constant';
            prop.InitValue = '2';
            writer.ClassWriter.addProperty(prop);

            addProps(writer); % Add base class specific props
        end

        function b = getBuffer(writer)
            b = getFileBuffer(writer.ClassWriter);
        end

        function writeContentsToEditor(writer)
            buff = getBuffer(writer);
            indentCode(buff);
            contents = char(buff);
            editorDoc = matlab.desktop.editor.newDocument(contents);
            editorDoc.Text = contents;
            editorDoc.smartIndentContents;
            editorDoc.goToLine(1);
        end

        function writeStateTransition(writer)
            %WRITESTATETRANSITION Write the stateTransition method
            mw = sigutils.internal.emission.MatlabMethodGenerator;
            writer.FcnWriter = mw;
            mw.Name = 'stateTransition';
            plugintype = lower(getPluginType(writer));
            pluginstates = [plugintype 'states'];
            mw.InputArgs = {plugintype, 'filt', 'dt', 'varargin'};
            mw.OutputArgs = {'statesdot'};
            mw.H1Line = ['State transition for ' plugintype ' states'];
            mw.Help = {...
              'STATETRANSITION returns a struct with identical fields', ...
              ['as the output of the ' getStatesFcnName(writer) ' function. The'], ...
              'returned struct describes the per-state transition function' , ...
              ['for the ' plugintype, ' model states.'], ...
              '', ...
              'This function is called by the insEKF object FILT when the', ...
              'PREDICT method of the FILT function is called. The DT and ', ...
              'varargin inputs are the corresponding inputs to the', ...
              'predict method of the insEKF object.', ...
              '', ...
              '*** THIS METHOD IS OPTIONAL ***', ...
              'If you delete this method, the model states will be', ...
              'constant. In this case, also delete the ', ...
              'stateTransitionJacobian method.'};
            mw.SeeAlso = {'insEKF', [' ' getBaseClass(writer)]};
           
            % State1
            writer.addComment([... 
                "Set statesdot.State1 to the derivative of State1 with", ...
                "respect to time. If State1 is constant overtime, leave the", ...
                "following line unchanged."]);
            writer.addCode(...
                "statesdot.State1 = zeros(1, " + plugintype + ".State1Length, ""like"", filt.State);");

            writer.addCR();

            % State2
            writer.addComment([... 
                "Set statesdot.State2 to the derivative of State2 with", ...
                "respect to time. If State2 is constant overtime, leave the", ...
                "following line unchanged."]);
            writer.addCode(...
                "statesdot.State2 = zeros(1, " + plugintype + ".State2Length, ""like"", filt.State);");

            addMethod(writer.ClassWriter, mw);
        end

        function writeStateTransitionJacobian(writer)
            %WRITESTATETRANSITIONJACOBIAN Write the stateTransitionJacobian
            %   method
            mw = sigutils.internal.emission.MatlabMethodGenerator;
            writer.FcnWriter = mw;
            mw.Name = 'stateTransitionJacobian';
            plugintype = lower(getPluginType(writer));
            pluginstates = [plugintype 'states'];
            mw.InputArgs = {plugintype, 'filt', 'dt', 'varargin'};
            mw.OutputArgs = {'dfdx'};
            mw.H1Line = 'Jacobian of the stateTransition function';
            mw.SeeAlso = {'insEKF', [' ' getBaseClass(writer)]};
            mw.Help = {...
                'STATETRANSITIONJACOBIAN returns a struct with identical', ...
                ['fields as ' getStatesFcnName(writer) ' and describes the Jacobian of the'], ...
                'per-state transition function relative to the State', ...
                'property of FILT. Each field value of STATESDOT should be a', ...
                'M-by-numel(FILT.State) row vector, representing the partial', ... ', ...
                ['derivatives of ' char("that field's state transition function")], ...
                'relative to the state vector.', ...
                '', ...
                'This function is called by the insEKF object FILT when the', ...
                'PREDICT method of the FILT function is called. The DT and', ...
                'varargin inputs are the corresponding inputs to the', ...
                'predict method.', ...
                '', ...
                '*** THIS METHOD IS OPTIONAL ***', ...
                'If this method is not implemented, a numerical Jacobian', ...
                'will be used instead.'};

            writer.addCode("N = numel(filt.State);");
            writer.addCR;

            writer.addCode("dfdx.State1 = zeros(" + plugintype + ".State1Length, N, ""like"", filt.State);"); 
            writer.addCode("dfdx.State2 = zeros(" + plugintype + ".State2Length, N, ""like"", filt.State);"); 
            writer.addCR;

            % Create indexing
            writer.addComment("Create indexing");
            writer.addCode("s1idx = " + callStateInfoPreamble(writer, "filt") + ", ""State1"");");
            writer.addCode("s2idx = " + callStateInfoPreamble(writer, "filt") + ", ""State2"");");
            writer.addCR;

            % Assign State1
            writer.addComment("Uncomment the line below, and set dfdx.State1 to the Jacobian " + ...
                "of the stateTransition function with respect to the State property " + ...
                "of the filter object filt. Use s1idx to index the columns of dfdx.State1.");
            writer.addCR;
            writer.addComment("% dfdx.State1(:,s1idx) =");

            writer.addCR;

            % Assign State2
            writer.addComment("Uncomment the line below, and set dfdx.State2 to the Jacobian " + ...
                "of the stateTransition function with respect to the State property " + ...
                "of the filter object filt. Use s2idx to index the columns of dfdx.State2.");
            writer.addCR;
            writer.addComment("% dfdx.State2(:,s2idx) =");

            addMethod(writer.ClassWriter, mw);
        end

        function writeStatesFunction(writer)
            % writeStatesFunction  write sensorstates or modelstates
            mw = sigutils.internal.emission.MatlabMethodGenerator;
            writer.FcnWriter = mw;
            plugintype = lower(getPluginType(writer));
            statesFcnName = getStatesFcnName(writer);
            mw.Name =  char(statesFcnName);
            mw.InputArgs = {plugintype, 'opts'};
            mw.OutputArgs = 's';
            mw.H1Line = ['Define the tracked states for this ' plugintype ' model'];
            mw.Help = {...
                [upper(mw.Name) ' returns a struct which describes the'], ...
                ['states used by this '  plugintype ' model and tracked by the insEKF'], ...
                'filter object. The field names describe the individual state', ...
                'quantities, and you can access the estimates of those', ...
                'quantities through the statesparts function. The values of', ...
                'the struct determine the size and default values of the', ...
                'state vector. The input OPTS is the insOptions object used', ...
                'to build the filter.'};

            note = statesOptionalNote(writer);
            mw.Help = [mw.Help, note];


            writer.addComment("Preallocate a struct with fields State1 and State2. Overwrite " + ...
                "the fields with different default values if needed.");
            writer.addCode("s = struct(""State1"", zeros(1, " + plugintype +  ".State1Length, opts.Datatype), ..." + newline + ...
                """State2"", zeros(1, " + plugintype +  ".State2Length, opts.Datatype));");
            
            mw.SeeAlso = {'insEKF',  [' ' getBaseClass(writer)]};

            addMethod(writer.ClassWriter, mw);
        end

        function writeMeasurementFunction(writer)
            %WRITEMEASUREMENTFUNCTION  - write measurement method
            mw = sigutils.internal.emission.MatlabMethodGenerator;
            writer.FcnWriter = mw;
            mw.Name =  'measurement'; 
            mw.InputArgs = {'sensor', 'filt'};
            mw.OutputArgs = 'z';
            mw.H1Line = 'Sensor measurement estimate from states'; 
            mw.Help = {...
                'MEASUREMENT returns a 1-by-MEASUERMENTLENGTH array of ', ...
                'predicted measurements for this SENSOR based on the current', ...
                'state of filter FILT. The FILT input is an insEKF object.'};
               
            mw.SeeAlso = {'insEKF', [' ' getBaseClass(writer)]};

            writer.addCommentLines([...
                "Preallocate the measurement and get the current value of the", ...
                "sensor-related states."]);

            writer.addCR;
            writer.addCode("z = zeros(1,sensor.MeasurementLength, ""like"", filt.State);"); 
            writer.addCR;
            writer.addCode("state1 = stateparts(filt, sensor, ""State1"");");
            writer.addCode("state2 = stateparts(filt, sensor, ""State2"");");
            writer.addCR;
            writer.addCommentLines([...
                "Uncomment the line below and fill in z as a function of", ...
                "the State property (of the filt object) and sensor states", ...
                "(defined in the sensorstates method) if necessary.", ...
                "", ...
                "z = ..."]);
            addMethod(writer.ClassWriter, mw);
            
        end

        function writeMeasurementJacobian(writer)
            %WRITEMEASUREMENTJACOBIAN write measurementJacobian function
            mw = sigutils.internal.emission.MatlabMethodGenerator;
            writer.FcnWriter = mw;
            mw.Name =  'measurementJacobian'; 
            mw.InputArgs = {'sensor', 'filt'};
            mw.OutputArgs = 'dzds';
            mw.H1Line = 'Jacobian of the measurement method'; 
            mw.Help = {...
                'MEASUREMENTJACOBIAN returns an M-by-NS matrix which is the', ...
                'Jacobian of the MEASUREMENT method relative to the State', ...
                'property of filter FILT. The FILT input is an instance of', ...
                'an insEKF filter. Here M is the number of elements in a', ...
                'sensor measurement and NS is the number of elements', ...
                'in the State property of FILT.', ...
                '', ...
                '*** THIS METHOD IS OPTIONAL ***', ...
                'If this method is not implemented a numeric Jacobian', ...
                'will be computed instead.'
                    
                    };

            mw.SeeAlso = {'insEKF', [' ' getBaseClass(writer)]};

            writer.addCR;
            writer.addCode("N = numel(filt.State); % Number of states")
            writer.addCR;
            writer.addComment("Initialize a matrix of partial derivatives.");
            writer.addCode("dzds = zeros(sensor.MeasurementLength,N, ""like"", filt.State);");

            writer.addComment("Get the indicies of each state being used.");
            writer.addCode("s1idx = stateinfo(filt, sensor, ""State1"");");
            writer.addCode("s2idx = stateinfo(filt, sensor, ""State2"");");

            writer.addCR;
            writer.addComment("Uncomment the line below, and set dzds to the Jacobian " + ...
                "of the measurement function with respect to the State property of the filter " + ...
                "object filt. The rows of dzds correspond to a measurement index while the " + ...
                "columns correspond to a state index. Use s1idx and s2idx to index the columns of dzds.");
            writer.addCR;
            writer.addComment("dzds = ...");
            addMethod(writer.ClassWriter, mw);
        end

    end

    % Helper methods
    methods (Access = 'protected')
        function addCode(writer, s)
            % Add code to the current writer
            writer.FcnWriter.addCode(char(s));
        end
        function addCR(writer)
            % Add a carriage return
            addCode(writer.FcnWriter, ' '); % add a carriage return
        end
        function addCommentLines(writer, s)
            % Add several lines of comments. s is a cellstr or string array.
            cs = cellstr(s);
            for ii=1:numel(s)
                addCode(writer.FcnWriter, ['% ', cs{ii}]);
            end
        end
        function addComment(writer, s)
            % Add several lines of comments and wrap. 
            w = textwrap(s, writer.CommentWrap );
            c = '% ' + string(w);
            for ii=1:numel(c)
                addCode(writer.FcnWriter, char(c(ii)));
            end
        end
        function addProps(~)
            % Override to add any base class specific properties. 
            % Default implementation is empty.
        end
    end

    methods(Abstract, Access = protected)
        b = getBaseClass(writer);
        p = getPluginType(writer); 
        ex = getExample(writer)
        n = statesOptionalNote(writer);
        n = getStatesFcnName(writer);
        c = callStateInfoPreamble(writer, filtname);
    end
    
end

