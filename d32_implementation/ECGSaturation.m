function [output] = ECGSaturation(input)
%ECGLOWSATURATION Summary of this function goes here
%   Detailed explanation goes here
    % Parameters
    ecg_high_saturation = 949;
    ecg_low_saturation = 74;
    ecg_packet_length = 63;
    
    % Create a map with an integer key (Bug: 1-71KD5H)
    output = containers.Map(uint32(1) , uint32(1) );
    remove(output, 1);
    bad_packets = [];

    % Find saturated individual samples that lie on the maximum or minimum
    saturated_samples = zeros(size(input) ); % default is false
    saturated_samples(find(input > (ecg_high_saturation - 1) | input < (ecg_low_saturation + 1 ) ) ) = 1;
    
    % Indicate which packets are bad
    for p = 1 : floor(length(input) / ecg_packet_length)
        start_index = 1 + ((p - 1) * ecg_packet_length);
        end_index = (p * ecg_packet_length);
        
        packet = saturated_samples(start_index : end_index);
        packet_is_saturated = 1 - isempty(find(packet == 1, 1) );
        
        % Add the packet to the output
        if (packet_is_saturated == 1)
            bad_packets = [ bad_packets (start_index - 1) ];
        end
    end % foreach packet
    
    % Convert list of bad packets into indicies with durations
    if (numel(bad_packets) ~= 0)
    
        current_index = bad_packets(1);
        for (i = bad_packets)
            if (~isKey(output, current_index) )
                output(current_index) = ecg_packet_length;
            end
            
            if (i - output(current_index) == current_index)
                output(current_index) = output(current_index) + ecg_packet_length;
            else
                current_index = i;
            end    
        end % foreach bad_packet
        
	end % if elements to operate on
end

