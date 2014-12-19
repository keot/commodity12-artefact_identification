# Commodity12 Artefact Identification Algorithms

## Description

A series of electrocardiogram (ECG) artefact identification algorithms for the [Zephyr BioHarness 3](http://zephyranywhere.com/products/bioharness-3/).

Written as part of a deliverable to the [Commodity12](http://commodity12.eu/) project by James Mardell &lt;[james@keot.co.uk](mailto:james@keot.co.uk)&gt; on behalf of [Imperial College London](http://www3.imperial.ac.uk/rodriguez-villegas-lab).


## Directory Structure

### Miscellaneous Files and Directories

#### `./commodity12-artefact_sensing/

A Java project for developing and testing the artefact identification algorithms before implementing them on the [Commodity12 SmartHub](https://play.google.com/store/apps/details?id=com.bodytel.android&hl=en).




### Deliverable 3.2 (`./d32_*`)

#### `./d32_implementation`

```
ECGLowSNR.m
ecg-mains.csv
ecg-mains-ECGMainsInterference.csv
ECGMainsInterference.m
ecg-normal.csv
ecg-saturated.csv
ecg-saturated-ECGLowSaturation.csv
ecg-saturated-ECGSaturation.csv
ECGSaturation.m
```

#### `./d32_profiling`

```
BioHarness_caller.m
breathing.m
data_rate_calc.m
ecg_loader.m
ecg_loader_v02.m
heart_in_resp.m
load_accelerometer.m
load_bioharness.m
```


### Deliverable 3.3 (`./d33_*`)


#### `./d33_algorithms`

```
driftButterworth.m
driftMeanMedian.m
driftMedian.m
lowSnrStaticThreshold.m
mainsArraySlicing.m
mainsIirNotch.m
saturationStaticThreshold.m
```

#### `./d33_profiling`

```
derivsecgsyn.m               # Required by ecgsyn.m
ecgsyn.m                     # ECGSYN[1][] is a realistic ECG waveform generator, and is used to produce the artificial signals for comparative analysis throughout the profiling
filterProfiling.m            # An example profiling script using MATLAB DCS
filterProfilingStarter.m     # An example wrapper for the profiling script
noiseProfiling.m             # The noise profiling script returns the results for the seven SQIs (Signal Quality Indicies) for all combinations of noise and heart rate
qrsDetector.m                # A helper script to load two beat-detection scripts: OSEA (a.k.a. Epilimited) and WQRS
saveResults.m                # Dumps the contents of an SQI result structure to a file
sqi.m                        # The Signal Quality Indicies calculator
```

Peforms seven Signal Quality Indicies (SQIs) to determine the quality of the ECG signal. Some of these indices may require normalisation.

1. iSQI: Calculates the percentage of beats detected on each lead that were deteted on all leads
2. bSQI: Calculates the percentage of beats detected by 'wqrs' that were also detected by 'eplimited' (a.k.a 'osea')
3. pSQI: Calculates the relative power in the QRS complex
4. sSQI: Calculates the third moment (skewness) of the distribution
5. kSQI: Calculates the fourth moment (kurtosis) of the distribution
6. fSQI: Calculates the percentage of the signal which appeared to be a flat line
7. basSQI: Calculates the relative power in the baseline

[1]: McSharry P. E., Clifford G. D., Tarassenko, L. and Smith, L. "A Dynamical Model for Generating Synthetic Electrocardiogram Signals". In _IEEE Transactions on Biomedical Engineering_ *50*(3): 289--294; March 2003.


