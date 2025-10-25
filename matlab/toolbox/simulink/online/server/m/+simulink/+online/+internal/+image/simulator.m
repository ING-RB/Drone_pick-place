function simulator(mode)
    if ~strcmp(mode, 'off')
        slonline.setNeedToUpdateFrontendStatus(true);
        slonline.setSimulationMode(mode);
    end

    if mode == "planned"
        plannedSimulator();
    end
end

function plannedSimulator
    message.subscribe("/simulinkonline/simulation", @(msg)handleSimulationMessage(msg));

    jsonString = fileread('testjson.json');
    data = jsondecode(jsonString);

    if length(data.updateregions) ~= 0
        lastTime = data.updateregions(1).data.time;
        t0 = lastTime;

        for i = 1:length(data.updateregions)
            currentData = data.updateregions(i).data;
            currentTime = currentData.time;

            delayInSeconds = (currentTime - lastTime) / 1000;

            if i > 1
                pause(delayInSeconds);
            end

            lastTime = currentTime;
            disp(currentTime - t0);

            % Construct the message
            if i == 1
                msg = createMessage(currentData.network, currentData.ping, currentData.sizeInKB, true, false);
            elseif i == length(data.updateregions)
                msg = createMessage(currentData.network, currentData.ping, currentData.sizeInKB, false, true);
            else
                msg = createMessage(currentData.network, currentData.ping, currentData.sizeInKB, false, false);
            end

            message.publish("/simulinkonline/simulation", msg);
        end
    end

end


function msg = createMessage(network, ping, size, isItFirst, isItEnd)
    msg = struct('testdata', true, 'simulation', true, 'isItFirst', isItFirst, 'isItEnd', isItEnd, 'network', network, 'ping', ping, 'imageSize', size);
end


function handleSimulationMessage(msg)
    disp(msg);
end