classdef nmeaParser < matlabshared.gps.internal.SensorConnectivityBase
    %NMEAPARSER parses data from NMEA sentences
    %   parserObj = nmeaParser parses data from these NMEA messages: RMC,
    %   GGA, and GSA. These message IDs are the default property values.
    %   The order of structure arrays in the parsed output data follows
    %   the order: parsed RMC data, parsed GGA data, and parsed GSA data.
    %
    %   parserObj = nmeaParser("MessageIDs",msgId) parses data from
    %   different NMEA messages specified using Name-Value pair 'MessageIDs'.
    %   Specify msgIds as "RMC", "GGA", "GSA", "VTG", "GLL", "GST", "ZDA",
    %   "HDT", and "GSV" or a combination of these IDs (for example:
    %   ["VTG","GLL","HDT"]). The order in which you specify the Message IDs
    %   determines the order of the parsed structure arrays in the output data.
    %   The default value is ["RMC","GGA","GSA"].
    %   
    %   parserObj = nmeaParser("MessageIDs",msgId,"CustomSentence",...
    %   {["MessageId1","FunctionName1"], ["MessageId2","FunctionName2"]})
    %   configures nmeaParser to parse messages other than the built-in
    %   messages of "RMC", "GGA", "GSA", "VTG", "GLL", "GST", "ZDA", "HDT",
    %   and "GSV." CustomSentence accepts a nested Cell array where each
    %   element is a pair of message ID name and name of the function 
    %   written by the user that extracts the message. The user-defined
    %   function must accept two arguments. First argument reads the 
    %   unparsed data, and the second argument reads MessageID. The function
    %   returns one argument which is used internally by the nmeaParser
    %   to return the parsed output data.
    %   Here is an example of the function signature 
    %   function OutputData = FunctionName1(unparsedData, MessageID)
    %
    %   NMEAPARSER methods:
    %
    %   step           - See the below description for using this method.
    %   release        - Release the system object. After release, the
    %                    message IDs can be changed.
    %   clone          - Create another NMEAPARSER object with the same
    %                    property values
    %   isLocked       - Display locked status (logical)
    %
    %   Syntax for 'step' method:
    %
    %   [out1,out2,....] =  step(parserObj,data), parses data and returns
    %   the parsed data as structures. If you specify more than one
    %   MessageIDs, then it returns multiple structures where each
    %   structure corresponds to a single MessageID. The location of the
    %   output structure is as per the order in which MessageIDs are
    %   specified during object creation.
    %
    %   System objects can be called directly like a function instead of
    %   using the step method. For example, y = step(obj, x) and y = obj(x)
    %   are equivalent.
    %
    %   NMEAPARSER properties:
    %
    %   MessageIDs  -  Specify the message IDs of the sentences to be
    %   parsed. Multiple message IDs can be specified as an array of
    %   strings, or a cell array of character vectors. The supported
    %   message IDs are "RMC", "GGA", "GSA", "GLL", "VTG", "GST", "HDT",
    %   "ZDA", and "GSV".
    %
    %   Status field:
    %   
    %   All output structures have a status field, displayed along with  
    %   the extracted values, which can be used to determine the parsing
    %   status. The possible status values are:
    %   Status: 0 - Sentence is valid (checksum validation is successful) 
    %               and the extracted data is as per the requested Message
    %               ID
    %   Status: 1 - Sentence is invalid. Checksum of the sentence to be 
    %               parsed is invalid
    %   Status: 2 - The requested sentence is not found in the input data
    %
    %   Example:
    %
    %   ggaRawData = ['$GPGGA,111357.771,5231.364,N,01324.240,E,1,12,'...
    %                 '1.0,0.0,M,0.0,M,,*69'];
    %   gsaRawData = ['$GPGSA,A,3,01,02,03,04,05,06,07,08,09,10,11,12,'...
    %                 '1.0,1.0,1.0*30'];
    %   rmcRawData = ['$GNRMC,105440.000,A,6012.5669,N,02449.6536,E,'...
    %                 '0.00,0.00,061112,,,D*70'];
    %   gsvRawData = ['$GPGSV,3,1,12,42,55,137,43,16,54,279,39,31,47,04'...
    %                  '9,48,27,37,187,37*77'];
    %   rawNMEAData = [ggaRawData, newline, gsaRawData, newline,...
    %                  rmcRawData, newline, gsvRawData];
    %
    %   % Parse NMEA sentences and extract GGA and GSA data
    %   parserObj = nmeaParser("MessageIDs",["GGA","GSA"]);
    %   [ggaData,gsaData] =  parserObj(rawNMEAData);
    %
    %   % Parse NMEA sentences and extract RMC data
    %   release(parserObj);
    %   parserObj.MessageIDs = "RMC";
    %   rmcData = parserObj(rawNMEAData);
    %
    %   % Parse NMEA sentences and extract GSV data
    %   release(parserObj);
    %   parserObj.MessageIDs = "GSV";
    %   gsvData = parserObj(rawNMEAData);
    %
    %   See also EXTRACTNMEASENTENCE, GPSDEV
    
    %   Copyright 2020-2023 The MathWorks, Inc.
    
    properties (Nontunable)
        %MessageIDs  -  Specify the message IDs of the sentences to be
        %   parsed. The supported message IDs are "RMC", "GGA", "GSA", 
        %   "GLL", "VTG", "GST", "HDT", "ZDA", and "GSV". Multiple message
        %   IDs can be specified as an array of strings (for example:
        %   ["VTG","GLL","HDT"]), or a cell array of character vectors.
        %   Type:Nontunable
        %   Default: ["RMC","GGA","GSA"]
        MessageIDs = ["RMC","GGA","GSA"];
    end
    
    properties(Access = private,Constant)
        ChecksumStartChar = '*';
        StartChar = '$';
    end
    
    properties(Access = private)
        NumOutputs
        SupportedMessageIDs
        
        %Custom messages
        NoOfCustomMessages           
        CustomMessageHandlesMap        
        CustomMessageIDs
        MaxLengthCustomMessageIDs = 0;        
    end
    
    properties(Hidden, GetAccess=private)
        CustomSentence
    end
    
    methods
        function obj = nmeaParser(varargin)
            try
                narginchk(0,4);
                p = inputParser;
                addParameter(p, 'MessageIDs',obj.MessageIDs);
                
                addParameter(p,'CustomSentence',{});

                parse(p, varargin{:});               
                
                % Get the list of supported Message IDs.
                obj.SupportedMessageIDs = matlabshared.gps.internal.getSupportedMessageIDs;
                customSentenceValue = p.Results.CustomSentence;
                
                validateCustomSentenceValues(obj,customSentenceValue);             
                % Case where MessageIDs and CustomSentence are empty then
                % init MessageIDs to ["RMC","GGA","GSA"] for backward
                % compatibility
                containsMessageIDs = contains(p.UsingDefaults,{'MessageIDs'});
                usingDefaultsMessageID = false;                 
                if(~isempty(containsMessageIDs) && containsMessageIDs(1,1))
                   usingDefaultsMessageID = true; 
                end
                
                MessageIDs = p.Results.MessageIDs;
                
                if(usingDefaultsMessageID && ~isempty(p.Results.CustomSentence) )
                   MessageIDs = []; 
                end

               %Check duplicate messages after populating MessageIDs
                checkDuplicateMessageID(obj,MessageIDs,obj.CustomMessageIDs);              
                
               setProperties(obj,nargin,"MessageIDs",[MessageIDs,obj.CustomMessageIDs],"CustomSentence",p.Results.CustomSentence);

            catch ME
                throwAsCaller(ME);
            end
        end
    end        
        
