within SolarTherm.Media.Sodium.Sodium_utilities;
function p_v "Vapour pressure of saturated sodium"
	extends Modelica.Icons.Function;
	input Modelica.SIunits.Temperature T "Temperature";
	output Modelica.Media.Interfaces.Types.AbsolutePressure p "Pressure";
protected
	constant Real a = 11.9463;
	constant Real b = -12633.7;
	constant Real c = -0.4672;
algorithm
	//Ref. ANL/RE-95/2, pp. 55
	p := (1e+6) * exp(a + b / T + c * log(max(1,T)));
	annotation(derivative = p_v_T_der);
end p_v;
