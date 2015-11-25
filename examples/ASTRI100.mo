model ASTRI100
	import SI = Modelica.SIunits;
	import CN = Modelica.Constants;
	import CV = Modelica.SIunits.Conversions;

	// Salt is 60% NaNO3 40% KNO3
	replaceable package MedRec = SolarTherm.Media.Sodium;

	inner Modelica.Fluid.System system(
		energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
		//energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial,
		//energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
		//energyDynamics=Modelica.Fluid.Types.Dynamics.DynamicFreeInitial,
		allowFlowReversal=false);

	parameter String weaFile = "resources/Alice_Springs_Real2000_Created20130430.motab";
	// Might have to deactivate price calcs if not connected to NEM
	parameter String priFile = "resources/aemo_vic_2014.motab";

	// Power block
	// Boiler operating pressure 100Bar
	// Condenser pressure ratio 1.0028
	// Condender type air cooled
	// Inlet temperature 574degC
	// Outlet temperature 290degC
	// Design power 294MWt (calc)
	// Turbine gross output 111MWe
	// Gross to net conversion factor 0.9
	// Estimated net output 99.9MWe (calc)
	// Backup boiler LHV efficiency 0.9
	// Thermal fraction for standby 0.2
	// Thermal fraction for start 0.5
	// Min turbine operation 0.25
	// Min start temperature 500degC
	// Standby period 2h
	// Minimum restart time 1h
	// Start time 0.5h
	// Rated conversion efficiency 0.3774
	parameter SI.Power P_rate = 100000 "Rating of power block";
	parameter SI.Efficiency eff_adj = 0.9 "Adjustment factor for power block efficiency";
	parameter SI.Efficiency eff_est = 0.48 "Estimate of overall power block efficiency";

	// Field
	// Start up energy of single heliostat 0.025kWh
	// Tracking power of single heliostat 0.055kWe
	// Total land area 1452acres (calc)
	// Heliostat area 144.375m2 (calc)
	// Heliostat height 12.2m
	// Heliostat width 12.2m
	// Image error 1.53mrad
	// Mirror reflectance 0.9
	// Number of heliostats 6377 (calc)

	parameter SI.Area A_con = 700 "Concentrator area";

	// Receiver
	// Aperture height 18m (calc)
	// Aperture width 15m
	// Coating absorptance 0.94
	// Coating emmittance 0.88
	// Flow pattern 1
	// Heat loss factor 1
	// Material type Stainless AISI316
	// Max flow rate 1484.76kg/s (calc)
	// Max flux 1000kWt/m2
	// Max temperature to receiver 350degC
	// Max turndown fraction 0.25
	// Number of panels 20
	// Design thermal power 529.412MWt (calc)
	// Start energy fraction 0.25
	// Start time 0.2hr
	// Required outlet temp 574degC
	// Solar multiple 1.8
	// Tower height 183m
	// Tube OD 40mm
	// Tube WT 1.25mm
	// Tower parasitics 2.69MWe (calc)
	// Piping length multiplier 2.6
	// Piping loss coeff 10200Wt/m
	// Pump efficiency 0.85
	// Pumping power through power block 0.55kJ/kg
	// Pumping power through storage 0.15kJ/kg
	// Total piping length 476.658m
	parameter SI.Area A_rec = 1 "Receiver area";
	parameter Real em_steel = 0.85 "Emissivity of reciever";
	parameter SI.CoefficientOfHeatTransfer h_th_rec = 10 "Receiver heat tran coeff";

	parameter SI.Efficiency eff_ext = 0.9 "Extractor efficiency";

	// Storage
	// Cold tank heater set temperature 280degC
	// Filler material quartzite
	// Filler material density 2640kg/m3 (calc)
	// Filler material specific heat 1.105kJ/kgK (calc)
	// Full load hours 4h
	// Hot tank heater set temperature 500degC
	// Cold initial temperature 290degC
	// Cold initial volume 3831m3 (calc)
	// Hot initial temperatue 574degC
	// Hot initial volume 1642m3 (calc)
	// Max storage volume 5200 (calc)
	// Min storage volume 274 (calc)
	// Tank diameter 18.67m
	// Tank height 20m
	// Tank min fluid height 1m
	parameter Real t_storage(unit="h") = 5 "Hours of storage";
	//parameter SI.Mass m_max = (1/eff_est)*P_rate*t_storage*3600/
	//	(MedRec.cp_const*(T_hot_set - T_cold_set)) "Max mass in tanks";
		// only works with PartialSimpleMedium
	parameter SI.Mass m_max = (1/eff_est)*P_rate*t_storage*3600/
		(1277*(T_hot_set - T_cold_set)) "Max mass in tanks";
	parameter MedRec.Temperature T_cold_set = CV.from_degC(290) "Target cold tank T";
	parameter MedRec.Temperature T_hot_set = CV.from_degC(565) "Target hot tank T";
	parameter MedRec.Temperature T_cold_start = CV.from_degC(290) "Cold tank starting T";
	parameter MedRec.Temperature T_hot_start = CV.from_degC(565) "Hot tank starting T";
	parameter SI.RadiantPower R_go = 200*A_con "Receiver radiant power for running";
	parameter SI.MassFlowRate m_flow_fac = 1.2 "Mass flow factor for receiver";
	//parameter SI.MassFlowRate m_flow_pblk = (1/eff_est)*P_rate/
	//	(MedRec.cp_const*(T_hot_set - T_cold_set)) "Mass flow rate for power block";
		// only works with PartialSimpleMedium
	parameter SI.MassFlowRate m_flow_pblk = (1/eff_est)*P_rate/
		(1277*(T_hot_set - T_cold_set)) "Mass flow rate for power block";
	parameter SI.Mass m_up_warn = 0.85*m_max;
	parameter SI.Mass m_up_stop = 0.95*m_max;
	parameter Real split_cold = 0.95 "Starting fluid fraction in cold tank";

	parameter SolarTherm.Utilities.Finances.Money C_cap =
			120*A_con // field cost
			+ 135*A_con // receiver cost
			//+ (30/(1e3*3600))*m_max*MedRec.cp_const*(T_hot_set - T_cold_set) // storage cost
			// only works with PartialSimpleMedium
			+ (30/(1e3*3600))*m_max*1277*(T_hot_set - T_cold_set) // storage cost
			+ (1440/1e3)*P_rate // power block cost
			"Capital costs";
	parameter SolarTherm.Utilities.Finances.MoneyPerYear C_main =
			10*A_con // field cleaning/maintenance
			"Maintenance costs for each year";
	parameter Real r_disc = 0.05 "Discount rate";
	parameter Integer t_life(unit="year") = 20 "Lifetime of plant";
	parameter Integer t_cons(unit="year") = 1 "Years of construction";

	SolarTherm.Utilities.Weather.WeatherSource wea(weaFile=weaFile);
	SolarTherm.Utilities.Finances.SpotPriceTable pri(fileName=priFile);

	SolarTherm.Optics.IdealInc con(A_con=A_con, A_foc=A_rec);

	SolarTherm.Receivers.Plate rec(
		redeclare package Medium=MedRec,
		A=A_rec, em=em_steel, h_th=h_th_rec);

	SolarTherm.Pumps.IdealPump pmp_rec(
		redeclare package Medium=MedRec,
		cont_m_flow=true,
		use_input=true);
	SolarTherm.Pumps.IdealPump pmp_ext(
		redeclare package Medium=MedRec,
		cont_m_flow=true,
		use_input=true);

	SolarTherm.Storage.FluidTank ctnk(
		redeclare package Medium=MedRec,
		m_max=m_max,
		m_start=m_max*split_cold,
		T_start=T_cold_start);
	SolarTherm.Storage.FluidTank htnk(
		redeclare package Medium=MedRec,
		m_max=m_max,
		m_start=m_max*(1 - split_cold),
		T_start=T_hot_start);

	SolarTherm.HeatExchangers.Extractor ext(
		redeclare package Medium=MedRec,
		eff = eff_ext,
		use_input=false,
		T_fixed=T_cold_set);

	SolarTherm.PowerBlocks.HeatGen pblk(
		redeclare package Medium=MedRec,
		P_rate=P_rate,
		eff_adj=eff_adj);

	SolarTherm.Control.Trigger hf_trig(
		low=m_up_warn,
		up=m_up_stop,
		y_0=true);
	SolarTherm.Control.Trigger cf_trig(
		low=m_up_warn,
		up=m_up_stop,
		y_0=true);

	Boolean radiance_good "Adequate radiant power on receiver";
	Boolean fill_htnk "Hot tank can be filled";
	Boolean fill_ctnk "Cold tank can be filled";

	SI.Power P_elec;
	SolarTherm.Utilities.Finances.Money R_spot(start=0, fixed=true)
		"Spot market revenue";
	SI.Energy E_elec(start=0, fixed=true) "Generate electricity";
