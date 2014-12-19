% saveResults : saves the results structure to a file

function [success] = saveResults(filename, results)
	success = 1;
	file_id = fopen(filename, 'w');

	fprintf(file_id, '#%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'bpm', 'driftNoise', 'motionNoise', 'mainsNoise', 'emgNoise', 'attenuation', 'iSQI', 'bSQI', 'pSQI', 'sSQI', 'kSQI', 'fSQI', 'basSQI');
	for i = [1:length(results)]
		r = results(i);
		fprintf(file_id, '%d\t%d\t%d\t%d\t%d\t%d\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', r.noise.bpm, r.noise.driftNoise, r.noise.motionNoise, r.noise.mainsNoise, r.noise.emgNoise, r.noise.attenuation, r.iSQI, r.bSQI, r.pSQI, r.sSQI, r.kSQI, r.fSQI, r.basSQI);
	end
	
	fclose(file_id);
	
	success = 0;
end
