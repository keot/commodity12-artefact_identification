% filterProfiling: runs the SQI metrics on various simulated signals with noise filtered by the filterFunctionHandler

function [answers] = filterProfiling(filterFunctionHandler)
	%Configure experiment
	%disp('Debugging mode activated!');
	bpm_range = [60:60:180]; % incl.
	noise_range = [100.0, 50.0, 25.0, 12.5, 6.25, 0.0]; %6.25, 3.125, 1.5625, 0.78125, 0.390625, 0.1953125, 0.0]; % SNR dB: 0,-3,-6,-9,..,-27,Inf

	%Prepare output structure
	noises = repmat(struct( ...
							'bpm', [], ...
							'driftNoise', [], ...
							'motionNoise', [], ...
							'mainsNoise', [], ...
							'emgNoise', [], ...
							'attenuation', [] ...
							), length(bpm_range)*length(noise_range)^5, 1);
	i = 1;
	for driftNoise = noise_range
		for motionNoise = noise_range
			for mainsNoise = noise_range
				for emgNoise = noise_range
					for attenuation = noise_range
						for bpm = bpm_range
							noises(i).bpm = bpm;
							noises(i).driftNoise = driftNoise;
							noises(i).motionNoise = motionNoise;
							noises(i).mainsNoise = mainsNoise;
							noises(i).emgNoise = emgNoise;
							noises(i).attenuation = attenuation;
							i = i + 1;
						end
					end
				end
			end
		end
	end

	fprintf('Computing %d combinations of noise and heartrate.\n', length(noises) );
	
	answers = repmat(struct( ...
							'noise', [], ...
							'iSQI', [], ...
							'bSQI', [], ...
							'pSQI', [], ...
							'sSQI', [], ...
							'kSQI', [], ...
							'fSQI', [], ...
							'basSQI', [] ...
							), length(noises), 1);
	
	mjs = gcp; %Beginning of parallel pool
	addAttachedFiles(mjs, {'ecgsyn.m', 'derivsecgsyn.m', 'sqi.m'}); %Add ecgsyn.m, sqi.m and dependents for workers
	
	fs = 250; %Sample frequency (Hz)
	
	parfor i = [1:length(answers)]
		bpm = noises(i).bpm;
		
		answer = sqi( ...
					addDriftNoise( ...
					addMotionNoise( ...
					addMainsNoise( ...
					addEmgNoise( ...
					attenuate( ...
						filterFunctionHandler(ecgsyn(fs, bpm*2, 0, bpm, 1, 0.5, fs) ) ... %two minute segments with filter
					, noises(i).attenuation) ...
					, noises(i).emgNoise) ...
					, fs, noises(i).mainsNoise) ...
					, fs, noises(i).motionNoise) ...
					, fs, noises(i).driftNoise) ...
					, fs, bpm*2); %sqi
		
		answers(i).iSQI = answer(1);
		answers(i).bSQI = answer(2);
		answers(i).pSQI = answer(3);
		answers(i).sSQI = answer(4);
		answers(i).kSQI = answer(5);
		answers(i).fSQI = answer(6);
		answers(i).basSQI = answer(7);
		
		answers(i).noise = noises(i);
	end
	
	delete(mjs); %End of parallel pool
end

function [y] = addSine(x, sample_frequency, sine_frequency, sine_amplitude)
% Adds a sine wave to a signal of amplitude 0-100 of max(x)
    amplitude = range(x) * (sine_amplitude / 100.0);
   
   y(1:length(x) ) = 0; % Pre-allocate array

    for i = 1 : length(x)
        y(i) = x(i) + (amplitude * sin( i / ((sample_frequency / sine_frequency) / (2*pi)) ) );
    end
    
end

function [y] = addGaussianNoise(x, amplitude)
% Adds Gaussian noise to signal x of amplitude 0-100 of range(x)
	y = awgn(x, amplitude / 100.0, 'measured', 'linear');
end

function [y] = addDriftNoise(x, fs, amp)
	if amp == 0
		y = x;
	else
		y = addSine(x, fs, 0.5, amp);
	end
end

function [y] = addMotionNoise(x, fs, amp)
	if amp == 0
		y = x;
	else
		y = addSine(x, fs, 5.0, amp);
	end
end

function [y] = addMainsNoise(x, fs, amp)
	if amp == 0
		y = x;
	else
		y = addSine(x, fs, 50.0, amp);
	end
end

function [y] = addEmgNoise(x, amp)
	if amp == 0
		y = x;
	else
		y = addGaussianNoise(x, amp);
	end
end

function [y] = attenuate(x, amp)
	if amp > 99.9
		amp = 99.9; %Avoid complete attenuation
	end
	y = ((100.0 - amp) / 100.0) * x;
end
