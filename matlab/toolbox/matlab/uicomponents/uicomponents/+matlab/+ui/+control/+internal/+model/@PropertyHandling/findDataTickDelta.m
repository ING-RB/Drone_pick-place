function dataTickDelta = findDataTickDelta(lower, upper, width)
% find the spacing between ticks in data units
% lower and upper are the data bounds
% width is the number of pixels the ruler is to span

% how many ticks should there be?

% no more than 20 pixels apart
minNumberOfTicksPossible = width / 30;
if (minNumberOfTicksPossible < 1)
    minNumberOfTicksPossible = 1;
end

% no less than 15 pixels apart
maxNumberOfTicksPossible = width / 18;
if (maxNumberOfTicksPossible < 2)
    maxNumberOfTicksPossible = 2;
end

% What is the range that tick spacing could take?
range = abs(upper - lower);


% Handle numbers smaller than 1, Multiply them so they are in
% a larger range so the tick calculation is more consistent
factor = 1;
while (abs(factor * range) < 10.0)
    % Get into the range 1 < factor*range
    factor = factor * 10;
end
if (abs(factor * range) < 20.0)
    factor = factor * 2;
end
range = range*factor;

% rate the ticks on their potential to be good rounding
% low number means that they divide well
% when rating is 0 that's perfect divisibility
possibleTicks = round(minNumberOfTicksPossible):round(maxNumberOfTicksPossible);
dividableRating = range./possibleTicks - round(range./possibleTicks);

% Handle case where ticks can be evenly divided
validTicks = possibleTicks(dividableRating == 0);

if ~isempty(validTicks)
    % There is a tick that can be evenly divided into the range
    % Choose the larger number of ticks if there are multiple
    % valid evenly divisible ticks.
    dataTickDelta = range/validTicks(end);
    dataTickDelta = dataTickDelta/factor;
else

    % Sort ratins so there is a criteria to pick one
    [~, index] = sort(abs(dividableRating));
    validTicks = possibleTicks(index);

    % What is the range that tick spacing could take?
    dataTickDelta = range/validTicks(1);

    % Clean up dataTickDelta so that it's a round number
    % If for example, the dataTickDelta value is 76.5, we want
    % it to be something more even like 80.
    dataTickFactor = 1;
    while (abs(dataTickFactor * dataTickDelta) > 10.0)
        dataTickFactor = dataTickFactor / 10;
    end

    dataTickDelta = round(dataTickDelta*dataTickFactor)/dataTickFactor/factor;
end

end