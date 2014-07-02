package uk.ac.ic.ee.cas;

import java.util.HashMap;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;

public class ArtefactSensing {
	private static int ecg_packet_length = 63;
	private static int respiration_packet_length = 18;
	
	private static double ecg_snr = 0.2; // based on observation
	private static int ecg_quantisation_jitter = 2; // based on observation
	private static int ecg_maximum = 949; // based on observation
	private static int ecg_minimum = 75; // based on observation
	
	private static int respiration_quantisation_jitter = 5; // based on observation
	
	public Map<Integer, Integer> ECGArtefacts(int[] input) {
		return ECGLowSNR(input);// + ECGMainsInterference(input) + ECGSaturation(input);
	}
	
	public Map<Integer, Integer> respirationArtefacts(int[] input) {
		return respirationLowSNR(input);
	}
	
	public Map<Integer, Integer> accelormeterArtefacts(int[] input) {
		return null;
	}
	
	private Map<Integer, Integer> lowSNR(int[] input, int jitter, int packet_length) {
		int previous_range = 0;
		int current_range = 0;
		
		Map<Integer, Integer> output = new HashMap<Integer, Integer>();
		SortedSet<Integer> lowSNRPackets = new TreeSet<Integer>();
		
		// Ignore the samples at the end of the input
		int packets = input.length / packet_length;
		
		// Foreach packet in the input
		for (int p = 0; p < packets; p++) {
			int start_index = p * packet_length;
			int end_index = ((p + 1) * packet_length) - 1;
			
			// Check that end_index is valid
			if (end_index >= input.length) {
				// TODO: alert: incomplete packet
				end_index = input.length;
			}
			
			// Compute the range of values for the current packet
			int maximum_value = Integer.MIN_VALUE;
			int minimum_value = Integer.MAX_VALUE;
			for (int i = start_index; i < end_index; i++) {
				if (input[i] > maximum_value) maximum_value = input[i];
				if (input[i] < minimum_value) minimum_value = input[i];
			}
			current_range = maximum_value - minimum_value;
			
			// Establish the range
			int range = 0;
			if (previous_range > current_range) {
				range = previous_range;
			} else {
				range = current_range;
			}
			
			if (range <= jitter) {
				lowSNRPackets.add(start_index);
			}
			
			previous_range = current_range;
			
		} // foreach packet
		
		// Check if there were no saturated samples at all
		if (lowSNRPackets.size() == 0) {
			return output;
		}
		
		System.out.println(lowSNRPackets.size() );
		
		// Coalesce sets
		Integer currentLocation = lowSNRPackets.first();
		
		for (Integer location : lowSNRPackets) {
			if (!output.containsKey(currentLocation) ) {
				output.put(currentLocation, packet_length);
			}
			if (location - output.get(currentLocation) == currentLocation) {
				output.put(currentLocation, output.get(currentLocation) + packet_length);
			} else {
				currentLocation = location;
			}
		} // foreach saturated_packet
		
		return output;
	}
	
	Map<Integer, Integer> respirationLowSNR(int[] input) {
		return lowSNR(input, respiration_quantisation_jitter, respiration_packet_length);
	}
	
	Map<Integer, Integer> ECGLowSNR(int[] input) {
		return lowSNR(input, ecg_quantisation_jitter, ecg_packet_length);
	}
	
