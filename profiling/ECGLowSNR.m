function [output] = ECGLowSNR(input)
%ECGLOWSNR Summary of this function goes here
%   Detailed explanation goes here
    % Parameters
    ecg_high_saturation = 949;
    ecg_low_saturation = 74;
    ecg_packet_length = 63;
    ecg_quantisation_noise = 5;
    
    previous_packet_range = 0;
    
    % Create a map with an integer key (Bug: 1-71KD5H)
    output = containers.Map(uint32(1) , uint32(1) );
    remove(output, 1);
    bad_packets = [];
    
    % Indicate which packets are bad
    for p = 1 : floor(length(input) / ecg_packet_length)
        start_index = 1 + ((p - 1) * ecg_packet_length);
        end_index = (p * ecg_packet_length);
        
        packet = input(start_index : end_index);
        packet_range = max(input) - min(input);
        
        % Add the packet to the output
        if (max([previous_packet_range packet_range] <= ecg_quantisation_noise) )
            bad_packets = [ bad_packets (start_index - 1) ];
        end
    end % foreach packet
    
    previous_packet_range = packet_range;
    
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

