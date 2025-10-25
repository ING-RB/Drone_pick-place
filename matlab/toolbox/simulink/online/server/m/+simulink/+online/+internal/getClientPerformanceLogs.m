function ret = getClientPerformanceLogs(clientPerfFile)
% % Example Usage:
% % clear client performance logs
% simulink.online.internal.clearClientPerformanceLogs()
% % enable server performance and client performance
% slsvTestingHook('SlOnlinePerfLevel', 1);
% % ...matlab commands or user actions...
% % stop logging and write the captured server logs to "/tmp/slOnline_perfLog_<pid>.log" file
% slsvTestingHook('SlOnlinePerfLevel', 0);
% simulink.online.internal.getClientPerformanceLogs("/tmp/clientPerfLogs.json")

messageReceived = false;
    function messageHandler(msg)
        fid = fopen(clientPerfFile, 'w');
        fwrite(fid, msg.message);
        fclose(fid);
        messageReceived = true;
    end

    function r = pollingHandler
        r = messageReceived;
    end
messageServiceId = message.subscribe("/slonlineserver/logger", @messageHandler);
message.publish("/slonlineclient/logger", struct('eventType', 'sendclientlogs'));
pollStatus = matlab.unittest.constraints.Eventually(matlab.unittest.constraints.IsTrue).satisfiedBy(@pollingHandler);
message.unsubscribe(messageServiceId);
assert(pollStatus == true);

ret = 0;
end