	Map<Integer, Integer> ECGMainsInterference(int[] input) {
		Map<Integer, Integer> output = new HashMap<Integer, Integer>();
		SortedSet<Integer> mains_packets = new TreeSet<Integer>();
		
		// Ignore the samples at the end of the packet
		int packets = input.length / ecg_packet_length; // round down
		
		// Foreach packet in the input
		for (int p = 0; p < packets; p++) {
			int start_index = p * ecg_packet_length;
			int end_index = ((p + 1) * ecg_packet_length) - 1;
			
			// Check that end_index is valid
			if (end_index >= input.length) {
				// TODO: alert: incomplete packet
				end_index = input.length;
			}
			
			// Find the mains noise signal size (transversal)
			//   Initialise variables
			int transversal_step_size = 5;
			int[] transversalMaximums = new int [transversal_step_size];
			int[] transversalMinimums = new int [transversal_step_size];
			for (int i = 0; i < transversal_step_size; i++) transversalMaximums[i] = Integer.MIN_VALUE;
			for (int i = 0; i < transversal_step_size; i++) transversalMinimums[i] = Integer.MAX_VALUE;
			
			//    Find the maximum and minimum values
			for (int offset = 0; offset < transversal_step_size; offset++) {
				for (int i = start_index + offset; i < end_index; i += transversal_step_size) {
					if (input[i] > transversalMaximums[offset]) transversalMaximums[offset] = input[i];
					if (input[i] < transversalMinimums[offset]) transversalMinimums[offset] = input[i];
				} // foreach index
			} // foreach offset
			
			//    Find the minimum range
			int transversal_range = Integer.MAX_VALUE;
			for (int offset = 0; offset < transversal_step_size; offset++) {
				int range = transversalMaximums[offset] - transversalMinimums[offset];
				if (range < transversal_range) transversal_range = range; // set the biggest
			}
			
			// Find the signal range (signal)
			//   Initialise variables
			int signal_step_size = ecg_packet_length / 5;
			int[] signalMaximums = new int [signal_step_size];
			int[] signalMinimums = new int [signal_step_size];
			for (int i = 0; i < signal_step_size; i++) signalMaximums[i] = Integer.MIN_VALUE;
			for (int i = 0; i < signal_step_size; i++) signalMinimums[i] = Integer.MAX_VALUE;
			
			//    Find the maximum and minimum values
			for (int offset = 0; offset < signal_step_size; offset++) {
				for (int i = start_index + offset; i < end_index; i += transversal_step_size) {
					if (input[i] > signalMaximums[offset]) signalMaximums[offset] = input[i];
					if (input[i] < signalMinimums[offset]) signalMinimums[offset] = input[i];
				} // foreach index
			} // foreach offset
			
			//    Find the maximum range
			int signal_range = Integer.MIN_VALUE;
			for (int offset = 0; offset < transversal_step_size; offset++) {
				int range = transversalMaximums[offset] - transversalMinimums[offset];
				if (range > signal_range) signal_range = range; // set the biggest
			}

			// Add bad packets to the set
			if ((float) transversal_range / (float) signal_range < ecg_snr) {
				mains_packets.add(start_index);
			}
		} // foreach packet
		
		// Check if there were no saturated samples at all
		if (mains_packets.size() == 0) {
			return output;
		}
		
		// Coalesce sets
		Integer currentLocation = mains_packets.first();
		
		for (Integer location : mains_packets) {
			if (!output.containsKey(currentLocation) ) {
				output.put(currentLocation, ecg_packet_length);
			}
			
			if (location - output.get(currentLocation) == currentLocation) {
				output.put(currentLocation, output.get(currentLocation) + ecg_packet_length);
			} else {
				currentLocation = location;
			}
		} // foreach saturated_packet
		
		return output;
	}
	
	Map<Integer, Integer> ECGSaturation(int[] input) {
		SortedSet<Integer> saturated_packets = new TreeSet<Integer>();
		Map<Integer, Integer> output = new HashMap<Integer, Integer>();
		
		int packets = (input.length + (ecg_packet_length - 1) ) / ecg_packet_length; // round up
		
		// Foreach packet in the input
		for (int p = 0; p < packets; p++) {
			// Set the relevant indexes
			int start_index = p * ecg_packet_length;
			int end_index = ((p + 1) * ecg_packet_length) - 1;
			
			// Check that end_index is valid
			if (end_index >= input.length) {
				// TODO: alert: incomplete packet
				end_index = input.length;
			}
		
			// Check for saturation within the packet
			for (int i = start_index; i < end_index; i++) {
				if ((input[i] >= ecg_maximum) || (input[i] <= ecg_minimum) ) {
					saturated_packets.add(start_index);
				}
			} // foreach index
		} // foreach packet
		
		// Check if there were no saturated samples at all
		if (saturated_packets.size() == 0) {
			return output;
		}
		
		// Coalesce sets
		Integer currentLocation = saturated_packets.first();
		
		for (Integer location : saturated_packets) {
			if (!output.containsKey(currentLocation) ) {
				output.put(currentLocation, ecg_packet_length);
			}
			if (location - output.get(currentLocation) == currentLocation) {
				output.put(currentLocation, output.get(currentLocation) + ecg_packet_length);
			} else {
				currentLocation = location;
			}
		} // foreach saturated_packet
		
		return output;
	}
}
