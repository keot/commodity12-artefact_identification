function [output] = driftMedian(input, window_size)
% Median filter to remove the baseline drift of an ECG signal.
%   Based on the comments in Ghasemzadeh2013.
    
    % Initialisation
    window_values(1 : window_size) = input(1);
    output = zeros(size(input) ); % preallocated
    
    % Windowing function
    for i = 1 : length(input)
        j = mod(i, window_size) + 1;
        window_values(j) = input(i);
        output(i) = input(i) - median(window_values);
    end
end
