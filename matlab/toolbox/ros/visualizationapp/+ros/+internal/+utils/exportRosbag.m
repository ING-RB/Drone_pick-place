function exportRosbag(bagReader, timeIntervals, topics, outLocation, outputVersion, storageFormat)
% This function is for internal use only

%EXPORTROSBAG Exports selected messages from a ROS bag.
%   exportRosbag(bagReader, timeIntervals, topics, outLocation, outputVersion)
%   exports messages that fall within the given timeIntervals
%   and belong to the listed topics from the ROS bag associated with the 
%   bagReader object, saving the output to a new ROS bag file at
%   outLocation. This function support both ROS and ROS2 but does not
%   support ROS -> ROS2 or ROS2 -> ROS.

%  Copyright 2024 The MathWorks, Inc.

arguments
    bagReader {mustBeA(bagReader, ["rosbagreader" "ros2bagreader"])}
    timeIntervals (:,2)
    topics (1,:)
    outLocation {mustBeText}
    outputVersion {mustBeMember(outputVersion, ["ROS", "ROS2"]) }
    storageFormat {mustBeMember(storageFormat, ["sqlite3", "mcap", ""])}
end
    if isequal( outputVersion, "ROS" )
        bagWriter = rosbagwriter(outLocation);
    else
        bagWriter = ros2bagwriter(outLocation, "StorageFormat", storageFormat);
    end
    
    % If intervals is empty, select the whole duration
    if isempty(timeIntervals)
        timeIntervals = [ 0, bagReader.EndTime - bagReader.StartTime];
    end


    % Need to merge all the overlapping intervals
    % [(1 4) (2 5)] Have overlapping intervals. We need to convert
    % it to [(1 5)].

    % Start by sorting based on start time for each interval
    sortedIntervals = sortrows(timeIntervals, 1);

    % Final array that will contain all non overlapping
    % intervals. Start by picking the first interval
    mergedIntervals = sortedIntervals(1, :);

    % Now select an interval to add, If it overlaps with last one
    % create a new interval by [last.start max(last.end, curr.end)]
    % and add to the mergedIntervals set. Sorting made sure that
    % last.start < curr.start.
    for i = 2:size(sortedIntervals, 1)
        lastMerged = mergedIntervals(end, :);
        currInterval = sortedIntervals(i, :);

        % Start of current is greater than end of the last
        % merged. We have the start of new interval append to
        % final list
        if (currInterval(1) > lastMerged(2))
            mergedIntervals = [mergedIntervals; currInterval]; %#ok<AGROW>
        else
            % We have overlapping intervals, Get the end time
            % of the final interval
            endTime = max(currInterval(2), lastMerged(2));
            
            % Update the endTime for the last merged in the list
            mergedIntervals(end, 2) = endTime;
        end
    end

    timeIntervals = mergedIntervals;

    % If topics is empty, select all the topics
    if (isempty(topics) || any(contains(topics, "All Topics")))
        topics = bagReader.AvailableTopics.Properties.RowNames';
    end

    writerCleanup = onCleanup(@() delete(bagWriter));

    [numIntervals, ~] = size(timeIntervals);

    timeIntervals = timeIntervals + bagReader.StartTime;
    for intervalIdx = 1:numIntervals
        interval = timeIntervals;

        for topicIdx = 1:numel(topics)
            topic = topics{topicIdx};
            bagSel = select(bagReader, "Time", interval, "Topic", topic);
            msgs = bagSel.readMessages;
            msgTimes = bagSel.MessageList.Time;
            
            %Check if no messages present in the selection
            if isempty(msgs)
                %TODO throw error
                return;
            end

            if isscalar(msgs)
                write(bagWriter, topic, msgTimes, msgs{1});
            else
                write(bagWriter, topic, msgTimes, msgs);
            end
        end
    end
end

% LocalWords:  rosbagreader bagreader sqlite mcap curr
