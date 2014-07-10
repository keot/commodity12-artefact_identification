function [output] = driftButterworth(input)
% Removes baseline drift according to Srisawat2013

    % Configuration
    sample_rate = 250; % Hz (fs)
    pass_at = 0.05; % Hz (f0)
    
    w0 = pass_at / (sample_rate / 2); % nyquist frequency
    
    % Calculate coefficients (investigate with fvtool(b, a) )
    [B, A] = butter(4, w0, 'high');

    % Run the filter
    output = manual4Filter(B, A, input);
end

function [y] = manual4Filter(B, A, x)
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
    
    for n = 5 : length(y)
        y(n) = B(1)*x(n) + B(2)*x(n-1) + B(3)*x(n-2) + B(4)*x(n-3) + B(5)*x(n-4) - A(2)*y(n-1) - A(3)*y(n-2) - A(4)*y(n-3) - A(5)*y(n-4);
        
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