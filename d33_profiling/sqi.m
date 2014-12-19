function [output] = sqi(input, frequency, expected_beats)
%Calculates the Signal Quality Metrics for an ECG signal
%   * Adapted from the metrics defined by Clifford2012a
%	* iSQI is not suitable for a single-lead recording and has therefore been adapted
%	* Each of these metrics returns [0..1] where 1 is a high quality ECG signal

    output = [	iSQI(input, frequency, expected_beats),
				bSQI(input, frequency),
				pSQI(input, frequency),
				sSQI(input, frequency),
				kSQI(input, frequency),
				fSQI(input, frequency),
				basSQI(input, frequency)
				];
end

function [sqi] = iSQI(x, fs, expected_beats)
%Calculates the percentage of beats detected on each lead that were deteted on all leads
%	Not possible with a single-lead, so we return the percentage of beats that could have been detected
	wqrs_beats = qrsDetector(x, fs, 'method', 'wqrs');
	osea_beats = qrsDetector(x, fs, 'method', 'osea');
	
	wqrs_variation = abs(double(length(wqrs_beats) ) - expected_beats);
	osea_variation = abs(double(length(osea_beats) ) - expected_beats);
	
	min_variation = min(wqrs_variation, osea_variation);
	
	sqi = (expected_beats - min_variation) / expected_beats;
end

function [sqi] = bSQI(x, fs)
%Calculates the percentage of beats detected by 'wqrs' that were also detected by 'epilimited'
	wqrs_beats = qrsDetector(x, fs, 'method', 'wqrs');
	osea_beats = qrsDetector(x, fs, 'method', 'osea');
	
	wqrs_count = double(length(wqrs_beats) );
	osea_count = double(length(osea_beats) );
	
	lower = max(wqrs_count, osea_count);
	upper = min(wqrs_count, osea_count);

	sqi = upper / lower;
end

function [sqi] = pSQI(x, fs)
%Calculates the relative power in the QRS complex
    sqi_ps = pwelch(x);
    sqi_psd = dspdata.psd(sqi_ps, 'Fs', fs);
    sqi = avgpower(sqi_psd, [5, 15]) / avgpower(sqi_psd, [5, 40]);
end

function [sqi] = sSQI(x, fs)
%Calculates the third moment (skewness) of the distribution
	f = designfilt('highpassiir', 'FilterOrder', 2, 'PassbandFrequency', 0.7, 'SampleRate', fs);
	fx = filtfilt(f, x);
	
	sqi = skewness(fx);
end

function [sqi] = kSQI(x, fs)
%Calculates the fourth moment (kurtosis) of the distribution
	f = designfilt('highpassiir', 'FilterOrder', 2, 'PassbandFrequency', 0.7, 'SampleRate', fs);
	fx = filtfilt(f, x);
	
	sqi = kurtosis(fx);
end

function [sqi] = fSQI(x, fs)
%Calculates the percentage of the signal which appeared to be a flat line
	ratio = 1.0 / 100.0;
	above = sum(x > (mean(x) + (range(x)*ratio) ) );
	below = sum(x < (mean(x) - (range(x)*ratio) ) );
	sqi = (above + below) / length(x);
end

function [sqi] = basSQI(x, fs)
%Calculates the relative power in the baseline
    sqi_ps = pwelch(x);
    sqi_psd = dspdata.psd(sqi_ps, 'Fs', fs);
    sqi = 1 - (avgpower(sqi_psd, [0, 1]) / avgpower(sqi_psd, [0, 40]) );
end

