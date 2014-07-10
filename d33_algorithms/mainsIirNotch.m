function [output] = mainsIirNotch(input)
% Runs an IIR notch filter to remove 50 Hz mains noise.

    % Configuration
    sample_rate = 250; % Hz (fs)
    notch_location = 50; % Hz (f0)
    q_factor = 125;
    
    w0 = notch_location / (sample_rate / 2); % nyquist frequency
    bw = w0 / q_factor;
    
    % Calculate coefficients (investigate with fvtool(b, a) )
    [B, A] = iirnotch(w0, bw);
    
    % Note, for a 50 Hz notch filter (Q factor 35) in a 1 kHz signal:
    % A = [1, -1.8936, 0.9911]; B = [0.9955, -1.8936, 0.9955];

    % Run the filter
    output = manualFilter(B, A, input);
end

function [y] = manualFilter(B, A, x)
% A reimplemtation of the MATLAB filter(B, A, x) command.

    % Catch misconfigurations
    if (size(A) ~= size(B) )
        error('Coefficients A and B must be of the same length for an IIR filter.');
    end
    
    if (A(1) ~= 1.0)
        error('The first element of A must be one. Please normalise your coefficients.');
    end

    % Initialisation
    y = ones(1, length(x) ); % for initial dampening
    
    for n = 3 : length(y)
        y(n) = B(1)*x(n) + B(2)*x(n-1) + B(3)*x(n-2) - A(2)*y(n-1) - A(3)*y(n-2);
        
        %sum = 0;
        %for nb = 1 : size(B)
        %    sum = sum + B(nb) * x(n - (nb - 1) );
        %end
        % 
        %for na = 2 : size(A)
        %    sum = sum - A(na) * y(n - (na - 1) );
        %end
        
        %y(n) = sum;
    end
        
    
end