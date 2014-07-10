function [output] = driftMeanMedian(input, window_size)
% Mean Median filter to remove the baseline drift of an ECG signal.
%   Based on the comments in Hao2011
    
    % Initialisation
    window_values(1 : window_size) = input(1);
    output = zeros(size(input) ); % preallocated
    
    % Windowing function
    for i = 1 : length(input)
        j = mod(i, window_size) + 1;
        window_values(j) = input(i);
        output(i) = input(i) - (0.5*median(window_values)) - (0.5*mean(window_values));
    end
end
