function [rmcidx,ggaidx,gsaidx,numSamplesToRead] = findStartIndex(rmcData,ggaData,gsaData,readMode,numSamplesToRead)
% This function checks the equality of time between RMC and GGA data and returns the
% index from which data has to be read. This ensures the data read is from
% same frame.The indexing is affected by the Readmode property as well.

% Copyright 2020-2023 The MathWorks, Inc.
rmcidx = [];
ggaidx = [];
gsaidx = [];
timeRMC = NaT(numel(rmcData),1);
timeRMC.Format = 'd-MMM-y HH:mm:ss.SSS';
timeGGA = NaT(numel(ggaData),1);
timeGGA.Format = 'd-MMM-y HH:mm:ss.SSS';
numGGASentences = numel(ggaData);
numRMCSentences = numel(rmcData);
numGSASentences = numel(gsaData);
% read time data from RMC and GGA sentences.GSA does not  have
% time information
[timeRMC,timeGGA] = getTimeInfo(rmcData,numRMCSentences,ggaData,numGGASentences);
numSamplesToRead = min([numRMCSentences,numGGASentences,numGSASentences,numSamplesToRead]);
if numSamplesToRead < 1
    return;
end
% if there is only data point available, compare the value, if there is a
% match (Nat or time value match), return.
% if one of the data is Nat and other is a time value, this could be
% because of checksum error, however there is no way to determine it, hence return
% without no indices, the main code will return previous values in this case
if numRMCSentences == 1 && numGGASentences == 1
    if isequaln(timeGGA,timeRMC)
        rmcidx = 1;
        ggaidx = 1;
        numSamplesToRead = 1;
        if strcmp(readMode,'latest')
            gsaidx = numGSASentences;
        else
            gsaidx = 1;
        end
    else
        rmcidx = [];
        ggaidx = [];
        gsaidx = [];
        numSamplesToRead = [];
    end
    return;
end
% If all values are Nat, there is no way to check if they are time synchronized,
% hence return last or first numSampleToRead samples
% ideal when time is NaT, the other elements in the sentence should be nans
if all(isnat(timeRMC)) || all(isnat(timeGGA))
    if strcmp(readMode,'latest')
        rmcidx = numRMCSentences-numSamplesToRead+1;
        ggaidx = numGGASentences-numSamplesToRead+1;
        gsaidx = numGSASentences-numSamplesToRead+1;
    else
        rmcidx = 1;
        ggaidx = 1;
        gsaidx = 1;
    end
    return;
end

if strcmp(readMode,'latest')
    [rmcidx,ggaidx,gsaidx,numSamplesToRead] = getIndicesForLatestMode(timeRMC,numRMCSentences,timeGGA,numGGASentences,gsaData, numGSASentences,numSamplesToRead);
else
    [rmcidx,ggaidx,gsaidx,numSamplesToRead] = getIndicesForOldestMode(timeRMC,numRMCSentences,timeGGA,numGGASentences,gsaData, numGSASentences,numSamplesToRead);
