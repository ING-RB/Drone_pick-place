function uniqueString = generateRandomString(length)
%generateRandomString used to generate random string for a inputted length

% Set the desired length of the unique string
stringLength = length;

% Generate a random permutation of numbers
randomNumbers = randperm(26, stringLength) + 96; % ASCII codes for lowercase alphabets

% Convert the random numbers to characters
uniqueString = char(randomNumbers);

% Display the unique string
% disp(uniqueString);

end