methods(Access=private)         
        
        function validateCustomSentenceValues(obj,customSentenceValue)
               if(~isempty(customSentenceValue) && ~isa(customSentenceValue, "cell") && size(customSentenceValue,1)==1 )
                   error(message("shared_gps:general:InvalidCustomSentenceValue"));
               end
               if(~isempty(customSentenceValue))
                   customSentenceCellArray = cell(size(customSentenceValue));
                   for index = 1: length(customSentenceValue)
                       if(isa(customSentenceValue{index},'string') && all(size(customSentenceValue{index})==[1,2]))
                           tempString = customSentenceValue{index};
                           tempCellArray = {tempString(1),tempString(2)};

                           customSentenceCellArray{index} = tempCellArray;
                       else
                           if(~all(size(customSentenceValue{index})==[1,2]))
                               error(message("shared_gps:general:InvalidCustomSentenceValue"));
                           end
                           customSentenceCellArray{index} = customSentenceValue{index};
                       end
                   end   

                   % Container map to store function handles for
                   obj.CustomMessageHandlesMap = containers.Map;
                   obj.NoOfCustomMessages = length(customSentenceCellArray);
                   returncustomSentenceCellArray = extractCustomMessageIDs(obj,customSentenceCellArray);
                   extractFunctionHandles(obj,returncustomSentenceCellArray);
               end                        
        end
        
        function checkDuplicateMessageID(~, msgId, customMsgID)

            if(~isa(msgId, "string"))
                msgId = string(msgId);
            end

            for index = 1 : length(customMsgID)
                if(any(strcmp(msgId,customMsgID(index))))
                   error(message("shared_gps:general:DuplicateMessageID",customMsgID(index)));                    
                end
            end

        end
    end