end

    function [timeRMC,timeGGA] = getTimeInfo(rmcData,numRMCSentences,ggaData,numGGASentences)
        if numRMCSentences > 0 && numGGASentences > 0
            timeRMC = NaT(1,numRMCSentences);
            timeGGA = NaT(1,numGGASentences);
            for count = 1:numRMCSentences
                timeRMC(count) = rmcData(count).Time;
            end
            for count = 1:numGGASentences
                timeGGA(count) = ggaData(count).Time;
            end
        else
            timeRMC = [];
            timeGGA = [];
        end
    end

    function [rmcidx,ggaidx,gsaidx,numSamplesToRead] = getIndicesForLatestMode(timeRMC,numRMCSentences,timeGGA,numGGASentences, ~, numGSASentences,numSamplesToRead)
        % Look for the latest match between time values excluding occurrences of NATs.
        % Nats cannot be used for synchronization since this can occur due to
        % multiple reasons
        mode = 1; % latest
        [rmcidx,ggaidx] = findTimeMatch(timeRMC,numRMCSentences,timeGGA,numGGASentences,mode);

        % if no match between time values are found, look for the occurence of
        % Nats and see if both rmc and gga have matching Nats
        if isempty(ggaidx) && isempty(rmcidx)
            [rmcidx,ggaidx] = findNaTMatch(timeRMC,numRMCSentences,timeGGA,numGGASentences,mode);
        end
        if ~isempty(ggaidx) && ~isempty(rmcidx)
            [rmcidx,ggaidx,gsaidx,numSamplesToRead] = verifyElementsMatchiInFrameLatestMode(rmcidx,timeRMC,numRMCSentences,ggaidx,timeGGA,numGGASentences, numGSASentences,numSamplesToRead);

        else
            [rmcidx,ggaidx,gsaidx,numSamplesToRead] = getNoMatchArguments();
        end
    end

    function [rmcidx,ggaidx,gsaidx,numSamplesToRead] = getIndicesForOldestMode(timeRMC,numRMCSentences,timeGGA,numGGASentences,~, numGSASentences,numSamplesToRead)
        % Look for the first match between time values excluding occurrences of NATs.
        % Nats cannot be used for synchronization since this can occur due to
        % multiple reasons
        mode = 0; % oldest
        [rmcidx,ggaidx] = findTimeMatch(timeRMC,numRMCSentences,timeGGA,numGGASentences,mode);

        % if no match between time values are found, look for the occurrence of
        % Nats and see if both rmc and gga have matching Nats
        % start the indexing from 1
        if isempty(ggaidx) && isempty(rmcidx)
            [rmcidx,ggaidx] = findNaTMatch(timeRMC,numRMCSentences,timeGGA,numGGASentences,mode);
        end
        if ~isempty(ggaidx) && ~isempty(rmcidx)
            [rmcidx,ggaidx,gsaidx,numSamplesToRead] = verifyElementsMatchiInFrameOldestMode(rmcidx,timeRMC,numRMCSentences,ggaidx,timeGGA,numGGASentences,numGSASentences,numSamplesToRead);
        else
            [rmcidx,ggaidx,gsaidx,numSamplesToRead] = getNoMatchArguments();
        end
    end

    function [rmcidx,ggaidx] = findTimeMatch(timeRMC,numRMCSentences,timeGGA,~,mode)
        % for latest mode, start from the end
        rmcidx = [];
        ggaidx = [];
        if mode == 1
            i = numRMCSentences;
            while i>0
                ggaidx = find(timeRMC(i)== timeGGA,1);
                if(~isempty(ggaidx))
                    rmcidx = i;
                    break;
                end
                i = i-1;
            end
            % for oldest mode start from the first
        else
            i = 1;
            while i<=numRMCSentences
                ggaidx = find(timeRMC(i)== timeGGA,1);
                if(~isempty(ggaidx))
                    rmcidx = i;
                    break;
                end
                i = i+1;
            end
        end
    end

    function  [rmcidx,ggaidx] = findNaTMatch(timeRMC,numRMCSentences,timeGGA,numGGASentences,mode)
          rmcidx = [];
        ggaidx = [];
        if mode == 1
            % for latest mode, start from the end
            i = numRMCSentences;
            while i>0
                for j = numGGASentences:-1:1
                    matchFound = isequaln(timeRMC(i),timeGGA(j));
                    if matchFound
                        ggaidx = j;
                        rmcidx = i;
                        break;
                    end
                end
                i = i-1;
            end
        else
            % for oldest mode, start from the beginning
            i = 1;
            while i<=numRMCSentences
                for j = 1:numGGASentences
                    matchFound = isequaln(timeRMC(i),timeGGA(j));
                    if matchFound
                        ggaidx = j;
                        rmcidx = i;
                        break;
                    end
                end
                i = i+1;
            end
        end
    end

    function [rmcidx,ggaidx,gsaidx,numSamplesToRead] = getNoMatchArguments()
        rmcidx = [];
        ggaidx = [];
        gsaidx = [];
        numSamplesToRead = [];
    end

    function [rmcidx,ggaidx,gsaidx,numSamplesMatched] = verifyElementsMatchiInFrameLatestMode(rmcidx,timeRMC,numRMCSentences,ggaidx,timeGGA,numGGASentences, numGSASentences,numSamplesToRead)
        % the index at which match was found, need not be the latest data point
        % Assume rmcData = [1,2,3,4,5], ggaData =[3,4,Nat],numSamplesPerRead = 1
        % from the above match logic rmcidx == 4, ggaIdx = 2
        % Since last ggadata is nat, the comparison might have
        % failed, but this can happen due to checksum error in one of the sentences
        % Ideally the rmcidx should be 5 and ggaidx should be 3
        rmcMatchIdx = rmcidx;
        ggaMatchidx = ggaidx;
        % find the actual end index of rmc data and ggadata by getting the
        % number of samples to the actual end index in the buffer
        % Consider the below samples, the last value in ggadata is
        % part of next frame. So the offset should be 1.
        % rmcData = [1,2,3,4,5], ggaData =[3,4,Nat,1],
        offset = min(numGGASentences-ggaidx,numRMCSentences-rmcidx);
        rmcEndIdx = rmcMatchIdx+offset;
        ggaEndIdx = ggaMatchidx+offset;
        % now check if all the data points in the numSamplesPerRead in the
        % sample are equal
        % The following conditions are considered equal in ggadata and
        % rmcdata
        % corresponding values are at equal time
        % corresponding values are NaTs
        % Value corresponding to nat in either sentence is a time value
        % (possible checksum error)
        numSamplesMatched = 0;
        i = rmcEndIdx;
        j = ggaEndIdx;
        while numSamplesMatched < numSamplesToRead && i>0 && j>0
            if ~isequaln(timeRMC(i),timeGGA(j)) && ~isnat(timeRMC(i)) && ~isnat(timeGGA(j))
                if i>=rmcEndIdx || j>=ggaEndIdx
                    % rmcData = [1,2,3,4,5,6] % ggaData = [3,4,Nat,1]
                    % here time match will be obtained at rmcMatchidx = 4, ggaMatchidx = 2
                    % there are 2 samples after match indices, [5,6] in rmc amd [Nat, 1]
                    % Since latest data 6 and 1 are not matching, return [], the main
                    % code will return previous samples
                    [rmcidx,ggaidx,gsaidx,numSamplesMatched] = getNoMatchArguments();
                else
                    % rmcData = [1,2,3,4,5,10,Nat] % ggaData = [3,4,Nat,11,NaT]
                    % here time match will be obtained at rmcMatchidx = 4, ggaMatchidx = 2
                    % there are 3 samples after match indices, [5,10,nat] in rmc and 3 samples after match indices
                    % in gga [Nat, 11,nat]
                    % Since data 1 and 2 are not matching, return only the matching
                    % elements after this point
                    rmcidx = i+1;
                    ggaidx = j+1;
                    numSamplesMatched = min([ggaEndIdx-ggaidx+1, rmcEndIdx-rmcidx+1,numSamplesToRead]);
                    gsaidx = numGSASentences-numSamplesMatched+1;
                end
                return;
            end
            numSamplesMatched = numSamplesMatched+1;
            i = i-1;
            j = j-1;
        end
        [rmcidx,ggaidx,gsaidx,numSamplesMatched] = findStartIndicesLatestMode(rmcEndIdx,ggaEndIdx,numGSASentences,numSamplesMatched);
    end

    function  [rmcidx,ggaidx,gsaidx,numSamplesMatched] = findStartIndicesLatestMode(rmcEndIdx,ggaEndIdx,numGSASentences,numSamplesMatched)
        % if no match is found in the last samples, discard the sample and
        % return [], main code will return previous values
        % rmcData = [1,2,3,4,5,6] % ggaData = [3,4,Nat,1]
        % here time match will be obtained at rmcMatchidx = 4, ggaMatchidx = 2
        % there are 2 samples after match indices, [5,6] in rmc amd [Nat, 1]
        % Since latest data 6 and 1 are not matching, return [], the main
        % code will return previous samples
        if numSamplesMatched == 0 && isempty(numSamplesMatched)
            [rmcidx,ggaidx,gsaidx,numSamplesMatched] = getNoMatchArguments();
        else
            % rmcData = [1,2,3,4,5,6] % ggaData = [1,4,Nat] % numSamplesRead
            % == 3, the time synchronized elements are [4,5] (rmc) and [4,NaT]
            % (gga), so make numSamples to read as 2. Point the rmcidx and
            % ggaidx to the start of the frame from which data needs to
            % written
            rmcidx = rmcEndIdx-numSamplesMatched+1;
            ggaidx = ggaEndIdx-numSamplesMatched+1;
            gsaidx = numGSASentences-numSamplesMatched+1;
        end
    end

    function [rmcidx,ggaidx,gsaidx,numSamplesToRead] = verifyElementsMatchiInFrameOldestMode(rmcidx,timeRMC,numRMCSentences,ggaidx,timeGGA,numGGASentences, ~,numSamplesToRead)
        % the index at which match was found, need not be the first data point
        % Assume rmcData = [nat,3,4,5], ggaData =[1,3,4,Nat],numSamplesPerRead = 1
        % from the above match logic rmcidx == 2, ggaIdx = 2
        % Since first ggadata is nat, the comparison might have
        % failed, but this can happen due to checksum error in one of the sentences
        % Ideally the rmcidx should be 1 and ggaidx should be 1
        rmcMatchIdx = rmcidx;
        ggaMatchidx = ggaidx;
        % find the actual start index of rmc data and ggadata
        % Consider the below samples,
        % rmcData = [nat,nat,2,3,4,5], ggaData =[1,2,3,4]
        % rmcMatchidx = 3 and ggaMatchidx = 2
        % rmcStartIdx = 2 and ggaStartIdx = 1
        offset = min(ggaidx,rmcidx);
        rmcidx = rmcMatchIdx-offset+1;
        ggaidx = ggaMatchidx-offset+1;
        % now check if all the data points in the numSamplesPerRead in the
        % sample are equal
        % The following conditions are considered as equal in ggadata and
        % rmcdata
        % corresponding values are at equal time
        % corresponding values are NaTs
        % Value corresponding to Nat in either sentence is a time value
        % (possible checksum error)
        numSamples = 0;
        i = rmcidx;
        j = ggaidx;
        while numSamples < numSamplesToRead && i<=numRMCSentences && j<=numGGASentences
            if ~isequaln(timeRMC(i),timeGGA(j)) && ~isnat(timeRMC(i)) && ~isnat(timeGGA(j))
                if numSamples == 0
                    % if no match found, move the starting index to next
                    % index
                    rmcidx = i+1;
                    ggaidx = j+1;
                else
                    break;
                end
            else
                numSamples = numSamples+1;
            end
            i = i+1;
            j = j+1;
        end
        if numSamples == 0
            [rmcidx,ggaidx,gsaidx,numSamplesToRead] = getNoMatchArguments();
        else
            numSamplesToRead = numSamples;
            gsaidx = 1;
        end
    end
end