equation
	connect(wea.wbus, con.wbus);
	connect(wea.wbus, rec.wbus);
	connect(wea.wbus, pblk.wbus);
	connect(con.R_foc, rec.R);
	connect(ctnk.port_b, pmp_rec.port_a);
	connect(pmp_rec.port_b, rec.port_a);
	connect(rec.port_b, htnk.port_a);

	connect(htnk.port_b, pmp_ext.port_a);
	connect(pmp_ext.port_b, ext.port_a);
	connect(ext.port_b, ctnk.port_a);

	connect(ext.Q_flow, pblk.Q_flow);
	connect(ext.T, pblk.T);

	connect(hf_trig.x, htnk.m);
	connect(cf_trig.x, ctnk.m);

	radiance_good = sum(rec.R) >= R_go;

	fill_htnk = not hf_trig.y;
	fill_ctnk = not cf_trig.y;

	rec.door_open = radiance_good and fill_htnk;
	pmp_rec.m_flow_set = if radiance_good and fill_htnk then
		m_flow_fac*sum(rec.R)/(A_con*1000) else 0;
	pmp_ext.m_flow_set = if fill_ctnk then m_flow_pblk else 0;

	con.track = true;

	P_elec = pblk.P_elec;
	der(E_elec) = P_elec;
	der(R_spot) = P_elec*pri.price;
end ASTRI100;
