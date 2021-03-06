block TestCatromOE
	import CN = Modelica.Constants;
	import SolarTherm.Models.CSP.CRS.HeliostatsField.CatromOE;
	import Modelica.Utilities.Files.loadResource;
	CatromOE oeff(
		file=loadResource("modelica://SolarTherm/Data/Optics/AliceSprings_N10M24_ext.csv"),
		n = 10,
		m = 24,
		sym = "E"
		);
	SolarTherm.Models.Sources.Weather.WeatherSource wea(
		file=loadResource("modelica://SolarTherm/Data/Weather/AUS_NT.Alice.Springs.Airport.943260_RMY.motab")
		);
equation
	connect(wea.wbus, oeff.wbus);
	//annotation(experiment(StartTime=0.0, StopTime=31536000.0, Interval=300, Tolerance=1e-06));
end TestCatromOE;
