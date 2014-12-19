% qrsDetector: Wrapper for various ECG QRS-complex detectors
%	* 

function [answer] = qrsDetector(waveform, waveform_fs, varargin)
	%Parse arguments
	parser = inputParser;
	
	default_method = 'osea';
	valid_methods = {'osea', 'wqrs'};
	check_methods = @(x) any(validatestring(x, valid_methods) );
	
	addRequired(parser, 'waveform', @isnumeric);
	addRequired(parser, 'waveform_fs', @isnumeric);
	
	addOptional(parser, 'method', default_method, check_methods);
	
	parse(parser, waveform, waveform_fs, varargin{:});
	
	%Run detectors
	switch(parser.Results.method)
		case 'osea'
			answer = oseaDetect(waveform);
						
		case 'wqrs'
			answer = wqrsDetect(waveform, waveform_fs);
	end
end

function [beats] = oseaDetect(waveform)
	%Write the waveform to a temporary file
	osea_input_filename = [tempname, '-jpm04-osea.dat'];
	dlmwrite(osea_input_filename, waveform, 'delimiter', '\n', 'precision', 16);
	
	%Use OSEA to detect the beats within the waveform
	[success, raw_detected_beats] = unix(['/home/jpm04/dev/oseawrapper/oseawrapper', ' ', osea_input_filename]);
	
	if success ~= 0
		%External execution failed
		[~, hostname] = unix('hostname');
		
		fprintf('***\n');
		fprintf('Error executing oseaDetect on host "%s".\n', strtrim(hostname) );
		fprintf('Output: %s\n', raw_detected_beats);
		fprintf('***\n');
	else
		%Success!
		detected_beats = textscan(raw_detected_beats, '%d\t%d%*[^\n]', 'HeaderLines', 1);
		beats = detected_beats{1};
		
		delete(osea_input_filename);
	end
end

function [success] = writeWqrsHeader(path, waveform_fs, waveform_len)
	header_filename = [path, '.hea'];
	[~, header_prefix, ~] = fileparts(header_filename);
	
	header_id = fopen(header_filename, 'w');
	
	fprintf(header_id, '%s 1 %d %d\n', header_prefix, waveform_fs, waveform_len);
	fprintf(header_id, '- 212'); %default 212 format from stdin
	
	success = fclose(header_id);
end

function [success] = writeWqrsInput(path, waveform)
	input_filename = [path, '.dat'];
	
	input_id = fopen(input_filename, 'w');
	
 	for i = waveform
		fprintf(input_id, '%f\n', i);
	end
	
	success = fclose(input_id);
end

function [beats] = wqrsDetect(waveform, waveform_fs)
	%Write the waveform and header to temproary files
	[~, uuid] = unix('uuidgen');
	uuid_parts = strsplit(strtrim(uuid), '-');
	
	record_name = sprintf('%s%s', uuid_parts{1}, '_jpm04wqrs');
	base_filename = sprintf('/tmp/%s', record_name);
	
	writeWqrsHeader(base_filename, waveform_fs, length(waveform) );
	writeWqrsInput(base_filename, waveform);
	
	%Use the WFDB toolkit to detect the beats within the waveform
	wfdb_cmd = sprintf('PATH=$PATH:/usr/local/bin; cd /tmp; cat %s.dat | wrsamp -F %d | wqrs -r %s; rdann -r %s -a wqrs', base_filename, waveform_fs, record_name, record_name); % PATH is a hack for ee-avalanche not setting this env var correctly
	[success, raw_detected_beats] = unix(wfdb_cmd);
	
	if success ~= 0
		%External execution failed
		[~, hostname] = unix('hostname');
		
		fprintf('***\n');
		fprintf('Error executing wqrsDetect on host "%s".\n', strtrim(hostname) );
		fprintf('Command: %s\n', wfdb_cmd);
		fprintf('Output: %s\n', raw_detected_beats);
		fprintf('***\n');
	else
		%Success!
		detected_beats = textscan(raw_detected_beats, '%*s %d %*[^\n]', 'HeaderLines', 5);
		beats = detected_beats{1};
		
		delete([base_filename, '.dat'], [base_filename, '.hea'], [base_filename, '.wqrs']);
	end
	
end