methods(Access=private)        
        function customSentenceCellArray = extractCustomMessageIDs(obj,customSentenceCellArray)
            for index = 1 : obj.NoOfCustomMessages
                % Verify that first argument of the cell array is a
                % string or character array
                % n = nmeaParser("MessageIDs",["RMC"], {"CustomSentence", {"GRME",fgrme}})
                % Cell array under verification is {"GRME",fgrme}
                if~(ischar(customSentenceCellArray{index}{1}) || isStringScalar(customSentenceCellArray{index}{1}))
                   error(message("shared_gps:general:InvalidCustomSentenceMessageID"));                    
                else
                    % convert the characters to strings for further logic                    
                    customSentenceCellArray{index}{1} = string(customSentenceCellArray{index}{1});
                end
                
                % Update MessageIDs with the new Custom Sentence
                % Messages
                obj.SupportedMessageIDs = [obj.SupportedMessageIDs, customSentenceCellArray{index}{1}];
                obj.CustomMessageIDs = [obj.CustomMessageIDs, customSentenceCellArray{index}{1}];
                obj.MessageIDs = [obj.MessageIDs, obj.CustomMessageIDs];


                % Compute maximum length of the custom message
                % Required during parsing
                if(strlength(customSentenceCellArray{index}{1}) > obj.MaxLengthCustomMessageIDs)
                    obj.MaxLengthCustomMessageIDs = strlength(customSentenceCellArray{index}{1});
                end
                
            end
            
            
        end
        
        function extractFunctionHandles(obj,customSentenceCellArray)
            for index = 1 : obj.NoOfCustomMessages
                % Verify that the second argument of cell array is a
                % function handle or a function name
                % Cell array under verification is {"GRME",fgrme}
                if~(isa(customSentenceCellArray{index}{2},"function_handle") || isa(customSentenceCellArray{index}{2}, "string") || isa(customSentenceCellArray{index}{2}, "char"))
                   error(message("shared_gps:general:InvalidCustomSentenceFunctionType"));                                        
                end

                % Add the function handles to the 
                if(isa(customSentenceCellArray{index}{2},"function_handle"))
                    obj.CustomMessageHandlesMap(customSentenceCellArray{index}{1}) = customSentenceCellArray{index}{2};
                else
                    obj.CustomMessageHandlesMap(customSentenceCellArray{index}{1}) = eval("@" + customSentenceCellArray{index}{2});
                end
                testFunction = obj.CustomMessageHandlesMap(customSentenceCellArray{index}{1});

                %Verify that custom function is a valid MATLAB function
                % try exist with function handle and function name
                try
                    testFunction();
                catch ME
                    if(strcmp(ME.identifier,'MATLAB:UndefinedFunction'))
                        error(message("shared_gps:general:InvalidCustomSentenceFunction"));
                    end
                end
            end        
        end
        
end        

