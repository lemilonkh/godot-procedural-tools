extends Node

# Ridged multifractal terrain model
# Copyright 1994 F. Kenton Musgrave
# Good starting parameter values: H = 1.0, offset = 1.0, gain = 2.0
# Noise should be one octave only. TODO Or use own noise function?
static func ridged_multifractal(point: Vector3, noise: OpenSimplexNoise, H: float = 1.0, lacunarity: float = 1.0, octaves: int = 4, offset: float = 1.0, gain: float = 2.0) -> float:
	var exponent_array = []
	var frequency = 1.0
	
	for i in range(octaves + 1):
		exponent_array.append(pow(frequency, -H))
		frequency *= lacunarity
	
	# get first octave
	var signal_value = noise.get_noise_3dv(point)
	# make signal always positive, creates the ridges
	signal_value = abs(signal_value)
	# invert and translate (offset should be ~= 1.0)
	signal_value = offset - signal_value
	# square to increase sharpness of ridges
	signal_value *= signal_value
	
	var result = signal_value
	var weight = 1.0
	
	for i in range(1, octaves):
		# increase the frequency
		point.x *= lacunarity
		point.y *= lacunarity
		point.z *= lacunarity
		
		weight = clamp(signal_value * gain, 0.0, 1.0)
		signal_value = noise.get_noise_3dv(point)
		signal_value = abs(signal_value)
		signal_value = offset - signal_value
		signal_value *= signal_value
		signal_value *= weight
		result += signal_value * exponent_array[i]
	
	return result
