classdef (Hidden) DataMap
%

%   Copyright 2021 The MathWorks, Inc.

    properties (GetAccess=public, SetAccess=protected)
        Map struct = struct;
        DataSource matlab.graphics.data.DataSource
        NumObjects = 1
    end
    
    methods
        function obj=DataMap(ds)
            narginchk(1,1);
            assert(isscalar(ds), ...
                "MATLAB:graphics:data:NonScalarDataSource", "DataSource must be scalar");
            obj.DataSource=ds;
        end
        
        function obj=addChannel(obj,channel,subscript)
            assert(isvarname(channel), ...
                "MATLAB:graphics:data:InvalidChannelName", "Invalid channel name");
            try
                ind = obj.DataSource.subscriptToIndex(subscript, false);
            catch ME
                switch ME.identifier
                    case 'MATLAB:graphics:chart:VariableNotFound'
                        throwAsCaller(ME)
                    case {'MATLAB:graphics:chart:InvalidSubscriptValue', ...
                            'MATLAB:graphics:chart:SubscriptOutOfBounds', ...
                            'MATLAB:graphics:chart:InvalidSubscriptType'}
                        msg = message('MATLAB:graphics:chart:InvalidSubscriptForChannel', channel, ME.message);
                        throwAsCaller(MException(ME.identifier,msg));
                    otherwise
                        msg=message('MATLAB:Chart:InvalidTableSubscript',channel);
                        error(msg);
                end
            end
                
            n = numel(ind);
            if n ~= 1
                msg = message('MATLAB:graphics:chart:NumVariablesMismatch', channel);
                assert(obj.NumObjects==1 || obj.NumObjects==n, msg)
                obj.NumObjects=n;
            end
            
            % Validate that the data within the channel is compatible.
            data = obj.DataSource.getData(ind);
            channelType = missing;
            for d = 1:numel(data)
                dataType = string(class(data{d}));
                if ismember(dataType, ["datetime", "duration", "categorical"])
                    assert(ismissing(channelType) || dataType == channelType, ...
                        message('MATLAB:graphics:chart:MixingChannelDataType', channelType, dataType, channel))
                    channelType = dataType;
                elseif ismissing(channelType)
                    channelType = "numeric";
                end
            end
            
            obj.Map.(channel) = subscript;
        end
        
        function sliced = slice(obj,sliceindex)
            assert(isscalar(sliceindex) && sliceindex > 0 && ...
                sliceindex <= obj.NumObjects, "MATLAB:graphics:data:InvalidSlice", ...
                "Invalid slice index");
            
            channels = fieldnames(obj.Map);
            sliced=obj.Map;
            
            for c = 1:numel(channels)
                channel = channels{c};
                subs = obj.Map.(channel);
                nsubs = numel(subs);
                
                if isstring(subs) && nsubs > 1
                    % Names retain their type and are just being indexed
                    %
                    % Note that ischar(subs) and nsubs<=1 is a noop,
                    % just retain the existing values
                    sliced.(channel)=subs(sliceindex);
                    
                elseif iscellstr(subs) && nsubs > 1
                    sliced.(channel)=subs{sliceindex};

                elseif isa(subs, 'pattern')
                    % Because pattern uses variable names for matching,
                    % preserve the variable name (not index).
                    ind = obj.DataSource.subscriptToIndex(subs);
                    if numel(ind) == 1
                        sliced.(channel)=char(obj.DataSource.getVarNames(ind));
                    else
                        sliced.(channel)=char(obj.DataSource.getVarNames(ind(sliceindex)));
                    end
                    
                elseif ~(isstring(subs) || iscellstr(subs) || ischar(subs))
                    % All other subs types get coerced to an index:
                    ind = obj.DataSource.subscriptToIndex(subs);
                    if numel(ind) == 1
                        sliced.(channel)=ind;
                    else
                        sliced.(channel)=ind(sliceindex);
                    end
                end
            end
        end
    end
end