methods
        function set.MessageIDs(obj,value)
            % Input can be character vector or string.For Multiple
            % MessageIDs, specify either as array of strings or cell array
            % of characters
            validateattributes(value,{'char','string','cell'},{'nonempty'});
            value = upper(string(value));
            % Function to validate given Message ID is supported
            msgIDs = obj.validateFcn(value);
            obj.MessageIDs = msgIDs;
        end
    end
    
    methods(Access = protected)
        function setupImpl(obj)
            obj.NumOutputs = numel(obj.MessageIDs);
        end
        
        function varargout = stepImpl(obj,inData)
            % Returns parsed data in structure format corresponding to inData.
            % The order of output is as per the order in which MessageIDs
            % are specified during object creation.
            try
                narginchk(2,2);
                nargoutchk(0,obj.NumOutputs);
                varargout = cell(1,obj.NumOutputs);
                % Check the datatype and range validity of input Data.
                inData = checkInputDataValidity(obj,inData);
                % This function looks for the sentence corresponding to required
                % messageIDs
                out = varargout;
                % returns cell array of NMEA lines, each column corresponds to
                % lines of each Message ID
                [out{:}] = preprocessData(obj,inData);
                for i = 1:obj.NumOutputs
                    % check for proprietary messages before looking for
                    % standard nmea messages
                    
                    CustomMessageFound = strcmp(obj.CustomMessageIDs, obj.MessageIDs(i));
                    if(any(CustomMessageFound))                        
                        % Proprietary message - Extract the Proprietary message id function handle
                        msgFunctionHandle = obj.CustomMessageHandlesMap(obj.MessageIDs(i));
                        if( ~isempty(out{i}))
                            noOfSentences = numel(out{i});
                            for j = 1 : noOfSentences
                                parsedOutput = msgFunctionHandle(out{i}{j},obj.MessageIDs(i));

                                %initialize the array of structures after you
                                %get the first output
                                if(j==1)
                                    % initialize outputs
                                    parsedOutputStructureArray = repmat(parsedOutput,noOfSentences,1);
                                end

                                parsedOutputStructureArray(j) = parsedOutput;
                            end
                            varargout{i} = parsedOutputStructureArray;
                        else
                            % passing 2 empty strings to Custom function 
                            parsedOutput = msgFunctionHandle("","");
                            varargout{i} = parsedOutput;
                        end
                    else
                      msgClassObj = matlabshared.gps.internal.getSentenceParser(obj.MessageIDs(i));
                      varargout{i} = parse(msgClassObj,out{i});
                    end
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@matlab.System(obj);            

            % Save private properties.
            s.NumOutputs = obj.NumOutputs;
            s.SupportedMessageIDs = obj.SupportedMessageIDs;
            s.NoOfCustomMessages  = obj.NoOfCustomMessages;           
            s.CustomMessageHandlesMap = obj.CustomMessageHandlesMap;        
            s.CustomMessageIDs = obj.CustomMessageIDs;
            s.MaxLengthCustomMessageIDs = obj.MaxLengthCustomMessageIDs; 
            s.CustomSentence = obj.CustomSentence; 

        end

        function loadObjectImpl(obj, s, wasLocked)

            % Load private properties.

            obj.SupportedMessageIDs = s.SupportedMessageIDs;           
            obj.NumOutputs = s.NumOutputs;
            obj.NoOfCustomMessages  = s.NoOfCustomMessages;           
            obj.CustomMessageHandlesMap = s.CustomMessageHandlesMap;        
            obj.CustomMessageIDs = s.CustomMessageIDs;
            obj.MaxLengthCustomMessageIDs = s.MaxLengthCustomMessageIDs; 
            obj.CustomSentence = s.CustomSentence; 

             % Load public properties.
            loadObjectImpl@matlab.System(obj, s, wasLocked);
        end
    end
    
    methods(Access = private)
        function msgIDs = validateFcn(obj,x)
            % Validate message IDs
            msgIDs = repmat(string(char(zeros(1,3))),1,numel(x));
            for i= 1:numel(x)
                msgIDs(i) = validatestring(x(i),convertStringsToChars(obj.SupportedMessageIDs));
            end
        end
        
        function inData = checkInputDataValidity(~,inData)
            % Check if input is ascii characters, if the input is numeric,
            % make sure the values are in the range [0x20,0x7F](specified
            % by NMEA)
            if isnumeric(inData)
                % check the values are in ASCII range (not extended range)
                validateattributes(inData, {'numeric'},{'nonempty','>=',0,'<=',127});
                inData = uint8(inData);
            else
                validateattributes(inData, {'char','string','numeric'},{'nonempty'});
            end
            inData = reshape(char(inData'),1,[]); 
        end
        
        function varargout = preprocessData(obj,inData)
            % Get lines of NMEA data corresponding to required Message IDs
            % Output of this function is a cell array where each column
            % corresponds to lines of one particular Message ID

            varargout = cell(1,obj.NumOutputs);
            splitData = split(inData,'$');

            if(~isempty(splitData))
                %move all the sentences to a common cell array
                for index = 1: length(splitData)
                    if(~isempty(splitData{index}))
                        tempString = splitData{index};
                        messageIndex = returnMessageIndexForSentence(obj,tempString);
                        if(messageIndex)
                                varargout{messageIndex}{end+1} = ['$', tempString];                                                       
                        end
                    end

                end
            end
        end
        function index = returnMessageIndexForSentence(obj, tempString)
            index = 0;
            if(contains(tempString,'*'))
                %verify 2 characters after "*" is a valid checksum
                checksumPrecursorPosition = strfind(tempString,'*');
                try
                    checksum = tempString(checksumPrecursorPosition(1)+1:checksumPrecursorPosition(1)+2);
                catch
                    % indicates that the there is only one or
                    % no elements after '*'
                    index = 0;
                    return;
                end

                %check if it is a valid checksum
                hexRange =  ['0':'9','A':'F'];
                if ~all(ismember(checksum,hexRange))
                    index = 0;
                    return;
                end

                MessageID = findMessageIDSentence(obj,tempString);
                index = find(obj.MessageIDs == MessageID);
            end

        end

        function MessageID = findMessageIDSentence(obj,tempString)
            if(tempString(1)=='P')
                MessageID = findMessageIDProprietarySentence(obj,tempString);
            else
                MessageID = tempString(3:5);
            end
        end
        
        function MessageID = findMessageIDProprietarySentence(obj, tempString)
            %find message Id for custom message
            manufacturerID = tempString(2:4);
            IDFound = 0;
            MessageID = "";
            for j = 1: obj.MaxLengthCustomMessageIDs - length(manufacturerID)
                MessageID = [manufacturerID, tempString(5:4+j)];

                for j2 = 1 : (length(obj.CustomMessageIDs))
                    if(strcmp(MessageID,obj.CustomMessageIDs{j2}))
                        IDFound = 1;
                        break;
                    end
                end

                if IDFound
                    break;
                end
            end                        

        end                
        
    end
end
