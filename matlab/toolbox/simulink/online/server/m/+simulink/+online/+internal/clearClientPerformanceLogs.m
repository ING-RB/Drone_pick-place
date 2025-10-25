function clearClientPerformanceLogs
message.publish("/slonlineclient/logger", struct('eventType', 'clearclientlogs'));
end