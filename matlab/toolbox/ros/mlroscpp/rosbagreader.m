classdef rosbagreader < ros.BagSelection
    
    properties (Access = private)
        CallerName
    end
    
    methods
        function obj = rosbagreader(filePath, varargin) 
            filePath = convertStringsToChars(filePath);
            absFilePath = robotics.internal.validation.findFilePath(filePath);

            % rosBagTfImpl will hold the c++ object of rosbag tf
            rosBagTfImpl = [];

            if isequal(length(varargin), 4) && ...
                    isequal(varargin{4}, 'loadobj')
                %This operation is allowed only While loading object from 
                % a .mat file.
                
                narginchk(5,5);
                cleanPath = ros.internal.setupRosEnv(); %#ok<NASGU> 
                bagWrapper = roscpp.bag.internal.RosbagWrapper(absFilePath);
                msgList = varargin{1};
                topicTypeMap = varargin{2};
                topicDefinitionMap = varargin{3};
            elseif isequal(length(varargin), 6) && ...
                    isequal(varargin{6}, 'select')
                % This operation is allowed only if it is called from
                % select() API.
                
                narginchk(7,7);
                bagWrapper = varargin{1};
                msgList = varargin{2};
                topicTypeMap = varargin{3};
                topicDefinitionMap = varargin{4};
                rosBagTfImpl = varargin{5};
            else
                if isequal(length(varargin), 1) && ...
                    isequal(varargin{1}, 'noTf')
                    narginchk(2,2);
                    rosBagTfImpl = false;
                else
                    % Actual rosbagreader call (from user or from any other place). 
                    narginchk(1,1);
                end
                
                % Parse the given rosbag
                bagParser = ros.bag.internal.BagParser(absFilePath);
                bagWrapper = bagParser.Bag;
                msgList = bagParser.MessageList;
                topicTypeMap = bagParser.TopicTypeMap;
                topicDefinitionMap = bagParser.TopicDefinitionMap;
            end
             
            % Create a bag selection and return it to the user
            obj = obj@ros.BagSelection(absFilePath, bagWrapper, ...
                msgList, topicTypeMap, topicDefinitionMap,rosBagTfImpl);
        end
        
        function rosBagReader = select(obj, varargin)
            if nargin == 1
                rosBagReader = obj;
                return;
            end

            indexOp = parseAndIndex(obj, varargin{:});

            % Return a new bag selection based on the filtering criteria
            bagParser = ros.bag.internal.BagParser(obj.FilePath);
            rosBagReader = rosbagreader(obj.FilePath, bagParser.Bag, ...
                                         obj.MessageList(indexOp,:), obj.TopicTypeMap, ...
                                         obj.TopicDefinitionMap, obj.BagTF, 'select');
        end
    end
     
    methods (Static)
        function obj = loadobj(s)
            obj = rosbagreader(s.FilePath, s.MessageList, ...
                                   s.TopicTypeMap, s.TopicDefinitionMap, 'loadobj');
        end
    end
end

%   Copyright 2022 The MathWorks, Inc.
