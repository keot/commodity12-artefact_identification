/**
 * 
 */
package uk.ac.ic.ee.cas;

import static org.junit.Assert.*;

import java.io.FileReader;
import java.io.IOException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Test;

import au.com.bytecode.opencsv.CSVReader;

/**
 * @author James Mardell <james.mardell@imperial.ac.uk>
 *
 */
public class ArtefactSensingTest {
	private CSVReader reader;
	private static String ecg_saturated_csv = "testfiles/ecg-saturated.csv";
	private static String ecg_mains_csv = "testfiles/ecg-mains.csv";
	private static String ecg_normal_csv = "testfiles/ecg-normal.csv";

	private final int[] readCSV(String file_name) {
		int[] data;
		
		try {
			// Open the test file
			reader = new CSVReader(new FileReader(file_name));
			List<String[]> inputFile = reader.readAll();
			reader.close();
				
			// Convert test data to ArrayList<Integer>
			// TODO: Replace this crude code
			List<Integer> inputData = new ArrayList<Integer>(); // unknown size
			
			for (String[] line: inputFile) {
				for (String s: line) inputData.add(Integer.valueOf(s)); 
			}
			
			// Convert ArrayList to int[]
			data = new int[inputData.size()];
			
			for (int i=0; i < data.length; i++) {
				data[i] = inputData.get(i).intValue();
			}
		
		} catch (IOException e) {
			fail("Unable to read input CSV file '" + file_name + "' for reading.");
			return null;
		}
		
		return data;
	}
	
	/**
	 * Test method for {@link uk.ac.ic.ee.cas.ArtefactSensing#ECGSaturation(int[])}.
	 */
	@Test
	public void testECGSaturationNormalData() {		
			// Perform the test
			int[] input_ecg_data = readCSV(ecg_normal_csv);
			ArtefactSensing tester = new ArtefactSensing();
			
			// Create empty list for ecg_unsaturated_csv (i.e. there are no events)
			Map<Integer, Integer> outputECGData = new HashMap<Integer, Integer>();
			
			// Assert the result
			assertEquals("ECG saturation, normal signal: output data incorrect.", outputECGData, tester.ECGSaturation(input_ecg_data) );
	}
	
	@Test
	public void testECGSaturationBadData() {		
			// Perform the test
			int[] input_ecg_data = readCSV(ecg_saturated_csv);
			ArtefactSensing tester = new ArtefactSensing();
			
			// Create result manually for ecg_saturated_csv
			Map<Integer, Integer> outputECGData = new HashMap<Integer, Integer>();
			outputECGData.put(945, 378); // saturated low
			outputECGData.put(3024, 1008); // saturated high
			
			// Assert the result
			assertEquals("ECG saturation, bad signal: output data incorrect.", outputECGData, tester.ECGSaturation(input_ecg_data) );
	}
	
	@Test
	public void testECGMainsInterferenceBadData() {		
			// Perform the test
			int[] input_ecg_data = readCSV(ecg_mains_csv);
			ArtefactSensing tester = new ArtefactSensing();
			
			// Entire signal is mains noise
			Map<Integer, Integer> outputECGData = new HashMap<Integer, Integer>();
			outputECGData.put(0, input_ecg_data.length);
			
			// Assert the result
			assertEquals("ECG mains interference, bad signal: output data incorrect.", outputECGData, tester.ECGMainsInterference(input_ecg_data) );
	}
	
	@Test
	public void testECGMainsInterferenceNormalData() {		
			// Perform the test
			int[] input_ecg_data = readCSV(ecg_normal_csv);
			ArtefactSensing tester = new ArtefactSensing();
			
			// Create empty result
			Map<Integer, Integer> outputECGData = new HashMap<Integer, Integer>();
			
			// Assert the result
			assertEquals("ECG mains interference, normal signal: output data incorrect.", outputECGData, tester.ECGMainsInterference(input_ecg_data) );
	}
	
	@Test
	public void testECGLowSNRNormalData() {		
			// Perform the test
			int[] input_ecg_data = readCSV(ecg_normal_csv);
			ArtefactSensing tester = new ArtefactSensing();
			
			// Create empty result
			Map<Integer, Integer> outputECGData = new HashMap<Integer, Integer>();
			
			// Assert the result
			assertEquals("ECG low SNR, normal signal: output data incorrect.", outputECGData, tester.ECGLowSNR(input_ecg_data) );
	}
	
	@Test
	public void testECGLowSNRBadData() {		
			// Perform the test
			int[] input_ecg_data = readCSV(ecg_mains_csv);
			ArtefactSensing tester = new ArtefactSensing();
			
			// Create empty result
			Map<Integer, Integer> outputECGData = new HashMap<Integer, Integer>();
			
			// Assert the result
			assertEquals("ECG low SNR, bad signal: output data incorrect.", outputECGData, tester.ECGLowSNR(input_ecg_data) );
	}
}