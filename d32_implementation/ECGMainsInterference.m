function [output] = ECGMainsInterference(input)
%ECGLOWSATURATION Summary of this function goes here
%   Detailed explanation goes here
    % Parameters
packet=63; % samples
win_len=packet;

bad_packets = [];
output = containers.Map(uint32(1) , uint32(1) );
remove(output, 1);
ecg_packet_length = packet;

for i=1:floor(length(input)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    
    block=input(ind_start:ind_end); % this corresponds to one bluetooth win_len.
    sig_mat=reshape(block(1:60),5,12);
    trans_var=zeros(1,5);
    for j=1:5
        trans_block=sig_mat(j,:); % Select rows 
        %i
        %j
        %trans_block
        %max(trans_block)
        %min(trans_block)
        trans_var(j)=max(trans_block)-min(trans_block);
    end
    %trans_var
    %size(trans_var)
    summary_trans_var=max(trans_var); % MAX is used to be conservative
    
    lin_var=zeros(1,12);
    for k=1:12
        lin_block=sig_mat(:,k); 
        lin_var(k)=max(lin_block)-min(lin_block);
    end
    %size(lin_var)
    summary_lin_var=min(lin_var);  % MIN is used to be conservative
    %size(summary_trans_var)
    %size(summary_lin_var)
    var_ratio=summary_trans_var/summary_lin_var;
    if summary_trans_var./summary_lin_var < 0.2
        % No need for updating flag samples previous to the present packet.
        %mains_sig_flag(ind_start:ind_end)=var_ratio.*ones(1,63); %1; % if at the start only flat one win_len
        %mains_sig_flag(ind_start:ind_end)=1; % if at the start only flat one win_len
        bad_packets = [ bad_packets ind_start ];
    end 
   
end
    
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

