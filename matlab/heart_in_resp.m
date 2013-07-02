function [heart_osc_flag]=heart_in_resp(vec_t,vec); %heart_in_resp()



heart_osc_flag=zeros(size(vec));
heart_osc_flag(10)=1;




%% Ripple and heart detector for respiration band signal.
packet=18; % samples
win_len=packet;
prev_range=0
range_th=5; % quantisation step value = 1;
prev_sample=512 %to initialise the diff calculation.
diff_prev=0
diff_dir=0;
rise_det=0;
fall_det=0;
counter=0;
ripple_sig_flag=zeros(size(vec_t));
ripple_sig_flag2=zeros(size(vec_t));
max_peak_len=15;
max_logger=0;
min_logger=0;
for i=1:floor(length(vec)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    block=vec(ind_start:ind_end);
    for j=1:length(block)
        if j==1 %this is if we are looking at the first sample of the packet.
            diff_val=block(j)-prev_sample; % calculate diff with previous sample.
        else
            diff_val=block(j)-block(j-1);
        end
        diff_dir=diff_val;
        ripple_sig_flag(ind_start+(j-1))=diff_dir;
        if counter>0
            max_logger=max([max_logger diff_val]);
            min_logger=min([min_logger diff_val]);
        end
        if counter==0 && diff_prev>-2 && diff_val<=-2 % if the downward crossing of 0
            rise_det=1;
        end
        if rise_det==1
            counter=counter+1; % keep track of time since rise detected.
        end
        if counter>7 && counter<max_peak_len && diff_prev>0 && diff_val<=0 % if the downward crossing of 0 is within the time window.
            fall_det=1;
        end
        if fall_det==1 && counter>10 && counter<max_peak_len+7 && diff_prev<1 && diff_val>=1 && max_logger<10 && min_logger>-10 % if the downward crossing of 0 is within the time window.
            ripple_sig_flag2(ind_start+(j-1)-counter:ind_start+(j-1))=1;
            rise_det=0;
            counter=0;
            fall_det=0;
            max_logger=0;
            min_logger=0;
        end
        if counter>max_peak_len+7 % no detection so reset.
            rise_det=0;
            counter=0;
            fall_det=0;
            max_logger=0;
            min_logger=0;
        end
        
        if j==length(block)
            prev_sample=block(j); % store the sample value of the last sample in the packet.
        end
        diff_prev=diff_val;
    end
end

heart_osc_flag=ripple_sig_flag2;
